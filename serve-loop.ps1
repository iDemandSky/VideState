$ErrorActionPreference = "Stop"
Set-Location -LiteralPath $PSScriptRoot

$emberBin = Join-Path (Join-Path $env:USERPROFILE ".ember") "bin"
$larvaeCommand = Join-Path $emberBin "larvae.exe"
$rojoCommand = Join-Path $emberBin "rojo.exe"

if (-not (Test-Path -LiteralPath $larvaeCommand) -or -not (Test-Path -LiteralPath $rojoCommand)) {
    Write-Error "The pinned Larvae or Rojo shim is missing. Run 'embr install' from the project folder first."
    exit 1
}

$projectFile = Join-Path $PSScriptRoot ".larvae\build.project.json"
$retryDelaySeconds = 5

function Stop-ChildProcess {
    param([System.Diagnostics.Process]$Process)

    if ($null -eq $Process) {
        return
    }

    try {
        if (-not $Process.HasExited) {
            try {
                $Process.Kill()
            }
            catch [System.InvalidOperationException] {
                if (-not $Process.HasExited) {
                    throw
                }
            }
            $Process.WaitForExit()
        }
    }
    finally {
        $Process.Dispose()
    }
}

while ($true) {
    Write-Host "`n[VideState] Refreshing Larvae output..."
    & $larvaeCommand process
    $buildExitCode = $LASTEXITCODE

    if ($buildExitCode -ne 0) {
        Write-Warning "Larvae process exited with code $buildExitCode. Retrying in $retryDelaySeconds seconds."
        Start-Sleep -Seconds $retryDelaySeconds
        continue
    }

    if (-not (Test-Path -LiteralPath $projectFile)) {
        Write-Warning "Larvae did not create $projectFile. Retrying in $retryDelaySeconds seconds."
        Start-Sleep -Seconds $retryDelaySeconds
        continue
    }

    $watcher = $null
    $server = $null

    try {
        Write-Host "[VideState] Starting Larvae watch and Rojo serve..."

        $watcher = Start-Process `
            -FilePath $larvaeCommand `
            -ArgumentList @("process", "--watch") `
            -WorkingDirectory $PSScriptRoot `
            -NoNewWindow `
            -PassThru

        $server = Start-Process `
            -FilePath $rojoCommand `
            -ArgumentList @("serve", ".larvae\build.project.json") `
            -WorkingDirectory $PSScriptRoot `
            -NoNewWindow `
            -PassThru

        while (-not $watcher.HasExited -and -not $server.HasExited) {
            Start-Sleep -Seconds 1
        }

        if ($watcher.HasExited) {
            Write-Warning "Larvae watch exited with code $($watcher.ExitCode)."
        }
        else {
            Write-Warning "Rojo serve exited with code $($server.ExitCode)."
        }
    }
    catch [System.Management.Automation.PipelineStoppedException] {
        throw
    }
    catch {
        Write-Warning "Serve process failed: $($_.Exception.Message)"
    }
    finally {
        Stop-ChildProcess $watcher
        Stop-ChildProcess $server
    }

    Write-Host "[VideState] Refreshing and restarting in $retryDelaySeconds seconds."
    Start-Sleep -Seconds $retryDelaySeconds
}
