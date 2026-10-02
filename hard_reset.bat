@echo off
echo [1/3] Killing running Python processes (Backend)...
taskkill /F /IM python.exe /T
taskkill /F /IM uvicorn.exe /T

echo.
echo [2/3] Resetting ADB Bridge...
adb reverse --remove-all
adb reverse tcp:8000 tcp:8000

echo.
echo [3/3] Done! Now run start_all.bat again.
pause
