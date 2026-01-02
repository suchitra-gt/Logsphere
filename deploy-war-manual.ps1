# Manual WAR Deployment Script
# This is an alternative to uploading through Manager

$tomcatDir = "$env:USERPROFILE\apache-tomcat-9.0.95"
$warFile = "target\LogSphere-0.0.1-SNAPSHOT.war"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Manual WAR Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if WAR file exists
if (-not (Test-Path $warFile)) {
    Write-Host "ERROR: WAR file not found: $warFile" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please build the WAR file first:" -ForegroundColor Yellow
    Write-Host "  .\mvnw.cmd clean package -DskipTests" -ForegroundColor White
    exit 1
}

$warSize = (Get-Item $warFile).Length / 1MB
Write-Host "WAR File: $warFile" -ForegroundColor Cyan
Write-Host "Size: $([math]::Round($warSize, 2)) MB" -ForegroundColor Cyan
Write-Host ""

# Ask for deployment name
Write-Host "Enter deployment name (or press Enter for 'LogSphere'):" -ForegroundColor Yellow
$deployName = Read-Host
if ([string]::IsNullOrWhiteSpace($deployName)) {
    $deployName = "LogSphere"
}

$targetWar = "$tomcatDir\webapps\$deployName.war"
$targetDir = "$tomcatDir\webapps\$deployName"

# Stop Tomcat if app is already deployed
if (Test-Path $targetDir) {
    Write-Host "Stopping Tomcat to undeploy existing application..." -ForegroundColor Yellow
    Push-Location "$tomcatDir\bin"
    & ".\shutdown.bat" 2>&1 | Out-Null
    Pop-Location
    Start-Sleep -Seconds 3
    
    # Remove old deployment
    Remove-Item $targetDir -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item $targetWar -Force -ErrorAction SilentlyContinue
    Write-Host "Old deployment removed" -ForegroundColor Green
}

# Copy WAR file
Write-Host "Copying WAR file..." -ForegroundColor Yellow
Copy-Item $warFile $targetWar -Force
Write-Host "WAR file copied to: $targetWar" -ForegroundColor Green

# Start Tomcat
Write-Host "Starting Tomcat..." -ForegroundColor Yellow
$env:CATALINA_HOME = $tomcatDir
Start-Process -FilePath "$tomcatDir\bin\startup.bat" -WindowStyle Normal
Start-Sleep -Seconds 15

# Verify
$running = netstat -ano | Select-String ":8080.*LISTENING"
if ($running) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Deployment Successful!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Application deployed as: $deployName" -ForegroundColor Cyan
    Write-Host "Access URL: http://localhost:8080/$deployName/" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Opening application..." -ForegroundColor Cyan
    Start-Process "http://localhost:8080/$deployName/"
} else {
    Write-Host "Tomcat is starting, please wait..." -ForegroundColor Yellow
    Write-Host "Then access: http://localhost:8080/$deployName/" -ForegroundColor Cyan
}

Write-Host ""

