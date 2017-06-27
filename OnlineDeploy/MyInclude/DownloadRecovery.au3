#cs -----------------------------------------------------------------------

	Au3�汾:	3.3.14.2
	�ű�����:
	�ű�����:	���ؾ��񲢻�ԭ
	������־:	2017.05.24---------------�����ļ�

#ce -----------------------------------------------------------------------


;==========================================================================
; ��������_DownloadImageByAria2c
; ˵�������ؾ���(ͨ��Aria2c��ʽ����)
; ��������
; ����ֵ����
;==========================================================================
Func _DownloadImageByAria2c()
	
	_FileWriteLog($sLogPath, "------6.���ؾ���*��ʼ------")
	
	If FileExists($sDownloadDrive & ":\") Then
		_FileWriteLog($sLogPath, "�ɹ�;����Ŀ¼��" & $sDownloadDrive & "�̿���")
	Else
		_FileWriteLog($sLogPath, "ʧ��;����Ŀ¼��" & $sDownloadDrive & "�̲����ڣ��뷴����������Ա")
		FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
		Shutdown($SD_SHUTDOWN)
		Exit
	EndIf
	
	;ƴ��Aria2c������
	Local $sCmdstr = @ScriptDir & "\OtherTools\aria2c.exe -x 10 -s 10 "
	For $i = 1 To $aServerArray[0][0]
		$sCmdstr &= $aServerArray[$i][1] & $sImagePath & " "
	Next
	$sCmdstr &= "-d " & $sDownloadDrive & ":\ -o image." & $sExt
	_FileWriteLog($sLogPath, "�ɹ�;��ȡ�����У�" & $sCmdstr)
	_FileWriteLog($sLogPath, "�ɹ�;�������ؾ����ļ�����ȴ�...")
	FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
	
	;ִ�о������ز���ʱ
	Local $hTimer = TimerInit()
	RunWait(@ComSpec & " /c " & $sCmdstr, "")
	Local $fDiff = TimerDiff($hTimer)
	
	;��������Ƿ�ɹ�
	$sDownloadImagePath = $sDownloadDrive & ":\image." & $sExt
	If FileExists($sDownloadImagePath) Then
		_FileWriteLog($sLogPath, "�ɹ�;���ؾ��񣬺�ʱ" & Round($fDiff / 60000) & "��" & StringRight("0" & Mod(Round($fDiff / 1000), 60), 2) & "��")
	Else
		_FileWriteLog($sLogPath, "ʧ��;���ؾ���ʧ�ܣ�������������¿���")
		FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
		Shutdown($SD_SHUTDOWN)
		Exit
	EndIf
	
	_FileWriteLog($sLogPath, "------6.���ؾ���*���------")
	_FileWriteLog($sLogPath, "==============================================================================================")
	FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
	
EndFunc   ;==>_DownloadImageByAria2c


;==========================================================================
; ��������_RecoveryImage
; ˵������ԭ����
; ��������
; ����ֵ����
;==========================================================================
Func _RecoveryImage()
	
	_FileWriteLog($sLogPath, "------7.��ԭ����*��ʼ------")
	
	;ִ�о���ԭ����ʱ
	Local $hTimer = TimerInit()
	
	Switch StringLower($sExt)
		Case "wim"
			_FileWriteLog($sLogPath, "�ɹ�;��⵽������Ҫ����WIM����ԭ")
			_Recovery_WIM() ;WIM ����ԭ
		Case "gho"
			_FileWriteLog($sLogPath, "�ɹ�;��⵽������Ҫ����GHO����ԭ")
			_Recovery_GHO() ;GHO ����ԭ
	EndSwitch
	
	Local $fDiff = TimerDiff($hTimer)
	_FileWriteLog($sLogPath, "�ɹ�;��ԭ���񣬺�ʱ" & Round($fDiff / 60000) & "��" & StringRight("0" & Mod(Round($fDiff / 1000), 60), 2) & "��")

	_FileWriteLog($sLogPath, "------7.��ԭ����*���------")
	_FileWriteLog($sLogPath, "==============================================================================================")
	
	;��ԭ��ɺ�ɾ�������ļ���ʧ�ܲ��˳�����
	If FileDelete($sDownloadImagePath) = 1 Then
		_FileWriteLog($sLogPath, "�ɹ�;��ԭ��ɺ�ɾ�������ļ�")
	Else
		_FileWriteLog($sLogPath, "ʧ��;��ԭ��ɺ�ɾ�������ļ�ʧ�ܣ��뷴����������Ա")
	EndIf
	
	;��ԭ��ɺ󴴽�����ļ���ʶ���Է������ظ���װ��ʧ�ܲ��˳�����
	If _FileCreate("W:\InstallationSuccess.Mark") = 1 Then
		_FileWriteLog($sLogPath, "�ɹ�;��ԭ��ɺ󴴽�����ļ���ʶ")
	Else
		_FileWriteLog($sLogPath, "ʧ��;��ԭ��ɺ󴴽�����ļ���ʶʧ�ܣ��뷴����������Ա")
	EndIf
	
	$fDiff = TimerDiff($hDeployTimer)
	_FileWriteLog($sLogPath, "�ɹ�;��װϵͳ��ɣ���ʱ" & Round($fDiff / 60000) & "��" & StringRight("0" & Mod(Round($fDiff / 1000), 60), 2) & "��")
	_FileWriteLog($sLogPath, "==============================================================================================")
	FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
	
	Shutdown($SD_REBOOT)
	
EndFunc   ;==>_RecoveryImage


;==========================================================================
; ��������_Recovery_WIM
; ˵������ԭWIM����
; ��������
; ����ֵ����
;==========================================================================
Func _Recovery_WIM()

	Local $sHidePartition = ""
	
	;��黹ԭ�ű��Ƿ����
	If Not FileExists($sImageScriptPath) Then
		_FileWriteLog($sLogPath, "ʧ��;��ԭ����ű������ڣ��뷴����������Ա")
		FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
		Shutdown($SD_SHUTDOWN)
		Exit
	Else
		_FileWriteLog($sLogPath, "�ɹ�;��⵽��ԭ����ű�")
	EndIf
	
	_FileWriteLog($sLogPath, "�ɹ�;���ڻ�ԭ������ȴ�...")
	FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
	
	;ִ�л�ԭ����ű�
	RunWait(@ComSpec & " /c " & $sImageScriptPath & " " & $sDownloadImagePath, "")
	_FileWriteLog($sLogPath, "�ɹ�;ִ�л�ԭ����ű���" & $sImageScriptPath & " " & $sDownloadImagePath)
	
	$sHidePartition &= "select disk " & $iSystem & @CRLF
	$sHidePartition &= "select partition " & $iRecovery & @CRLF
	$sHidePartition &= "remove" & @CRLF
	$sHidePartition &= "set id=de94bba4-06d1-4d40-a16a-bfd50179d6ac" & @CRLF
	$sHidePartition &= "gpt attributes=0x8000000000000001" & @CRLF
	$sHidePartition &= "list volume" & @CRLF
	$sHidePartition &= "exit" & @CRLF

	;�����ط�������д��ű��ļ���
	Local $hFileOpen = FileOpen($sHidePartScriptPath, $FO_OVERWRITE + $FO_CREATEPATH)
	If $hFileOpen = -1 Then
		_FileWriteLog($sLogPath, "ʧ��;��ȡ���ط����ű����뷴����������Ա")
		FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
		Shutdown($SD_SHUTDOWN)
		Exit
	Else
		_FileWriteLog($sLogPath, "�ɹ�;��ȡ���ط����ű�")
	EndIf
	
	FileWrite($hFileOpen, $sHidePartition)
	FileClose($hFileOpen)
	
	;ִ�����ط����ű�
	RunWait(@ComSpec & " /c diskpart /s " & $sHidePartScriptPath, "")
	_FileWriteLog($sLogPath, "�ɹ�;ִ�����ط����ű���" & "diskpart /s " & $sHidePartScriptPath)
	
EndFunc   ;==>_Recovery_WIM


;==========================================================================
; ��������_Recovery_GHO
; ˵������ԭGHO����
; ��������
; ����ֵ����
;==========================================================================
Func _Recovery_GHO()
	
	Local Const $sCmdstr = @ScriptDir & "\OtherTools\Ghost64.exe -clone,mode=pload,src=" & $sDownloadImagePath & ":1,dst=1:1 -sure -fx"
	
	_FileWriteLog($sLogPath, "�ɹ�;��ȡ�����У�" & $sCmdstr)
	_FileWriteLog($sLogPath, "�ɹ�;���ڻ�ԭ������ȴ�...")
	FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
	
	RunWait(@ComSpec & " /c " & $sCmdstr, "")

EndFunc   ;==>_Recovery_GHO


