# Redeploy LogSphere Application
$tomcatDir = "$env:USERPROFILE\apache-tomcat-9.0.95"
$warFile = "target\LogSphere-0.0.1-SNAPSHOT.war"
$deployWar = "$tomcatDir\webapps\LogSphere.war"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Redeploying LogSphere Application" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if WAR exists
if (-not (Test-Path $warFile)) {
    Write-Host "ERROR: WAR file not found: $warFile" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please build the WAR file first:" -ForegroundColor Yellow
    Write-Host "  Note: You need Java 17 to build" -ForegroundColor Yellow
    Write-Host "  Or use an existing WAR file" -ForegroundColor Yellow
    exit 1
}

# Stop Tomcat
Write-Host "Stopping Tomcat..." -ForegroundColor Yellow
Push-Location "$tomcatDir\bin"
& ".\shutdown.bat" 2>&1 | Out-Null
Pop-Location
Start-Sleep -Seconds 5

# Clean old deployment
Write-Host "Cleaning old deployment..." -ForegroundColor Yellow
Remove-Item "$tomcatDir\webapps\LogSphere" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$tomcatDir\webapps\LogSphere.war" -Force -ErrorAction SilentlyContinue
Remove-Item "$tomcatDir\webapps\LogSphere-0.0.1-SNAPSHOT*" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "  ✓ Old deployment removed" -ForegroundColor Green

# Copy WAR
Write-Host "Copying WAR file..." -ForegroundColor Yellow
Copy-Item $warFile $deployWar -Force
$warSize = (Get-Item $deployWar).Length / 1MB
Write-Host "  ✓ WAR copied: $([math]::Round($warSize, 2)) MB" -ForegroundColor Green

# Start Tomcat
Write-Host "Starting Tomcat..." -ForegroundColor Yellow
$env:CATALINA_HOME = $tomcatDir
Start-Process -FilePath "$tomcatDir\bin\startup.bat" -WindowStyle Normal
Write-Host "  ✓ Tomcat started" -ForegroundColor Green

Write-Host ""
Write-Host "Waiting for deployment (this may take 30-60 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 20

# Check deployment
$deployed = Test-Path "$tomcatDir\webapps\LogSphere"
$running = netstat -ano | Select-String ":8080.*LISTENING"

if ($running) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Deployment Status" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Tomcat: Running on port 8080" -ForegroundColor Cyan
    if ($deployed) {
        Write-Host "Application: Deployed" -ForegroundColor Green
    } else {
        Write-Host "Application: Still deploying (wait 30 more seconds)" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "Access URLs:" -ForegroundColor Yellow
    Write-Host "  http://localhost:8080/LogSphere/" -ForegroundColor White
    Write-Host "  http://localhost:8080/LogSphere/login" -ForegroundColor White
    Write-Host ""
    Write-Host "If you get 404, check:" -ForegroundColor Yellow
    Write-Host "  1. Wait 30-60 seconds for Spring Boot to start" -ForegroundColor White
    Write-Host "  2. Check database connection (MySQL must be running)" -ForegroundColor White
    Write-Host "  3. Check logs: $tomcatDir\logs\catalina.*.log" -ForegroundColor White
    Write-Host ""
    Start-Process "http://localhost:8080/LogSphere/"
} else {
    Write-Host "Tomcat may still be starting..." -ForegroundColor Yellow
}

Write-Host ""

