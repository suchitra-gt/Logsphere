# Restore Manager Context.xml
$tomcatDir = "$env:USERPROFILE\apache-tomcat-9.0.95"
$managerContextFile = "$tomcatDir\webapps\manager\META-INF\context.xml"

Write-Host "Restoring manager context.xml..." -ForegroundColor Yellow

# Create proper context.xml with IP restriction commented out
$contextXml = @'
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

Set-Content -Path $managerContextFile -Value $contextXml -Encoding UTF8
Write-Host "Manager context.xml restored!" -ForegroundColor Green

Write-Host "Starting Tomcat..." -ForegroundColor Yellow
$env:CATALINA_HOME = $tomcatDir
Start-Process -FilePath "$tomcatDir\bin\startup.bat" -WindowStyle Normal
Start-Sleep -Seconds 12

$running = netstat -ano | Select-String ":8080.*LISTENING"
if ($running) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Tomcat Manager Fixed!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Manager URL: http://localhost:8080/manager/html" -ForegroundColor Cyan
    Write-Host "Username: admin" -ForegroundColor Yellow
    Write-Host "Password: admin123" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Opening manager..." -ForegroundColor Cyan
    Start-Process "http://localhost:8080/manager/html"
} else {
    Write-Host "Tomcat is starting, please wait..." -ForegroundColor Yellow
}

