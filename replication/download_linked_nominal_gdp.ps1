param(
    [ValidateSet("0", "1")]
    [string]$Refresh = "0"
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$rawDirectory = Join-Path (Get-Location).Path "data/raw"
New-Item -ItemType Directory -Path $rawDirectory -Force | Out-Null

$archivePath = Join-Path $rawDirectory "wb_gdp_linked_current_lcu.zip"
$csvPath = Join-Path $rawDirectory "wb_gdp_linked_current_lcu.csv"
$metadataPath = Join-Path $rawDirectory "wb_gdp_linked_current_lcu_metadata.txt"
$sourceUrl = "https://api.worldbank.org/v2/country/all/indicator/NY.GDP.MKTP.CN.AD?source=2&downloadformat=csv"

function Test-WbWideCsv {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Expected World Bank CSV was not created: $Path"
    }

    $file = Get-Item -LiteralPath $Path
    if ($file.Length -lt 1000) {
        throw "World Bank CSV is unexpectedly small ($($file.Length) bytes): $Path"
    }

    $lines = @(Get-Content -LiteralPath $Path -TotalCount 12)
    $headerIndex = -1

    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "Country Name" -and
            $lines[$i] -match "Country Code" -and
            $lines[$i] -match "Indicator Code") {
            $headerIndex = $i
            break
        }
    }

    if ($headerIndex -lt 0) {
        throw "World Bank CSV header was not found in $Path."
    }

    $headerColumns = @($lines[$headerIndex].Split(",") | ForEach-Object { $_.Trim().Trim('"') })
    foreach ($requiredYear in @("1990", "2024")) {
        if ($headerColumns -notcontains $requiredYear) {
            throw "World Bank CSV is missing required year column $requiredYear."
        }
    }

    if ($headerIndex -ge ($lines.Count - 1)) {
        throw "World Bank CSV contains a header but no country data rows."
    }
}

try {
    $shouldDownload = ($Refresh -eq "1") -or
        (-not (Test-Path -LiteralPath $archivePath -PathType Leaf)) -or
        (-not (Test-Path -LiteralPath $csvPath -PathType Leaf))

    if (-not $shouldDownload) {
        try {
            Test-WbWideCsv -Path $csvPath
            Write-Host "Preserving existing validated World Bank GDP, linked series (current LCU) CSV."
        }
        catch {
            Write-Warning ("Existing World Bank CSV failed validation and will be downloaded again: " + $_.Exception.Message)
            $shouldDownload = $true
        }
    }

    if ($shouldDownload) {
        $temporaryRoot = Join-Path $env:TEMP ("wb-gdp-current-lcu-" + [guid]::NewGuid().ToString("N"))
        New-Item -ItemType Directory -Path $temporaryRoot -Force | Out-Null

        try {
            $temporaryArchive = Join-Path $temporaryRoot "wb_gdp_linked_current_lcu.zip"
            $temporaryCsv = Join-Path $temporaryRoot "wb_gdp_linked_current_lcu.csv"
            $extractDirectory = Join-Path $temporaryRoot "extracted"
            New-Item -ItemType Directory -Path $extractDirectory -Force | Out-Null

            Write-Host "Downloading World Bank WDI GDP, linked series (current LCU), indicator NY.GDP.MKTP.CN.AD..."
            Invoke-WebRequest -Uri $sourceUrl -OutFile $temporaryArchive -UseBasicParsing -Headers @{ "User-Agent" = "financial-cycles-macroeconomic-fluctuations-Stata/1.0" } -ErrorAction Stop

            if ((Get-Item -LiteralPath $temporaryArchive).Length -lt 1000) {
                throw "World Bank CSV archive is unexpectedly small."
            }

            Expand-Archive -LiteralPath $temporaryArchive -DestinationPath $extractDirectory -Force

            $csvMatches = @(
                Get-ChildItem -LiteralPath $extractDirectory -Recurse -File |
                Where-Object {
                    $_.Name -like "API_NY.GDP.MKTP.CN.AD*.csv" -and
                    $_.Name -notmatch "Metadata"
                }
            )

            if ($csvMatches.Count -ne 1) {
                throw "Expected exactly one NY.GDP.MKTP.CN.AD data CSV in the World Bank archive; found $($csvMatches.Count)."
            }

            Copy-Item -LiteralPath $csvMatches[0].FullName -Destination $temporaryCsv -Force
            Test-WbWideCsv -Path $temporaryCsv

            Move-Item -LiteralPath $temporaryArchive -Destination $archivePath -Force
            Move-Item -LiteralPath $temporaryCsv -Destination $csvPath -Force
        }
        finally {
            if (Test-Path -LiteralPath $temporaryRoot) {
                Remove-Item -LiteralPath $temporaryRoot -Recurse -Force
            }
        }
    }

    Test-WbWideCsv -Path $csvPath

    $metadataUrl = "https://api.worldbank.org/v2/country/all/indicator/NY.GDP.MKTP.CN.AD?source=2&date=2024&format=json&per_page=1"
    $lastUpdated = "Not returned by World Bank API"

    try {
        $apiMetadata = Invoke-RestMethod -Uri $metadataUrl -UseBasicParsing -Headers @{ "User-Agent" = "financial-cycles-macroeconomic-fluctuations-Stata/1.0" } -ErrorAction Stop
        if ($apiMetadata.Count -gt 0 -and $apiMetadata[0].lastupdated) {
            $lastUpdated = [string]$apiMetadata[0].lastupdated
        }
    }
    catch {
        Write-Warning ("Could not retrieve the World Bank source update date: " + $_.Exception.Message)
    }

    $archiveHash = "Not available"
    if (Test-Path -LiteralPath $archivePath -PathType Leaf) {
        $archiveHash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash
    }

    $csvHash = (Get-FileHash -LiteralPath $csvPath -Algorithm SHA256).Hash

    $metadataLines = @(
        "Indicator: NY.GDP.MKTP.CN.AD",
        "Indicator name: GDP, linked series (current LCU)",
        "Source database: World Development Indicators (World Bank source ID 2)",
        "Unit: current local currency units; current prices; annual frequency",
        "Source URL: $sourceUrl",
        "Retrieval date (UTC): $((Get-Date).ToUniversalTime().ToString('yyyy-MM-dd HH:mm:ss'))",
        "World Bank last-updated date from API metadata: $lastUpdated",
        "Archive SHA-256: $archiveHash",
        "CSV SHA-256: $csvHash",
        "The Stata validation script retains 1989-2024 and matches the 43 BIS economies."
    )

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllLines($metadataPath, $metadataLines, $utf8NoBom)

    Write-Host "Validated World Bank GDP, linked series (current LCU) source."
    Write-Host "CSV: $csvPath"
    Write-Host "Archive: $archivePath"
    Write-Host "World Bank last-updated date: $lastUpdated"
    Write-Host "CSV SHA-256: $csvHash"
    exit 0
}
catch {
    Write-Error ("World Bank GDP source acquisition failed: " + $_.Exception.Message)
    exit 1
}