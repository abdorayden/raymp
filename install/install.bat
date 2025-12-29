@echo off
setlocal enabledelayedexpansion

REM /************************************************************************************/
REM /*  Copyright (c) 2025 Ray Den 							*/
REM /*  										*/ 
REM /*  Permission is hereby granted, free of charge, to any person obtaining a copy 	*/
REM /*  of this software and associated documentation files (the "Software"), to deal 	*/
REM /*  in the Software without restriction, including without limitation the rights 	*/
REM /*  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 	*/
REM /*  copies of the Software, and to permit persons to whom the Software is 		*/
REM /*  furnished to do so, subject to the following conditions: 			*/
REM /*  										*/ 
REM /*  The above copyright notice and this permission notice shall be included in 	*/
REM /*  all copies or substantial portions of the Software. 				*/
REM /*  										*/ 
REM /*  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 	*/
REM /*  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 	*/
REM /*  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 	*/
REM /*  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 		*/
REM /*  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 	*/
REM /*  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN 	*/
REM /*  THE SOFTWARE. 									*/
REM /*  										*/ 
REM /************************************************************************************/

set INIT_PATH=%USERPROFILE%\.rmp\init.lua
set INCLUDE_PATH=-I..\src\engine\lua\include -I..\src\third_party\
set LUA_LIB_PATH=..\src\engine\lua\lib
set CC=gcc

set FLAGS=-shared -s -Wall -static

:: Check if no command was provided or if help is requested
if "%~1"=="" goto help
if "%~1"=="/?" goto help
if "%~1"=="-h" goto help
if "%~1"=="--help" goto help
if "%~1"=="help" goto help

:: Check for admin privileges for install/clean
if "%~1"=="install" goto check_admin
if "%~1"=="clean" goto check_admin
goto :skip_admin_check

:check_admin
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: This script must be run as administrator
    echo Try: Run as Administrator
    goto help
)

:skip_admin_check

:: Set Lua directories for Windows
set LUA_SHARE=%ProgramFiles%\Lua\5.4\rmp
set LUA_LIB=%ProgramFiles%\Lua\5.4\rmp

:: Create directories if they don't exist
if not exist "%LUA_SHARE%" mkdir "%LUA_SHARE%"
if not exist "%LUA_LIB%" mkdir "%LUA_LIB%"

if "%~1"=="clean" (
    echo [+] Cleaning...
    if "%~2"=="-v" echo on
    del "%LUA_LIB%\rmpaudio.dll" 2>nul
    del "%LUA_LIB%\keyboard.dll" 2>nul
    del "%LUA_LIB%\rsocket.dll" 2>nul
    del "%LUA_LIB%\sleep.dll" 2>nul
    del "%LUA_LIB%\directory.dll" 2>nul
    del "%LUA_LIB%\window.dll" 2>nul

    del "%LUA_SHARE%\rmp.lua" 2>nul
    del "%LUA_SHARE%\promises.lua" 2>nul
    del "%LUA_SHARE%\future.lua" 2>nul
    del "%LUA_SHARE%\util.lua" 2>nul
    del "%LUA_SHARE%\oop.lua" 2>nul

    echo Clean completed.
    goto :eof
)

if "%~1"=="compile" (
    echo [+] Compiling...
    if "%~2"=="-v" echo on

    :: Check which Lua library to use
    if exist "%LUA_LIB_PATH%\lua54.a" (
        set LIB_FILE=-L%LUA_LIB_PATH% -l:lua54.a
    ) else if exist "%LUA_LIB_PATH%\liblua.a" (
        set LIB_FILE=-L%LUA_LIB_PATH% -l:liblua.a
    ) else if exist "%LUA_LIB_PATH%\lua54.dll" (
        set LIB_FILE=-L%LUA_LIB_PATH% -l:lua54.dll
    ) else (
        echo ERROR: No Lua library found in %LUA_LIB_PATH%
        goto :eof
    )

    %CC% %FLAGS% -o ..\src\engine\core\lib\rmpaudio.dll ..\src\engine\core\src\rmpaudio.c %INCLUDE_PATH% %LIB_FILE% -lwinmm
    %CC% %FLAGS% -o ..\src\engine\core\lib\virtualterminalrmp.dll ..\src\engine\core\src\virtualterminalrmp.c %INCLUDE_PATH% %LIB_FILE%
    %CC% %FLAGS% -o ..\src\engine\core\lib\keyboard.dll ..\src\engine\core\src\keyboard.c %INCLUDE_PATH% %LIB_FILE% -luser32
    %CC% %FLAGS% -o ..\src\engine\core\lib\sleep.dll ..\src\engine\core\src\sleep.c %INCLUDE_PATH% %LIB_FILE%
    %CC% %FLAGS% -o ..\src\engine\core\lib\platform.dll ..\src\engine\core\src\platform.c %INCLUDE_PATH% %LIB_FILE%
    %CC% %FLAGS% -o ..\src\engine\core\lib\directory.dll ..\src\engine\core\src\directory.c %INCLUDE_PATH% %LIB_FILE%
    %CC% %FLAGS% -o ..\src\engine\core\lib\window.dll ..\src\engine\core\src\window.c %INCLUDE_PATH% %LIB_FILE% -lgdi32 -luser32
    %CC% %FLAGS% -o ..\src\engine\core\lib\rsocket.dll ..\src\engine\core\src\rsocket.c %INCLUDE_PATH% %LIB_FILE% -lws2_32

    echo Compile completed.
    goto :eof
)

if "%~1"=="install" (
    echo [+] Installing...
    if "%~2"=="-v" echo on

    :: Copy Lua DLL to system path if it exists
    if exist "%LUA_LIB_PATH%\lua54.dll" (
        copy "%LUA_LIB_PATH%\lua54.dll" "%SystemRoot%\system32\" >nul 2>&1
        if errorlevel 1 (
            echo Note: Could not copy lua54.dll to system32. You may need to add it to PATH.
        ) else (
            echo Copied lua54.dll to system32.
        )
    )

    copy "..\src\engine\core\lib\rmpaudio.dll" "%LUA_LIB%"
    copy "..\src\engine\core\lib\keyboard.dll" "%LUA_LIB%"
    copy "..\src\engine\core\lib\sleep.dll" "%LUA_LIB%"
    copy "..\src\engine\core\lib\platform.dll" "%LUA_LIB%"
    copy "..\src\engine\core\lib\directory.dll" "%LUA_LIB%"
    copy "..\src\engine\core\lib\window.dll" "%LUA_LIB%"
    copy "..\src\engine\core\lib\rsocket.dll" "%LUA_LIB%"
    copy "..\src\engine\core\lib\virtualterminalrmp.dll" "%LUA_LIB%"

    xcopy "..\src\engine\selfrmp" "%LUA_SHARE%\selfrmp" /E /I /Y

    copy "..\src\promises.lua" "%LUA_SHARE%"
    copy "..\src\future.lua" "%LUA_SHARE%"
    copy "..\src\util.lua" "%LUA_SHARE%"
    copy "..\src\oop.lua" "%LUA_SHARE%"
    copy "..\src\engine\RMPManager.lua" "%LUA_SHARE%"
    copy "..\src\engine\core\rmp.lua" "%LUA_SHARE%"

    echo Install completed.
    echo.
    echo IMPORTANT: Make sure lua54.dll is in your PATH or in the same directory as your application.
    goto :eof
)

if "%~1"=="install-conf" (
    echo [+] Installing configuration...
    if "%~2"=="-v" echo on
    if not exist "%USERPROFILE%\.rmp" (
        mkdir "%USERPROFILE%\.rmp"
        mkdir "%USERPROFILE%\.rmp\themes"
        mkdir "%USERPROFILE%\.rmp\plugins"

        copy "..\src\engine\selfrmp\init.lua" "%USERPROFILE%\.rmp"
        copy "..\src\engine\selfrmp\themes\tutorial.lua" "%USERPROFILE%\.rmp\themes"
        xcopy "..\src\engine\selfrmp\plugins\tutorial_rmp" "%USERPROFILE%\.rmp\plugins\tutorial_rmp" /E /I /Y
        xcopy "..\src\engine\selfrmp\plugins\helper_keys_tutorial" "%USERPROFILE%\.rmp\plugins\helper_keys_tutorial" /E /I /Y
        copy "..\src\engine\selfrmp\plugins\digital_clock_with_effects.lua" "%USERPROFILE%\.rmp\plugins"
    )
    echo Install configuration completed.
    goto :eof
)

if "%~1"=="clean-conf" (
    echo [+] Removing configuration...
    if "%~2"=="-v" echo on
    if exist "%USERPROFILE%\.rmp" rmdir /s /q "%USERPROFILE%\.rmp"
    echo Remove configuration completed.
    goto :eof
)

:help
echo HELP:
echo Usage: %0 [command]
echo.
echo Commands:
echo   clean       : remove all installed shared libraries and lua files from system directories
echo   clean-conf   : remove the default configurations and plugins in home directory be careful if your configurations are there it will be deleted
echo   compile     : compile .c files to shared libraries
echo   install     : install .dll and .lua files to system directories
echo   install-conf : install the default configurations and plugins for tutorial to learn how to work with raymp
echo   -v          : verbose flag
echo.
echo NOTE:
echo   install and clean commands may require administrator privileges
echo.
goto :eof

echo [-] Unknown command: %~1
goto help
