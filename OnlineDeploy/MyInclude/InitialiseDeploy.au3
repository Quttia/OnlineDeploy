#cs -----------------------------------------------------------------------

	Au3版本:	3.3.14.2
	脚本作者:
	脚本功能:	运行环境初始化
	更新日志:	2017.05.24---------------创建文件

#ce -----------------------------------------------------------------------


;==========================================================================
; 函数名：_API_Get_NetworkAdapterMAC
; 说明：获取本机MAC地址
;		成功：初始化MAC地址，如 “30-85-A9-40-EB-B1”;
;			  初始化日志文件路径
;　　　 失败: @error=1
; 参数：无
; 返回值：1：成功；0：失败
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
	
	;PE启动时有可能初始化未完成无法获取Mac地址
	If $sMac = "00-00-00-00-00-00" Then
		Return 0
	Else
		;写日志文件
		$sLogPath = @ScriptDir & "\ConfigFile\" & $sMac & ".log"
		FileDelete($sLogPath)
		_FileWriteLog($sLogPath, "------1.初始化运行环境*开始------")
		_FileWriteLog($sLogPath, "成功;获取本机IP地址:" & $sIP)
		_FileWriteLog($sLogPath, "成功;获取本机MAC地址:" & $sMac)
		Return 1
	EndIf
	
EndFunc   ;==>_API_Get_NetworkAdapterMAC


;==========================================================================
; 函数名：_Read_ShareMapPath
; 说明：获取配置文件中的服务器共享地址映射配置
;		成功: 初始化服务器共享地址映射；注意地址最后要加斜杠，如\\192.168.40.1\share\
;　　　 失败: 运行终止
; 参数：无
; 返回值：无
;==========================================================================
Func _Read_ShareMapPath()
	
	Local Const $sFilePath = @ScriptDir & "\ConfigFile\ShareMapConfig.ini"
	
	;服务器共享地址映射
	Local $sRead = IniRead($sFilePath, "ShareMap", "ShareMapPath", "Error")
	If $sRead = "Error" Then
		_FileWriteLog($sLogPath, "失败;获取配置文件中的服务器共享地址映射失败，程序退出")
		;Shutdown($SD_SHUTDOWN)
		Exit
	Else
		$sShareMapPath = $sRead
		_FileWriteLog($sLogPath, "成功;获取配置文件中的服务器共享地址映射配置：" & $sShareMapPath)
	EndIf
	
	;服务器登录
	$sRead = IniRead($sFilePath, "User", "User", "Error")
	If $sRead = "Error" Then
		_FileWriteLog($sLogPath, "失败;获取配置文件中的服务器用户名失败，程序退出")
		;Shutdown($SD_SHUTDOWN)
		Exit
	Else
		$sUser = $sRead
		_FileWriteLog($sLogPath, "成功;获取配置文件中的服务器用户名：" & $sUser)
	EndIf
	
	$sRead = IniRead($sFilePath, "Psd", "Psd", "Error")
	If $sRead = "Error" Then
		_FileWriteLog($sLogPath, "失败;获取配置文件中的服务器密码失败，程序退出")
		;Shutdown($SD_SHUTDOWN)
		Exit
	Else
		$sPsd = $sRead
		_FileWriteLog($sLogPath, "成功;获取配置文件中的服务器密码")
	EndIf
	
EndFunc   ;==>_Read_ShareMapPath


;==========================================================================
; 函数名：_CreateMap
; 说明：1.在PE上建立服务器上共享的映射
;~		2.同步服务器时间到本机
; 参数：无
; 返回值：无
;==========================================================================
Func _CreateMap()
	
	Local $sCmdStr = "net use * /del /y && net use T: " & StringLeft($sShareMapPath, StringLen($sShareMapPath) - 1) & ' "' & $sPsd & '" /user:' & StringTrimRight(StringTrimLeft($sShareMapPath, 2), 6) & $sUser
	Local $bFlag = True
	$sServerLogPath = $sShareMapPath & "\LogFile\"
	$sServerLogDirPath = $sServerLogPath & $sMac
	_FileWriteLog($sLogPath, "成功;获取在PE上建立服务器上共享的映射命令行：" & $sCmdStr)
	
	For $i = 0 To 5
		RunWait(@ComSpec & " /c " & $sCmdStr, "")
		
		If FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE + $FC_CREATEPATH) Then
			_FileWriteLog($sLogPath, "成功;在PE上建立服务器上共享的映射")
			$bFlag = False
			ExitLoop
		Else
			_FileWriteLog($sLogPath, "重试" & $i & ";在PE上建立服务器上共享的映射")
			Sleep(5000)
		EndIf
	Next
	
	If $bFlag Then
		_FileWriteLog($sLogPath, "失败;在PE上建立服务器上共享的映射失败")
		;Shutdown($SD_SHUTDOWN)
		Exit
	Else
		;由于WIN10PE时区的原因，需要先修改时区，才能同步
		$sCmdStr = "net time " & StringTrimRight($sShareMapPath, 7) & " /set /y"
		_FileWriteLog($sLogPath, "成功;获取同步服务器时间到本机的命令行：" & $sCmdStr)
		RunWait(@ComSpec & " /c " & $sCmdStr, "")
		_FileWriteLog($sLogPath, "成功;同步服务器时间到本机成功")
	EndIf
	
EndFunc   ;==>_CreateMap


;==========================================================================
; 函数名：_IsWinPE
; 说明：检测当前系统环境不是PE环境
; 参数：无
; 返回值：1：是PE环境
;		  0：非PE环境
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
; 函数名：_CheckEnvironment
; 说明：程序启动前检测当前系统环境
; 参数：无
; 返回值：无
;==========================================================================
Func _CheckEnvironment()
	
	If _IsWinPE() = 0 Then
		Local $iReturn = MsgBox($MB_OKCANCEL + $MB_ICONQUESTION, "CheckEnvironment", "Checked The Environment Not PE System, Are You Sure To Continue?")
		_FileWriteLog($sLogPath, "失败;检测到当前系统环境不是PE环境，程序退出")
		
		Switch $iReturn
			Case $IDOK
				ConsoleWrite("Continue......" & @CRLF)
			Case $IDCANCEL
				;Shutdown($SD_SHUTDOWN)
				Exit
			Case Else
				;Shutdown($SD_SHUTDOWN)
				Exit
		EndSwitch
	Else
		_FileWriteLog($sLogPath, "成功;检测到当前系统环境是PE环境，可以运行")
	EndIf
	
EndFunc   ;==>_CheckEnvironment


;==========================================================================
; 函数名：_CheckIfExistOS
; 说明：检测是否已存在操作系统，防止网启设在第一优先级导致重复安装
; 参数：无
; 返回值：无
;==========================================================================
Func _CheckIfExistOS()
	
	If FileExists("C:\InstallationSuccess.Mark") Then
		_FileWriteLog($sLogPath, "失败;检测到本机已经完成安装操作系统，如果确认需要重新安装，请先进入系统删除C盘下的InstallationSuccess.Mark文件")
		FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
		DirCopy($sLogDirPath, $sServerLogDirPath, $FC_OVERWRITE)
		;Shutdown($SD_SHUTDOWN)
		Exit
	Else
		_FileWriteLog($sLogPath, "成功;检测到本机尚未安装操作系统，可以继续安装")
	EndIf
	
EndFunc   ;==>_CheckIfExistOS


;==========================================================================
; 函数名：_InitialiseDeploy
; 说明：程序初始化工作
; 参数：无
; 返回值：无
;==========================================================================
Func _InitialiseDeploy()
	
	ConsoleWrite(@CRLF & "Auto Deploy Start......" & @CRLF)
	
	;初始化MAC地址，日志文件路径
	For $i = 0 To 9
		Sleep(5000)
		If _API_Get_NetworkAdapterMAC() = 1 Then
			ExitLoop
		EndIf
	Next
	
	_CheckEnvironment() ;程序启动前检测当前系统环境
	
	_Read_ShareMapPath() ;初始化服务器映射地址
	
	_CreateMap() ;在PE上建立服务器上共享的映射
	
	_CheckIfExistOS() ;检测是否已存在操作系统
	
	_FileWriteLog($sLogPath, "------1.初始化运行环境*完成------")
	_FileWriteLog($sLogPath, "==============================================================================================")
	FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
	
EndFunc   ;==>_InitialiseDeploy
