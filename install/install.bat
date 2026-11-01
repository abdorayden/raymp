@echo off
setlocal

REM Build RMP with the MinGW-w64 toolchain. Run this file from any directory.
pushd "%~dp0" >nul
if errorlevel 1 (
    echo ERROR: Could not enter the install directory.
    exit /b 1
)

set "ROOT=.."
set "LUA_SRC=..\src\engine\lua\lua-5.4.4\src"
set "LUA_INCLUDE=..\src\engine\lua\include"
set "THIRD_PARTY=..\src\third_party"
set "CORE_SRC=..\src\engine\core\src"
set "CORE_LIB=..\src\engine\core\lib"
set "APP_LUA=..\lua\rmp"
set "APP_LIB=..\rmp"

if "%~1"=="" goto help
if /I "%~1"=="help" goto help
if /I "%~1"=="-h" goto help
if /I "%~1"=="--help" goto help
if /I "%~1"=="/?" goto help

if /I "%~1"=="compile" goto compile
if /I "%~1"=="install" goto install
if /I "%~1"=="clean" goto clean
if /I "%~1"=="install-conf" goto install_conf
if /I "%~1"=="clean-conf" goto clean_conf
echo ERROR: Unknown command "%~1".
goto help

:compile
where gcc >nul 2>&1
if errorlevel 1 (
    echo ERROR: gcc was not found. Install MinGW-w64 and add it to PATH.
    set "RESULT=1"
    goto finish
)
where ar >nul 2>&1
if errorlevel 1 (
    echo ERROR: ar was not found. Install the MinGW-w64 binutils package.
    set "RESULT=1"
    goto finish
)

set "BUILD_DIR=%TEMP%\raymp-mingw-%RANDOM%-%RANDOM%"
mkdir "%BUILD_DIR%" >nul 2>&1
if errorlevel 1 (
    echo ERROR: Could not create temporary build directory "%BUILD_DIR%".
    set "RESULT=1"
    goto finish
)

echo [+] Building Windows Lua runtime and RMP modules...
for %%F in (lapi lcode lctype ldebug ldo ldump lfunc lgc llex lmem lobject lopcodes lparser lstate lstring ltable ltm lundump lvm lzio lauxlib lbaselib lcorolib ldblib liolib lmathlib loadlib loslib lstrlib ltablib lutf8lib linit) do (
    gcc -O2 -Wall -DLUA_COMPAT_5_3 -I"%LUA_SRC%" -I"%LUA_INCLUDE%" -c "%LUA_SRC%\%%F.c" -o "%BUILD_DIR%\%%F.o"
    if errorlevel 1 goto compile_failed
)

for %%F in (lapi lcode lctype ldebug ldo ldump lfunc lgc llex lmem lobject lopcodes lparser lstate lstring ltable ltm lundump lvm lzio lauxlib lbaselib lcorolib ldblib liolib lmathlib loadlib loslib lstrlib ltablib lutf8lib linit) do (
    ar rcs "%BUILD_DIR%\liblua.a" "%BUILD_DIR%\%%F.o"
    if errorlevel 1 goto compile_failed
)

gcc -shared -s -static -Wall -Wl,--export-all-symbols -I"%LUA_INCLUDE%" -I"%THIRD_PARTY%" -o "%BUILD_DIR%\rmpaudio.dll" "%CORE_SRC%\rmpaudio.c" "%BUILD_DIR%\liblua.a" -lwinmm -lm
if errorlevel 1 goto compile_failed
gcc -shared -s -static -Wall -Wl,--export-all-symbols -I"%LUA_INCLUDE%" -I"%THIRD_PARTY%" -o "%BUILD_DIR%\virtualterminalrmp.dll" "%CORE_SRC%\virtualterminalrmp.c" "%BUILD_DIR%\liblua.a" -lm
if errorlevel 1 goto compile_failed
gcc -shared -s -static -Wall -Wl,--export-all-symbols -I"%LUA_INCLUDE%" -I"%THIRD_PARTY%" -o "%BUILD_DIR%\keyboard.dll" "%CORE_SRC%\keyboard.c" "%BUILD_DIR%\liblua.a" -luser32 -lm
if errorlevel 1 goto compile_failed
gcc -shared -s -static -Wall -Wl,--export-all-symbols -I"%LUA_INCLUDE%" -I"%THIRD_PARTY%" -o "%BUILD_DIR%\sleep.dll" "%CORE_SRC%\sleep.c" "%BUILD_DIR%\liblua.a" -lm
if errorlevel 1 goto compile_failed
gcc -shared -s -static -Wall -Wl,--export-all-symbols -I"%LUA_INCLUDE%" -I"%THIRD_PARTY%" -o "%BUILD_DIR%\platform.dll" "%CORE_SRC%\platform.c" "%BUILD_DIR%\liblua.a" -lm
if errorlevel 1 goto compile_failed
gcc -shared -s -static -Wall -Wl,--export-all-symbols -I"%LUA_INCLUDE%" -I"%THIRD_PARTY%" -o "%BUILD_DIR%\directory.dll" "%CORE_SRC%\directory.c" "%BUILD_DIR%\liblua.a" -lm
if errorlevel 1 goto compile_failed
gcc -shared -s -static -Wall -Wl,--export-all-symbols -I"%LUA_INCLUDE%" -I"%THIRD_PARTY%" -o "%BUILD_DIR%\window.dll" "%CORE_SRC%\window.c" "%BUILD_DIR%\liblua.a" -lgdi32 -luser32 -lm
if errorlevel 1 goto compile_failed
gcc -shared -s -static -Wall -Wl,--export-all-symbols -I"%LUA_INCLUDE%" -I"%THIRD_PARTY%" -o "%BUILD_DIR%\rsocket.dll" "%CORE_SRC%\rsocket.c" "%BUILD_DIR%\liblua.a" -lws2_32 -lm
if errorlevel 1 goto compile_failed

gcc -s -static -Wall -Wextra -I"%LUA_INCLUDE%" -o "%BUILD_DIR%\rmp.exe" "%ROOT%\main.c" "%BUILD_DIR%\liblua.a" -lm
if errorlevel 1 goto compile_failed

if not exist "%CORE_LIB%" mkdir "%CORE_LIB%"
for %%F in (rmpaudio virtualterminalrmp keyboard sleep platform directory window rsocket) do (
    move /Y "%BUILD_DIR%\%%F.dll" "%CORE_LIB%\%%F.dll" >nul
    if errorlevel 1 goto compile_failed
)
move /Y "%BUILD_DIR%\rmp.exe" "%ROOT%\rmp.exe" >nul
if errorlevel 1 goto compile_failed

rmdir /s /q "%BUILD_DIR%" >nul 2>&1
echo Compile completed. Run "rmp.exe" from the repository root after install.
echo NOTE: UV async bindings are unavailable: this checkout contains no libuv source or Windows library.
set "RESULT=0"
goto finish

:compile_failed
echo ERROR: Windows compilation failed. No installation was performed.
rmdir /s /q "%BUILD_DIR%" >nul 2>&1
set "RESULT=1"
goto finish

:install
if not exist "%ROOT%\rmp.exe" (
    echo ERROR: rmp.exe was not built. Run "install.bat compile" first.
    set "RESULT=1"
    goto finish
)
for %%F in (rmpaudio virtualterminalrmp keyboard sleep platform directory window rsocket) do if not exist "%CORE_LIB%\%%F.dll" (
    echo ERROR: Missing "%CORE_LIB%\%%F.dll". Run "install.bat compile" first.
    set "RESULT=1"
    goto finish
)

if not exist "%APP_LUA%" mkdir "%APP_LUA%"
if not exist "%APP_LIB%" mkdir "%APP_LIB%"
if not exist "%APP_LUA%" (
    echo ERROR: Could not create the local RMP runtime directories.
    set "RESULT=1"
    goto finish
)
if not exist "%APP_LIB%" (
    echo ERROR: Could not create the local RMP runtime directories.
    set "RESULT=1"
    goto finish
)

copy /Y "%ROOT%\src\promises.lua" "%APP_LUA%\promises.lua" >nul
if errorlevel 1 goto install_failed
copy /Y "%ROOT%\src\future.lua" "%APP_LUA%\future.lua" >nul
if errorlevel 1 goto install_failed
copy /Y "%ROOT%\src\util.lua" "%APP_LUA%\util.lua" >nul
if errorlevel 1 goto install_failed
copy /Y "%ROOT%\src\oop.lua" "%APP_LUA%\oop.lua" >nul
if errorlevel 1 goto install_failed
copy /Y "%ROOT%\src\engine\RMPManager.lua" "%APP_LUA%\RMPManager.lua" >nul
if errorlevel 1 goto install_failed
copy /Y "%ROOT%\src\engine\core\rmp.lua" "%APP_LUA%\rmp.lua" >nul
if errorlevel 1 goto install_failed
xcopy "%ROOT%\src\engine\builtin" "%APP_LUA%\builtin" /E /I /Y >nul
if errorlevel 1 goto install_failed

for %%F in (rmpaudio virtualterminalrmp keyboard sleep platform directory window rsocket) do (
    copy /Y "%CORE_LIB%\%%F.dll" "%APP_LIB%\%%F.dll" >nul
    if errorlevel 1 goto install_failed
)

echo Install completed. Run "..\rmp.exe" from the repository root.
echo Lua files: ..\lua\rmp   Native modules: ..\rmp
set "RESULT=0"
goto finish

:install_failed
echo ERROR: Installation failed while copying runtime files.
set "RESULT=1"
goto finish

:clean
for %%F in (rmpaudio virtualterminalrmp keyboard sleep platform directory window rsocket) do if exist "%APP_LIB%\%%F.dll" del /Q "%APP_LIB%\%%F.dll"
if exist "%ROOT%\rmp.exe" del /Q "%ROOT%\rmp.exe"
if exist "%APP_LUA%" rmdir /s /q "%APP_LUA%"
echo Clean completed for the local Windows runtime.
set "RESULT=0"
goto finish

:install_conf
if not exist "%USERPROFILE%\.rmp" mkdir "%USERPROFILE%\.rmp"
if not exist "%USERPROFILE%\.rmp\plugins" mkdir "%USERPROFILE%\.rmp\plugins"
if not exist "%USERPROFILE%\.rmp\init.lua" (
    copy /Y "%ROOT%\src\engine\builtin\init.lua" "%USERPROFILE%\.rmp\init.lua" >nul
    if errorlevel 1 (
        echo ERROR: Could not install the default user configuration.
        set "RESULT=1"
        goto finish
    )
)
if not exist "%USERPROFILE%\.rmp\plugins\tutorial_rmp" (
    xcopy "%ROOT%\src\engine\builtin\plugins\tutorial_rmp" "%USERPROFILE%\.rmp\plugins\tutorial_rmp" /E /I /Y >nul
    if errorlevel 1 (
        echo ERROR: Could not install the tutorial plugin.
        set "RESULT=1"
        goto finish
    )
)
echo Configuration installed in "%USERPROFILE%\.rmp".
set "RESULT=0"
goto finish

:clean_conf
if exist "%USERPROFILE%\.rmp" rmdir /s /q "%USERPROFILE%\.rmp"
echo User configuration removed.
set "RESULT=0"
goto finish

:help
echo Usage: install.bat [compile^|install^|clean^|install-conf^|clean-conf]
echo.
echo   compile      Build rmp.exe and the Windows native module DLLs with MinGW-w64.
echo   install      Copy runtime files beside rmp.exe for Lua's Windows search paths.
echo   clean        Remove the locally installed runtime and rmp.exe.
echo   install-conf Install the builtin defaults and tutorial plugin under %%USERPROFILE%%\.rmp.
echo   clean-conf   Remove %%USERPROFILE%%\.rmp.
set "RESULT=0"
goto finish

:finish
popd >nul
endlocal & exit /b %RESULT%
