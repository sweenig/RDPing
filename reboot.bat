@echo off
if "%1"=="" goto:HELP
::shutdown the server
echo.
echo %1 rebooting...
shutdown /r /d p:4:1 /m \\%1 /t 0 /c "Remote reboot requested"
if errorlevel 1 GOTO:EOF
::Ping until unsuccessful then successful
set pingfailyet=FALSE
set pingwaittime=3
echo.
echo Pinging %1...
:startping
ping -n 1 %1 | find "Reply"
if %errorlevel%==0 (
 if %pingfailyet%==FALSE (
 ::echo %1 hasn't gone down yet.  Pinging again in %pingwaittime% seconds...
  CHOICE /C x /N /T %pingwaittime% /D x > NUL
  goto startping
 ) else (
  echo Successfully pinged %1.
  goto endping
 )
) else (
 set pingfailyet==TRUE
 echo No reply from %1.
 CHOICE /C x /N /T %pingwaittime% /D x > NUL
 goto startping
)
:endping
::use tcping to check when RDP becomes available
echo.
echo Waiting for RDP on %1 to become available...
if not exist tcping.exe call:gatherer
tcping.exe -t -i %pingwaittime% -s %1 3389
if %errorlevel%==1 GOTO:EOF
::launch RDP
echo.
if NOT "%2"=="NOCONNECT" (
echo RDP is available on %1.  Connecting...
start mstsc /v:%1 /f
) ELSE (
echo RDP is available on %1.
)
goto:EOF
:HELP
echo ERROR: Missing server name, exiting...
echo.
echo This script reboots a server, pings until it doesn't respond,
echo pings until it responds, then waits for RDP to come up, then
echo launches the RDP client and connects to the server.  If your
echo password is saved and you don't have a welcome message before
echo logon, you should be brought directly to the desktop of the
echo server after rebooting.
echo.
echo Usage: reboot server_name [NOCONNECT]
echo.
echo Options:
echo     NOCONNECT          Skip launching of mstsc.exe to reconnecto to the server
echo.
echo The first argument is the name of the server to reboot.
echo The second argument is optional. If you specify NOCONNECT,
echo reboot.bat will skip the last section that launches the RDP client.
echo.
echo (C) 2013-2014 Stuart Weenig stuart.weenig.com
echo version 2.3 Last Updated Jan 14, 2014.
echo.
echo Use a command like the following to run this for a list of servers:
echo     FOR %%A in (server1 server2 server3) DO (start reboot.bat %%A [NOCONNECT])
goto:EOF
:gatherer
echo TCPing missing. Downloading...
(
echo dim xHttp
echo set xHttp = createobject^("Microsoft.XMLHTTP"^)
echo dim bStrm
echo set bStrm = createobject^("Adodb.Stream"^) 'create bitstream object
echo dim targetURL
echo targetURL = "http://www.elifulkerson.com/projects/downloads/tcping-0.31/tcping.exe"
echo WScript.echo "Downloading TCPing from " ^& targetURL ^& "..."
echo xHttp.Open "GET", targetURL ,False
echo xHttp.Send
echo WScript.echo "HTTP Response Code: " ^& xHttp.status
echo dim fso 
echo dim curDir
echo set fso = CreateObject^("Scripting.FileSystemObject"^)
echo curDir = fso.GetAbsolutePathName^("."^)
echo set fso = nothing
echo if xHttp.status^>=400 and xHttp.status ^<=599 then
echo 	WScript.echo targetURL ^& " was not found."
echo 	WScript.Quit 1
echo Else
echo 	with bStrm
echo 		.type = 1
echo 		.open
echo 		.write xHttp.responseBody
echo 		WScript.echo "Saving to " ^& curDir ^& "\tcping.exe..."
echo 		.savetofile curDir ^& "\tcping.exe", 2
echo 	end with
echo End If
) > gatherer.vbs
cscript gatherer.vbs
del /q gatherer.vbs
GOTO:EOF
