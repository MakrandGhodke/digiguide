@echo off
echo ===================================================
echo   DIGIGUIDE - ONE-CLICK STARTUP (Fixes Connections)
echo ===================================================
echo.

echo Select Connection Mode:
echo [1] USB (Always works, use cable)
echo [2] Wi-Fi (Requires same network)
set /p mode="Enter choice (1/2): "

if "%mode%"=="1" (
    echo [INFO] Setting up for USB...
    echo [INFO] Attempting to set up ADB reverse port forwarding...
    adb reverse tcp:8000 tcp:8000
    if errorlevel 1 (
         echo [WARN] ADB not found or device not connected. 
         echo        Please ensure 'adb' is in PATH and USB Debugging is ON.
         echo        Otherwise, this mode might not work on a real device.
    ) else (
         echo [SUCCESS] ADB Reverse tunneling active. App can connect to localhost:8000.
    )
    python update_ip.py --localhost
) else (
    echo [INFO] Detecting Wi-Fi IP...
    python update_ip.py
)

echo.
echo [2/5] Attempting USB Connection (Optional)...
    adb reverse tcp:8000 tcp:8000
    if %errorlevel% neq 0 (
        echo [INFO] USB Bridge failed. Assuming Wireless Connection mode.
    ) else (
        echo [OK] USB Bridge Active.
    )

echo.
echo [2/4] Starting Backend Server (In New Window)...
start "DigiGuide Backend" cmd /k "python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000"

echo.
echo [3/4] Waiting 5 seconds for Backend to warm up...
timeout /t 5 /nobreak >nul

echo.
echo [4/4] Starting Mobile App...
cd frontend
flutter run

echo.
echo ===================================================
echo  If App fails to launch, close this and try again!
echo ===================================================
pause
