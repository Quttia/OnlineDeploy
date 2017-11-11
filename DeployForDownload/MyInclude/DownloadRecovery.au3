#cs -----------------------------------------------------------------------

	Au3版本:	3.3.14.2
	脚本作者:
	脚本功能:	下载镜像并还原
	更新日志:	2017.10.26---------------创建文件

#ce -----------------------------------------------------------------------


;==========================================================================
; 函数名：_DownloadImageByAria2c
; 说明：下载镜像(通过Aria2c方式下载)
; 参数：无
; 返回值：无
;==========================================================================
Func _DownloadImageByAria2c()
	
	_FileWriteLog($sLogPath, "------5.下载镜像*开始------")
	
	If FileExists($sDownloadDrive & ":\") Then
		_FileWriteLog($sLogPath, "成功;下载目录：" & $sDownloadDrive & "盘可用")
	Else
		_FileWriteLog($sLogPath, "失败;下载目录：" & $sDownloadDrive & "盘不存在，请反馈至开发人员")
		FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
		DirCopy($sLogDirPath, $sServerLogDirPath, $FC_OVERWRITE)
		;Shutdown($SD_SHUTDOWN)
		Exit
	EndIf
	
	;拼接Aria2c命令行
	Local $sCmdstr = @ScriptDir & "\OtherTools\aria2c.exe -x 10 -s 10 "
	For $i = 1 To $aServerArray[0][0]
		$sCmdstr &= $aServerArray[$i][1] & $sImagePath & " "
	Next
	$sCmdstr &= "-d " & $sDownloadDrive & ":\"
	_FileWriteLog($sLogPath, "成功;读取命令行：" & $sCmdstr)
	_FileWriteLog($sLogPath, "成功;正在下载镜像文件，请等待...")
	FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
	
	;执行镜像下载并计时
	Local $hTimer = TimerInit()
	RunWait(@ComSpec & " /c " & $sCmdstr, "")
	Local $fDiff = TimerDiff($hTimer)
	
	;检测下载是否成功
	$sDownloadImagePath = $sDownloadDrive & ":\" & $sImageName
	If FileExists($sDownloadImagePath) Then
		_FileWriteLog($sLogPath, "成功;下载镜像，耗时" & Round($fDiff / 60000) & "分" & StringRight("0" & Mod(Round($fDiff / 1000), 60), 2) & "秒")
	Else
		_FileWriteLog($sLogPath, "失败;下载镜像失败，请检查网络后重新开机")
		FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
		DirCopy($sLogDirPath, $sServerLogDirPath, $FC_OVERWRITE)
		;Shutdown($SD_SHUTDOWN)
		Exit
	EndIf
	
	_FileWriteLog($sLogPath, "------5.下载镜像*完成------")
	_FileWriteLog($sLogPath, "==============================================================================================")
	
	$fDiff = TimerDiff($hDeployTimer)
	_FileWriteLog($sLogPath, "成功;灌装系统完成，耗时" & Round($fDiff / 60000) & "分" & StringRight("0" & Mod(Round($fDiff / 1000), 60), 2) & "秒")
	_FileWriteLog($sLogPath, "==============================================================================================")
	FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)

	Shutdown($SD_SHUTDOWN)
	
EndFunc   ;==>_DownloadImageByAria2c
