@echo off
rem Run the app as a Windows desktop app — safe on Windows usernames with spaces.
call "%~dp0run_flutter.bat" run -d windows %*
