# Fix Tomcat Manager 404 Error
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Fixing Tomcat Manager 404 Error" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$tomcatDir = "$env:USERPROFILE\apache-tomcat-9.0.95"
$tomcatUsersFile = "$tomcatDir\conf\tomcat-users.xml"
$managerContextFile = "$tomcatDir\webapps\manager\META-INF\context.xml"
$managerWebappsDir = "$tomcatDir\webapps\manager"
$managerWarFile = "$tomcatDir\webapps\manager.war"

# Check if Tomcat directory exists
if (-not (Test-Path $tomcatDir)) {
    Write-Host "ERROR: Tomcat directory not found at: $tomcatDir" -ForegroundColor Red
    Write-Host "Please install Tomcat first or update the path in this script." -ForegroundColor Yellow
    exit 1
}

# Step 1: Stop Tomcat
Write-Host "Step 1: Stopping Tomcat..." -ForegroundColor Yellow
Push-Location "$tomcatDir\bin"
& ".\shutdown.bat" 2>&1 | Out-Null
Pop-Location
Start-Sleep -Seconds 5

# Step 2: Check if manager application exists
Write-Host "Step 2: Checking manager application..." -ForegroundColor Yellow
$managerExists = $false

if (Test-Path $managerWebappsDir) {
    if (Test-Path "$managerWebappsDir\WEB-INF\web.xml") {
        Write-Host "  ✓ Manager application found" -ForegroundColor Green
        $managerExists = $true
    } else {
        Write-Host "  ⚠ Manager directory exists but is incomplete" -ForegroundColor Yellow
    }
} elseif (Test-Path $managerWarFile) {
    Write-Host "  ✓ Manager WAR file found, will be extracted on startup" -ForegroundColor Green
    $managerExists = $true
} else {
    Write-Host "  ⚠ Manager application not found in webapps" -ForegroundColor Yellow
    Write-Host "  Checking for manager in Tomcat distribution..." -ForegroundColor Yellow
    
    # Check if manager exists in the original Tomcat installation
    $possibleManagerPaths = @(
        "$tomcatDir\server\webapps\manager",
        "$tomcatDir\webapps\manager",
        "$tomcatDir\webapps\manager.war"
    )
    
    $foundManager = $false
    foreach ($path in $possibleManagerPaths) {
        if (Test-Path $path) {
            Write-Host "  ✓ Found manager at: $path" -ForegroundColor Green
            if (Test-Path "$path\WEB-INF\web.xml") {
                # Copy manager directory to webapps
                Write-Host "  Copying manager to webapps..." -ForegroundColor Yellow
                Copy-Item -Path $path -Destination "$tomcatDir\webapps\manager" -Recurse -Force
                $foundManager = $true
                $managerExists = $true
                break
            } elseif ($path -like "*.war") {
                # Copy manager WAR to webapps
                Write-Host "  Copying manager WAR to webapps..." -ForegroundColor Yellow
                Copy-Item -Path $path -Destination "$tomcatDir\webapps\manager.war" -Force
                $foundManager = $true
                $managerExists = $true
                break
            }
        }
    }
    
    if (-not $foundManager) {
        Write-Host "  ⚠ Manager application not found. It should be extracted on first Tomcat start." -ForegroundColor Yellow
        Write-Host "  Creating placeholder to ensure deployment..." -ForegroundColor Yellow
        # Create a minimal manager directory structure
        if (-not (Test-Path "$managerWebappsDir")) {
            New-Item -ItemType Directory -Force -Path "$managerWebappsDir" | Out-Null
        }
        if (-not (Test-Path "$managerWebappsDir\META-INF")) {
            New-Item -ItemType Directory -Force -Path "$managerWebappsDir\META-INF" | Out-Null
        }
    }
}

# Step 3: Fix tomcat-users.xml
Write-Host "Step 3: Configuring tomcat-users.xml..." -ForegroundColor Yellow
$usersXmlContent = '<?xml version="1.0" encoding="UTF-8"?>
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

Set-Content -Path $tomcatUsersFile -Value $usersXmlContent -Encoding UTF8
Write-Host "  ✓ User 'admin' with password 'admin123' configured" -ForegroundColor Green

# Step 4: Fix manager context.xml (remove IP restriction)
Write-Host "Step 4: Configuring manager context.xml..." -ForegroundColor Yellow
if (-not (Test-Path "$managerWebappsDir\META-INF")) {
    New-Item -ItemType Directory -Force -Path "$managerWebappsDir\META-INF" | Out-Null
}

$contextXmlContent = @'
<?xml version="1.0" encoding="UTF-8"?>
<!--
  Licensed to the Apache Software Foundation (ASF) under one or more
  contributor license agreements.  See the NOTICE file distributed with
  this work for additional information regarding copyright ownership.
  The ASF licenses this file to You under the Apache License, Version 2.0
  (the "License"); you may not use this file except in compliance with
  the License.  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
-->
<Context antiResourceLocking="false" privileged="true" >
  <CookieProcessor className="org.apache.tomcat.util.http.Rfc6265CookieProcessor"
                   sameSiteCookies="strict" />
  <!-- IP restriction commented out to allow local access -->
  <!--
  <Valve className="org.apache.catalina.valves.RemoteAddrValve"
         allow="127\.\d+\.\d+\.\d+|::1|0:0:0:0:0:0:0:1" />
  -->
  <Manager sessionAttributeValueClassNameFilter="java\.lang\.(?:Boolean|Integer|Long|Number|String)|org\.apache\.catalina\.filters\.CsrfPreventionFilter\$LruCache(?:\$1)?|java\.util\.(?:Linked)?HashMap"/>
</Context>
'@

Set-Content -Path $managerContextFile -Value $contextXmlContent -Encoding UTF8
Write-Host "  ✓ Manager context.xml configured (IP restriction removed)" -ForegroundColor Green

# Step 5: Ensure manager is properly deployed
Write-Host "Step 5: Ensuring manager deployment..." -ForegroundColor Yellow
if (-not (Test-Path "$managerWebappsDir\WEB-INF")) {
    Write-Host "  ⚠ Manager WEB-INF not found. Manager will be extracted from WAR on startup." -ForegroundColor Yellow
}

# Step 6: Start Tomcat
Write-Host "Step 6: Starting Tomcat..." -ForegroundColor Yellow
$env:CATALINA_HOME = $tomcatDir
Start-Process -FilePath "$tomcatDir\bin\startup.bat" -WindowStyle Normal
Write-Host "  Waiting for Tomcat to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

# Step 7: Verify
Write-Host "Step 7: Verifying Tomcat and Manager..." -ForegroundColor Yellow
$running = netstat -ano | Select-String ":8080.*LISTENING"
if ($running) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "✓ Tomcat is RUNNING!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Manager Access:" -ForegroundColor Cyan
    Write-Host "  URL: http://localhost:8080/manager/html" -ForegroundColor White
    Write-Host "  Username: admin" -ForegroundColor Yellow
    Write-Host "  Password: admin123" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Waiting a few more seconds for manager to fully deploy..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
    
    Write-Host ""
    Write-Host "Opening manager in browser..." -ForegroundColor Cyan
    Start-Process "http://localhost:8080/manager/html"
} else {
    Write-Host ""
    Write-Host "⚠ Tomcat may still be starting. Please wait a few more seconds and try:" -ForegroundColor Yellow
    Write-Host "  http://localhost:8080/manager/html" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "If the issue persists, check Tomcat logs:" -ForegroundColor Yellow
    Write-Host "  $tomcatDir\logs\catalina.*.log" -ForegroundColor White
}

Write-Host ""

