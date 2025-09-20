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

set INIT_PATH=%USERPROFILE%\.rmp\.init.lua
set INCLUDE_PATH=-I../src/engine/lua/include
set LIB_PATH=../src/engine/lua/lib/liblua54.a
set CC=gcc.exe

set FLAGS=-shared -s -Wall

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
	del "%LUA_LIB%\sleep.dll" 2>nul
	del "%LUA_LIB%\directory.dll" 2>nul
	del "%LUA_LIB%\window.dll" 2>nul
	del "%LUA_LIB%\platform.dll" 2>nul
	del "%LUA_LIB%\virtualterminalrmp.dll" 2>nul

	del "%LUA_SHARE%\rmp.lua" 2>nul
	del "%LUA_SHARE%\promises.lua" 2>nul
	del "%LUA_SHARE%\util.lua" 2>nul
	del "%LUA_SHARE%\oop.lua" 2>nul

	echo Clean completed.
	goto :eof
)

if "%~1"=="compile" (
	echo [+] Compiling...
	if "%~2"=="-v" echo on

	%CC% %FLAGS% -o ../src/engine/core/lib/rmpaudio.dll ../src/engine/core/src/rmpaudio.c %INCLUDE_PATH% %LIB_PATH% -lwinmm
	%CC% %FLAGS% -o ../src/engine/core/lib/virtualterminalrmp.dll ../src/engine/core/src/virtualterminalrmp.c %INCLUDE_PATH% %LIB_PATH%
	%CC% %FLAGS% -o ../src/engine/core/lib/keyboard.dll ../src/engine/core/src/keyboard.c %INCLUDE_PATH% %LIB_PATH% -luser32
	%CC% %FLAGS% -o ../src/engine/core/lib/sleep.dll ../src/engine/core/src/sleep.c %INCLUDE_PATH% %LIB_PATH%
	%CC% %FLAGS% -o ../src/engine/core/lib/platform.dll ../src/engine/core/src/platform.c %INCLUDE_PATH% %LIB_PATH%
	%CC% %FLAGS% -o ../src/engine/core/lib/directory.dll ../src/engine/core/src/directory.c %INCLUDE_PATH% %LIB_PATH%
	%CC% %FLAGS% -o ../src/engine/core/lib/window.dll ../src/engine/core/src/window.c %INCLUDE_PATH% %LIB_PATH% -lgdi32 -luser32

	%CC% -s -Wall -o ../rmp.exe ../main.c ../src/engine/runner.c %INCLUDE_PATH% -I../src/engine %LIB_PATH%

	echo Compile completed.
	goto :eof
)

if "%~1"=="install" (
	echo [+] Installing...
	if "%~2"=="-v" echo on

	copy "..\src\engine\core\lib\rmpaudio.dll" "%LUA_LIB%"
	copy "..\src\engine\core\lib\keyboard.dll" "%LUA_LIB%"
	copy "..\src\engine\core\lib\sleep.dll" "%LUA_LIB%"
	copy "..\src\engine\core\lib\platform.dll" "%LUA_LIB%"
	copy "..\src\engine\core\lib\directory.dll" "%LUA_LIB%"
	copy "..\src\engine\core\lib\window.dll" "%LUA_LIB%"
	copy "..\src\engine\core\lib\virtualterminalrmp.dll" "%LUA_LIB%"

	if not exist "%LUA_SHARE%\selfrmp" mkdir "%LUA_SHARE%\selfrmp"
	xcopy "..\src\engine\selfrmp" "%LUA_SHARE%\selfrmp" /E /I /Y

	copy "..\src\promises.lua" "%LUA_SHARE%"
	copy "..\src\util.lua" "%LUA_SHARE%"
	copy "..\src\oop.lua" "%LUA_SHARE%"
	copy "..\src\engine\core\rmp.lua" "%LUA_SHARE%"

	REM :: Create user config directory if it doesn't exist
	REM if not exist "%USERPROFILE%\.rmp" (
	REM     mkdir "%USERPROFILE%\.rmp"
	REM     mkdir "%USERPROFILE%\.rmp\themes"
	REM     mkdir "%USERPROFILE%\.rmp\plugins"

	REM     (
	REM         echo return {
	REM         echo     sound_cfg = {
	REM         echo         pause = api.KEY_SPACE,
	REM         echo         resume = api.KEY_SPACE,
	REM         echo         next = api.KEY_N,
	REM         echo         prev = api.KEY_P,
	REM         echo         vol_up = api.KEY_PLUS,
	REM         echo         vol_down = api.KEY_MINUS,
	REM         echo         seek_left = api.KEY_LEFT,
	REM         echo         seek_right = api.KEY_RIGHT,
	REM         echo         speed_up = api.KEY_UP,
	REM         echo         speed_down = api.KEY_DOWN,
	REM         echo     },
	REM         echo     theme = "theme path",
	REM         echo     plugins = {
	REM         echo     },
	REM         echo }
	REM     ) > "%INIT_PATH%"
	REM )

	echo Install completed.
	goto :eof
)

:help
echo HELP:
echo Usage: %0 [command]
echo.
echo Commands:
echo   clean    : remove all installed DLLs and lua files from system directories
echo   compile  : compile .c files to DLLs
echo   install  : install DLLs and .lua files to system directories
echo   -v       : verbose flag (for install and clean)
echo.
echo NOTE:
echo   install and clean commands may require administrator privileges
echo.
goto :eof

echo [-] Unknown command: %~1
goto help
