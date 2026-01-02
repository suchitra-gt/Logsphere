# Fix Tomcat Manager Credentials
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Fixing Tomcat Manager Credentials" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$tomcatDir = "$env:USERPROFILE\apache-tomcat-9.0.95"
$tomcatUsersFile = "$tomcatDir\conf\tomcat-users.xml"

# Backup
Copy-Item $tomcatUsersFile "$tomcatUsersFile.backup.$(Get-Date -Format 'yyyyMMddHHmmss')" -Force

# Read current content
$content = Get-Content $tomcatUsersFile -Raw

# Remove any existing LogSphere configuration
$content = $content -replace '(?s)<!-- LogSphere.*?-->.*?</user>', ''

# Add new configuration before closing tag
$newConfig = @"

<!-- LogSphere Manager Configuration -->
<role rolename="manager-gui"/>
<role rolename="manager-script"/>
<role rolename="manager-jmx"/>
<role rolename="manager-status"/>
<role rolename="admin-gui"/>
<role rolename="admin-script"/>
<user username="admin" password="admin123" roles="manager-gui,manager-script,manager-jmx,manager-status,admin-gui,admin-script"/>
</tomcat-users>
"@

$content = $content -replace "</tomcat-users>", $newConfig
Set-Content -Path $tomcatUsersFile -Value $content -NoNewline -Encoding UTF8

Write-Host "User configuration updated!" -ForegroundColor Green
Write-Host "  Username: admin" -ForegroundColor Cyan
Write-Host "  Password: admin123" -ForegroundColor Cyan
Write-Host ""

# Fix manager context.xml to remove IP restriction
$managerContextFile = "$tomcatDir\webapps\manager\META-INF\context.xml"
if (Test-Path $managerContextFile) {
    $contextContent = Get-Content $managerContextFile -Raw
    $contextContent = $contextContent -replace '<Valve className="org\.apache\.catalina\.valves\.RemoteAddrValve"[^>]*/>', '<!-- IP restriction removed for local access -->'
    Set-Content -Path $managerContextFile -Value $contextContent -NoNewline -Encoding UTF8
    Write-Host "IP restriction removed from manager context!" -ForegroundColor Green
}

Write-Host ""
Write-Host "Restarting Tomcat..." -ForegroundColor Yellow

# Stop Tomcat
Push-Location "$tomcatDir\bin"
& ".\shutdown.bat" 2>&1 | Out-Null
Pop-Location
Start-Sleep -Seconds 3

# Start Tomcat
$env:CATALINA_HOME = $tomcatDir
Start-Process -FilePath "$tomcatDir\bin\startup.bat" -WindowStyle Normal
Start-Sleep -Seconds 10

# Verify
$running = netstat -ano | Select-String ":8080.*LISTENING"
if ($running) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Tomcat restarted successfully!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Manager URL: http://localhost:8080/manager/html" -ForegroundColor Cyan
    Write-Host "Username: admin" -ForegroundColor Cyan
    Write-Host "Password: admin123" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Opening manager in browser..." -ForegroundColor Yellow
    Start-Process "http://localhost:8080/manager/html"
} else {
    Write-Host "Tomcat is starting, please wait a few more seconds..." -ForegroundColor Yellow
}

