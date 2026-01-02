# Fix All Deployment Errors for LogSphere
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Fixing All Deployment Errors" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$tomcatDir = "$env:USERPROFILE\apache-tomcat-9.0.95"
$projectDir = "C:\Users\admin\Desktop\LogSphere\LogSphere"

# Step 1: Rebuild WAR file with fixes
Write-Host "Step 1: Rebuilding WAR file..." -ForegroundColor Yellow
Push-Location $projectDir

# Check Java version
$javaVersion = java -version 2>&1 | Select-String "version"
Write-Host "Java version: $javaVersion" -ForegroundColor Gray

# Set JAVA_HOME if needed
if (-not $env:JAVA_HOME) {
    $possibleJavaPaths = @(
        "C:\Program Files\Java\jdk-17",
        "C:\Program Files\Eclipse Adoptium\jdk-17*",
        "C:\Program Files\Eclipse Adoptium\jdk-21*"
    )
    foreach ($path in $possibleJavaPaths) {
        $found = Get-ChildItem $path -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) {
            $env:JAVA_HOME = $found.FullName
            Write-Host "Set JAVA_HOME to: $env:JAVA_HOME" -ForegroundColor Green
            break
        }
    }
}

Write-Host "Building WAR file..." -ForegroundColor Yellow
& ".\mvnw.cmd" clean package -DskipTests
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Build failed!" -ForegroundColor Red
    Pop-Location
    exit 1
}

Pop-Location

# Step 2: Stop Tomcat
Write-Host ""
Write-Host "Step 2: Stopping Tomcat..." -ForegroundColor Yellow
Push-Location "$tomcatDir\bin"
& ".\shutdown.bat" 2>&1 | Out-Null
Pop-Location
Start-Sleep -Seconds 5

# Step 3: Remove old deployment
Write-Host "Step 3: Removing old deployment..." -ForegroundColor Yellow
$oldWar = "$tomcatDir\webapps\LogSphere-0.0.1-SNAPSHOT.war"
$oldDir = "$tomcatDir\webapps\LogSphere-0.0.1-SNAPSHOT"
if (Test-Path $oldWar) {
    Remove-Item $oldWar -Force
    Write-Host "  Removed old WAR file" -ForegroundColor Green
}
if (Test-Path $oldDir) {
    Remove-Item $oldDir -Recurse -Force
    Write-Host "  Removed old deployment directory" -ForegroundColor Green
}

# Step 4: Deploy new WAR
Write-Host "Step 4: Deploying new WAR..." -ForegroundColor Yellow
$newWar = "$projectDir\target\LogSphere-0.0.1-SNAPSHOT.war"
if (Test-Path $newWar) {
    Copy-Item $newWar -Destination "$tomcatDir\webapps\LogSphere-0.0.1-SNAPSHOT.war" -Force
    Write-Host "  WAR file deployed" -ForegroundColor Green
} else {
    Write-Host "  ERROR: WAR file not found at $newWar" -ForegroundColor Red
    exit 1
}

# Step 5: Start Tomcat
Write-Host "Step 5: Starting Tomcat..." -ForegroundColor Yellow
$env:CATALINA_HOME = $tomcatDir
Start-Process -FilePath "$tomcatDir\bin\startup.bat" -WindowStyle Normal
Start-Sleep -Seconds 20

# Step 6: Verify
Write-Host "Step 6: Verifying deployment..." -ForegroundColor Yellow
$running = netstat -ano | Select-String ":8080.*LISTENING"
if ($running) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Deployment Complete!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Application URLs:" -ForegroundColor Cyan
    Write-Host "  Main: http://localhost:8080/LogSphere-0.0.1-SNAPSHOT/" -ForegroundColor White
    Write-Host "  Login: http://localhost:8080/LogSphere-0.0.1-SNAPSHOT/login" -ForegroundColor White
    Write-Host "  Admin: http://localhost:8080/LogSphere-0.0.1-SNAPSHOT/admin/dashboard" -ForegroundColor White
    Write-Host ""
    Write-Host "Note: Context path is /LogSphere-0.0.1-SNAPSHOT" -ForegroundColor Yellow
    Write-Host "To change it, rename the WAR file to 'LogSphere.war'" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Waiting for application to fully start..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    
    Write-Host ""
    Write-Host "Opening application..." -ForegroundColor Cyan
    Start-Process "http://localhost:8080/LogSphere-0.0.1-SNAPSHOT/"
} else {
    Write-Host ""
    Write-Host "Tomcat may still be starting. Please wait and check:" -ForegroundColor Yellow
    Write-Host "  http://localhost:8080/LogSphere-0.0.1-SNAPSHOT/" -ForegroundColor Cyan
}

Write-Host ""

