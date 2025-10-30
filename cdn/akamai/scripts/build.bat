@echo off
setlocal enabledelayedexpansion

REM Akamai CDN Refresh Tool - Build Script (win64/mac64 only)
cd /d "%~dp0\.."

echo Akamai CDN Refresh Tool - Build (win64/mac64)
echo =============================================

REM Check Go environment
go version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Go not found. Please install Go first.
    exit /b 1
)

echo Go version:
go version

REM Clean and create dist directory
echo.
echo Cleaning dist directory...
if exist dist rmdir /s /q dist
mkdir dist

set success_count=0
set total_count=2

REM Windows 64bit
echo [BUILD] windows/amd64 -> akamai_cdn_refresh_windows_amd64.exe
set GOOS=windows
set GOARCH=amd64
set CGO_ENABLED=0
go build -ldflags "-s -w" -o "dist/akamai_cdn_refresh_windows_amd64.exe" src/akamai_cdn_refresh.go
if !errorlevel! equ 0 (
    echo    [OK] win64 build success
    set /a success_count+=1
) else (
    echo    [FAIL] win64 build failed
)

REM macOS Intel 64bit
echo [BUILD] darwin/amd64 -> akamai_cdn_refresh_darwin_amd64
set GOOS=darwin
set GOARCH=amd64
set CGO_ENABLED=0
go build -ldflags "-s -w" -o "dist/akamai_cdn_refresh_darwin_amd64" src/akamai_cdn_refresh.go
if !errorlevel! equ 0 (
    echo    [OK] mac64 build success
    set /a success_count+=1
) else (
    echo    [FAIL] mac64 build failed
)

echo.
echo Build summary: %success_count% / %total_count% platforms succeeded
if %success_count% equ %total_count% (
    echo [ALL OK] All platforms built successfully!
) else (
    echo [WARN] Some platforms failed, please check the log.
)

echo.
echo Output files:
dir /b dist\

REM Copy config files to dist directory
echo.
echo Copying config files...
if exist conf\akamai.conf copy conf\akamai.conf dist\ >nul
if exist conf\url.json copy conf\url.json dist\ >nul
if exist conf\urls.txt copy conf\urls.txt dist\ >nul

echo.
echo Build finished! Executables are in the dist\ directory.
echo Example: cd dist && akamai_cdn_refresh_windows_amd64.exe --help

pause