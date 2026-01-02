# Complete Tomcat Manager Credentials Fix
$tomcatDir = "$env:USERPROFILE\apache-tomcat-9.0.95"
$tomcatUsersFile = "$tomcatDir\conf\tomcat-users.xml"
$managerContextFile = "$tomcatDir\webapps\manager\META-INF\context.xml"

Write-Host "Stopping Tomcat..." -ForegroundColor Yellow
Push-Location "$tomcatDir\bin"
& ".\shutdown.bat" 2>&1 | Out-Null
Pop-Location
Start-Sleep -Seconds 5

Write-Host "Configuring tomcat-users.xml..." -ForegroundColor Yellow
$xmlContent = '<?xml version="1.0" encoding="UTF-8"?>
<tomcat-users xmlns="http://tomcat.apache.org/xml"
              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
              xsi:schemaLocation="http://tomcat.apache.org/xml tomcat-users.xsd"
              version="1.0">
<role rolename="manager-gui"/>
<role rolename="manager-script"/>
<role rolename="manager-jmx"/>
<role rolename="manager-status"/>
<role rolename="admin-gui"/>
<role rolename="admin-script"/>
<user username="admin" password="admin123" roles="manager-gui,manager-script,manager-jmx,manager-status,admin-gui,admin-script"/>
</tomcat-users>'
Set-Content -Path $tomcatUsersFile -Value $xmlContent -Encoding UTF8
Write-Host "User configured: admin / admin123" -ForegroundColor Green

if (Test-Path $managerContextFile) {
    Write-Host "Removing IP restriction..." -ForegroundColor Yellow
    $contextContent = Get-Content $managerContextFile -Raw
    $pattern = '<Valve className="org.apache.catalina.valves.RemoteAddrValve"[^>]*/>'
    $replacement = '<!-- IP restriction removed -->'
    $contextContent = $contextContent -replace $pattern, $replacement
    Set-Content -Path $managerContextFile -Value $contextContent -Encoding UTF8
    Write-Host "IP restriction removed" -ForegroundColor Green
}

Write-Host "Starting Tomcat..." -ForegroundColor Yellow
$env:CATALINA_HOME = $tomcatDir
Start-Process -FilePath "$tomcatDir\bin\startup.bat" -WindowStyle Normal
Start-Sleep -Seconds 12

$running = netstat -ano | Select-String ":8080.*LISTENING"
if ($running) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Tomcat is RUNNING!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Manager URL: http://localhost:8080/manager/html" -ForegroundColor Cyan
    Write-Host "Username: admin" -ForegroundColor Yellow
    Write-Host "Password: admin123" -ForegroundColor Yellow
    Start-Process "http://localhost:8080/manager/html"
} else {
    Write-Host "Tomcat is starting, please wait..." -ForegroundColor Yellow
}

