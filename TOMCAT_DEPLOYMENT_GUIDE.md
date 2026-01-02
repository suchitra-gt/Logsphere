# Tomcat Deployment Guide for LogSphere

## Prerequisites

### 1. Install Java 17
- Download Java 17 JDK from: https://adoptium.net/temurin/releases/
- Install it (e.g., to `C:\Program Files\Java\jdk-17`)
- Set JAVA_HOME environment variable:
  ```powershell
  [System.Environment]::SetEnvironmentVariable('JAVA_HOME', 'C:\Program Files\Java\jdk-17', 'Machine')
  ```
- Add to PATH: `%JAVA_HOME%\bin`

### 2. Download and Install Apache Tomcat 10.x
- Download from: https://tomcat.apache.org/download-10.cgi
- Extract to a folder (e.g., `C:\Program Files\Apache Software Foundation\Tomcat 10.1`)
- **Important**: Tomcat 10.x requires Java 17+

## Building the WAR File

1. **Set JAVA_HOME to Java 17** (if you have multiple Java versions):
   ```powershell
   $env:JAVA_HOME = "C:\Program Files\Java\jdk-17"
   ```

2. **Build the WAR file**:
   ```powershell
   cd "C:\Users\admin\Desktop\LogSphere\LogSphere"
   .\mvnw.cmd clean package -DskipTests
   ```

3. **WAR file location**: `target\LogSphere-0.0.1-SNAPSHOT.war`

## Tomcat Configuration

### 1. Configure Tomcat Manager (Username & Password)

Edit the file: `[TOMCAT_HOME]\conf\tomcat-users.xml`

Add the following inside `<tomcat-users>` tag:

```xml
<role rolename="manager-gui"/>
<role rolename="manager-script"/>
<role rolename="manager-jmx"/>
<role rolename="manager-status"/>
<role rolename="admin-gui"/>
<role rolename="admin-script"/>
<user username="admin" password="admin123" roles="manager-gui,manager-script,manager-jmx,manager-status,admin-gui,admin-script"/>
```

**Default Credentials:**
- **Username**: `admin`
- **Password**: `admin123`

⚠️ **Change these credentials in production!**

### 2. Enable Manager Access (if needed)

Edit: `[TOMCAT_HOME]\webapps\manager\META-INF\context.xml`

Comment out or remove the IP restriction:
```xml
<!--
<Valve className="org.apache.catalina.valves.RemoteAddrValve"
         allow="127\.\d+\.\d+\.\d+|::1|0:0:0:0:0:0:0:1" />
-->
```

### 3. Configure Database Connection

Make sure MySQL is running and the database `logsphere` exists.

Update `application.properties` if needed:
- Database URL: `jdbc:mysql://localhost:3306/logsphere`
- Username: `root`
- Password: `root`

## Starting Tomcat

### Windows (Command Prompt):
```cmd
cd "C:\Program Files\Apache Software Foundation\Tomcat 10.1\bin"
startup.bat
```

### Windows (PowerShell):
```powershell
cd "C:\Program Files\Apache Software Foundation\Tomcat 10.1\bin"
.\startup.bat
```

### Check if Tomcat is running:
Open browser: http://localhost:8080

You should see the Tomcat welcome page.

## Deploying the WAR File

### Method 1: Using Tomcat Manager (Web Interface)

1. Open: http://localhost:8080/manager/html
2. Login with:
   - Username: `admin`
   - Password: `admin123`
3. Scroll to "WAR file to deploy" section
4. Click "Choose File" and select: `target\LogSphere-0.0.1-SNAPSHOT.war`
5. Click "Deploy"
6. Wait for deployment to complete
7. Access your application at: http://localhost:8080/LogSphere-0.0.1-SNAPSHOT/

### Method 2: Manual Deployment

1. Copy the WAR file:
   ```powershell
   Copy-Item "target\LogSphere-0.0.1-SNAPSHOT.war" -Destination "C:\Program Files\Apache Software Foundation\Tomcat 10.1\webapps\LogSphere.war"
   ```

2. Tomcat will automatically deploy it
3. Access at: http://localhost:8080/LogSphere/

### Method 3: Using Manager API (Command Line)

```powershell
$warFile = "C:\Users\admin\Desktop\LogSphere\LogSphere\target\LogSphere-0.0.1-SNAPSHOT.war"
$tomcatUrl = "http://localhost:8080/manager/text/deploy?path=/LogSphere"
$credentials = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("admin:admin123"))

Invoke-WebRequest -Uri $tomcatUrl -Method PUT -InFile $warFile -Headers @{Authorization="Basic $credentials"} -ContentType "application/octet-stream"
```

## Accessing Your Application

After deployment, access your application at:
- **Root URL**: http://localhost:8080/LogSphere/
- **Admin Dashboard**: http://localhost:8080/LogSphere/admin/dashboard
- **HR Dashboard**: http://localhost:8080/LogSphere/hr/dashboard
- **Employee Dashboard**: http://localhost:8080/LogSphere/employee/dashboard

## Stopping Tomcat

```cmd
cd "C:\Program Files\Apache Software Foundation\Tomcat 10.1\bin"
shutdown.bat
```

## Troubleshooting

### Port 8080 Already in Use
- Change Tomcat port in `[TOMCAT_HOME]\conf\server.xml`
- Find `<Connector port="8080"` and change to another port (e.g., 8081)

### Deployment Fails
- Check Tomcat logs: `[TOMCAT_HOME]\logs\catalina.out`
- Ensure Java 17 is being used
- Check database connection

### Manager Access Denied
- Verify `tomcat-users.xml` configuration
- Check `manager\context.xml` for IP restrictions
- Restart Tomcat after configuration changes

## Security Recommendations

1. **Change default passwords** in `tomcat-users.xml`
2. **Restrict manager access** to specific IPs in production
3. **Use HTTPS** in production environments
4. **Keep Tomcat updated** to latest stable version

