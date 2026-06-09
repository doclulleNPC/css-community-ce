@echo off
setlocal enableextensions enabledelayedexpansion
REM ===========================================================================
REM start-community.bat - launch Counter-Strike: Source Community Edition on
REM Windows. Windows counterpart of start-community.sh.
REM
REM Usage:
REM   start-community.bat                  main menu
REM   start-community.bat +map de_dust2    straight into a map
REM   start-community.bat -bots            de_dust2 listen server with 8 bots
REM Extra args pass straight through to the engine.
REM ===========================================================================

REM --- mod dir (this script's folder + mp\game\community) ----------------------
set "MOD_DIR=%~dp0mp\game\community"
if not exist "%MOD_DIR%\gameinfo.txt" (
    echo ERROR: mod dir not found at "%MOD_DIR%" 1>&2
    exit /b 1
)

REM --- locate Steam (registry) ------------------------------------------------
set "STEAM_PATH="
for /f "tokens=2,*" %%a in ('reg query "HKCU\Software\Valve\Steam" /v SteamPath 2^>nul') do set "STEAM_PATH=%%b"
if not defined STEAM_PATH for /f "tokens=2,*" %%a in ('reg query "HKLM\SOFTWARE\WOW6432Node\Valve\Steam" /v InstallPath 2^>nul') do set "STEAM_PATH=%%b"
if not defined STEAM_PATH (
    echo ERROR: could not find Steam in the registry. Is Steam installed? 1>&2
    exit /b 1
)
REM Registry uses forward slashes; normalize to backslashes.
set "STEAM_PATH=%STEAM_PATH:/=\%"

REM --- require a running, logged-in Steam -------------------------------------
REM Like the Linux script: without Steam, SteamAPI_Init() fails and the engine
REM crashes inside steam_api.dll on startup. Make sure Steam is up first.
tasklist /fi "imagename eq steam.exe" 2>nul | find /i "steam.exe" >nul
if errorlevel 1 (
    echo Steam is not running -- starting it ^(the engine crashes without it^)...
    if not exist "%STEAM_PATH%\steam.exe" (
        echo ERROR: steam.exe not found at "%STEAM_PATH%". Start Steam and log in, then re-run. 1>&2
        exit /b 1
    )
    start "" "%STEAM_PATH%\steam.exe"
    echo Waiting for Steam to start...
    for /l %%i in (1,1,30) do (
        timeout /t 2 /nobreak >nul
        tasklist /fi "imagename eq steamwebhelper.exe" 2>nul | find /i "steamwebhelper.exe" >nul && goto steam_ready
    )
    echo ERROR: Steam did not start in time. Start it, log in, then re-run. 1>&2
    exit /b 1
)
:steam_ready
echo NOTE: make sure you are logged into Steam, or the game will crash on start.

REM --- locate Source SDK Base 2013 Multiplayer (Steam app 243750) --------------
set "SDK_DIR="
call :find_sdk "%STEAM_PATH%"
if not defined SDK_DIR (
    REM Scan extra Steam library folders listed in libraryfolders.vdf.
    for /f "usebackq tokens=2 delims=	 " %%p in (`findstr /i /c:"\"path\"" "%STEAM_PATH%\steamapps\libraryfolders.vdf" 2^>nul`) do (
        set "_lib=%%~p"
        set "_lib=!_lib:\\=\!"
        call :find_sdk "!_lib!"
    )
)
if not defined SDK_DIR (
    echo ERROR: Source SDK Base 2013 Multiplayer not found ^(Steam app 243750^). 1>&2
    echo        Install it from Steam ^(Library ^> Tools^), then re-run. 1>&2
    exit /b 1
)

REM --- args (with -bots convenience) ------------------------------------------
set "EXTRA="
:argloop
if "%~1"=="" goto run
if /i "%~1"=="-bots" (
    set "EXTRA=!EXTRA! +sv_cheats 1 +bot_quota 8 +bot_join_after_player 0 +map de_dust2"
) else (
    set "EXTRA=!EXTRA! %~1"
)
shift
goto argloop

:run
echo Launching CS:S Community Edition  ^(mod=%MOD_DIR%^)
start "" /d "%SDK_DIR%" "%SDK_DIR%\hl2.exe" -game "%MOD_DIR%" -insecure%EXTRA%
endlocal
exit /b 0

REM --- helper: set SDK_DIR if a library root contains the SDK base -------------
:find_sdk
set "_cand=%~1\steamapps\common\Source SDK Base 2013 Multiplayer"
if exist "%_cand%\hl2.exe" set "SDK_DIR=%_cand%"
goto :eof
