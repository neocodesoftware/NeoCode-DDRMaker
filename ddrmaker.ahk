; Ctrl-D terminates script	

										; DB Setup
fmVersion = FM11						; Filemaker client version. Has to match key in FmSettings
fmDB = C:\Path2DB\DBname.fp7			; DB path - local or remote in fmnet.. format
fmLogin = FMLoginHere
fmPass = FmPasswordHere

;fmVersion = FM14						; Example for FM 14 DB
;fmDB = C:\Path2DB\DBname.fmp12
;fmLogin = FMLoginHere
;fmPass = FmPasswordHere

reportType := "HTML"					; DDR Type HTML or XML (XML by default)
										; DB Setup END
										
										; Adjustable user config parameters
workFolder := "d:\DDR_Maker\"
LOGFILE := workFolder . "logfile.log"
DdrSaveDirName := workFolder . "DDR" . A_Now
										; Paths to store result
ZipPath := "C:\Program Files\7-Zip\7z.exe"		; Path to 7zip
CurlPath := "C:\Program Files (x86)\cURL\bin\curl.exe"	; Path to curl	
FtpPath := "ftp://ServerNameHere.com/ddrmaker/"
FtpUser := "FtpUserLogin"
FtpPass := "FtpUserPass"
										
FmSettings := {  FM11: { App: "C:\Program Files (x86)\FileMaker\FileMaker Pro 11 Advanced\FileMaker Pro Advanced.exe"
						, Class: "FMPRO11.0APP"
						, Title: "FileMaker Pro Advanced"
						, PopUpClass: "#32770"
						, SendType: "Class"}
			   , FM14: {  App: "C:\Program Files (x86)\FileMaker\FileMaker Pro 14 Advanced\FileMaker Pro Advanced.exe"
						, Class: "FMPRO14.0APP"
						, Title: "FileMaker Pro Advanced"
						, PopUpClass: "#32770"
						, SendType: ""}}
										; Adjustable user  config parameters END

;..............update the code below only if you know what you are doing :) .............
										; Config parameters
DetectHiddenWindows, On
SetKeyDelay, 100, 100	
controlSendType := FmSettings[fmVersion, "SendType"]	
fmApp := FmSettings[fmVersion, "App"]							; FM version
fmAppClass := FmSettings[fmVersion, "Class"]					; FM application class
fmPopUpClass := FmSettings[fmVersion, "PopUpClass"]				; Class for notification/error popup windows
fmAppTitle := FmSettings[fmVersion, "Title"]					; FM application title
fmDDRWindowTitle := "Database Design Report"					; DDR window title
fmDDRSaveReportTitle := "Save Report"							; "Save report" window title
fmDDRSavingReportTitle := "Saving Report"						; "Saving report" window title
fmLoginTitle := "Open"
										
; WriteLog  - write message in log file
; Call:		WriteLog(msg)
; Where:	msg - message to write in log file
;
WriteLog(TextToLog) {
  global LOGFILE  
  global FmPID
  FileAppend, %A_Now%: (%FmPID%) %TextToLog%`n, %LOGFILE%
}									; -- WriteLog --

; CheckWindow - checks active window to match title
;				if checks fail write error message to log and exit application
; Call: 	CheckWindow(title,errorMsg)
; Where:	title - required title
;			errorMsg - message to write in log in case of error
;
CheckWindow(title,errorMsg) {
  global fmAppTitle
  global FmPID
  WriteLog("Check " . title)
  DebugWindows()
  SetTitleMatchMode, 1						; Match beginning of the title
  WinGet, myid, ID,%title%					; Find window with required title
  if (!myid) {								; window with required title not found
	WriteLog(errorMsg)
	CloseFM()
    ExitApp 
  } 
  SetTitleMatchMode, 3						; Match the whole title by default
  return
}									; -- CheckWindow --

; DebugWindows - write all active windows in log
DebugWindows() {
  WinGet, id, list,,, Program Manager
  Loop, %id% {
    this_id := id%A_Index%
    WinGetClass, thisClass, ahk_id %this_id%
    WinGetTitle, thisTitle, ahk_id %this_id%
	WinGetText, thisText, ahk_id %this_id%
;    WriteLog(id . " this_id: " . this_id . " ahk_class: " . thisClass . " title: " . thisTitle . " text: " . thisText)
    WriteLog(id . " this_id: " . this_id . " ahk_class: " . thisClass . " title: " . thisTitle)
  }
}									; -- DebugWindows --

; Log and close any error window produced by FM
; Close all windows but the one with the title %okTitle%
CloseErrorWindows(okTitle) {
  global fmPopUpClass
  if (fmPopUpClass) {
    WinGet, id, list, ahk_class %fmPopUpClass%
    Loop, %id% {
      this_id := id%A_Index%
      WinGetClass, thisClass, ahk_id %this_id%
      WinGetTitle, thisTitle, ahk_id %this_id%
	  WinGetText, thisText, ahk_id %this_id%
	  if (thisTitle != okTitle) {			; Close this window
        WriteLog("Close this_id: " . this_id . " ahk_class: " . thisClass . " title: " . thisTitle . " text: " . thisText) 
;        WinClose, %thisTitle%
		WinClose, ahk_id %this_id%
      }
    }
  }
}												; -- CloseErrorWindows -- 

; CloseFM - Close FileMaker
; Try both close and kill :)
CloseFM() {
  global FmPID									; File maker process PID
  global fmAppTitle								; File Maker window title
  
  sleep, 10000
  WinClose, ahk_pid %FmPID%						; Close with PID works for FM11
  sleep, 10000
  IfWinNotExist, ahk_pid %FmPID% 
  {
    WriteLog("FM closed by PID")
    return
  }
 
  WinClose, %fmAppTitle%						; Close with Title works with FM14
  sleep, 10000
  IfWinNotExist, ahk_pid %FmPID% 
  {
    WriteLog("FM closed by title")
    return
  }

  WriteLog("Try to kill FM process")
  WinKill, ahk_pid %FmPID%						; Try kill just in case
  sleep, 10000
  WinKill, %fmAppTitle%							; Try kill just in case
  sleep, 10000	  
  IfWinNotExist, ahk_pid %FmPID% 
  {
    WriteLog("FM killed")
    return
  }
  WriteLog("FM was not closed")
}											; --   CloseFM --

											; STAR HERE
WriteLog("Started")

if WinExist("ahk_class " . fmAppClass) {	; FileMaker already started. TODO - use started FM to proceed
  WriteLog("FileMaker already running")
  ExitApp
}
Run, %fmApp% %fmDB%, , max, FmPID
sleep, 10000								; Sleep enough time for FM to start
WriteLog("FileMaker started")

											; Check if FM started
CheckWindow(fmLoginTitle,"FileMaker App not started")

										; Enter login/pass
if (controlSendType = "Class") {								; Use Class in ControlSend
  ControlSend, Edit1, {delete 30}, ahk_pid %FmPID%				; Empty username field
  ControlSetText, Edit1, %fmLogin%, ahk_pid %FmPID%				; Username. ControlSend sends everything lowercase. Use ControlSetText instead
  ControlSetText, Edit2, %fmPass%, ahk_pid %FmPID%				; Password. ControlSend sends everything lowercase. Use ControlSetText instead
} else {
  ControlSend ,, {Tab %loginTab2Field%}, ahk_pid %FmPID%		; Send Tab X to switch to username 
  sleep, 1000
  ControlSend ,, A%fmLogin%, ahk_pid %FmPID%					; Ugly workaround: Autohotkey miss first char here
  sleep, 1000
  ControlSend ,, {Tab}, ahk_pid %FmPID%							; Send Tab to switch to password 
  sleep, 1000
  ControlSend ,, %fmPass%, ahk_pid %FmPID%
}

sleep, 1000
ControlSend ,, {Enter}, ahk_pid %FmPID%							; Login


Loop, 20 {														; Check for error popup windows and close them if any
  CloseErrorWindows("")
  sleep, 1000   
}


; Open DDR window
ControlSend ,, {F10}tg, ahk_pid %FmPID%

sleep, 2000
											; Check if DDR windows was opened
CheckWindow(fmDDRWindowTitle,"DDR window not opened")

if (controlSendType = "Class") {						; Use Class in ControlSend
  if (reportType = "HTML") {							; HTML report type
    ControlSend, Button1, {space}, ahk_pid %FmPID%		; Click space to select HTML Report typed
  } else {	
    ControlSend, Button2, {space}, ahk_pid %FmPID%		; Click space to select XML Report typed
  }	
  sleep, 1000
  ControlSend, Button3, {space}, ahk_pid %FmPID%		; Click space to uncheck checkbox "Automatically open report when done"
} else {
  if (reportType = "HTML") {							; HTML report type
    ControlSend ,, {Tab 4}, ahk_pid %FmPID%				; Presses Tab 4 times to select report type XML
    ControlSend ,, {Space}, ahk_pid %FmPID%				; Click space to select XML Report type
    sleep, 1000
    ControlSend ,, {Tab 2}, ahk_pid %FmPID%				; go to activate checkbox "Automatically open report when done"
    ControlSend ,, {Space}, ahk_pid %FmPID%				; Click space to uncheck checkbox "Automatically open report when done"
  } else {
    ControlSend ,, {Tab 5}, ahk_pid %FmPID%				; Presses Tab 5 times to select report type XML
    ControlSend ,, {Space}, ahk_pid %FmPID%				; Click space to select XML Report type
    sleep, 1000
    ControlSend ,, {Tab}, ahk_pid %FmPID%				; go to activate checkbox "Automatically open report when done"
    ControlSend ,, {Space}, ahk_pid %FmPID%				; Click space to uncheck checkbox "Automatically open report when done"
  }
}
sleep, 1000
ControlSend ,, {Enter}, ahk_pid %FmPID%					; Click Save report button
sleep, 1000

														; Check if DDR save windows was opened
CheckWindow(fmDDRSaveReportTitle,"DDR save window not opened")

FileCreateDir, %DdrSaveDirName%							; Create folder to save report
WriteLog("Saving report in " . DdrSaveDirName)
if (controlSendType = "Class") {						; Use Class in ControlSend
  ControlSetText ,Edit1, %DdrSaveDirName%\report, Save Report		; Can't use ControlSend here - when sends ':', it transfers it to ';'. This dialog is using ClassNN  as well
} else {
;  ControlSetText ,Edit1, %DdrSaveDirName%\report, ahk_pid %FmPID%		; Can't use ControlSend here - when sends ':', it transfers it to ';'. This dialog is using ClassNN  as well
  ControlSetText ,Edit1, %DdrSaveDirName%\report, Save Report		; Can't use ControlSend here - when sends ':', it transfers it to ';'. This dialog is using ClassNN  as well
}  
sleep, 1000

ControlSend ,,{Enter}, Save Report	; Click Save report button
sleep, 1000
;DebugWindows()

i = 0											; Wait up to 10 sec for "Saving Report" window
stop = 0										; 0 - continue checking, 1 - stop checking
while stop=0 {
  sleep, 1000									; wait 1 sec before next checking
  WinGet, myid, ID,%fmDDRSavingReportTitle%		; Find "Saving report" window
  if (myid) {									; "Saving report" window found
    WriteLog("Saving in process")
    CloseErrorWindows(fmDDRSavingReportTitle)	; Check and close error windows if any
    sleep 9000
    i = 1000000000								; stop as soon as this window disappear
  } else {
    i += 1										; increment wait counter
    if (i > 10) {								; Stop: we either waited too long or 'Saving report' window disappear
     stop = 1
    }	 
  }
}

WriteLog("Report finished")
;DebugWindows()
sleep, 10000									; wait 10 sec before exiting
CloseFM()
WriteLog("app closed")
;DebugWindows()

RunWait, %ZipPath% a %DdrSaveDirName%.zip %DdrSaveDirName% 
sleep, 1000
RunWait, %CurlPath% -T %DdrSaveDirName%.zip -u %FtpUser%:%FtpPass%  %FtpPath%

WriteLog("Finished")
ExitApp

; Pressing Ctrl+d terminates the script. This code has to be at the bottom of the script
;#x::ExitApp  
;Escape:: 
^d::
ExitApp 
Return 