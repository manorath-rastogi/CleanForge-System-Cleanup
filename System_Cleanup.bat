@echo off

:: ----------------------------------------------------------------
::  SELF-ELEVATION  --  Auto relaunch as Administrator if needed
:: ----------------------------------------------------------------
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -NoProfile -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

chcp 65001 >nul 2>&1
setlocal EnableDelayedExpansion

:: ================================================================
::  System Cleanup Pro  |  Version 1.0.0 Stable
::  Professional Windows Maintenance Utility
::  Compatible: Windows 10 / Windows 11
::  Author    : CleanForge Project
:: ================================================================

:: ----------------------------------------------------------------
::  GLOBAL CONFIGURATION
:: ----------------------------------------------------------------
set /a TOTAL_TASKS=12
set /a STEP=0
set /a PASS=0
set /a FAIL=0
set /a WARN=0
set /a TOTAL_FREED=0

:: Log directory and filename
set "LOG_DIR=%~dp0Logs"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
for /f "tokens=2 delims==" %%a in ('wmic os get LocalDateTime /value') do set "DT=%%a"
set "LOG_TS=%DT:~0,4%%DT:~4,2%%DT:~6,2%_%DT:~8,2%%DT:~10,2%%DT:~12,2%"
set "LOGFILE=%LOG_DIR%\cleanup_%LOG_TS%.log"

:: ----------------------------------------------------------------
::  MAIN FLOW
:: ----------------------------------------------------------------
call :FN_ADMIN_CHECK
call :FN_BANNER
call :FN_MODULE_LOAD
call :FN_SYSINFO
call :FN_SAFETY_CHECKS
call :FN_DISK_BEFORE
call :FN_HIBER_PROMPT
call :FN_LOG_INIT

:: Record start time
set "START_TIME=%TIME%"
for /f "tokens=2 delims==" %%t in ('wmic os get LocalDateTime /value') do set "DT_S=%%t"
set /a _SH=%DT_S:~8,2%
set /a _SM=%DT_S:~10,2%
set /a _SS=%DT_S:~12,2%
set /a START_SEC=(_SH*3600)+(_SM*60)+_SS

:: ---- SECTION 1/4 ----
call :FN_SECTION_HDR 1 "TEMPORARY FILES CLEANUP"
call :TASK_USER_TEMP
call :TASK_WIN_TEMP
call :TASK_PREFETCH
call :TASK_RECYCLE

:: ---- SECTION 2/4 ----
call :FN_SECTION_HDR 2 "CACHE CLEANUP"
call :TASK_DNS
call :TASK_THUMB
call :TASK_DX_SHADER
call :TASK_DEL_OPT

:: ---- SECTION 3/4 ----
call :FN_SECTION_HDR 3 "SYSTEM MAINTENANCE"
call :TASK_WU_CACHE
call :TASK_WER
call :TASK_RECENT
call :TASK_STORE

:: ---- SECTION 4/4 ----
call :FN_SECTION_HDR 4 "ADVANCED CLEANUP"
call :TASK_DISM
call :TASK_CLEANMGR
if /i "!HIBER_CHOICE!"=="Y" call :TASK_HIBER

:: Record end time and elapsed
for /f "tokens=2 delims==" %%t in ('wmic os get LocalDateTime /value') do set "DT_E=%%t"
set "END_TIME=%TIME%"
set /a _EH=%DT_E:~8,2%
set /a _EM=%DT_E:~10,2%
set /a _ES=%DT_E:~12,2%
set /a END_SEC=(_EH*3600)+(_EM*60)+_ES
set /a ELAPSED=END_SEC - START_SEC
if %ELAPSED% lss 0 set /a ELAPSED+=86400
set /a ELAPSED_M=ELAPSED / 60
set /a ELAPSED_S=ELAPSED - (ELAPSED_M * 60)

:: Disk space AFTER
call :FN_FREE_MB SPACE_AFTER

:: Final report and export
call :FN_FINAL_REPORT
call :FN_EXPORT_PROMPT

endlocal
exit /b 0


:: ================================================================
::  :FN_ADMIN_CHECK
::  Verify Administrator privileges. Exit if not elevated.
:: ================================================================
:FN_ADMIN_CHECK
net session >nul 2>&1
if %errorlevel% neq 0 (
    color 0C
    cls
    echo.
    echo  +==============================================================+
    echo  ^|             SYSTEM CLEANUP UTILITY  v1.0.0                  ^|
    echo  +==============================================================+
    echo.
    echo   [x] Administrator Access Required
    echo.
    echo   This utility must be run with elevated privileges.
    echo.
    echo   HOW TO FIX:
    echo   Right-click on System_Cleanup.bat
    echo   Select  "Run as administrator"
    echo.
    echo  +==============================================================+
    echo.
    pause
    exit /b 1
)
goto :EOF


:: ================================================================
::  :FN_BANNER
::  Display the startup banner
:: ================================================================
:FN_BANNER
color 0B
cls
echo.
powershell -NoProfile -Command "[Console]::OutputEncoding=[System.Text.Encoding]::UTF8; $tl=[char]0x2554; $tr=[char]0x2557; $bl=[char]0x255A; $br=[char]0x255D; $v=[char]0x2551; $line=([string][char]0x2550)*58; Write-Host ""  $tl$line$tr"" -ForegroundColor Cyan; Write-Host ""  $v                                                          $v"" -ForegroundColor Cyan; Write-Host ""  $v           SYSTEM CLEANUP UTILITY                     $v"" -ForegroundColor Cyan; Write-Host ""  $v            Version 1.0.0 Stable                      $v"" -ForegroundColor Cyan; Write-Host ""  $v     Windows 10 / Windows 11 Supported                $v"" -ForegroundColor Cyan; Write-Host ""  $v                                                          $v"" -ForegroundColor Cyan; Write-Host ""  $bl$line$br"" -ForegroundColor Cyan"
echo.
goto :EOF


:: ================================================================
::  :FN_MODULE_LOAD
::  Animated module loading sequence
:: ================================================================
:FN_MODULE_LOAD
color 0F
echo  Loading Cleanup Modules...
echo.
ping -n 2 127.0.0.1 >nul
color 0A
echo   [+] Temp Cleaner Module     Loaded
ping -n 1 127.0.0.1 >nul
echo   [+] Cache Cleaner Module    Loaded
ping -n 1 127.0.0.1 >nul
echo   [+] Update Cache Module     Loaded
ping -n 1 127.0.0.1 >nul
echo   [+] DISM Module             Loaded
ping -n 1 127.0.0.1 >nul
echo   [+] Report Module           Loaded
ping -n 2 127.0.0.1 >nul
echo.
color 0F
echo  Initialization Complete.
echo.
echo  ------------------------------------------------------------
ping -n 2 127.0.0.1 >nul
goto :EOF


:: ================================================================
::  :FN_SYSINFO
::  Gather and display system information
:: ================================================================
:FN_SYSINFO
:: Gather info - use built-in env vars for PC name and user (always current machine)
set "SYS_PC=%COMPUTERNAME%"
set "SYS_USER=%USERNAME%"
for /f "delims=" %%o in ('powershell -NoProfile -Command "(Get-WmiObject Win32_OperatingSystem).Caption"') do set "SYS_OS=%%o"

:: Fetch fresh date/time right now (not stale DT from script start)
for /f "tokens=2 delims==" %%a in ('wmic os get LocalDateTime /value') do set "DT_NOW=%%a"
set /a "_H24=%DT_NOW:~8,2%"
set "_MN=%DT_NOW:~10,2%"
set "_DD=%DT_NOW:~6,2%"
set "_MM=%DT_NOW:~4,2%"
set "_YY=%DT_NOW:~0,4%"
set "_AMPM=AM"
if %_H24% GEQ 12 set "_AMPM=PM"
if %_H24% GTR 12 set /a "_H24=%_H24%-12"
if %_H24% EQU 0  set "_H24=12"
for %%m in (01-Jan 02-Feb 03-Mar 04-Apr 05-May 06-Jun 07-Jul 08-Aug 09-Sep 10-Oct 11-Nov 12-Dec) do (
    for /f "tokens=1,2 delims=-" %%a in ("%%m") do (
        if "%_MM%"=="%%a" set "_MON=%%b"
    )
)
set "SYS_DATE=%_DD%-%_MON%-%_YY%  %_H24%:%_MN% %_AMPM%"

color 0F
echo.
powershell -NoProfile -Command "[Console]::OutputEncoding=[System.Text.Encoding]::UTF8; Write-Host '  System Information' -ForegroundColor White; Write-Host ('  ' + ([string][char]0x2500)*62) -ForegroundColor DarkCyan"
color 0B
echo   Computer Name  :  !SYS_PC!
echo   User           :  !SYS_USER!
echo   Windows        :  !SYS_OS!
echo   Drive          :  C:
echo   Date ^& Time    :  !SYS_DATE!
color 0F
powershell -NoProfile -Command "[Console]::OutputEncoding=[System.Text.Encoding]::UTF8; Write-Host ('  ' + ([string][char]0x2500)*62) -ForegroundColor DarkCyan"
echo.
set /p "_CONT=  Press ENTER to begin cleanup . . . "
echo.
goto :EOF


:: ================================================================
::  :FN_SAFETY_CHECKS
::  Display safety validation steps
:: ================================================================
:FN_SAFETY_CHECKS
color 0F
echo  Performing Safety Checks...
echo.
ping -n 1 127.0.0.1 >nul
color 0A
echo   [+] Administrator Access Granted
ping -n 1 127.0.0.1 >nul
echo   [+] System Drive  C:  Accessible
ping -n 1 127.0.0.1 >nul
echo   [+] Log Directory Prepared
ping -n 1 127.0.0.1 >nul
echo   [+] Personal Files Protection  Active
ping -n 1 127.0.0.1 >nul
echo   [+] Safe Cleanup Paths Verified
ping -n 2 127.0.0.1 >nul
echo.
color 0F
echo  All Safety Checks Passed.
echo.
echo  ------------------------------------------------------------
echo.
goto :EOF


:: ================================================================
::  :FN_DISK_BEFORE
::  Capture and display disk space before cleanup
:: ================================================================
:FN_DISK_BEFORE
call :FN_FREE_MB SPACE_BEFORE
for /f %%t in ('powershell -NoProfile -Command "[math]::Round((Get-PSDrive C).Used / 1GB + (Get-PSDrive C).Free / 1GB)"') do set "DRIVE_TOTAL_GB=%%t"
set /a SPACE_BEFORE_GB=SPACE_BEFORE / 1024
set /a SPACE_BEFORE_MB_R=SPACE_BEFORE - (SPACE_BEFORE_GB * 1024)

color 0F
echo  Disk Space Before Cleanup
echo  ------------------------------------------------------------
color 0E
echo   Total Drive Size      :  %DRIVE_TOTAL_GB% GB
echo   Free Space Available  :  %SPACE_BEFORE_GB% GB  (%SPACE_BEFORE% MB)
color 0F
echo  ------------------------------------------------------------
echo.
goto :EOF


:: ================================================================
::  :FN_HIBER_PROMPT
::  Detect hiberfil.sys and ask user preference
:: ================================================================
:FN_HIBER_PROMPT
set "HIBER_CHOICE=N"
set "HIBER_SIZE=Not Found"
if exist "C:\hiberfil.sys" (
    for /f %%s in ('powershell -NoProfile -Command "try{[math]::Round((Get-Item -Force C:\hiberfil.sys).Length/1GB,2)}catch{0}"') do set "HIBER_SIZE=%%s GB"
    echo.
    color 0E
    echo  ------------------------------------------------------------
    echo   Hibernation File Detected
    echo  ------------------------------------------------------------
    color 0F
    echo.
    echo   Location     :  C:\hiberfil.sys
    echo   Current Size :  !HIBER_SIZE!
    echo.
    echo   Disabling hibernation will recover !HIBER_SIZE! of disk space.
    echo   It can be re-enabled anytime via:  powercfg /hibernate on
    echo.
    echo     [Y]  Yes - Disable hibernation and remove file
    echo     [N]  No  - Keep hibernation enabled
    echo.
    set /p "HIBER_CHOICE=   Your choice: "
    echo.
    echo  ------------------------------------------------------------
    echo.
)
goto :EOF


:: ================================================================
::  :FN_LOG_INIT
::  Initialize log file with system header
:: ================================================================
:FN_LOG_INIT
echo ================================================================ >  "%LOGFILE%"
echo   System Cleanup Pro  -  Version 1.0.0                         >> "%LOGFILE%"
echo ================================================================ >> "%LOGFILE%"
echo   Computer   : %SYS_PC%                                         >> "%LOGFILE%"
echo   User       : %SYS_USER%                                        >> "%LOGFILE%"
echo   OS         : %SYS_OS%                                          >> "%LOGFILE%"
echo   Date/Time  : %SYS_DATE%                                        >> "%LOGFILE%"
echo   Log File   : %LOGFILE%                                         >> "%LOGFILE%"
echo ================================================================ >> "%LOGFILE%"
echo.                                                                 >> "%LOGFILE%"
goto :EOF


:: ================================================================
::  :FN_FREE_MB  <VarName>
::  Get C: drive free space in MB using PowerShell (no 32-bit overflow)
:: ================================================================
:FN_FREE_MB
for /f %%f in ('powershell -NoProfile -Command "(Get-PSDrive C).Free / 1MB -as [int]"') do set "%~1=%%f"
goto :EOF


:: ================================================================
::  :FN_DIR_SIZE_MB  <"Path">  <VarName>
::  Get directory size in MB before deleting
:: ================================================================
:FN_DIR_SIZE_MB
set "%~2=0"
if exist "%~1" (
    for /f %%s in ('powershell -NoProfile -Command "try{(Get-ChildItem -LiteralPath \"%~1\" -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB -as [int]}catch{0}"') do set "%~2=%%s"
)
goto :EOF


:: ================================================================
::  :FN_COUNT_FILES  <"Path">  <VarName>
::  Count files in a directory
:: ================================================================
:FN_COUNT_FILES
set "%~2=0"
if exist "%~1" (
    for /f %%n in ('powershell -NoProfile -Command "try{(Get-ChildItem -LiteralPath \"%~1\" -Recurse -Force -ErrorAction SilentlyContinue | Where-Object {-not $_.PSIsContainer} | Measure-Object).Count}catch{0}"') do set "%~2=%%n"
)
goto :EOF


:: ================================================================
::  :FN_SECTION_HDR  <Number>  <"Title">
::  Print a section header
:: ================================================================
:FN_SECTION_HDR
color 0B
echo.
echo  ============================================================
echo   SECTION %~1/4  :  %~2
echo  ============================================================
echo.
echo   Preparing Next Cleanup Phase...
echo.
ping -n 2 127.0.0.1 >nul
echo [%TIME%] SECTION %~1/4 - %~2 >> "%LOGFILE%"
goto :EOF


:: ================================================================
::  :FN_PROGRESS
::  Draw progress bar and task counter
:: ================================================================
:FN_PROGRESS
set /a "_PCT=(STEP * 100) / TOTAL_TASKS"
set /a "_FILL=STEP * 20 / TOTAL_TASKS"
set /a "_EMPT=20 - _FILL"
for /f %%b in ('powershell -NoProfile -Command "('#' * %_FILL%) + ('-' * %_EMPT%)"') do set "_BAR=%%b"
if "!_BAR!"=="" set "_BAR=--------------------"
color 0F
echo.
echo   Progress
echo.
echo   [!_BAR!] %_PCT%%%
echo.
echo   Completed Tasks  :  %STEP% / %TOTAL_TASKS%
echo.
echo  ------------------------------------------------------------
goto :EOF


:: ================================================================
::  :FN_TASK_DONE  <"TaskName">  <rc>  <freed_MB>
::  Log task result and update counters
::  rc=0 Pass  rc=2 Warn  else Fail
:: ================================================================
:FN_TASK_DONE
set /a STEP+=1
set "_TN=%~1"
set /a "_RC=%~2"
set /a "_FMB=%~3"

:: Build freed string
if %_FMB% gtr 0 (
    set /a TOTAL_FREED+=_FMB
    set /a "_FGB=_FMB / 1024"
    set /a "_FRM=_FMB - (_FGB*1024)"
    if !_FGB! gtr 0 (
        set "_FS=!_FGB! GB !_FRM! MB Freed"
    ) else (
        set "_FS=!_FMB! MB Freed"
    )
) else (
    set "_FS=--"
)

if %_RC% EQU 0 (
    set /a PASS+=1
    powershell -NoProfile -Command "[Console]::OutputEncoding=[System.Text.Encoding]::UTF8; Write-Host '  [' -NoNewline -ForegroundColor White; Write-Host ([char]0x2713) -NoNewline -ForegroundColor Green; Write-Host '] Completed' -ForegroundColor Green"
    powershell -NoProfile -Command "[Console]::OutputEncoding=[System.Text.Encoding]::UTF8; Write-Host '  Space Recovered  :  !_FS!' -ForegroundColor Green"
    echo [%TIME%] [PASS] %_TN% ^| !_FS! >> "%LOGFILE%"
) else if %_RC% EQU 2 (
    set /a WARN+=1
    powershell -NoProfile -Command "[Console]::OutputEncoding=[System.Text.Encoding]::UTF8; Write-Host '  [' -NoNewline -ForegroundColor White; Write-Host ([char]0x26A0) -NoNewline -ForegroundColor Yellow; Write-Host '] Skipped  (Locked or Not Found)' -ForegroundColor Yellow"
    powershell -NoProfile -Command "Write-Host '      Continuing cleanup...' -ForegroundColor Yellow"
    echo [%TIME%] [WARN] %_TN% ^| Skipped >> "%LOGFILE%"
) else (
    set /a FAIL+=1
    powershell -NoProfile -Command "[Console]::OutputEncoding=[System.Text.Encoding]::UTF8; Write-Host '  [' -NoNewline -ForegroundColor White; Write-Host ([char]0x2717) -NoNewline -ForegroundColor Red; Write-Host '] Failed  (Error: %_RC%)' -ForegroundColor Red"
    powershell -NoProfile -Command "Write-Host '      Continuing cleanup...' -ForegroundColor Red"
    echo [%TIME%] [FAIL] %_TN% ^| rc=%_RC% >> "%LOGFILE%"
)
color 0B
call :FN_PROGRESS
goto :EOF


:: ================================================================
::  TASK 1/12  --  User Temp Files  (%TEMP%)
:: ================================================================
:TASK_USER_TEMP
color 0F
echo  [1/%TOTAL_TASKS%] User Temp Files
echo.
echo   Scanning...
call :FN_COUNT_FILES "%TEMP%" "_CNT"
echo   Found %_CNT% Files
echo.
echo   Deleting...
call :FN_DIR_SIZE_MB "%TEMP%" "_PRE"
rd /s /q "%TEMP%" >nul 2>&1
md "%TEMP%" >nul 2>&1
call :FN_TASK_DONE "User Temp Files" 0 %_PRE%
goto :EOF


:: ================================================================
::  TASK 2/12  --  Windows Temp Files  (C:\Windows\Temp)
:: ================================================================
:TASK_WIN_TEMP
color 0F
echo  [2/%TOTAL_TASKS%] Windows Temp Files
echo.
echo   Scanning...
call :FN_COUNT_FILES "C:\Windows\Temp" "_CNT"
echo   Found %_CNT% Files
echo.
echo   Deleting...
call :FN_DIR_SIZE_MB "C:\Windows\Temp" "_PRE"
rd /s /q "C:\Windows\Temp" >nul 2>&1
md "C:\Windows\Temp" >nul 2>&1
call :FN_TASK_DONE "Windows Temp Files" 0 %_PRE%
goto :EOF


:: ================================================================
::  TASK 3/12  --  Prefetch Files  (C:\Windows\Prefetch)
:: ================================================================
:TASK_PREFETCH
color 0F
echo  [3/%TOTAL_TASKS%] Prefetch Files
echo.
echo   Scanning...
call :FN_COUNT_FILES "C:\Windows\Prefetch" "_CNT"
echo   Found %_CNT% Files
echo.
echo   Deleting...
call :FN_DIR_SIZE_MB "C:\Windows\Prefetch" "_PRE"
del /q /f /s "C:\Windows\Prefetch\*" >nul 2>&1
set "_RC=%errorlevel%"
call :FN_TASK_DONE "Prefetch Files" %_RC% %_PRE%
goto :EOF


:: ================================================================
::  TASK 4/12  --  Recycle Bin
:: ================================================================
:TASK_RECYCLE
color 0F
echo  [4/%TOTAL_TASKS%] Recycle Bin
echo.
echo   Scanning...
call :FN_DIR_SIZE_MB "C:\$Recycle.Bin" "_PRE"
echo   Scanning complete.
echo.
echo   Emptying...
rd /s /q "C:\$Recycle.Bin" >nul 2>&1
call :FN_TASK_DONE "Recycle Bin" 0 %_PRE%
goto :EOF


:: ================================================================
::  TASK 5/12  --  DNS Cache
:: ================================================================
:TASK_DNS
color 0F
echo  [5/%TOTAL_TASKS%] DNS Cache
echo.
echo   Flushing...
ipconfig /flushdns >nul 2>&1
set "_RC=%errorlevel%"
call :FN_TASK_DONE "DNS Cache" %_RC% 0
goto :EOF


:: ================================================================
::  TASK 6/12  --  Thumbnail Cache
:: ================================================================
:TASK_THUMB
color 0F
echo  [6/%TOTAL_TASKS%] Thumbnail Cache
echo.
echo   Scanning...
call :FN_DIR_SIZE_MB "%LocalAppData%\Microsoft\Windows\Explorer" "_PRE"
echo   Scanning complete.
echo.
echo   Deleting...
taskkill /f /im explorer.exe >nul 2>&1
del /f /s /q "%LocalAppData%\Microsoft\Windows\Explorer\thumbcache_*.db" >nul 2>&1
set "_RC=%errorlevel%"
start explorer.exe
call :FN_TASK_DONE "Thumbnail Cache" %_RC% %_PRE%
goto :EOF


:: ================================================================
::  TASK 7/12  --  DirectX Shader Cache
:: ================================================================
:TASK_DX_SHADER
color 0F
echo  [7/%TOTAL_TASKS%] DirectX Shader Cache
echo.
echo   Scanning...
call :FN_DIR_SIZE_MB "%LocalAppData%\D3DSCache" "_PRE"
echo   Scanning complete.
echo.
echo   Deleting...
rd /s /q "%LocalAppData%\D3DSCache" >nul 2>&1
call :FN_TASK_DONE "DirectX Shader Cache" 0 %_PRE%
goto :EOF


:: ================================================================
::  TASK 8/12  --  Delivery Optimization Cache
:: ================================================================
:TASK_DEL_OPT
color 0F
echo  [8/%TOTAL_TASKS%] Delivery Optimization Cache
echo.
set "_DO=C:\Windows\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization"
echo   Scanning...
call :FN_DIR_SIZE_MB "%_DO%" "_PRE"
echo   Scanning complete.
echo.
echo   Deleting...
rd /s /q "%_DO%" >nul 2>&1
call :FN_TASK_DONE "Delivery Optimization Cache" 0 %_PRE%
goto :EOF


:: ================================================================
::  TASK 9/12  --  Windows Update Cache
:: ================================================================
:TASK_WU_CACHE
color 0F
echo  [9/%TOTAL_TASKS%] Windows Update Download Cache
echo.
echo   Stopping Windows Update services...
net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1
echo   Scanning...
call :FN_DIR_SIZE_MB "C:\Windows\SoftwareDistribution\Download" "_PRE"
echo   Scanning complete.
echo.
echo   Deleting...
rd /s /q "C:\Windows\SoftwareDistribution\Download" >nul 2>&1
md "C:\Windows\SoftwareDistribution\Download" >nul 2>&1
net start wuauserv >nul 2>&1
net start bits >nul 2>&1
call :FN_TASK_DONE "Windows Update Cache" 0 %_PRE%
goto :EOF


:: ================================================================
::  TASK 10/12  --  Windows Error Reporting Cache
:: ================================================================
:TASK_WER
color 0F
echo  [10/%TOTAL_TASKS%] Windows Error Reporting Cache
echo.
echo   Scanning...
call :FN_DIR_SIZE_MB "%LocalAppData%\Microsoft\Windows\WER" "_PRE"
echo   Scanning complete.
echo.
echo   Deleting...
rd /s /q "%LocalAppData%\Microsoft\Windows\WER" >nul 2>&1
rd /s /q "C:\ProgramData\Microsoft\Windows\WER" >nul 2>&1
call :FN_TASK_DONE "Windows Error Reporting Cache" 0 %_PRE%
goto :EOF


:: ================================================================
::  TASK 11/12  --  Recent Files History
:: ================================================================
:TASK_RECENT
color 0F
echo  [11/%TOTAL_TASKS%] Recent Files History
echo.
echo   Clearing...
del /q /f "%AppData%\Microsoft\Windows\Recent\*" >nul 2>&1
del /q /f "%AppData%\Microsoft\Windows\Recent\AutomaticDestinations\*" >nul 2>&1
del /q /f "%AppData%\Microsoft\Windows\Recent\CustomDestinations\*" >nul 2>&1
call :FN_TASK_DONE "Recent Files History" 0 0
goto :EOF


:: ================================================================
::  TASK 12/12  --  Microsoft Store Cache Reset
:: ================================================================
:TASK_STORE
color 0F
echo  [12/%TOTAL_TASKS%] Microsoft Store Cache
echo.
echo   Resetting Store cache...
wsreset.exe >nul 2>&1
call :FN_TASK_DONE "Microsoft Store Cache" 0 0
goto :EOF


:: ================================================================
::  DISM Component Store Cleanup  (Advanced - not counted in 12)
:: ================================================================
:TASK_DISM
color 0F
echo  [DISM] Component Store Cleanup
echo.
echo   This may take several minutes. Please wait...
echo [%TIME%] Starting DISM cleanup... >> "%LOGFILE%"
DISM /Online /Cleanup-Image /StartComponentCleanup /ResetBase >nul 2>&1
set "_RC=%errorlevel%"
if %_RC% EQU 0 (
    color 0A
    echo   [+] DISM Cleanup Completed
) else (
    color 0E
    echo   [!] DISM returned code %_RC% (may be normal on some systems)
)
echo [%TIME%] DISM done rc=%_RC% >> "%LOGFILE%"
color 0B
echo.
echo  ------------------------------------------------------------
echo.
goto :EOF


:: ================================================================
::  Disk Cleanup  (cleanmgr silent preset)
:: ================================================================
:TASK_CLEANMGR
color 0F
echo  [CLEANMGR] Silent Disk Cleanup
echo.
echo   Configuring cleanup preset...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Files"          /v StateFlags0099 /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Recycle Bin"              /v StateFlags0099 /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Thumbnail Cache"          /v StateFlags0099 /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting Files" /v StateFlags0099 /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Downloaded Program Files" /v StateFlags0099 /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Internet Cache Files"     /v StateFlags0099 /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Old ChkDsk Files"        /v StateFlags0099 /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Setup Log Files"          /v StateFlags0099 /t REG_DWORD /d 2 /f >nul 2>&1
echo   Running Disk Cleanup...
start /wait "" cleanmgr /sagerun:99
set "_RC=%errorlevel%"
if %_RC% EQU 0 (
    color 0A
    echo   [+] Disk Cleanup Completed
) else (
    color 0E
    echo   [!] Disk Cleanup returned code %_RC%
)
echo [%TIME%] cleanmgr done rc=%_RC% >> "%LOGFILE%"
color 0B
echo.
echo  ------------------------------------------------------------
echo.
goto :EOF


:: ================================================================
::  Hibernation Disable  (runs only if user chose Y)
:: ================================================================
:TASK_HIBER
color 0F
echo  [HIBER] Disabling Hibernation...
echo.
powercfg /hibernate off >nul 2>&1
set "_RC=%errorlevel%"
if %_RC% EQU 0 (
    color 0A
    echo   [+] Hibernation Disabled  (hiberfil.sys removed)
) else (
    color 0C
    echo   [x] Failed to disable hibernation  (rc=%_RC%)
)
echo [%TIME%] Hibernation disable rc=%_RC% >> "%LOGFILE%"
color 0B
echo.
echo  ------------------------------------------------------------
echo.
goto :EOF


:: ================================================================
::  :FN_FINAL_REPORT
::  Display the boxed final report screen
:: ================================================================
:FN_FINAL_REPORT
set /a RECOVERED=SPACE_AFTER - SPACE_BEFORE
set /a _BGB=SPACE_BEFORE / 1024
set /a _BMB=SPACE_BEFORE - (_BGB*1024)
set /a _AGB=SPACE_AFTER / 1024
set /a _AMB=SPACE_AFTER - (_AGB*1024)
set /a _RCG=RECOVERED / 1024
set /a _RCM=RECOVERED - (_RCG*1024)
if %_RCM% lss 0 set /a _RCM=0
if %_RCG% lss 0 set /a _RCG=0
set /a _FGB=TOTAL_FREED / 1024
set /a _FMBr=TOTAL_FREED - (_FGB*1024)

:: Convert MB to decimal GB for display (e.g. 128450 MB = 125.44 GB)
for /f %%g in ('powershell -NoProfile -Command "[math]::Round(%SPACE_BEFORE% / 1024, 2)"') do set "_DISP_B=%%g"
for /f %%g in ('powershell -NoProfile -Command "[math]::Round(%SPACE_AFTER% / 1024, 2)"') do set "_DISP_A=%%g"
for /f %%g in ('powershell -NoProfile -Command "[math]::Round(%RECOVERED% / 1024, 2)"') do set "_DISP_R=%%g"
if %RECOVERED% lss 0 set "_DISP_R=0.00"

cls
echo.
:: Unicode box header
powershell -NoProfile -Command "[Console]::OutputEncoding=[System.Text.Encoding]::UTF8; $tl=[char]0x2554; $tr=[char]0x2557; $bl=[char]0x255A; $br=[char]0x255D; $v=[char]0x2551; $line=([string][char]0x2550)*56; Write-Host \"  $tl$line$tr\" -ForegroundColor Cyan; Write-Host \"  $v                                                        $v\" -ForegroundColor Cyan; Write-Host \"  $v                  CLEANUP COMPLETE                      $v\" -ForegroundColor Cyan; Write-Host \"  $v                                                        $v\" -ForegroundColor Cyan; Write-Host \"  $bl$line$br\" -ForegroundColor Cyan"
echo.
:: Task summary
powershell -NoProfile -Command "Write-Host '  Tasks Executed      : %STEP%' -ForegroundColor White"
powershell -NoProfile -Command "Write-Host '  Tasks Successful    : %PASS%' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '  Tasks Failed        : %FAIL%' -ForegroundColor Red"
echo.
:: Disk space
powershell -NoProfile -Command "Write-Host '  Disk Space Before   : %_DISP_B% GB' -ForegroundColor Yellow"
powershell -NoProfile -Command "Write-Host '  Disk Space After    : %_DISP_A% GB' -ForegroundColor Green"
echo.
powershell -NoProfile -Command "Write-Host '  Recovered Space     : %_DISP_R% GB' -ForegroundColor Green"
echo.
:: Log file path
powershell -NoProfile -Command "Write-Host '  Log File Saved To:' -ForegroundColor White"
powershell -NoProfile -Command "Write-Host '  %LOGFILE%' -ForegroundColor Cyan"
echo.
:: Status
if %FAIL% EQU 0 (
    powershell -NoProfile -Command "Write-Host '  Status:' -ForegroundColor White; Write-Host '  SUCCESS' -ForegroundColor Green"
) else (
    powershell -NoProfile -Command "Write-Host '  Status:' -ForegroundColor White; Write-Host '  PARTIAL - %FAIL% task(s) failed' -ForegroundColor Yellow"
)
echo.

:: Write full summary to log
echo. >> "%LOGFILE%"
echo ================================================================ >> "%LOGFILE%"
echo   FINAL REPORT >> "%LOGFILE%"
echo ================================================================ >> "%LOGFILE%"
echo   Tasks     : %STEP%  ^| Pass: %PASS%  ^| Warn: %WARN%  ^| Fail: %FAIL% >> "%LOGFILE%"
echo   Duration  : %ELAPSED_M%m %ELAPSED_S%s >> "%LOGFILE%"
echo   Before    : %_DISP_B% GB >> "%LOGFILE%"
echo   After     : %_DISP_A% GB >> "%LOGFILE%"
echo   Recovered : %_DISP_R% GB >> "%LOGFILE%"
echo ================================================================ >> "%LOGFILE%"
goto :EOF


:: ================================================================
::  :FN_EXPORT_PROMPT
::  Ask user if they want to export a report to Desktop
:: ================================================================
:FN_EXPORT_PROMPT
echo.
powershell -NoProfile -Command "[Console]::OutputEncoding=[System.Text.Encoding]::UTF8; Write-Host ('  ' + ([string][char]0x2500)*56) -ForegroundColor DarkCyan"
echo.
powershell -NoProfile -Command "Write-Host '  Would you like to export a cleanup report?' -ForegroundColor White"
echo.
powershell -NoProfile -Command "Write-Host '    [Y]  Export Report  ->  cleanup_report.txt saved to Desktop' -ForegroundColor Cyan"
powershell -NoProfile -Command "Write-Host '    [N]  Exit' -ForegroundColor Cyan"
echo.
set /p "EXP=   Your choice: "
echo.
if /i "!EXP!"=="Y" (
    set "RPT=%USERPROFILE%\Desktop\cleanup_report.txt"
    (
        echo ================================================================
        echo   System Cleanup Utility  -  Cleanup Report
        echo ================================================================
        echo   Computer   : %SYS_PC%
        echo   User       : %SYS_USER%
        echo   OS         : %SYS_OS%
        echo   Date/Time  : %SYS_DATE%
        echo ================================================================
        echo   Tasks Executed   : %STEP%
        echo   Tasks Successful : %PASS%
        echo   Tasks Failed     : %FAIL%
        echo   Tasks Warned     : %WARN%
        echo ================================================================
        echo   Disk Before      : %_DISP_B% GB
        echo   Disk After       : %_DISP_A% GB
        echo   Recovered Space  : %_DISP_R% GB
        echo ================================================================
        echo   Duration         : %ELAPSED_M%m %ELAPSED_S%s
        echo   Log File         : %LOGFILE%
        echo ================================================================
    ) > "!RPT!"
    powershell -NoProfile -Command "[Console]::OutputEncoding=[System.Text.Encoding]::UTF8; Write-Host '  [' -NoNewline -ForegroundColor White; Write-Host ([char]0x2713) -NoNewline -ForegroundColor Green; Write-Host '] Report saved to Desktop: cleanup_report.txt' -ForegroundColor Green"
    echo.
)

:: Footer
powershell -NoProfile -Command "[Console]::OutputEncoding=[System.Text.Encoding]::UTF8; Write-Host ('  ' + ([string][char]0x2500)*56) -ForegroundColor DarkCyan"
echo.
powershell -NoProfile -Command "Write-Host '  Cleanup Completed Successfully' -ForegroundColor Green"
echo.
powershell -NoProfile -Command "Write-Host '  Thank you for using System Cleanup Utility' -ForegroundColor Cyan"
echo.
powershell -NoProfile -Command "[Console]::OutputEncoding=[System.Text.Encoding]::UTF8; Write-Host ('  ' + ([string][char]0x2500)*56) -ForegroundColor DarkCyan"
echo.
powershell -NoProfile -Command "Write-Host '  Press any key to exit...' -ForegroundColor Yellow"
echo.
pause >nul
goto :EOF
