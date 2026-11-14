#requires -version 5.1
<#
.SYNOPSIS
    Publish the 14 reviewed Stata figures (PNG and editable GPH) to main.
.DESCRIPTION
    Reads figures from the current local repository, creates an isolated
    temporary Git worktree based on origin/main, copies only the expected
    reviewed figures, commits any changes, and pushes to main.

    Does not modify local datasets, logs, analysis results or source files.
    Does not stage or commit unrelated local changes.

    Run only after the latest combined sensitivity do-file has completed
    successfully in Stata and all intended final figures exist locally.
#>
[CmdletBinding()]
param(
    [switch] $PngOnly
)
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Invoke-Git {
    param([Parameter(Mandatory=$true)][string[]] $Arguments)
    & git @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw ("Git command failed (exit {0}): git {1}" -f $LASTEXITCODE, ($Arguments -join " "))
    }
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$verifiedRoot = (& git -C $repoRoot rev-parse --show-toplevel)
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($verifiedRoot)) {
    throw "This script must be run from its cloned Git repository."
}
$figures = @(
    "asymmetric_gap_coefficients",
    "balanced_panel_asymmetry",
    "balanced_panel_h1_coefficients",
    "bal_panel_horizon_coef",
    "credit_gap_gdp_scatter",
    "fe_horizon_coefficients",
    "mean_credit_gap_by_year",
    "nominal_gdp_validation_country_growth_mae",
    "nominal_gdp_validation_country_level_deviation",
    "nominal_gdp_validation_median_growth_difference",
    "nominal_gdp_validation_p95_growth_difference",
    "nominal_gdp_validation_scatter",
    "ratio_component_coefficients",
    "ratio_component_growth"
)
$extensions = if ($PngOnly) { @(".png") } else { @(".png", ".gph") }

$sourceFiles = @()
foreach ($stem in $figures) {
    foreach ($ext in $extensions) {
        $relative = "outputs/figures/$stem$ext"
        $absolute = Join-Path $repoRoot ($relative.Replace("/", "\"))
        if (-not (Test-Path -LiteralPath $absolute -PathType Leaf)) {
            throw "Required reviewed figure missing: $absolute"
        }
        if ((Get-Item -LiteralPath $absolute).Length -le 0) {
            throw "Required reviewed figure is empty: $absolute"
        }
        $sourceFiles += [pscustomobject]@{
            Source = $absolute
            Relative = $relative
        }
    }
}

Write-Host ("Checked {0} reviewed figure files in the local repository." -f $sourceFiles.Count)
Write-Host "Fetching the latest GitHub main branch..."
Invoke-Git -Arguments @("-C", $repoRoot, "fetch", "origin", "main")

$worktree = Join-Path ([System.IO.Path]::GetTempPath()) (
    "stata-figures-publish-" + [guid]::NewGuid().ToString("N")
)
$worktreeAdded = $false
$success = $false
try {
    Invoke-Git -Arguments @("-C", $repoRoot, "worktree", "add", "--detach", $worktree, "origin/main")
    $worktreeAdded = $true

    foreach ($item in $sourceFiles) {
        $destination = Join-Path $worktree ($item.Relative.Replace("/", "\"))
        $directory = Split-Path $destination -Parent
        New-Item -Path $directory -ItemType Directory -Force | Out-Null
        Copy-Item -LiteralPath $item.Source -Destination $destination -Force
    }

    $paths = @($sourceFiles | ForEach-Object { $_.Relative })
    Invoke-Git -Arguments (@("-C", $worktree, "add", "--") + $paths)
    $staged = @(& git -C $worktree diff --cached --name-only)
    if ($LASTEXITCODE -ne 0) { throw "Could not inspect staged figure files." }

    if ($staged.Count -eq 0 -or ($staged.Count -eq 1 -and [string]::IsNullOrWhiteSpace($staged[0]))) {
        Write-Host "These exact reviewed figures are already present on GitHub. No commit needed."
    }
    else {
        Write-Host ("Committing {0} changed figure files..." -f $staged.Count)
        Invoke-Git -Arguments @("-C", $worktree, "commit", "-m",
            "Publish reviewed Stata figures and editable graph exports")
        Invoke-Git -Arguments @("-C", $worktree, "push", "origin", "HEAD:main")
        Write-Host "Figure publication pushed to GitHub main successfully."
    }
    $success = $true
}
finally {
    if ($worktreeAdded -and $success) {
        Invoke-Git -Arguments @("-C", $repoRoot, "worktree", "remove", "--force", $worktree)
    }
    elseif ($worktreeAdded) {
        Write-Warning ("Publication did not finish. Temporary worktree retained for recovery: {0}" -f $worktree)
    }
}
Write-Host "Local project files were not modified."
