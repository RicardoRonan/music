@echo off
setlocal EnableExtensions

rem Work around Dart native-asset hooks breaking when paths contain spaces
rem (e.g. C:\Users\LENOVO THINKPAD P15\...). See README.md#windows-paths-with-spaces.

set "PROJECT_DIR=%~dp0"
if "%PROJECT_DIR:~-1%"=="\" set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"

if not exist "C:\pub-cache" mkdir "C:\pub-cache" >nul 2>&1
set "PUB_CACHE=C:\pub-cache"

set "WORK_DIR=%PROJECT_DIR%"
echo "%PROJECT_DIR%" | findstr /C:" " >nul
if %ERRORLEVEL%==0 (
  subst M: "%PROJECT_DIR%" >nul 2>&1
  if exist M:\ (
    set "WORK_DIR=M:\"
  )
)

cd /d "%WORK_DIR%"
if errorlevel 1 (
  echo Could not enter project directory: %WORK_DIR%
  exit /b 1
)

set "FLUTTER_SDK=%LOCALAPPDATA%\Flutter"
if exist "%FLUTTER_SDK%\bin\flutter.bat" (
  call "%FLUTTER_SDK%\bin\flutter.bat" %*
  exit /b %ERRORLEVEL%
)

where flutter >nul 2>&1
if %ERRORLEVEL%==0 (
  flutter %*
  exit /b %ERRORLEVEL%
)

echo Flutter SDK not found. Install Flutter or set FLUTTER_SDK.
exit /b 1
