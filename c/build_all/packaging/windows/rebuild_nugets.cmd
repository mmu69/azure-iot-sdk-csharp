@REM Copyright (c) Microsoft. All rights reserved.
@REM Licensed under the MIT license. See LICENSE file in the project root for full license information.

@setlocal EnableExtensions EnableDelayedExpansion
@echo off

rem - Specify the Azure SDK client build root
set current-path=%~dp0
set current-path=%current-path:~0,-1%
set client-root=%current-path%\..\..\..\..
for %%i in ("%client-root%") do set client-root=%%~fi
echo Client root is %client-root%

pushd %client-root%\c\build_all\packaging\windows\

where /q nuget.exe
if not !errorlevel! == 0 (
@Echo Azure IoT SDK needs to download nuget.exe from https://www.nuget.org/nuget.exe 
@Echo https://www.nuget.org 
choice /C yn /M "Do you want to download and run nuget.exe?" 
if not !errorlevel!==1 goto :eof
rem if nuget.exe is not found, then ask user
Powershell.exe wget -outf nuget.exe https://nuget.org/nuget.exe
	if not exist .\nuget.exe (
		echo nuget does not exist
		exit /b 1
	)
)

del *.nupkg

rem -- Copy all the files from cmake build directory to the repo directory
xcopy /q /y /R %USERPROFILE%\cmake\iothub_client\Debug\*.* %client-root%\build_output\c\win32\debug\*.*
if %errorlevel% neq 0 exit /b %errorlevel%

xcopy /q /y /R %USERPROFILE%\cmake\common\Debug\*.* %client-root%\build_output\c\win32\debug\*.*
if %errorlevel% neq 0 exit /b %errorlevel%

xcopy /q /y /R %USERPROFILE%\cmake\serializer\Debug\*.* %client-root%\build_output\c\win32\debug\*.*
if %errorlevel% neq 0 exit /b %errorlevel%

nuget pack Microsoft.Azure.IoTHub.HttpTransport.nuspec
nuget pack Microsoft.Azure.IoTHub.AmqpTransport.nuspec
nuget pack Microsoft.Azure.IoTHub.IoTHubClient.nuspec
nuget pack Microsoft.Azure.IoTHub.Common.nuspec

rem because nuget cannot access absolute files given by environment variables
mkdir paho_outputs
cd paho_outputs
mkdir Win32
cd Win32
rem: for when build_paho will build release: mkdir Release
mkdir Debug
cd ..

rem when build_paho will build x64
rem mkdir x64
rem cd x64
rem mkdir Release
rem mkdir Debug
rem cd ..
cd ..

copy "%PAHO_PATH%\org.eclipse.paho.mqtt.c\Windows Build\paho-mqtt3cs\Debug\paho-mqtt3cs.lib" paho_outputs\Win32\Debug
copy "%PAHO_PATH%\org.eclipse.paho.mqtt.c\Windows Build\paho-mqtt3cs\Debug\paho-mqtt3cs.pdb" paho_outputs\Win32\Debug
copy "%PAHO_PATH%\org.eclipse.paho.mqtt.c\Windows Build\paho-mqtt3cs\Debug\paho-mqtt3cs.dll" paho_outputs\Win32\Debug

mkdir openssl_outputs
cd openssl_outputs
mkdir Win32
cd Win32
mkdir Debug
cd ..
cd ..
copy "%OpenSSLDir%\out32dll\libeay32.dll" openssl_outputs\Win32\Debug
copy "%OpenSSLDir%\out32dll\libeay32.lib" openssl_outputs\Win32\Debug
copy "%OpenSSLDir%\out32dll\libeay32.exp" openssl_outputs\Win32\Debug
copy "%OpenSSLDir%\out32dll\libeay32.pdb" openssl_outputs\Win32\Debug
copy "%OpenSSLDir%\out32dll\ssleay32.dll" openssl_outputs\Win32\Debug
copy "%OpenSSLDir%\out32dll\ssleay32.lib" openssl_outputs\Win32\Debug
copy "%OpenSSLDir%\out32dll\ssleay32.exp" openssl_outputs\Win32\Debug
copy "%OpenSSLDir%\out32dll\ssleay32.pdb" openssl_outputs\Win32\Debug

nuget pack Microsoft.Azure.IoTHub.MqttTransport.nuspec

rmdir paho_outputs /S /Q
rmdir openssl_outputs /S /Q

nuget pack Microsoft.Azure.IoTHub.Serializer.nuspec

rmdir %client-root%\build_output /S /Q

popd