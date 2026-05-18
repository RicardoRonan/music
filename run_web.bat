@echo off
rem Run the app in Chrome (web) — safe on Windows usernames with spaces.
call "%~dp0run_flutter.bat" run -d chrome %*
