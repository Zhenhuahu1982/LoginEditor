@echo off
setlocal
pushd "%~dp0"
set "DELPHI_BIN=C:\Program Files (x86)\Embarcadero\Studio\21.0\bin"

if not exist "..\..\Release\Login" mkdir "..\..\Release\Login"
if not exist "..\..\Release\LoginEditor" mkdir "..\..\Release\LoginEditor"

"%DELPHI_BIN%\DCC32.EXE" -E"..\..\Release\Login" GameLogin.dpr || goto :error
"%DELPHI_BIN%\BRCC32.EXE" LoginBootstrapResource.rc || goto :error
"%DELPHI_BIN%\BRCC32.EXE" ClientResource.rc || goto :error
"%DELPHI_BIN%\DCC32.EXE" -E"..\..\Release\LoginEditor" LoginEditor.dpr || goto :error
pause
echo Build completed.
popd
exit /b 0

:error
echo Build failed.
popd
exit /b 1
