# How to Fix "String cannot be resolved to a type" Error

## Problem
Your project requires Java 17, but your system only has Java 8 installed. Spring Boot 3.5.7 requires Java 17 or higher.

## Solution: Install Java 17

### Step 1: Download Java 17 JDK
1. Go to: https://adoptium.net/temurin/releases/?version=17
2. Download the Windows x64 JDK installer (.msi file)
3. Or use this direct link: https://adoptium.net/

### Step 2: Install Java 17
1. Run the downloaded installer
2. Install to default location: `C:\Program Files\Eclipse Adoptium\jdk-17.x.x`
3. **IMPORTANT**: Check "Add to PATH" and "Set JAVA_HOME variable" during installation

### Step 3: Verify Installation
Open PowerShell and run:
```powershell
java -version
```
You should see version 17.

### Step 4: Set JAVA_HOME Environment Variable
If not set automatically:
1. Right-click "This PC" → Properties
2. Click "Advanced system settings"
3. Click "Environment Variables"
4. Under "System variables", click "New"
5. Variable name: `JAVA_HOME`
6. Variable value: `C:\Program Files\Eclipse Adoptium\jdk-17.x.x` (your actual path)
7. Click OK

### Step 5: Configure Eclipse
1. Open Eclipse
2. Go to: Window → Preferences
3. Navigate to: Java → Installed JREs
4. Click "Add..." → Select "Standard VM" → Next
5. Click "Directory..." and browse to your Java 17 installation folder
6. Click "Finish" and check the box for Java 17
7. Click "Apply and Close"

### Step 6: Configure Project to Use Java 17
1. Right-click your project: LogSphere
2. Properties → Java Build Path → Libraries tab
3. Remove old "JRE System Library" (Java 8)
4. Click "Add Library..." → JRE System Library → Next
5. Select "Workspace default JRE (JavaSE-17)" or "Installed JREs"
6. Select Java 17 → Finish → Apply and Close

### Step 7: Update Project Facets (if needed)
1. Right-click project → Properties
2. Project Facets
3. Ensure Java version is set to 17
4. Click Apply and Close

### Step 8: Clean and Rebuild
1. Project → Clean → Select "LogSphere" → Clean
2. Project → Build All

## Quick Fix (If Java 17 Already Installed)
If Java 17 is installed but Eclipse can't find it, update the .classpath file to use the correct path, or configure Eclipse's installed JREs as described in Step 5 above.

## Verify It Works
After following these steps, the error should be resolved. Try running:
```powershell
.\mvnw.cmd clean compile
```

This should now work without errors.

