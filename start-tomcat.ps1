# Quick Tomcat Start Script
$tomcatDir = "$env:USERPROFILE\apache-tomcat-10.1.20"

if (-not (Test-Path "$tomcatDir\bin\startup.bat")) {
    Write-Host "ERROR: Tomcat not found at $tomcatDir" -ForegroundColor Red
    Write-Host "Please run setup-and-start-tomcat.ps1 first" -ForegroundColor Yellow
    exit 1
}

# Check Java version
$javaVersion = java -version 2>&1 | Select-String "version"
Write-Host "Java Version: $javaVersion" -ForegroundColor Yellow

# Check if port 8080 is in use
$portCheck = netstat -ano | Select-String ":8080.*LISTENING"
if ($portCheck) {
    Write-Host "Port 8080 is already in use!" -ForegroundColor Red
    Write-Host "Tomcat may already be running, or another application is using port 8080" -ForegroundColor Yellow
    Write-Host "Access: http://localhost:8080" -ForegroundColor Cyan
    exit 0
}

Write-Host "Starting Tomcat..." -ForegroundColor Yellow
$env:CATALINA_HOME = $tomcatDir

Push-Location "$tomcatDir\bin"
Start-Process -FilePath "startup.bat" -WindowStyle Normal
Pop-Location

Write-Host "Tomcat startup initiated!" -ForegroundColor Green
Write-Host "Waiting 15 seconds for Tomcat to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

# Check if started
$tomcatRunning = netstat -ano | Select-String ":8080.*LISTENING"
if ($tomcatRunning) {
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Tomcat is RUNNING!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Manager URL: http://localhost:8080/manager/html" -ForegroundColor Cyan
    Write-Host "Username: admin" -ForegroundColor Cyan
    Write-Host "Password: admin123" -ForegroundColor Cyan
    Write-Host "Tomcat Home: http://localhost:8080" -ForegroundColor Cyan
} else {
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "Tomcat may not have started properly" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "Possible issues:" -ForegroundColor Yellow
    Write-Host "1. Java version incompatible (Tomcat 10 needs Java 17+)" -ForegroundColor White
    Write-Host "2. Port 8080 may be in use" -ForegroundColor White
    Write-Host "3. Check logs at: $tomcatDir\logs\catalina.out" -ForegroundColor White
    Write-Host ""
    Write-Host "Current Java: $javaVersion" -ForegroundColor Yellow
    Write-Host "Required: Java 17 or higher" -ForegroundColor Yellow
}

