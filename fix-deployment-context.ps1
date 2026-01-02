# Fix Deployment Context Path
$tomcatDir = "$env:USERPROFILE\apache-tomcat-9.0.95"
$oldWar = "$tomcatDir\webapps\LogSphere-0.0.1-SNAPSHOT.war"
$newWar = "$tomcatDir\webapps\LogSphere.war"
$oldDir = "$tomcatDir\webapps\LogSphere-0.0.1-SNAPSHOT"
$newDir = "$tomcatDir\webapps\LogSphere"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Fixing Deployment Context Path" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Stop Tomcat
Write-Host "Stopping Tomcat..." -ForegroundColor Yellow
Push-Location "$tomcatDir\bin"
& ".\shutdown.bat" 2>&1 | Out-Null
Pop-Location
Start-Sleep -Seconds 5

# Remove old deployment
if (Test-Path $oldDir) {
    Write-Host "Removing old deployment directory..." -ForegroundColor Yellow
    Remove-Item $oldDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  ✓ Old directory removed" -ForegroundColor Green
}

if (Test-Path $oldWar) {
    Write-Host "Renaming WAR file..." -ForegroundColor Yellow
    Move-Item $oldWar $newWar -Force
    Write-Host "  ✓ Renamed to LogSphere.war" -ForegroundColor Green
    Write-Host "  New context path will be: /LogSphere/" -ForegroundColor Cyan
}

# Start Tomcat
Write-Host ""
Write-Host "Starting Tomcat..." -ForegroundColor Yellow
$env:CATALINA_HOME = $tomcatDir
Start-Process -FilePath "$tomcatDir\bin\startup.bat" -WindowStyle Normal
Start-Sleep -Seconds 15

# Verify
$running = netstat -ano | Select-String ":8080.*LISTENING"
if ($running) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Deployment Fixed!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Application deployed with context: /LogSphere/" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Access URLs:" -ForegroundColor Yellow
    Write-Host "  http://localhost:8080/LogSphere/" -ForegroundColor White
    Write-Host "  http://localhost:8080/LogSphere/admin/dashboard" -ForegroundColor White
    Write-Host "  http://localhost:8080/LogSphere/hr/dashboard" -ForegroundColor White
    Write-Host ""
    Write-Host "Opening application..." -ForegroundColor Cyan
    Start-Process "http://localhost:8080/LogSphere/"
} else {
    Write-Host "Tomcat is starting, please wait..." -ForegroundColor Yellow
}

Write-Host ""

