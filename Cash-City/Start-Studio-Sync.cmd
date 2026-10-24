@echo off
cd /d "%~dp0"
tools\rojo\rojo.exe serve scripts.project.json --address 127.0.0.1 --port 34872
