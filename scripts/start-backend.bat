@echo off
chcp 65001 >nul
set PATH=C:\Program Files\dotnet;%PATH%
cd /d "%~dp0.."
echo Starting backend with dotnet...
echo Working directory: %CD%
echo Executing: dotnet run --project PredictiveMaintenance.Api --urls http://0.0.0.0:5219
dotnet run --project PredictiveMaintenance.Api --urls http://0.0.0.0:5219
