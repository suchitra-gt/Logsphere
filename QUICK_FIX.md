# Quick Fix - Install Java 17

## The Issue
Your project requires **Java 17**, but only **Java 8** is installed.

## Quick Solution

### Option 1: Download Java 17 (Recommended - ~5 minutes)
1. **Download**: Go to https://adoptium.net/temurin/releases/?version=17
   - Choose: Windows x64 → JDK → .msi installer
2. **Install**: Run the installer
   - ✅ Check "Add to PATH"
   - ✅ Check "Set JAVA_HOME variable" 
   - ✅ Check "JavaSoft (Oracle) registry keys"
3. **Verify**: Close and reopen terminal, then run:
   ```
   java -version
   ```
   Should show version 17.

### Option 2: Use Chocolatey (if installed)
```powershell
choco install openjdk17
```

### After Installation - Configure Eclipse
1. **Eclipse** → Window → Preferences → Java → Installed JREs
2. Click **"Add..."** → Standard VM → Next
3. Click **"Directory..."** → Browse to: `C:\Program Files\Eclipse Adoptium\jdk-17.x.x`
4. Click **Finish**, then **check** Java 17
5. **Apply and Close**

### Update Your Project
1. Right-click **LogSphere** project → Properties
2. **Java Build Path** → Libraries tab
3. Remove old **JRE System Library [JavaSE-1.8]**
4. Click **Add Library...** → JRE System Library → Next
5. Select **JavaSE-17** → Finish
6. **Apply and Close**
7. **Project** → Clean → Clean all projects

### Verify It Works
After installing Java 17 and configuring Eclipse, try:
```powershell
.\mvnw.cmd clean compile
```

**Note**: You can have both Java 8 and Java 17 installed. Just make sure Eclipse uses Java 17 for this project.

