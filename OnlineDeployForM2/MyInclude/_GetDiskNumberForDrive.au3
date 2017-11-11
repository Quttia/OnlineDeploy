$sDDriveLetter = "c:"

$iDiskNumber = _GetDiskNumberForDrive($sDDriveLetter)

If @error Then
    MsgBox(48, "Error", "Error Number " & @error & @CRLF)
Else
    MsgBox(64, "_GetDiskNimberForDrive", "Drive " & StringUpper($sDDriveLetter) & " is on disk #" & $iDiskNumber)
EndIf



Func _GetDiskNumberForDrive($sDriveLetter)

    Local $a_hCall = DllCall("kernel32.dll", "hwnd", "CreateFile", _
            "str", "\\.\" & $sDriveLetter, _; logical drive
            "dword", 0, _
            "dword", 0, _
            "ptr", 0, _
            "dword", 3, _; OPEN_EXISTING
            "dword", 128, _; FILE_ATTRIBUTE_NORMAL
            "ptr", 0)

    If @error Then
        Return SetError(1, 0, -1); your system is very old. Do something.
    EndIf

    If $a_hCall[0] = -1 Then
        Return SetError(2, 0, -1); non-existing drive
    EndIf

    Local $hDevice = $a_hCall[0]

    Local $tIOCTL_STORAGE_GET_DEVICE_NUMBER = DllStructCreate("dword DeviceType;" & _
            "dword DeviceNumber;" & _
            "int PartitionNumber")

    Local $a_iCall = DllCall("kernel32.dll", "int", "DeviceIoControl", _
            "hwnd", $hDevice, _
            "dword", 0x2D1080, _; IOCTL_STORAGE_GET_DEVICE_NUMBER
            "ptr", 0, _
            "dword", 0, _
            "ptr", DllStructGetPtr($tIOCTL_STORAGE_GET_DEVICE_NUMBER), _
            "dword", DllStructGetSize($tIOCTL_STORAGE_GET_DEVICE_NUMBER), _
            "dword*", 0, _
            "ptr", 0)

    If @error Or Not $a_hCall[0] Then
        DllCall("kernel32.dll", "int", "CloseHandle", "hwnd", $hDevice)
        Return SetError(3, 0, -1); DeviceIoControl failed for some reason
    EndIf

    DllCall("kernel32.dll", "int", "CloseHandle", "hwnd", $hDevice)

    If DllStructGetData($tIOCTL_STORAGE_GET_DEVICE_NUMBER, "DeviceType") = 7 Then; FILE_DEVICE_DISK
        Return SetError(0, 0, DllStructGetData($tIOCTL_STORAGE_GET_DEVICE_NUMBER, "DeviceNumber"))
    EndIf

    Return SetError(4, 0, -1); not a disk partition

EndFunc ;==>_GetDiskNimberForDrive