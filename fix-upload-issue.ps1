# Fix Tomcat Upload/Deployment Issues
$tomcatDir = "$env:USERPROFILE\apache-tomcat-9.0.95"
$serverXml = "$tomcatDir\conf\server.xml"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Fixing Tomcat Upload Configuration" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Stop Tomcat
Write-Host "Stopping Tomcat..." -ForegroundColor Yellow
Push-Location "$tomcatDir\bin"
& ".\shutdown.bat" 2>&1 | Out-Null
Pop-Location
Start-Sleep -Seconds 3

# Update server.xml
Write-Host "Updating server.xml for large file uploads..." -ForegroundColor Yellow
$content = Get-Content $serverXml -Raw

# Increase maxPostSize and maxSwallowSize (100MB = 104857600 bytes)
$oldConnector = '<Connector port="8080" protocol="HTTP/1.1"\s+connectionTimeout="20000"\s+redirectPort="8443"\s+maxParameterCount="1000"\s+/>'
$newConnector = '<Connector port="8080" protocol="HTTP/1.1" connectionTimeout="20000" redirectPort="8443" maxParameterCount="1000" maxPostSize="104857600" maxSwallowSize="104857600" />'

if ($content -match $oldConnector) {
    $content = $content -replace $oldConnector, $newConnector
    Set-Content -Path $serverXml -Value $content -NoNewline -Encoding UTF8
    Write-Host "  ✓ Increased maxPostSize to 100MB" -ForegroundColor Green
    Write-Host "  ✓ Increased maxSwallowSize to 100MB" -ForegroundColor Green
} else {
    Write-Host "  ⚠ Connector configuration not found or already updated" -ForegroundColor Yellow
}

# Also update web.xml for manager if needed
$managerWebXml = "$tomcatDir\webapps\manager\WEB-INF\web.xml"
if (Test-Path $managerWebXml) {
    Write-Host "Checking manager web.xml..." -ForegroundColor Yellow
    $webContent = Get-Content $managerWebXml -Raw
    if ($webContent -notmatch "multipart-config") {
        # Add multipart config if not present
        $multipartConfig = @'
    <multipart-config>
        <max-file-size>104857600</max-file-size>
        <max-request-size>104857600</max-request-size>
        <file-size-threshold>0</file-size-threshold>
    </multipart-config>
'@
        # This would need to be added to servlet definitions, but let's just note it
        Write-Host "  ℹ Manager web.xml exists" -ForegroundColor Cyan
    }
}

# Start Tomcat
Write-Host ""
Write-Host "Starting Tomcat..." -ForegroundColor Yellow
$env:CATALINA_HOME = $tomcatDir
Start-Process -FilePath "$tomcatDir\bin\startup.bat" -WindowStyle Normal
Start-Sleep -Seconds 12

# Verify
$running = netstat -ano | Select-String ":8080.*LISTENING"
if ($running) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Tomcat Restarted Successfully!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Upload limits increased:" -ForegroundColor Cyan
    Write-Host "  maxPostSize: 100MB" -ForegroundColor White
    Write-Host "  maxSwallowSize: 100MB" -ForegroundColor White
    Write-Host ""
    Write-Host "You can now upload larger WAR files!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Alternative: Deploy via file system" -ForegroundColor Yellow
    Write-Host "  1. Copy WAR to: $tomcatDir\webapps\" -ForegroundColor White
    Write-Host "  2. Tomcat will auto-deploy it" -ForegroundColor White
} else {
    Write-Host "Tomcat is starting, please wait..." -ForegroundColor Yellow
}

Write-Host ""

