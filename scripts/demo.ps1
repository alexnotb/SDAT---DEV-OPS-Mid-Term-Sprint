<#
Demo script for the Sprint Week project.

I wrote this PowerShell script to help me record and run a short demo locally.
Developers on this project:
- Oleksii Bezkibalnyi — Front-end
- Ivan Zymalov — Back-end

What this script does (for my demo):
- Optionally load the demo SQL into MySQL (interactive password prompt)
- Start the Spring Boot API (runs mvn spring-boot:run in a new process if needed)
- Wait for port 8080 to become available
- Call the four aggregate API endpoints and print JSON output
- Build and run the CLI client (exec:java)

Usage examples (from my perspective):
# 1) Run the demo without loading SQL (assumes I already prepared the DB):
#    .\demo.ps1
# 2) Run the demo and load SQL (I will be prompted for MySQL root password):
#    .\demo.ps1 -LoadData

All comments and narration are written by me in English. Edit paths if your environment differs.
#>

[CmdletBinding()]
param(
    [switch]$LoadData
)

function Write-Title($text) { Write-Host "`n===== $text =====`n" -ForegroundColor Cyan }

Write-Title 'Prerequisite check'

# Java
try { & java -version 2>&1 | Out-Null; Write-Host 'Java is available.' -ForegroundColor Green } catch { Write-Host 'Java not found. Install JDK 17 or newer.' -ForegroundColor Red }

# Maven
$mvnCmd = (Get-Command mvn -ErrorAction SilentlyContinue).Source
if (-not $mvnCmd) {
    $alt = 'C:\Tools\apache-maven-3.9.6\bin\mvn.cmd'
    if (Test-Path $alt) { $mvnCmd = $alt }
}
if ($mvnCmd) { Write-Host "Maven detected: $mvnCmd" -ForegroundColor Green } else { Write-Host 'Maven not found. Install Maven or adjust $mvnCmd in this script.' -ForegroundColor Yellow }

# MySQL client
$mysqlCmd = (Get-Command mysql -ErrorAction SilentlyContinue).Source
if ($mysqlCmd) { Write-Host "MySQL client detected: $mysqlCmd" -ForegroundColor Green } else { Write-Host 'MySQL client not found (mysql). If you need to run data.sql interactively, install the mysql client.' -ForegroundColor Yellow }

Write-Title 'Optional: load demo SQL into MySQL'
if ($LoadData) {
    if (-not $mysqlCmd) { Write-Host 'Skipping load: mysql client not available.' -ForegroundColor Yellow }
    else {
        $sqlPath = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath '..\api-server\src\main\resources\data.sql'
        $sqlPath = (Resolve-Path $sqlPath).ProviderPath
    Write-Host "I will run: mysql -u root -p -e 'SOURCE $sqlPath'" -ForegroundColor Gray
    Write-Host 'Enter MySQL root password when prompted.'
        & mysql -u root -p -e "SOURCE $sqlPath;"
        if ($LASTEXITCODE -eq 0) { Write-Host 'data.sql executed successfully.' -ForegroundColor Green } else { Write-Host 'data.sql execution failed or was interrupted.' -ForegroundColor Red }
    }
} else { Write-Host 'Skipping SQL load (use -LoadData to enable).' -ForegroundColor Gray }

Write-Title 'Start API server (if not running)'
# If 8080 is already listening, skip starting
$port = 8080
$check = Test-NetConnection -ComputerName localhost -Port $port -WarningAction SilentlyContinue
if ($check.TcpTestSucceeded) {
    Write-Host "Server already listening on port $port - skipping start." -ForegroundColor Green
} else {
    if (-not $mvnCmd) { Write-Host 'Cannot start server: mvn not found. Install Maven and re-run.' -ForegroundColor Red; exit 1 }
    # We'll attempt to start the server up to 5 times. Each attempt will launch the packaged jar
    # (preferred) or fallback to 'mvn spring-boot:run' if the jar is missing.
    $apiDir = Resolve-Path "..\api-server"
    $jarPath = Join-Path $apiDir 'target\flight-api-0.0.1-SNAPSHOT.jar'
    $attempts = 5
    $started = $false
    $attempt = 0
    $logDir = Join-Path $apiDir 'logs'
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }

    while ($attempt -lt $attempts -and -not $started) {
        $attempt++
        Write-Host "Attempt #$attempt to start the API..." -ForegroundColor Cyan
        $timestamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
        $outLog = Join-Path $logDir "api-$timestamp-out.log"
        $errLog = Join-Path $logDir "api-$timestamp-err.log"

        if (Test-Path $jarPath) {
            Write-Host "Found jar: $jarPath - launching with java -jar (port $port)" -ForegroundColor Gray
            # Start java and redirect output to logs
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = 'java'
            $psi.Arguments = "-Dserver.port=$port -jar `"$jarPath`""
            $psi.WorkingDirectory = $apiDir
            $psi.RedirectStandardOutput = $true
            $psi.RedirectStandardError = $true
            $psi.UseShellExecute = $false
            $proc = New-Object System.Diagnostics.Process
            $proc.StartInfo = $psi
            $proc.Start() | Out-Null
            # asynchronously copy streams to files
            $stdOut = $proc.StandardOutput
            $stdErr = $proc.StandardError
            Start-Job -ScriptBlock { param($s, $f) while (-not $s.EndOfStream) { $line = $s.ReadLine(); Add-Content -LiteralPath $f -Value $line } } -ArgumentList $stdOut, $outLog | Out-Null
            Start-Job -ScriptBlock { param($s, $f) while (-not $s.EndOfStream) { $line = $s.ReadLine(); Add-Content -LiteralPath $f -Value $line } } -ArgumentList $stdErr, $errLog | Out-Null
        } else {
            Write-Host 'Jar not found - falling back to mvn spring-boot:run (capturing output to logs)' -ForegroundColor Yellow
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = $mvnCmd
            $psi.Arguments = 'spring-boot:run'
            $psi.WorkingDirectory = $apiDir
            $psi.RedirectStandardOutput = $true
            $psi.RedirectStandardError = $true
            $psi.UseShellExecute = $false
            $proc = New-Object System.Diagnostics.Process
            $proc.StartInfo = $psi
            $proc.Start() | Out-Null
            $stdOut = $proc.StandardOutput
            $stdErr = $proc.StandardError
            Start-Job -ScriptBlock { param($s, $f) while (-not $s.EndOfStream) { $line = $s.ReadLine(); Add-Content -LiteralPath $f -Value $line } } -ArgumentList $stdOut, $outLog | Out-Null
            Start-Job -ScriptBlock { param($s, $f) while (-not $s.EndOfStream) { $line = $s.ReadLine(); Add-Content -LiteralPath $f -Value $line } } -ArgumentList $stdErr, $errLog | Out-Null
        }

        # Wait up to 30 seconds for the port to open
        $ok = $false
        for ($i=0; $i -lt 30; $i++) {
            Start-Sleep -Seconds 1
            $r = Test-NetConnection -ComputerName localhost -Port $port -WarningAction SilentlyContinue
            if ($r.TcpTestSucceeded) { $ok = $true; break }
            # if process has exited early, stop waiting
            try { if ($proc -and $proc.HasExited) { break } } catch { }
        }

        if ($ok) {
            Write-Host "Server is up on port $port." -ForegroundColor Green
            $started = $true
            break
        } else {
            Write-Host "Attempt #$attempt failed to start server on port $port." -ForegroundColor Yellow
            # collect last 50 lines from logs (if files exist)
            if (Test-Path $outLog) { Write-Host "--- Last lines of stdout (attempt $attempt) ---" -ForegroundColor Gray; Get-Content $outLog -Tail 50 | ForEach-Object { Write-Host $_ } }
            if (Test-Path $errLog) { Write-Host "--- Last lines of stderr (attempt $attempt) ---" -ForegroundColor Gray; Get-Content $errLog -Tail 50 | ForEach-Object { Write-Host $_ } }
            # Analyze logs for common errors and provide guidance
            function Analyze-Logs($outFile, $errFile) {
                $summary = @()
                if (Test-Path $outFile) { $lines = Get-Content $outFile -Tail 200 } else { $lines = @() }
                if (Test-Path $errFile) { $elines = Get-Content $errFile -Tail 200 } else { $elines = @() }
                $all = $lines + $elines
                $joined = $all -join "`n"
                if ($joined -match 'Port \d+ in use|Address already in use|Failed to bind to') {
                    $summary += 'Port conflict detected: another process is using the chosen port.'
                    $summary += 'Action: stop the process using the port (use `netstat -ano`/`Get-Process -Id <pid>`/taskkill) or choose a different port.'
                }
                if ($joined -match 'Access denied for user|Access denied|permission denied') {
                    $summary += 'Database permission error detected: the app cannot authenticate to MySQL.'
                    $summary += 'Action: verify the credentials in api-server/src/main/resources/application.properties and ensure the DB user exists and can connect from this host.'
                }
                if ($joined -match 'Communications link failure|Could not open connection to the host') {
                    $summary += 'Database connection failure: MySQL is not reachable from the app.'
                    $summary += 'Action: ensure MySQL is running and accessible on the configured host/port.'
                }
                if ($joined -match 'Exception in thread "main"|Caused by:') {
                    $summary += 'Application exception detected in logs. See the log tail above for stack traces.'
                }
                if ($summary.Count -gt 0) {
                    Write-Host "--- Diagnostic summary (attempt $attempt) ---" -ForegroundColor Magenta
                    $summary | ForEach-Object { Write-Host $_ -ForegroundColor Magenta }
                } else {
                    Write-Host 'No obvious error pattern found in recent logs.' -ForegroundColor Gray
                }
            }
            Analyze-Logs $outLog $errLog
            # if we started via mvn and proc is running, attempt to stop it
            try {
                if ($proc -and -not $proc.HasExited) {
                    # print exit code if it exited after kill
                    $proc.Kill(); Start-Sleep -Seconds 1
                    if ($proc.HasExited) { Write-Host "Process exited with code: $($proc.ExitCode)" -ForegroundColor Yellow }
                }
            } catch { }
            Start-Sleep -Seconds 2
        }
    }

    if (-not $started) {
        Write-Host "Failed to start the API after $attempts attempts. See logs in $logDir for details." -ForegroundColor Red
        exit 1
    }
}

Write-Title 'Query aggregate endpoints'
$base = 'http://localhost:8080'
try { Write-Host 'GET /cities/airports' -ForegroundColor White; Invoke-RestMethod -Uri "$base/cities/airports" -Method GET | ConvertTo-Json -Depth 5 | Write-Host } catch { Write-Host 'I could not fetch /cities/airports:' $_.Exception.Message -ForegroundColor Red }
try { Write-Host 'GET /passengers/aircraft' -ForegroundColor White; Invoke-RestMethod -Uri "$base/passengers/aircraft" -Method GET | ConvertTo-Json -Depth 5 | Write-Host } catch { Write-Host 'I could not fetch /passengers/aircraft:' $_.Exception.Message -ForegroundColor Red }
try { Write-Host 'GET /aircraft/airports' -ForegroundColor White; Invoke-RestMethod -Uri "$base/aircraft/airports" -Method GET | ConvertTo-Json -Depth 5 | Write-Host } catch { Write-Host 'I could not fetch /aircraft/airports:' $_.Exception.Message -ForegroundColor Red }
try { Write-Host 'GET /passengers/airports' -ForegroundColor White; Invoke-RestMethod -Uri "$base/passengers/airports" -Method GET | ConvertTo-Json -Depth 5 | Write-Host } catch { Write-Host 'I could not fetch /passengers/airports:' $_.Exception.Message -ForegroundColor Red }

Write-Title 'Build and run CLI (interactive)'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$cliWd = Resolve-Path (Join-Path -Path $scriptDir -ChildPath '..\cli-client')
Push-Location $cliWd
try {
    Write-Host 'I am building the CLI (mvn -DskipTests package)...' -ForegroundColor Gray
    & $mvnCmd -DskipTests package
    if ($LASTEXITCODE -ne 0) { Write-Host 'CLI build failed.' -ForegroundColor Red; Pop-Location; exit 1 }
    Write-Host 'Checking for shaded CLI jar in target/ (preferred: java -jar)' -ForegroundColor Gray
    $targetDir = Join-Path $cliWd 'target'
    $shaded = Get-ChildItem -Path $targetDir -Filter '*-shaded.jar' -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($shaded) {
        Write-Host "Found shaded jar: $($shaded.Name) - running with java -jar" -ForegroundColor Green
        & java -jar $shaded.FullName 'http://localhost:8080'
    } else {
        Write-Host 'No shaded jar found - falling back to maven exec:java' -ForegroundColor Yellow
        & $mvnCmd -Dexec.mainClass=com.example.flightcli.FlightCliApplication -Dexec.args='http://localhost:8080' -DskipTests exec:java
    }
} finally { Pop-Location }

Write-Title 'Demo script finished'
Write-Host 'I will stop the server process manually when I am done (Ctrl+C in the mvn window or close the process).' -ForegroundColor Yellow
