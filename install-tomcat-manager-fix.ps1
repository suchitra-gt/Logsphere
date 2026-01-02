# Install Tomcat Manager - Complete Fix
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Tomcat Manager Installation Fix" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$tomcatDir = "$env:USERPROFILE\apache-tomcat-9.0.95"

# STEP 1: Check if Manager folder exists
Write-Host "STEP 1: Checking Manager installation..." -ForegroundColor Yellow
$managerDir = "$tomcatDir\webapps\manager"
$managerWar = "$tomcatDir\webapps\manager.war"

if (Test-Path $managerDir) {
    $managerWebXml = "$managerDir\WEB-INF\web.xml"
    if (Test-Path $managerWebXml) {
        Write-Host "  ✓ Manager folder EXISTS and is COMPLETE" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Manager folder exists but is INCOMPLETE" -ForegroundColor Red
        Write-Host "  → Manager needs to be downloaded and installed" -ForegroundColor Yellow
        exit 1
    }
} elseif (Test-Path $managerWar) {
    Write-Host "  ✓ Manager WAR file EXISTS" -ForegroundColor Green
} else {
    Write-Host "  ✗ Manager NOT FOUND" -ForegroundColor Red
    Write-Host "  → Please download apache-tomcat-9.0.x-windows-x64.zip" -ForegroundColor Yellow
    Write-Host "  → Extract and copy /webapps/manager folder to:" -ForegroundColor Yellow
    Write-Host "    $tomcatDir\webapps\" -ForegroundColor White
    exit 1
}

# STEP 2: Already verified - Manager exists

# STEP 3: Create User in tomcat-users.xml
Write-Host ""
Write-Host "STEP 3: Configuring tomcat-users.xml..." -ForegroundColor Yellow
$tomcatUsersFile = "$tomcatDir\conf\tomcat-users.xml"

$usersXmlContent = "<?xml version=`"1.0`" encoding=`"UTF-8`"?>
<tomcat-users xmlns=`"http://tomcat.apache.org/xml`"
              xmlns:xsi=`"http://www.w3.org/2001/XMLSchema-instance`"
              xsi:schemaLocation=`"http://tomcat.apache.org/xml tomcat-users.xsd`"
              version=`"1.0`">
<role rolename=`"manager-gui`"/>
<user username=`"admin`" password=`"admin`" roles=`"manager-gui`"/>
</tomcat-users>"

Set-Content -Path $tomcatUsersFile -Value $usersXmlContent -Encoding UTF8
Write-Host "  ✓ User configured:" -ForegroundColor Green
Write-Host "    Username: admin" -ForegroundColor Yellow
Write-Host "    Password: admin" -ForegroundColor Yellow
Write-Host "    Role: manager-gui" -ForegroundColor Yellow

# STEP 4: Restart Tomcat
Write-Host ""
Write-Host "STEP 4: Restarting Tomcat..." -ForegroundColor Yellow
Write-Host "  Stopping Tomcat..." -ForegroundColor Gray
Push-Location "$tomcatDir\bin"
& ".\shutdown.bat" 2>&1 | Out-Null
Pop-Location
Start-Sleep -Seconds 5

Write-Host "  Starting Tomcat..." -ForegroundColor Gray
$env:CATALINA_HOME = $tomcatDir
Start-Process -FilePath "$tomcatDir\bin\startup.bat" -WindowStyle Normal
Start-Sleep -Seconds 15

# Verify
Write-Host ""
Write-Host "Verifying Tomcat..." -ForegroundColor Yellow
$running = netstat -ano | Select-String ":8080.*LISTENING"
if ($running) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "✓ SUCCESS! Tomcat Manager is Ready" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Access Manager at:" -ForegroundColor Cyan
    Write-Host "  http://localhost:8080/manager/html" -ForegroundColor White
    Write-Host ""
    Write-Host "Login Credentials:" -ForegroundColor Cyan
    Write-Host "  Username: admin" -ForegroundColor Yellow
    Write-Host "  Password: admin" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Opening manager in browser..." -ForegroundColor Cyan
    Start-Sleep -Seconds 3
    Start-Process "http://localhost:8080/manager/html"
} else {
    Write-Host ""
    Write-Host "⚠ Tomcat is still starting. Please wait a few more seconds." -ForegroundColor Yellow
    Write-Host "Then access: http://localhost:8080/manager/html" -ForegroundColor Cyan
}

Write-Host ""

