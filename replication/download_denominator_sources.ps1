param(
    [ValidateSet("0", "1")]
    [string]$Refresh = "0"
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Windows PowerShell 5.1 may otherwise negotiate an older TLS version.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$rawDirectory = Join-Path (Get-Location).Path "data/raw"
New-Item -ItemType Directory -Path $rawDirectory -Force | Out-Null

$series = @(
    [pscustomobject]@{
        FileName = "bis_credit_gap_ratio.csv"
        Url = "https://stats.bis.org/api/v2/data/dataflow/BIS/WS_CREDIT_GAP/1.0/Q..P.A.A?format=csv&startPeriod=1990-Q1&endPeriod=2024-Q4"
        RequiredColumns = @("FREQ", "BORROWERS_CTY", "TC_BORROWERS", "TC_LENDERS", "CG_DTYPE", "UNIT_MULT", "TIME_PERIOD", "OBS_VALUE")
    },
    [pscustomobject]@{
        FileName = "bis_credit_gap_trend.csv"
        Url = "https://stats.bis.org/api/v2/data/dataflow/BIS/WS_CREDIT_GAP/1.0/Q..P.A.B?format=csv&startPeriod=1990-Q1&endPeriod=2024-Q4"
        RequiredColumns = @("FREQ", "BORROWERS_CTY", "TC_BORROWERS", "TC_LENDERS", "CG_DTYPE", "UNIT_MULT", "TIME_PERIOD", "OBS_VALUE")
    },
    [pscustomobject]@{
        FileName = "bis_total_credit_xdc.csv"
        Url = "https://stats.bis.org/api/v2/data/dataflow/BIS/WS_TC/2.0/Q..P.A.M.XDC.A?format=csv&startPeriod=1990-Q1&endPeriod=2024-Q4"
        RequiredColumns = @("FREQ", "BORROWERS_CTY", "TC_BORROWERS", "TC_LENDERS", "VALUATION", "UNIT_TYPE", "TC_ADJUST", "UNIT_MULT", "TIME_PERIOD", "OBS_VALUE")
    },
    [pscustomobject]@{
        FileName = "bis_total_credit_gdp.csv"
        Url = "https://stats.bis.org/api/v2/data/dataflow/BIS/WS_TC/2.0/Q..P.A.M.770.A?format=csv&startPeriod=1990-Q1&endPeriod=2024-Q4"
        RequiredColumns = @("FREQ", "BORROWERS_CTY", "TC_BORROWERS", "TC_LENDERS", "VALUATION", "UNIT_TYPE", "TC_ADJUST", "UNIT_MULT", "TIME_PERIOD", "OBS_VALUE")
    }
)

function Test-BisCsv {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string[]]$RequiredColumns
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Expected BIS file was not created: $Path"
    }

    $file = Get-Item -LiteralPath $Path
    if ($file.Length -lt 100) {
        throw "BIS file is unexpectedly small ($($file.Length) bytes): $Path"
    }

    $header = Get-Content -LiteralPath $Path -TotalCount 1
    $header = $header.TrimStart([char]0xFEFF)
    $columns = @($header.Split(",") | ForEach-Object { $_.Trim().Trim('"') })
    $missing = @($RequiredColumns | Where-Object { $_ -notin $columns })

    if ($missing.Count -gt 0) {
        throw "The BIS CSV header in $Path is missing required columns: $($missing -join ', '). Header received: $header"
    }

    $firstLines = @(Get-Content -LiteralPath $Path -TotalCount 2)
    if ($firstLines.Count -lt 2) {
        throw "The BIS CSV contains a header but no data rows: $Path"
    }
}

try {
    foreach ($item in $series) {
        $destination = Join-Path $rawDirectory $item.FileName
        $shouldDownload = ($Refresh -eq "1") -or (-not (Test-Path -LiteralPath $destination -PathType Leaf))

        if (-not $shouldDownload) {
            try {
                Test-BisCsv -Path $destination -RequiredColumns $item.RequiredColumns
                Write-Host "Preserving existing validated source file: $($item.FileName)"
            }
            catch {
                Write-Warning ("Existing file failed validation and will be downloaded again: " + $_.Exception.Message)
                $shouldDownload = $true
            }
        }

        if ($shouldDownload) {
            $temporary = "$destination.download"
            if (Test-Path -LiteralPath $temporary) {
                Remove-Item -LiteralPath $temporary -Force
            }

            Write-Host "Downloading $($item.FileName)..."
            try {
                Invoke-WebRequest -Uri $item.Url -OutFile $temporary -UseBasicParsing -Headers @{ "User-Agent" = "financial-cycles-macroeconomic-fluctuations-Stata/1.0" } -ErrorAction Stop
                Test-BisCsv -Path $temporary -RequiredColumns $item.RequiredColumns
                Move-Item -LiteralPath $temporary -Destination $destination -Force
            }
            finally {
                if (Test-Path -LiteralPath $temporary) {
                    Remove-Item -LiteralPath $temporary -Force
                }
            }
        }
        else {
            Write-Host "Preserving existing source file: $($item.FileName)"
        }

        Test-BisCsv -Path $destination -RequiredColumns $item.RequiredColumns
        $size = (Get-Item -LiteralPath $destination).Length
        Write-Host "Validated $($item.FileName) ($size bytes)."
    }

    Write-Host "All four supplementary BIS source files are present and passed header checks."
    exit 0
}
catch {
    Write-Error ("BIS source acquisition failed: " + $_.Exception.Message)
    exit 1
}
