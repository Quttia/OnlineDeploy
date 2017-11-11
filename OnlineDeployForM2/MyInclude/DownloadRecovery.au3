#cs -----------------------------------------------------------------------

	Au3版本:	3.3.14.2
	脚本作者:
	脚本功能:	下载镜像并还原
	更新日志:	2017.10.26---------------创建文件

#ce -----------------------------------------------------------------------


;==========================================================================
; 函数名：_RecoveryImage
; 说明：还原镜像
; 参数：无
; 返回值：无
;==========================================================================
Func _RecoveryImage()
	
	_FileWriteLog($sLogPath, "------5.还原镜像*开始------")
	
	;执行镜像还原并计时
	Local $hTimer = TimerInit()
	
	Switch StringLower($sExt)
		Case "wim"
			_FileWriteLog($sLogPath, "成功;检测到本机需要进行WIM镜像还原")
			_Recovery_WIM() ;WIM 镜像还原
		Case "gho"
			_FileWriteLog($sLogPath, "成功;检测到本机需要进行GHO镜像还原")
			_Recovery_GHO() ;GHO 镜像还原
	EndSwitch
	
	Local $fDiff = TimerDiff($hTimer)
	_FileWriteLog($sLogPath, "成功;还原镜像，耗时" & Round($fDiff / 60000) & "分" & StringRight("0" & Mod(Round($fDiff / 1000), 60), 2) & "秒")

	_FileWriteLog($sLogPath, "------5.还原镜像*完成------")
	_FileWriteLog($sLogPath, "==============================================================================================")
	
	$fDiff = TimerDiff($hDeployTimer)
	_FileWriteLog($sLogPath, "成功;灌装系统完成，耗时" & Round($fDiff / 60000) & "分" & StringRight("0" & Mod(Round($fDiff / 1000), 60), 2) & "秒")
	_FileWriteLog($sLogPath, "==============================================================================================")
	FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
	
	;Shutdown($SD_REBOOT)
	Shutdown($SD_SHUTDOWN)
	
EndFunc   ;==>_RecoveryImage


;==========================================================================
; 函数名：_Recovery_WIM
; 说明：还原WIM镜像
; 参数：无
; 返回值：无
;==========================================================================
Func _Recovery_WIM()

	Local $sHidePartition = ""
	
	;检查还原脚本是否存在
	If Not FileExists($sImageScriptPath) Then
		_FileWriteLog($sLogPath, "失败;还原镜像脚本不存在，请反馈至开发人员")
		FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
		DirCopy($sLogDirPath, $sServerLogDirPath, $FC_OVERWRITE)
		;Shutdown($SD_SHUTDOWN)
		Exit
	Else
		_FileWriteLog($sLogPath, "成功;检测到还原镜像脚本")
	EndIf
	
	_FileWriteLog($sLogPath, "成功;正在还原镜像，请等待...")
	FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
	
	;执行还原镜像脚本
	RunWait(@ComSpec & " /c " & $sImageScriptPath & " " & $sDownloadImagePath, "")
	_FileWriteLog($sLogPath, "成功;执行还原镜像脚本：" & $sImageScriptPath & " " & $sDownloadImagePath)
	
	$sHidePartition &= "select disk " & $iSystem & @CRLF
	$sHidePartition &= "select partition " & $iRecovery & @CRLF
	$sHidePartition &= "remove" & @CRLF
	$sHidePartition &= "set id=de94bba4-06d1-4d40-a16a-bfd50179d6ac" & @CRLF
	$sHidePartition &= "gpt attributes=0x8000000000000001" & @CRLF
	$sHidePartition &= "list volume" & @CRLF
	$sHidePartition &= "exit" & @CRLF

	;将隐藏分区命令写入脚本文件中
	Local $hFileOpen = FileOpen($sHidePartScriptPath, $FO_OVERWRITE + $FO_CREATEPATH)
	If $hFileOpen = -1 Then
		_FileWriteLog($sLogPath, "失败;读取隐藏分区脚本，请反馈至开发人员")
		FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
		DirCopy($sLogDirPath, $sServerLogDirPath, $FC_OVERWRITE)
		;Shutdown($SD_SHUTDOWN)
		Exit
	Else
		_FileWriteLog($sLogPath, "成功;读取隐藏分区脚本")
	EndIf
	
	FileWrite($hFileOpen, $sHidePartition)
	FileClose($hFileOpen)
	
	;执行隐藏分区脚本
	RunWait(@ComSpec & " /c diskpart /s " & $sHidePartScriptPath, "")
	_FileWriteLog($sLogPath, "成功;执行隐藏分区脚本：" & "diskpart /s " & $sHidePartScriptPath)
	
EndFunc   ;==>_Recovery_WIM


;==========================================================================
; 函数名：_Recovery_GHO
; 说明：还原GHO镜像
; 参数：无
; 返回值：无
;==========================================================================
Func _Recovery_GHO()
	
	Local Const $sCmdstr = @ScriptDir & "\OtherTools\Ghost64.exe -clone,mode=pload,src=" & $sDownloadImagePath & ":1,dst=1:1 -sure -fx"
	
	_FileWriteLog($sLogPath, "成功;读取命令行：" & $sCmdstr)
	_FileWriteLog($sLogPath, "成功;正在还原镜像，请等待...")
	FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
	
	RunWait(@ComSpec & " /c " & $sCmdstr, "")

EndFunc   ;==>_Recovery_GHO


