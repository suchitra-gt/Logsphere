# Fix LogSphere 404 Error

## Problem
Getting 404 error when accessing `/LogSphere/` after deployment.

## Root Causes & Solutions

### 1. WAR File Not Built or Missing
**Solution:** Build the WAR file (requires Java 17)
```powershell
# Set JAVA_HOME to Java 17 first
$env:JAVA_HOME = "C:\Program Files\Java\jdk-17"
.\mvnw.cmd clean package -DskipTests
```

### 2. Spring Boot Application Not Starting
**Check:** Look for Spring Boot startup messages in logs
```powershell
Get-Content "$env:USERPROFILE\apache-tomcat-9.0.95\logs\catalina.*.log" | Select-String "Started LogSphereApplication"
```

**Common Issues:**
- Database connection failure (MySQL not running)
- Port conflicts
- Missing dependencies

### 3. Database Connection Issue
**Check MySQL:**
- Is MySQL running?
- Is database `logsphere` created?
- Are credentials correct in `application.properties`?

### 4. Quick Fix - Manual Deployment
1. **Stop Tomcat:**
   ```powershell
   cd "$env:USERPROFILE\apache-tomcat-9.0.95\bin"
   .\shutdown.bat
   ```

2. **Copy WAR file:**
   ```powershell
   Copy-Item "target\LogSphere-0.0.1-SNAPSHOT.war" "$env:USERPROFILE\apache-tomcat-9.0.95\webapps\LogSphere.war"
   ```

3. **Start Tomcat:**
   ```powershell
   .\startup.bat
   ```

4. **Wait 60 seconds** for Spring Boot to initialize

5. **Access:** http://localhost:8080/LogSphere/

### 5. Check Application Logs
```powershell
# Check for Spring Boot errors
Get-Content "$env:USERPROFILE\apache-tomcat-9.0.95\logs\localhost.*.log" | Select-String "ERROR|Exception"
```

### 6. Verify Deployment
```powershell
# Check if directory was extracted
Test-Path "$env:USERPROFILE\apache-tomcat-9.0.95\webapps\LogSphere\WEB-INF\web.xml"

# Check if WAR exists
Test-Path "$env:USERPROFILE\apache-tomcat-9.0.95\webapps\LogSphere.war"
```

## Expected Behavior
- WAR file should extract to `LogSphere` directory
- Spring Boot should start and show "Started LogSphereApplication" in logs
- Application should be accessible at `/LogSphere/`

## If Still Not Working
1. Check MySQL is running
2. Verify database exists: `logsphere`
3. Check all logs for errors
4. Try accessing: http://localhost:8080/LogSphere/login (direct path)

