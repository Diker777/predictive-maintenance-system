@echo off
set PATH=C:\Program Files\nodejs;%PATH%
cd /d "%~dp0..\frontend"
echo Starting frontend with npm...
echo Working directory: %CD%
echo PATH: %PATH%
npm run dev
