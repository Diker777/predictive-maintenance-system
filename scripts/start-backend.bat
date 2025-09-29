@echo off
set PATH=C:\Program Files\dotnet;%PATH%
cd /d "%~dp0.."
echo Starting backend with dotnet...
echo Working directory: %CD%
dotnet run --project PredictiveMaintenance.Api --urls "http://localhost:5219"
