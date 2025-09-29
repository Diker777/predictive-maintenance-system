@echo off
chcp 65001 >nul
set PATH=C:\Program Files\nodejs;%PATH%
cd /d "%~dp0..\frontend"
echo Starting frontend with npm...
echo Working directory: %CD%
echo Executing: npm run dev -- --host 0.0.0.0
npm run dev -- --host 0.0.0.0
