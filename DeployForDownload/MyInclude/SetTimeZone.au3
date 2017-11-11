#include <Date.au3>

Local $aOld = _Date_Time_GetTimeZoneInformation()
If Not _Date_Time_SetTimeZoneInformation(-480, "China Standard Time", $aOld[3], $aOld[4], "China Daylight Time", $aOld[6], -60) Then
	ConsoleWrite(@CRLF & "Failed To Set China Standard Time !" & @CRLF)
	Exit
Else
	ConsoleWrite(@CRLF & "Set China Standard Time Successfully !" & @CRLF)
EndIf
