# Complete Tomcat Credentials Fix
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Complete Tomcat Manager Fix" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$tomcatDir = "$env:USERPROFILE\apache-tomcat-9.0.95"
$tomcatUsersFile = "$tomcatDir\conf\tomcat-users.xml"
$managerContextFile = "$tomcatDir\webapps\manager\META-INF\context.xml"

# Step 1: Stop Tomcat
Write-Host "Step 1: Stopping Tomcat..." -ForegroundColor Yellow
Push-Location "$tomcatDir\bin"
& ".\shutdown.bat" 2>&1 | Out-Null
Pop-Location
Start-Sleep -Seconds 5

# Step 2: Fix tomcat-users.xml
Write-Host "Step 2: Configuring tomcat-users.xml..." -ForegroundColor Yellow
$content = '<?xml version="1.0" encoding="UTF-8"?>
<tomcat-users xmlns="http://tomcat.apache.org/xml"
              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
              xsi:schemaLocation="http://tomcat.apache.org/xml tomcat-users.xsd"
              version="1.0">
<!-- LogSphere Manager Configuration -->
<role rolename="manager-gui"/>
<role rolename="manager-script"/>
<role rolename="manager-jmx"/>
<role rolename="manager-status"/>
<role rolename="admin-gui"/>
<role rolename="admin-script"/>
<user username="admin" password="admin123" roles="manager-gui,manager-script,manager-jmx,manager-status,admin-gui,admin-script"/>
</tomcat-users>'

Set-Content -Path $tomcatUsersFile -Value $content -Encoding UTF8
Write-Host "  ✓ User 'admin' with password 'admin123' configured" -ForegroundColor Green

# Step 3: Fix manager context.xml (remove IP restriction)
Write-Host "Step 3: Removing IP restriction from manager..." -ForegroundColor Yellow
if (Test-Path $managerContextFile) {
    $contextContent = Get-Content $managerContextFile -Raw
    $contextContent = $contextContent -replace '<Valve className="org\.apache\.catalina\.valves\.RemoteAddrValve"[^>]*/>', '<!-- IP restriction removed for local access -->'
    Set-Content -Path $managerContextFile -Value $contextContent -Encoding UTF8
    Write-Host "  ✓ IP restriction removed" -ForegroundColor Green
} else {
    Write-Host "  ⚠ Manager context.xml not found (may need to extract manager app)" -ForegroundColor Yellow
}

# Step 4: Start Tomcat
Write-Host "Step 4: Starting Tomcat..." -ForegroundColor Yellow
$env:CATALINA_HOME = $tomcatDir
Start-Process -FilePath "$tomcatDir\bin\startup.bat" -WindowStyle Normal
Start-Sleep -Seconds 12

# Step 5: Verify
Write-Host "Step 5: Verifying Tomcat..." -ForegroundColor Yellow
$running = netstat -ano | Select-String ":8080.*LISTENING"
if ($running) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "✓ Tomcat is RUNNING!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Manager Credentials:" -ForegroundColor Cyan
    Write-Host "  URL: http://localhost:8080/manager/html" -ForegroundColor White
    Write-Host "  Username: admin" -ForegroundColor Yellow
    Write-Host "  Password: admin123" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Opening manager in browser..." -ForegroundColor Cyan
    Start-Process "http://localhost:8080/manager/html"
} else {
    Write-Host "Tomcat may still be starting. Please wait a few more seconds." -ForegroundColor Yellow
}

Write-Host ""

