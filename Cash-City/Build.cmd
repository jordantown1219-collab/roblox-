@echo off
cd /d "%~dp0"
set "SS_PY=%USERPROFILE%\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
if exist "%SS_PY%" (
 "%SS_PY%" build.py
 if errorlevel 1 exit /b 1
 "%SS_PY%" tools\create_rojo_project.py
) else (
 py -3 build.py
 if errorlevel 1 exit /b 1
 py -3 tools\create_rojo_project.py
)
