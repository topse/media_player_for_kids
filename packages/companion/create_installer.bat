@echo off

:: Extract version from pubspec.yaml (e.g. "version: 1.0.0+1" -> "1.0.0+1")
for /f "tokens=2" %%a in ('findstr /r "^version:" pubspec.yaml') do set VERSION=%%a

echo Version: %VERSION%

echo.
echo [1/2] Building Flutter release bundle...
call flutter build windows --release
if errorlevel 1 (
    echo Flutter build failed.
    exit /b 1
)

echo.
echo [2/2] Compiling NSIS installer...
"C:\Program Files (x86)\NSIS\makensis.exe" /DVERSION="%VERSION%" installer\media_player_for_kids_companion.nsi
if errorlevel 1 (
    echo NSIS compilation failed.
    exit /b 1
)

echo.
echo Done: installer\media_player_for_kids_companion_%VERSION%.exe
