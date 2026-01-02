# LogSphere - Tomcat Setup and Start Script
# This script downloads, configures, and starts Tomcat

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "LogSphere - Tomcat Setup & Start" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check Java
Write-Host "Checking Java installation..." -ForegroundColor Yellow
$javaVersion = java -version 2>&1 | Select-String "version"
if ($javaVersion) {
    Write-Host "Java found: $javaVersion" -ForegroundColor Green
} else {
    Write-Host "ERROR: Java is not installed or not in PATH!" -ForegroundColor Red
    Write-Host "Please install Java 17+ first." -ForegroundColor Red
    exit 1
}

# Set Tomcat installation directory
$tomcatDir = "$env:USERPROFILE\apache-tomcat-10.1.20"
$tomcatUrl = "https://archive.apache.org/dist/tomcat/tomcat-10/v10.1.20/bin/apache-tomcat-10.1.20-windows-x64.zip"

# Check if Tomcat already exists
if (Test-Path "$tomcatDir\bin\startup.bat") {
    Write-Host "Tomcat found at: $tomcatDir" -ForegroundColor Green
} else {
    Write-Host "Tomcat not found. Downloading and installing..." -ForegroundColor Yellow
    
    # Create temp directory
    $tempDir = "$env:TEMP\tomcat-setup"
    New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
    
    $zipFile = "$tempDir\tomcat.zip"
    
    Write-Host "Downloading Tomcat 10.1.20..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri $tomcatUrl -OutFile $zipFile -UseBasicParsing
        Write-Host "Download complete!" -ForegroundColor Green
    } catch {
        Write-Host "ERROR: Failed to download Tomcat" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Extracting Tomcat..." -ForegroundColor Yellow
    Expand-Archive -Path $zipFile -DestinationPath $env:USERPROFILE -Force
    Write-Host "Extraction complete!" -ForegroundColor Green
    
    # Cleanup
    Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}

# Configure Tomcat Manager
Write-Host "Configuring Tomcat Manager..." -ForegroundColor Yellow
$tomcatUsersFile = "$tomcatDir\conf\tomcat-users.xml"

if (Test-Path $tomcatUsersFile) {
    $content = Get-Content $tomcatUsersFile -Raw
    
    # Check if already configured
    if ($content -notmatch "manager-gui") {
        # Backup original
        Copy-Item $tomcatUsersFile "$tomcatUsersFile.backup" -Force
        
        # Add manager configuration before closing tag
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
        Write-Host "  Username: admin" -ForegroundColor Cyan
        Write-Host "  Password: admin123" -ForegroundColor Cyan
    } else {
        Write-Host "Tomcat Manager already configured." -ForegroundColor Green
    }
}

# Check if Tomcat is already running
Write-Host "Checking if Tomcat is running..." -ForegroundColor Yellow
$tomcatRunning = netstat -ano | Select-String ":8080.*LISTENING"
if ($tomcatRunning) {
    Write-Host "Tomcat is already running on port 8080!" -ForegroundColor Green
    Write-Host "Access Manager at: http://localhost:8080/manager/html" -ForegroundColor Cyan
} else {
    Write-Host "Starting Tomcat..." -ForegroundColor Yellow
    
    # Set CATALINA_HOME
    $env:CATALINA_HOME = $tomcatDir
    
    # Start Tomcat
    Push-Location "$tomcatDir\bin"
    Start-Process -FilePath "startup.bat" -WindowStyle Hidden
    Pop-Location
    
    Write-Host "Waiting for Tomcat to start..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    
    # Check if started
    $tomcatRunning = netstat -ano | Select-String ":8080.*LISTENING"
    if ($tomcatRunning) {
        Write-Host "Tomcat started successfully!" -ForegroundColor Green
    } else {
        Write-Host "Tomcat may still be starting. Please wait a few more seconds." -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Tomcat Information" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Installation: $tomcatDir" -ForegroundColor White
Write-Host "Manager URL: http://localhost:8080/manager/html" -ForegroundColor Cyan
Write-Host "Username: admin" -ForegroundColor Cyan
Write-Host "Password: admin123" -ForegroundColor Cyan
Write-Host ""
Write-Host "To stop Tomcat, run:" -ForegroundColor Yellow
Write-Host "  cd `"$tomcatDir\bin`"" -ForegroundColor White
Write-Host "  .\shutdown.bat" -ForegroundColor White
Write-Host ""

