# Complete Fix for LogSphere 404 Error
$tomcatDir = "$env:USERPROFILE\apache-tomcat-9.0.95"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Complete LogSphere Deployment Fix" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check Java version
Write-Host "Step 1: Checking Java version..." -ForegroundColor Yellow
$javaVersion = java -version 2>&1 | Select-String "version"
Write-Host "  $javaVersion" -ForegroundColor White

if ($javaVersion -match "1\.8") {
    Write-Host "  WARNING: Java 8 detected. You need Java 17 to build!" -ForegroundColor Red
    Write-Host "  Download Java 17 from: https://adoptium.net/" -ForegroundColor Yellow
}

# Step 2: Check if WAR exists
Write-Host ""
Write-Host "Step 2: Checking for WAR file..." -ForegroundColor Yellow
$warFile = "target\LogSphere-0.0.1-SNAPSHOT.war"
if (Test-Path $warFile) {
    $warSize = (Get-Item $warFile).Length / 1MB
    Write-Host "  WAR file found: $([math]::Round($warSize, 2)) MB" -ForegroundColor Green
} else {
    Write-Host "  WAR file NOT found" -ForegroundColor Red
    Write-Host "  Need to build it first" -ForegroundColor Yellow
}

# Step 3: Check MySQL
Write-Host ""
Write-Host "Step 3: Checking MySQL..." -ForegroundColor Yellow
$mysqlProcess = Get-Process -Name "mysqld" -ErrorAction SilentlyContinue
if ($mysqlProcess) {
    Write-Host "  MySQL is running" -ForegroundColor Green
} else {
    Write-Host "  WARNING: MySQL may not be running!" -ForegroundColor Red
    Write-Host "  Start MySQL service if needed" -ForegroundColor Yellow
}

# Step 4: Stop Tomcat
Write-Host ""
Write-Host "Step 4: Stopping Tomcat..." -ForegroundColor Yellow
Push-Location "$tomcatDir\bin"
& ".\shutdown.bat" 2>&1 | Out-Null
Pop-Location
Start-Sleep -Seconds 5

# Step 5: Clean deployment
Write-Host "Step 5: Cleaning old deployment..." -ForegroundColor Yellow
Remove-Item "$tomcatDir\webapps\LogSphere" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$tomcatDir\webapps\LogSphere.war" -Force -ErrorAction SilentlyContinue
Remove-Item "$tomcatDir\webapps\LogSphere-0.0.1-SNAPSHOT*" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "  Old deployment cleaned" -ForegroundColor Green

# Step 6: Deploy WAR if exists
if (Test-Path $warFile) {
    Write-Host ""
    Write-Host "Step 6: Deploying WAR file..." -ForegroundColor Yellow
    Copy-Item $warFile "$tomcatDir\webapps\LogSphere.war" -Force
    Write-Host "  WAR deployed" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "Step 6: Cannot deploy - WAR file missing" -ForegroundColor Red
    Write-Host "  Build it with: .\mvnw.cmd clean package -DskipTests" -ForegroundColor Yellow
    Write-Host "  (Requires Java 17)" -ForegroundColor Yellow
}

# Step 7: Start Tomcat
Write-Host ""
Write-Host "Step 7: Starting Tomcat..." -ForegroundColor Yellow
$env:CATALINA_HOME = $tomcatDir
Start-Process -FilePath "$tomcatDir\bin\startup.bat" -WindowStyle Normal
Start-Sleep -Seconds 15

# Step 8: Verify
Write-Host ""
Write-Host "Step 8: Verifying deployment..." -ForegroundColor Yellow
$running = netstat -ano | Select-String ":8080.*LISTENING"
$deployed = Test-Path "$tomcatDir\webapps\LogSphere"

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Deployment Summary" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Tomcat Status: " -NoNewline
if ($running) {
    Write-Host "RUNNING" -ForegroundColor Green
} else {
    Write-Host "NOT RUNNING" -ForegroundColor Red
}

Write-Host "Application Status: " -NoNewline
if ($deployed) {
    Write-Host "DEPLOYED" -ForegroundColor Green
} else {
    Write-Host "NOT DEPLOYED (wait 30-60 seconds)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Access URLs:" -ForegroundColor Cyan
Write-Host "  http://localhost:8080/LogSphere/" -ForegroundColor White
Write-Host "  http://localhost:8080/LogSphere/login" -ForegroundColor White
Write-Host ""
Write-Host "IMPORTANT: Wait 60 seconds after deployment!" -ForegroundColor Yellow
Write-Host "Spring Boot needs time to initialize." -ForegroundColor Yellow
Write-Host ""

