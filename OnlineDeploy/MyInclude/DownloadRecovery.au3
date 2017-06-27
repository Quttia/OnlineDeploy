#cs -----------------------------------------------------------------------

	Au3版本:	3.3.14.2
	脚本作者:
	脚本功能:	下载镜像并还原
	更新日志:	2017.05.24---------------创建文件

#ce -----------------------------------------------------------------------


;==========================================================================
; 函数名：_DownloadImageByAria2c
; 说明：下载镜像(通过Aria2c方式下载)
; 参数：无
; 返回值：无
;==========================================================================
Func _DownloadImageByAria2c()
	
	_FileWriteLog($sLogPath, "------6.下载镜像*开始------")
	
	If FileExists($sDownloadDrive & ":\") Then
		_FileWriteLog($sLogPath, "成功;下载目录：" & $sDownloadDrive & "盘可用")
	Else
		_FileWriteLog($sLogPath, "失败;下载目录：" & $sDownloadDrive & "盘不存在，请反馈至开发人员")
		FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
		Shutdown($SD_SHUTDOWN)
		Exit
	EndIf
	
	;拼接Aria2c命令行
	Local $sCmdstr = @ScriptDir & "\OtherTools\aria2c.exe -x 10 -s 10 "
	For $i = 1 To $aServerArray[0][0]
		$sCmdstr &= $aServerArray[$i][1] & $sImagePath & " "
	Next
	$sCmdstr &= "-d " & $sDownloadDrive & ":\ -o image." & $sExt
	_FileWriteLog($sLogPath, "成功;读取命令行：" & $sCmdstr)
	_FileWriteLog($sLogPath, "成功;正在下载镜像文件，请等待...")
	FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
	
	;执行镜像下载并计时
	Local $hTimer = TimerInit()
	RunWait(@ComSpec & " /c " & $sCmdstr, "")
	Local $fDiff = TimerDiff($hTimer)
	
	;检测下载是否成功
	$sDownloadImagePath = $sDownloadDrive & ":\image." & $sExt
	If FileExists($sDownloadImagePath) Then
		_FileWriteLog($sLogPath, "成功;下载镜像，耗时" & Round($fDiff / 60000) & "分" & StringRight("0" & Mod(Round($fDiff / 1000), 60), 2) & "秒")
	Else
		_FileWriteLog($sLogPath, "失败;下载镜像失败，请检查网络后重新开机")
		FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
		Shutdown($SD_SHUTDOWN)
		Exit
	EndIf
	
	_FileWriteLog($sLogPath, "------6.下载镜像*完成------")
	_FileWriteLog($sLogPath, "==============================================================================================")
	FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
	
EndFunc   ;==>_DownloadImageByAria2c


;==========================================================================
; 函数名：_RecoveryImage
; 说明：还原镜像
; 参数：无
; 返回值：无
;==========================================================================
Func _RecoveryImage()
	
	_FileWriteLog($sLogPath, "------7.还原镜像*开始------")
	
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

	_FileWriteLog($sLogPath, "------7.还原镜像*完成------")
	_FileWriteLog($sLogPath, "==============================================================================================")
	
	;还原完成后删除镜像文件；失败不退出程序
	If FileDelete($sDownloadImagePath) = 1 Then
		_FileWriteLog($sLogPath, "成功;还原完成后删除镜像文件")
	Else
		_FileWriteLog($sLogPath, "失败;还原完成后删除镜像文件失败，请反馈至开发人员")
	EndIf
	
	;还原完成后创建完成文件标识，以防网启重复安装；失败不退出程序
	If _FileCreate("W:\InstallationSuccess.Mark") = 1 Then
		_FileWriteLog($sLogPath, "成功;还原完成后创建完成文件标识")
	Else
		_FileWriteLog($sLogPath, "失败;还原完成后创建完成文件标识失败，请反馈至开发人员")
	EndIf
	
	$fDiff = TimerDiff($hDeployTimer)
	_FileWriteLog($sLogPath, "成功;灌装系统完成，耗时" & Round($fDiff / 60000) & "分" & StringRight("0" & Mod(Round($fDiff / 1000), 60), 2) & "秒")
	_FileWriteLog($sLogPath, "==============================================================================================")
	FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
	
	Shutdown($SD_REBOOT)
	
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
		Shutdown($SD_SHUTDOWN)
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
		Shutdown($SD_SHUTDOWN)
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


