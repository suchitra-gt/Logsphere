# Setup Tomcat 9 (Compatible with Java 8)
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Setting up Tomcat 9 (Java 8 Compatible)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$tomcatDir = "$env:USERPROFILE\apache-tomcat-9.0.95"
$tomcatUrl = "https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.95/bin/apache-tomcat-9.0.95-windows-x64.zip"

# Remove old Tomcat 10 if exists
if (Test-Path "$env:USERPROFILE\apache-tomcat-10.1.20") {
    Write-Host "Removing incompatible Tomcat 10..." -ForegroundColor Yellow
    Get-Process -Name "java" -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "*tomcat*" } | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Remove-Item "$env:USERPROFILE\apache-tomcat-10.1.20" -Recurse -Force -ErrorAction SilentlyContinue
}

# Check if Tomcat 9 already exists
if (Test-Path "$tomcatDir\bin\startup.bat") {
    Write-Host "Tomcat 9 found at: $tomcatDir" -ForegroundColor Green
} else {
    Write-Host "Downloading Tomcat 9.0.95 (compatible with Java 8)..." -ForegroundColor Yellow
    
    $tempDir = "$env:TEMP\tomcat9-setup"
    New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
    $zipFile = "$tempDir\tomcat9.zip"
    
    try {
        Invoke-WebRequest -Uri $tomcatUrl -OutFile $zipFile -UseBasicParsing
        Write-Host "Download complete!" -ForegroundColor Green
        
        Write-Host "Extracting Tomcat 9..." -ForegroundColor Yellow
        Expand-Archive -Path $zipFile -DestinationPath $env:USERPROFILE -Force
        Write-Host "Extraction complete!" -ForegroundColor Green
        
        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Host "ERROR: Failed to download Tomcat 9" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        exit 1
    }
}

# Configure Tomcat Manager
Write-Host "Configuring Tomcat Manager..." -ForegroundColor Yellow
$tomcatUsersFile = "$tomcatDir\conf\tomcat-users.xml"

if (Test-Path $tomcatUsersFile) {
    $content = Get-Content $tomcatUsersFile -Raw
    
    if ($content -notmatch "manager-gui") {
        Copy-Item $tomcatUsersFile "$tomcatUsersFile.backup" -Force
        
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
        Set-Content -Path $tomcatUsersFile -Value $content -NoNewline
        Write-Host "Tomcat Manager configured!" -ForegroundColor Green
    }
}

# Start Tomcat
Write-Host "Starting Tomcat 9..." -ForegroundColor Yellow
$env:CATALINA_HOME = $tomcatDir

# Check if port is in use
$portCheck = netstat -ano | Select-String ":8080.*LISTENING"
if ($portCheck) {
    Write-Host "Port 8080 is already in use. Stopping existing Tomcat..." -ForegroundColor Yellow
    Push-Location "$tomcatDir\bin"
    & ".\shutdown.bat" 2>&1 | Out-Null
    Pop-Location
    Start-Sleep -Seconds 3
}

Push-Location "$tomcatDir\bin"
Start-Process -FilePath "startup.bat" -WindowStyle Normal
Pop-Location

Write-Host "Waiting for Tomcat to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

# Verify
$tomcatRunning = netstat -ano | Select-String ":8080.*LISTENING"
if ($tomcatRunning) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Tomcat 9 is RUNNING!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Installation: $tomcatDir" -ForegroundColor White
    Write-Host "Manager URL: http://localhost:8080/manager/html" -ForegroundColor Cyan
    Write-Host "Username: admin" -ForegroundColor Cyan
    Write-Host "Password: admin123" -ForegroundColor Cyan
    Write-Host "Tomcat Home: http://localhost:8080" -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "Tomcat may still be starting. Check:" -ForegroundColor Yellow
    Write-Host "1. Open browser: http://localhost:8080" -ForegroundColor White
    Write-Host "2. Check logs: $tomcatDir\logs\catalina.out" -ForegroundColor White
}

Write-Host ""

