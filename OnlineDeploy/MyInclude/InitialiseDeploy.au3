#cs -----------------------------------------------------------------------

	Au3�汾:	3.3.14.2
	�ű�����:
	�ű�����:	���л�����ʼ��
	������־:	2017.05.24---------------�����ļ�

#ce -----------------------------------------------------------------------


;==========================================================================
; ��������_API_Get_NetworkAdapterMAC
; ˵������ȡ����MAC��ַ
;		�ɹ�����ʼ��MAC��ַ���� ��30-85-A9-40-EB-B1��;
;			  ��ʼ����־�ļ�·��
;������ ʧ��: @error=1
; ��������
; ����ֵ��1���ɹ���0��ʧ��
;==========================================================================
Func _API_Get_NetworkAdapterMAC()
	Local $sIP = @IPAddress1
	Local $MAC, $MACSize
	Local $i, $s, $r, $iIP

	$MAC = DllStructCreate("byte[6]")
	$MACSize = DllStructCreate("int")

	DllStructSetData($MACSize, 1, 6)
	$r = DllCall("Ws2_32.dll", "int", "inet_addr", "str", $sIP)
	$iIP = $r[0]
	$r = DllCall("iphlpapi.dll", "int", "SendARP", "int", $iIP, "int", 0, "ptr", DllStructGetPtr($MAC), "ptr", DllStructGetPtr($MACSize))
	$s = ""
	For $i = 0 To 5
		If $i Then $s &= "-"
		$s &= Hex(DllStructGetData($MAC, 1, $i + 1), 2)
	Next
	$sMac = $s
	
	;PE����ʱ�п��ܳ�ʼ��δ����޷���ȡMac��ַ
	If $sMac = "00-00-00-00-00-00" Then
		Return 0
	Else
		;д��־�ļ�
		$sLogPath = @ScriptDir & "\ConfigFile\" & $sMac & ".log"
		FileDelete($sLogPath)
		_FileWriteLog($sLogPath, "------1.��ʼ�����л���*��ʼ------")
		_FileWriteLog($sLogPath, "�ɹ�;��ȡ����IP��ַ:" & $sIP)
		_FileWriteLog($sLogPath, "�ɹ�;��ȡ����MAC��ַ:" & $sMac)
		Return 1
	EndIf
	
EndFunc   ;==>_API_Get_NetworkAdapterMAC


;==========================================================================
; ��������_Read_ShareMapPath
; ˵������ȡ�����ļ��еķ����������ַӳ������
;		�ɹ�: ��ʼ�������������ַӳ�䣻ע���ַ���Ҫ��б�ܣ���\\192.168.40.1\share\
;������ ʧ��: ������ֹ
; ��������
; ����ֵ����
;==========================================================================
Func _Read_ShareMapPath()
	
	Local Const $sFilePath = @ScriptDir & "\ConfigFile\ShareMapConfig.ini"
	
	;�����������ַӳ��
	Local $sRead = IniRead($sFilePath, "ShareMap", "ShareMapPath", "Error")
	If $sRead = "Error" Then
		_FileWriteLog($sLogPath, "ʧ��;��ȡ�����ļ��еķ����������ַӳ��ʧ�ܣ������˳�")
		Shutdown($SD_SHUTDOWN)
		Exit
	Else
		$sShareMapPath = $sRead
		_FileWriteLog($sLogPath, "�ɹ�;��ȡ�����ļ��еķ����������ַӳ�����ã�" & $sShareMapPath)
	EndIf
	
	;��������¼
	$sRead = IniRead($sFilePath, "User", "User", "Error")
	If $sRead = "Error" Then
		_FileWriteLog($sLogPath, "ʧ��;��ȡ�����ļ��еķ������û���ʧ�ܣ������˳�")
		Shutdown($SD_SHUTDOWN)
		Exit
	Else
		$sUser = $sRead
		_FileWriteLog($sLogPath, "�ɹ�;��ȡ�����ļ��еķ������û�����" & $sUser)
	EndIf
	
	$sRead = IniRead($sFilePath, "Psd", "Psd", "Error")
	If $sRead = "Error" Then
		_FileWriteLog($sLogPath, "ʧ��;��ȡ�����ļ��еķ���������ʧ�ܣ������˳�")
		Shutdown($SD_SHUTDOWN)
		Exit
	Else
		$sPsd = $sRead
		_FileWriteLog($sLogPath, "�ɹ�;��ȡ�����ļ��еķ���������")
	EndIf
	
EndFunc   ;==>_Read_ShareMapPath


;==========================================================================
; ��������_CreateMap
; ˵������PE�Ͻ����������Ϲ����ӳ��
; ��������
; ����ֵ����
;==========================================================================
Func _CreateMap()
	Local $sCmdStr = "net use * /del /y && net use T: " & StringLeft($sShareMapPath, StringLen($sShareMapPath) - 1) & ' "' & $sPsd & '" /user:' & StringTrimRight(StringTrimLeft($sShareMapPath, 2), 6) & $sUser
	Local $bFlag = True
	$sServerLogPath = $sShareMapPath & "\LogFile\"
	_FileWriteLog($sLogPath, "�ɹ�;��ȡ��PE�Ͻ����������Ϲ����ӳ�������У�" & $sCmdStr)
	
	For $i = 0 To 5
		RunWait(@ComSpec & " /c " & $sCmdStr, "")
		
		If FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE + $FC_CREATEPATH) Then
			_FileWriteLog($sLogPath, "�ɹ�;��PE�Ͻ����������Ϲ����ӳ��")
			$bFlag = False
			ExitLoop
		Else
			_FileWriteLog($sLogPath, "����" & $i & ";��PE�Ͻ����������Ϲ����ӳ��")
			Sleep(5000)
		EndIf
	Next
	
	If $bFlag Then
		_FileWriteLog($sLogPath, "ʧ��;��PE�Ͻ����������Ϲ����ӳ��ʧ��")
		FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
		Shutdown($SD_SHUTDOWN)
		Exit
	EndIf
	
EndFunc   ;==>_CreateMap


;==========================================================================
; ��������_IsWinPE
; ˵������⵱ǰϵͳ��������PE����
; ��������
; ����ֵ��1����PE����
;		  0����PE����
;==========================================================================
Func _IsWinPE()
	Local $sRam = "ramdisk(0)"
	RegRead("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\MiniNT", "")
	If @error = 1 Then
		If RegRead("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control", "SystemBootDevice") = $sRam Then Return 1
		Return 0
	Else
		Return 1
	EndIf
EndFunc   ;==>_IsWinPE


;==========================================================================
; ��������_CheckEnvironment
; ˵������������ǰ��⵱ǰϵͳ����
; ��������
; ����ֵ����
;==========================================================================
Func _CheckEnvironment()
	
	If _IsWinPE() = 0 Then
		Local $iReturn = MsgBox($MB_OKCANCEL + $MB_ICONQUESTION, "CheckEnvironment", "Checked The Environment Not PE System, Are You Sure To Continue?")
		_FileWriteLog($sLogPath, "ʧ��;��⵽��ǰϵͳ��������PE�����������˳�")
		
		Switch $iReturn
			Case $IDOK
				ConsoleWrite("Continue......" & @CRLF)
			Case $IDCANCEL
				Shutdown($SD_SHUTDOWN)
				Exit
			Case Else
				Shutdown($SD_SHUTDOWN)
				Exit
		EndSwitch
	Else
		_FileWriteLog($sLogPath, "�ɹ�;��⵽��ǰϵͳ������PE��������������")
	EndIf
	
EndFunc   ;==>_CheckEnvironment


;==========================================================================
; ��������_CheckIfExistOS
; ˵��������Ƿ��Ѵ��ڲ���ϵͳ����ֹ�������ڵ�һ���ȼ������ظ���װ
; ��������
; ����ֵ����
;==========================================================================
Func _CheckIfExistOS()
	
	If FileExists("C:\InstallationSuccess.Mark") Then
		_FileWriteLog($sLogPath, "ʧ��;��⵽�����Ѿ���ɰ�װ����ϵͳ�����ȷ����Ҫ���°�װ�����Ƚ���ϵͳɾ��C���µ�InstallationSuccess.Mark�ļ�")
		FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
		Shutdown($SD_SHUTDOWN)
		Exit
	Else
		_FileWriteLog($sLogPath, "�ɹ�;��⵽������δ��װ����ϵͳ�����Լ�����װ")
	EndIf
	
EndFunc   ;==>_CheckIfExistOS


;==========================================================================
; ��������_InitialiseDeploy
; ˵���������ʼ������
; ��������
; ����ֵ����
;==========================================================================
Func _InitialiseDeploy()
	
	ConsoleWrite(@CRLF & "Auto Deploy Start......" & @CRLF)
	
	;��ʼ��MAC��ַ����־�ļ�·��
	For $i = 0 To 9
		Sleep(5000)
		If _API_Get_NetworkAdapterMAC() = 1 Then
			ExitLoop
		EndIf
	Next
	
	_CheckEnvironment() ;��������ǰ��⵱ǰϵͳ����
	
	_Read_ShareMapPath() ;��ʼ��������ӳ���ַ
	
	_CreateMap() ;��PE�Ͻ����������Ϲ����ӳ��
	
	_CheckIfExistOS() ;����Ƿ��Ѵ��ڲ���ϵͳ
	
	_FileWriteLog($sLogPath, "------1.��ʼ�����л���*���------")
	_FileWriteLog($sLogPath, "==============================================================================================")
	FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
	
EndFunc   ;==>_InitialiseDeploy
