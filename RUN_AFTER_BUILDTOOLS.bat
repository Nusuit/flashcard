@echo off
echo ============================================
echo Kiem tra Flutter environment...
echo ============================================
cd /d D:\Code\Important\project\knop_flashcard
"D:\Extra download\flutter\bin\flutter" doctor -v

echo.
echo ============================================
echo Chay ung dung Knop...
echo ============================================
"D:\Extra download\flutter\bin\flutter" run -d windows

pause
