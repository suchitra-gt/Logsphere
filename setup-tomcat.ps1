# LogSphere Tomcat Setup Script
# This script helps configure Tomcat for LogSphere deployment

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "LogSphere Tomcat Setup Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check Java version
Write-Host "Checking Java version..." -ForegroundColor Yellow
$javaVersion = java -version 2>&1 | Select-String "version"
Write-Host $javaVersion -ForegroundColor Green

# Get Tomcat installation path
Write-Host ""
Write-Host "Please enter your Tomcat installation path:" -ForegroundColor Yellow
Write-Host "Example: C:\Program Files\Apache Software Foundation\Tomcat 10.1" -ForegroundColor Gray
$tomcatPath = Read-Host "Tomcat Path"

if (-not (Test-Path $tomcatPath)) {
    Write-Host "Error: Tomcat path does not exist!" -ForegroundColor Red
    exit 1
}

$tomcatUsersFile = Join-Path $tomcatPath "conf\tomcat-users.xml"
$tomcatUsersBackup = Join-Path $tomcatPath "conf\tomcat-users.xml.backup"

# Backup existing tomcat-users.xml
if (Test-Path $tomcatUsersFile) {
    Write-Host "Backing up existing tomcat-users.xml..." -ForegroundColor Yellow
    Copy-Item $tomcatUsersFile $tomcatUsersBackup -Force
    Write-Host "Backup created: $tomcatUsersBackup" -ForegroundColor Green
}

# Copy template
$templateFile = Join-Path $PSScriptRoot "tomcat-users-template.xml"
if (Test-Path $templateFile) {
    Write-Host "Copying tomcat-users.xml template..." -ForegroundColor Yellow
    Copy-Item $templateFile $tomcatUsersFile -Force
    Write-Host "Configuration file updated!" -ForegroundColor Green
} else {
    Write-Host "Template file not found. Please manually configure tomcat-users.xml" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Configuration Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Tomcat Path: $tomcatPath" -ForegroundColor Green
Write-Host "Manager Username: admin" -ForegroundColor Green
Write-Host "Manager Password: admin123" -ForegroundColor Green
Write-Host ""
Write-Host "⚠️  IMPORTANT: Change the password in production!" -ForegroundColor Red
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Start Tomcat: cd `"$tomcatPath\bin`" ; .\startup.bat" -ForegroundColor White
Write-Host "2. Access Manager: http://localhost:8080/manager/html" -ForegroundColor White
Write-Host "3. Deploy your WAR file from the manager interface" -ForegroundColor White
Write-Host ""

