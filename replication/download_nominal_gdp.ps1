param(
    [ValidateSet("0", "1")]
    [string]$Refresh = "0"
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$rawDirectory = Join-Path (Get-Location).Path "data/raw"
New-Item -ItemType Directory -Path $rawDirectory -Force | Out-Null

$archivePath = Join-Path $rawDirectory "wb_gdp_current_lcu.zip"
$csvPath = Join-Path $rawDirectory "wb_gdp_current_lcu.csv"
$metadataPath = Join-Path $rawDirectory "wb_gdp_current_lcu_metadata.txt"
$sourceUrl = "https://api.worldbank.org/v2/country/all/indicator/NY.GDP.MKTP.CN?source=2&downloadformat=csv"
$indicatorCode = "NY.GDP.MKTP.CN"
$indicatorName = "GDP (current LCU)"
$requiredYears = @("1989", "2024")
$expectedCsvPattern = "API_NY.GDP.MKTP.CN*.csv"

function Test-WbWideCsv {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$ExpectedIndicatorCode,
        [Parameter(Mandatory = $true)][string[]]$RequiredYears
    )

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
            $lines[$i] -match "Indicator Name" -and
            $lines[$i] -match "Indicator Code") {
            $headerIndex = $i
            break
        }
    }

    if ($headerIndex -lt 0) {
        throw "World Bank CSV header was not found in $Path."
    }

    $headerLine = $lines[$headerIndex].TrimStart([char]0xFEFF)
    $headerColumns = @($headerLine.Split(",") | ForEach-Object { $_.Trim().Trim('"') })

    foreach ($requiredColumn in @("Country Name", "Country Code", "Indicator Name", "Indicator Code")) {
        if ($headerColumns -notcontains $requiredColumn) {
            throw "World Bank CSV is missing required column '$requiredColumn'."
        }
    }

    foreach ($requiredYear in $RequiredYears) {
        if ($headerColumns -notcontains $requiredYear) {
            throw "World Bank CSV is missing required year column $requiredYear."
        }
    }

    $dataLineIndex = $headerIndex + 1
    while ($dataLineIndex -lt $lines.Count -and [string]::IsNullOrWhiteSpace($lines[$dataLineIndex])) {
        $dataLineIndex++
    }

    if ($dataLineIndex -ge $lines.Count) {
        throw "World Bank CSV contains a header but no country data rows: $Path"
    }

    $firstRecord = $lines[$dataLineIndex] | ConvertFrom-Csv -Header $headerColumns
    if ([string]$firstRecord.'Indicator Code' -ne $ExpectedIndicatorCode) {
        throw "World Bank CSV contains indicator '$($firstRecord.'Indicator Code')'; expected '$ExpectedIndicatorCode'."
    }

    if ([string]::IsNullOrWhiteSpace([string]$firstRecord.'Country Code')) {
        throw "The first World Bank country row has no country code."
    }
}

try {
    $shouldDownload = ($Refresh -eq "1") -or
        (-not (Test-Path -LiteralPath $archivePath -PathType Leaf)) -or
        (-not (Test-Path -LiteralPath $csvPath -PathType Leaf))

    if (-not $shouldDownload) {
        try {
            Test-WbWideCsv -Path $csvPath -ExpectedIndicatorCode $indicatorCode -RequiredYears $requiredYears
            Write-Host "Preserving existing validated World Bank source CSV."
        }
        catch {
            Write-Warning ("Existing World Bank CSV failed validation and will be downloaded again: " + $_.Exception.Message)
            $shouldDownload = $true
        }
    }

    $downloadedThisRun = $false

    if ($shouldDownload) {
        $temporaryRoot = Join-Path $env:TEMP ("wb-gdp-current-lcu-" + [guid]::NewGuid().ToString("N"))
        New-Item -ItemType Directory -Path $temporaryRoot -Force | Out-Null

        try {
            $temporaryArchive = Join-Path $temporaryRoot "wb_gdp_current_lcu.zip"
            $temporaryCsv = Join-Path $temporaryRoot "wb_gdp_current_lcu.csv"
            $extractDirectory = Join-Path $temporaryRoot "extracted"
            New-Item -ItemType Directory -Path $extractDirectory -Force | Out-Null

            Write-Host "Downloading World Bank WDI indicator $indicatorCode..."
            Invoke-WebRequest -Uri $sourceUrl -OutFile $temporaryArchive -UseBasicParsing -Headers @{ "User-Agent" = "financial-cycles-macroeconomic-fluctuations-Stata/1.0" } -ErrorAction Stop

            if ((Get-Item -LiteralPath $temporaryArchive).Length -lt 1000) {
                throw "World Bank CSV archive is unexpectedly small."
            }

            Expand-Archive -LiteralPath $temporaryArchive -DestinationPath $extractDirectory -Force

            $csvMatches = @(
                Get-ChildItem -LiteralPath $extractDirectory -Recurse -File |
                Where-Object {
                    $_.Name -like $expectedCsvPattern -and
                    $_.Name -notmatch "Metadata"
                }
            )

            if ($csvMatches.Count -ne 1) {
                throw "Expected exactly one $indicatorCode data CSV in the World Bank archive; found $($csvMatches.Count)."
            }

            Copy-Item -LiteralPath $csvMatches[0].FullName -Destination $temporaryCsv -Force
            Test-WbWideCsv -Path $temporaryCsv -ExpectedIndicatorCode $indicatorCode -RequiredYears $requiredYears

            Move-Item -LiteralPath $temporaryArchive -Destination $archivePath -Force
            Move-Item -LiteralPath $temporaryCsv -Destination $csvPath -Force
            $downloadedThisRun = $true
        }
        finally {
            if (Test-Path -LiteralPath $temporaryRoot) {
                Remove-Item -LiteralPath $temporaryRoot -Recurse -Force
            }
        }
    }

    Test-WbWideCsv -Path $csvPath -ExpectedIndicatorCode $indicatorCode -RequiredYears $requiredYears

    $archiveHash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash
    $csvHash = (Get-FileHash -LiteralPath $csvPath -Algorithm SHA256).Hash

    if (-not $downloadedThisRun -and (Test-Path -LiteralPath $metadataPath -PathType Leaf)) {
        $existingMetadata = @(Get-Content -LiteralPath $metadataPath)
        $storedIndicatorLine = $existingMetadata | Where-Object { $_ -like "Indicator: *" } | Select-Object -First 1
        $storedArchiveLine = $existingMetadata | Where-Object { $_ -like "Archive SHA-256: *" } | Select-Object -First 1
        $storedCsvLine = $existingMetadata | Where-Object { $_ -like "CSV SHA-256: *" } | Select-Object -First 1
        $storedIndicator = if ($storedIndicatorLine) { $storedIndicatorLine -replace '^Indicator:\s*', '' } else { "" }
        $storedArchiveHash = if ($storedArchiveLine) { $storedArchiveLine -replace '^Archive SHA-256:\s*', '' } else { "" }
        $storedCsvHash = if ($storedCsvLine) { $storedCsvLine -replace '^CSV SHA-256:\s*', '' } else { "" }

        if ($storedIndicator -eq $indicatorCode -and $storedArchiveHash -eq $archiveHash -and $storedCsvHash -eq $csvHash) {
            Write-Host "Existing source checksums match the retained provenance metadata; metadata is unchanged."
            exit 0
        }

        Write-Warning "Existing provenance metadata is missing or does not match the current source-file checksums. Rebuilding metadata without claiming a new retrieval date."
    }

    $lastUpdated = "Not returned by World Bank API"
    $metadataUrl = "https://api.worldbank.org/v2/country/all/indicator/NY.GDP.MKTP.CN?source=2&date=2024&format=json&per_page=1"

    try {
        $apiMetadata = Invoke-RestMethod -Uri $metadataUrl -UseBasicParsing -Headers @{ "User-Agent" = "financial-cycles-macroeconomic-fluctuations-Stata/1.0" } -ErrorAction Stop
        if ($apiMetadata.Count -gt 0 -and $apiMetadata[0].lastupdated) {
            $lastUpdated = [string]$apiMetadata[0].lastupdated
        }
    }
    catch {
        Write-Warning ("Could not retrieve the World Bank source update date: " + $_.Exception.Message)
    }

    $metadataGenerated = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")
    if ($downloadedThisRun) {
        $retrievalDate = $metadataGenerated
        $retrievalStatus = "Downloaded during this run"
    }
    else {
        $retrievalDate = "Unknown; source files predate verifiable retrieval metadata"
        $retrievalStatus = "Metadata generated for existing source files; original retrieval date is not established"
    }

    $metadataLines = @(
        "Indicator: $indicatorCode",
        "Indicator name: $indicatorName",
        "Source database: World Development Indicators (World Bank source ID 2)",
        "Unit: current local currency units; current prices; annual frequency",
        "Source URL: $sourceUrl",
        "Retrieval date (UTC): $retrievalDate",
        "Metadata generated (UTC): $metadataGenerated",
        "Retrieval status: $retrievalStatus",
        "World Bank last-updated date from API metadata: $lastUpdated",
        "Archive SHA-256: $archiveHash",
        "CSV SHA-256: $csvHash",
        "The Stata validation script retains 1989-2024 and matches the 43 BIS economies."
    )

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    $temporaryMetadataPath = "$metadataPath.tmp"
    [System.IO.File]::WriteAllLines($temporaryMetadataPath, $metadataLines, $utf8NoBom)
    Move-Item -LiteralPath $temporaryMetadataPath -Destination $metadataPath -Force

    Write-Host "Validated World Bank source: $indicatorCode."
    Write-Host "CSV: $csvPath"
    Write-Host "Archive: $archivePath"
    Write-Host "Retrieval date: $retrievalDate"
    Write-Host "World Bank last-updated date: $lastUpdated"
    Write-Host "CSV SHA-256: $csvHash"
    exit 0
}
catch {
    Write-Error ("World Bank source acquisition failed: " + $_.Exception.Message)
    exit 1
}