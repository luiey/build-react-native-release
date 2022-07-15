@echo off
:: BatchGotAdmin
:-------------------------------------
REM  --> Check for permissions
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

REM --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params = %*:"=""
    echo UAC.ShellExecute "cmd.exe", "/c %~s0 %params%", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"
:--------------------------------------
if not defined in_subprocess (cmd /k set in_subprocess=y ^& %0 %*) & exit )
set driveName="%CD:~0,2%"
set currentFolder="%~dp0"
setlocal enableextensions enabledelayedexpansion
set /A count=1
set list=
CD %driveName%

echo ===========================================
for /d %%D in (*) do (
	set "listName=%%~f"
	set list=%listName%%1
	rem echo !listName! !
	echo !count!^. %%~D
	set /a count+=1
)
echo ===========================================
:startAgain
set choice=
set /p choice=Type in target folder from listing to build release APK (e.g. targetfolder): 
if not '%choice%'=='' (
	if exist %choice% (
		set choice=%choice%
		CD %choice%
		goto performbuild
	)
)
echo Invalid directory name!
goto startAgain

:performbuild
echo Script will start build target APK to release on %choice%...
cd android
call gradlew clean
timeout /t 2 /nobreak>nul
cd..
if exist ..\android\app\src\main\assets\index.android.bundle del /s /q ..\android\app\src\main\assets\index.android.bundle 2>nul
call npx jetify
timeout /t 1 /nobreak>nul
call react-native bundle --platform android --dev false --entry-file index.js --bundle-output android/app/src/main/assets/index.android.bundle
timeout /t 5 /nobreak>nul
if exist ..\android\app\src\main\res\drawable-hdpi del /s /q ..\android\app\src\main\res\drawable-hdpi 2>nul
if exist ..\android\app\src\main\res\drawable-mdpi del /s /q ..\android\app\src\main\res\drawable-mdpi 2>nul
if exist ..\android\app\src\main\res\drawable-xhdpi del /s /q ..\android\app\src\main\res\drawable-xhdpi 2>nul
if exist ..\android\app\src\main\res\drawable-xxhdpi del /s /q ..\android\app\src\main\res\drawable-xxhdpi 2>nul
if exist ..\android\app\src\main\res\drawable-xxxhdpi del /s /q ..\android\app\src\main\res\drawable-xxxhdpi 2>nul
if exist ..\android\app\src\main\res\raw del /s /q ..\android\app\src\main\res\raw 2>nul
timeout /t 2 /nobreak>nul
goto startbuilding

:startbuilding
ECHO.
ECHO 1. Build platform android bundle
ECHO 2. Build bundle release
ECHO 3. Build APK release
set choice=
set /p choice=Select build type(Enter number):
if not '%choice%'=='' set choice=%choice:~0,1%
if '%choice%'=='1' goto performbuild
if '%choice%'=='2' goto buildbundle
if '%choice%'=='3' goto buildapk
ECHO "%choice%" is not valid, try again
ECHO.
goto startbuilding

:buildbundle
cd android
call gradlew bundleRelease
timeout /t 5 /nobreak>nul
if exist ..\android\app\build\outputs\bundle\release start "" ..\android\app\build\outputs\bundle\release
goto proceed

:buildapk
cd android
call gradlew assembleRelease
timeout /t 5 /nobreak>nul
if exist ..\android\app\build\outputs\apk\release start "" ..\android\app\build\outputs\apk\release
goto proceed

:proceed
cd %currentFolder%%choice%
:choiceOpt
ECHO.
ECHO 1. Rebuild platform android bundle again
ECHO 2. Rebuild AAB or APK again
ECHO 3. Exit
set choice=
set /p choice=Select build type(Enter number):
if not '%choice%'=='' set choice=%choice:~0,1%
if '%choice%'=='1' goto performbuild
if '%choice%'=='2' goto startbuilding
if '%choice%'=='3' goto justexit
ECHO "%choice%" is not valid, try again
ECHO.
goto choiceOpt
REM set /P answ=Build complete. Do you want to rebuild again[Y/N]?
REM if /I "%answ%" EQU "Y" goto :performbuild
REM if /I "%answ%" EQU "N" goto :justexit
REM goto :choiceOpt

:justexit
echo Exiting
timeout /t 2 /nobreak>nul
exit
