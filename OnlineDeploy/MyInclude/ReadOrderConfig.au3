#cs -----------------------------------------------------------------------

	Au3版本:	3.3.14.2
	脚本作者:
	脚本功能:	1. 读取客户定制数据配置文件；
	~			2. 读取机器MAC地址，通过解析MAC地址命名的客户定制数据配置文件来获取相关信息等；配置文件由MES系统输出，包含客户定制数据有：
	~				a. 操作系统类型，版本信息等，如win7，8，10
	~				b. 订单分区的硬盘数目，大小，以及各个硬盘分区大小
	~			......
	~			......
	更新日志:	2017.05.24---------------创建文件

#ce -----------------------------------------------------------------------


;==========================================================================
; 函数名：_Read_OrderConfig
; 说明：获取存储在服务器中的订单配置文件信息，存储到 $aBasicInfoArray 和 $aHDInfoArray
; 参数：无
; 返回值：无
;==========================================================================
Func _Read_OrderConfig()
	Local Const $sConfigFilePath = $sShareMapPath & "OrderFile\" & $sMac & ".ini"
	_FileWriteLog($sLogPath, "------2.读取订单配置文件*开始------")
	_FileWriteLog($sLogPath, "成功;获取订单配置文件路径：" & $sConfigFilePath)

	;检查订单文件是否存在
	If FileExists($sConfigFilePath) Then
		_FileWriteLog($sLogPath, "成功;检测到本机对应的订单文件")
	Else
		_FileWriteLog($sLogPath, "失败;本机对应的订单文件：“" & $sMac & ".ini”文件缺失，请联系MES相关人员")
		FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
		Shutdown($SD_SHUTDOWN)
		Exit
	EndIf
	
	;读取“订单配置文件信息”中的“订单基本信息”
	$aBasicInfoArray = IniReadSection($sConfigFilePath, "BasicInfo")
	If @error Then
		_FileWriteLog($sLogPath, "失败;读取订单文件中的“订单基本信息”失败，请联系MES相关人员")
		FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
		Shutdown($SD_SHUTDOWN)
		Exit
	Else
		_FileWriteLog($sLogPath, "成功;读取订单文件中的“订单基本信息”")
	EndIf

	;读取“订单配置文件信息”中的“硬盘分区信息”，并进行加工
	Local $aRawHDInfoArray = IniReadSection($sConfigFilePath, "HDInfo")
	If @error Then
		_FileWriteLog($sLogPath, "失败;读取订单文件中的“硬盘分区信息”失败，请联系MES相关人员")
		FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
		Shutdown($SD_SHUTDOWN)
		Exit
	Else
		_FileWriteLog($sLogPath, "成功;读取订单文件中的“硬盘分区信息”")
	EndIf

	;存储为一个一维数组，注意不是二维的，注意取值加括号：MsgBox(0,0,($aTempArray[1])[1])
	Local $iCount = $aRawHDInfoArray[0][0]
	Local $aTempArray[$iCount]
	For $i = 1 To $iCount
		$aTempArray[$i - 1] = StringSplit($aRawHDInfoArray[$i][1], ",", $STR_NOCOUNT) ; 禁用返回表示元素数量的第一个元素 - 方便使用基于 0 开始的数组.
	Next
	$aHDInfoArray = $aTempArray
	
	_FileWriteLog($sLogPath, "------2.读取订单配置文件*完成------")
	_FileWriteLog($sLogPath, "==============================================================================================")
	FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
EndFunc   ;==>_Read_OrderConfig


;==========================================================================
; 函数名：_Get_DiskInfo
; 说明：获取实际硬盘列表
; 参数：无
; 返回值：无
;==========================================================================
Func _Get_DiskInfo()
	
	;获取实际硬盘列表
	If Not FileExists($sPartAssistExePath) Then
		_FileWriteLog($sLogPath, "失败;获取实际硬盘列表工具路径错误，请反馈至开发人员")
		FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
		Shutdown($SD_SHUTDOWN)
		Exit
	EndIf
	Local $tmpfile = @ScriptDir & "\ConfigFile\TempDiskInfo.txt"
	Local $sCmdStr = $sPartAssistExePath & " /list /out:" & $tmpfile
	RunWait(@ComSpec & " /c " & $sCmdStr, "")
	
	Local $aArray = 0
	_FileReadToArray($tmpfile, $aArray)
	If @error = 0 Then
		_FileWriteLog($sLogPath, "成功;获取实际硬盘列表")
		;FileDelete($tmpfile)
	Else
		_FileWriteLog($sLogPath, "失败;获取实际硬盘列表失败，请反馈至开发人员")
		FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
		Shutdown($SD_SHUTDOWN)
		Exit
	EndIf
	
	Local $iDiskCount = 0
	Local $aTempArray
	Local $sUnit ;TB or GB
	Local $sDiskSpace

	;原规则：过滤U盘和光驱，目前只有"SATA"类型才识别为需要分区的硬盘
	;05-09修改规则，由于不识别 m.2 接口，先修改成黑名单规则，排除 USB、Virtual、FileBackedVirtual 接口
	Local $aInterfaceArray = ["USB", "Virtual", "FileBackedVirtual"]
	Local $bInBlack = False
	Local $sBUSTYPE = ""
	
	For $i = 5 To $aArray[0]
		
		;获取总线类型
		$sBUSTYPE = DriveGetType($i - 5, $DT_BUSTYPE)
		_FileWriteLog($sLogPath, "成功;获取硬盘" & $i - 5 & "总线类型：" & $sBUSTYPE)
		
		;重置标志量，检测总线类型是否在黑名单内
		$bInBlack = False
		For $b In $aInterfaceArray
			If $b = $sBUSTYPE Then
				$bInBlack = True
				ExitLoop
			EndIf
		Next
		
		;05-09修改规则，由于不识别 m.2 接口，先修改成黑名单规则，排除 USB、Virtual、FileBackedVirtual 接口
		If Not $bInBlack Then
			ReDim $aDiskArray[$iDiskCount + 1][5]
			$aTempArray = StringSplit($aArray[$i], "|", $STR_NOCOUNT)
			$sDiskSpace = StringStripWS($aTempArray[1], $STR_STRIPALL)
			$sUnit = StringRight($sDiskSpace, 2)
			
			$aDiskArray[$iDiskCount][0] = (DriveGetType($i - 5, $DT_SSDSTATUS) = "SSD") ? 1 : 0 ; 是否固态硬盘
			$aDiskArray[$iDiskCount][1] = Number(StringReplace($sDiskSpace, $sUnit, "")) ;实际硬盘大小
			$aDiskArray[$iDiskCount][2] = StringStripWS($aTempArray[2], $STR_STRIPLEADING + $STR_STRIPTRAILING) ;硬盘信息
			$aDiskArray[$iDiskCount][3] = Round($aDiskArray[$iDiskCount][1] * 1.024 * 1.024 * 1.024) ;硬盘厂商标识大小
			$aDiskArray[$iDiskCount][4] = $i - 5 ;硬盘序号
			
			;如果是TB要转化成GB
			Switch $sUnit
				Case "TB"
					$aDiskArray[$iDiskCount][1] = $aDiskArray[$iDiskCount][1] * 1000
					$aDiskArray[$iDiskCount][3] = $aDiskArray[$iDiskCount][3] * 1000
				Case "GB"
				Case Else
					_FileWriteLog($sLogPath, "失败;硬盘大小识别出现异常，请反馈至开发人员：" & $sDiskSpace)
					FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
					Shutdown($SD_SHUTDOWN)
					Exit
			EndSwitch
			
			$iDiskCount += 1
		EndIf
	Next

EndFunc   ;==>_Get_DiskInfo


;==========================================================================
; 函数名：_Validate_OrderConfig
; 说明：校验“订单配置文件信息”与本机实际信息是否一致
;~ 		1.硬盘数目校验
;~ 		2.硬盘是不是固态硬盘，硬盘大小对不对
;~ 		3.分区数对不对，如果只有一个硬盘，至少要分两个区(不处理，没有意义，灌装系统只校验与工厂有关硬件有关的信息，基于订单信息是无误的，其它信息留给前台校验，这种订单就不能下)
;~ 		4.分区大小合不合理，C盘不小于20G，D盘不小于30G(用于存放系统还原镜像文件)(不处理)
;~ 关于订单中硬盘列表和实际装机中硬盘列表匹配的问题，目前由于无法唯一标识一块硬盘，所以在匹配的时候，
;~ 是采用硬盘大小和是否固态硬盘两个条件来标识一块硬盘，可能会存在风险
; 参数：无
; 返回值：无
;==========================================================================
Func _Validate_OrderConfig()
	_FileWriteLog($sLogPath, "------3.校验订单配置文件*开始------")
	;1.订单硬盘数目校验
	Local $iHDCount = $aBasicInfoArray[3][1]
	If $iHDCount <> UBound($aHDInfoArray) Then
		_FileWriteLog($sLogPath, "失败;订单基本信息中硬盘数目：" & $iHDCount & " 与硬盘分区信息中硬盘数目：" & UBound($aHDInfoArray) & " 不一致，请联系MES相关人员")
		FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
		Shutdown($SD_SHUTDOWN)
		Exit
	Else
		_FileWriteLog($sLogPath, "成功;订单基本信息中硬盘数目：" & $iHDCount & " 与硬盘分区信息中硬盘数目一致")
	EndIf
	
	;2.获取实际硬盘列表
	_Get_DiskInfo()
	;_ArrayDisplay($aDiskArray)
	
	;3.实际硬盘数目校验
	If $iHDCount <> UBound($aDiskArray) Then
		_FileWriteLog($sLogPath, "失败;订单基本信息中硬盘数目：" & $iHDCount & " 与实际检测到的硬盘数目：" & UBound($aDiskArray) & " 不一致，请联系MES相关人员")
		FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
		Shutdown($SD_SHUTDOWN)
		Exit
	Else
		_FileWriteLog($sLogPath, "成功;订单基本信息中硬盘数目：" & $iHDCount & " 与实际检测到的硬盘数目一致")
	EndIf
	
	;4.分区数目校验，本工具目前最多只能分8个区
	Local $iStartLetter = 0
	
	For $i = 0 To $iHDCount - 1
		$iStartLetter += ($aHDInfoArray[$i])[2]
	Next
	
	If $iStartLetter > 8 Then
		_FileWriteLog($sLogPath, "失败;分区总数：" & $iStartLetter & " 超过范围，本工具目前最多只能分8个区，请联系MES相关人员")
		FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
		Shutdown($SD_SHUTDOWN)
		Exit
	EndIf
	
	;5.硬盘是不是固态硬盘，硬盘大小对不对
	Local $bFlag ;是否存在该硬盘标志量
	For $i = 0 To $iHDCount - 1
		$bFlag = False
		For $j = $i To $iHDCount - 1
			If $aDiskArray[$i][0] = ($aHDInfoArray[$j])[0] And $aDiskArray[$i][3] = ($aHDInfoArray[$j])[1] Then
				;如果顺序不等，交换顺序达到和实际硬盘顺序一致
				If $i <> $j Then
					_ArraySwap($aHDInfoArray, $i, $j)
					_FileWriteLog($sLogPath, "成功;交换分区规则配置文件中硬盘顺序" & $i & "和" & $j)
				EndIf
				
				;增加一列：硬盘序号
				_ArrayInsert($aHDInfoArray[$i], 0, $aDiskArray[$i][4])
				
				;设置是否检测到该硬盘标志
				$bFlag = True
				_FileWriteLog($sLogPath, "成功;实际硬盘" & $i & "匹配到分区规则配置文件中硬盘，硬盘大小：" & $aDiskArray[$i][3] & "GB")
				ExitLoop
			EndIf
		Next

		;根据 $bFlag 来判断是否检测到该硬盘
		If Not $bFlag Then
			_FileWriteLog($sLogPath, "失败;实际硬盘" & $i & "没有匹配到分区规则配置文件中硬盘，硬盘大小：" & $aDiskArray[$i][3] & "GB，请联系MES相关人员")
			FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
			Shutdown($SD_SHUTDOWN)
			Exit
		EndIf
	Next
	
;~ 	For $i = 0 To UBound($aHDInfoArray) - 1
;~ 		_ArrayDisplay($aHDInfoArray[$i])
;~ 	Next
	
	_FileWriteLog($sLogPath, "------3.校验订单配置文件*完成------")
	_FileWriteLog($sLogPath, "==============================================================================================")
	FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
EndFunc   ;==>_Validate_OrderConfig


;==========================================================================
; 函数名：_ReadImagePath
; 说明：获取镜像路径
; 参数：无
; 返回值：无
;==========================================================================
Func _ReadImagePath()
	
	_FileWriteLog($sLogPath, "------4.获取镜像路径*开始------")
	
	;检查镜像配置文件是否存在
	Local Const $sFilePath = $sShareMapPath & "image_config.ini"
	If FileExists($sFilePath) Then
		_FileWriteLog($sLogPath, "成功;检查镜像配置文件是否存在")
	Else
		_FileWriteLog($sLogPath, "失败;镜像配置文件image_config.ini不存在，请反馈至开发人员")
		FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
		Shutdown($SD_SHUTDOWN)
		Exit
	EndIf
	
	;读取FTP服务器列表，存储到全局变量 $aServerArray
	$aServerArray = IniReadSection($sFilePath, "DownloadServer")
	If @error Then
		_FileWriteLog($sLogPath, "失败;读取FTP服务器列表失败，请反馈至开发人员")
		FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
		Shutdown($SD_SHUTDOWN)
		Exit
	Else
		_FileWriteLog($sLogPath, "成功;读取FTP服务器列表")
	EndIf
	
	;读取镜像路径，操作系统类型做参数
	$sImagePath = IniRead($sFilePath, $aBasicInfoArray[2][1], "path", "Error")

	If $sImagePath = "Error" Then
		_FileWriteLog($sLogPath, "失败;读取镜像路径失败，请反馈至开发人员")
		FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
		Shutdown($SD_SHUTDOWN)
		Exit
	Else
		_FileWriteLog($sLogPath, "成功;读取镜像路径：" & $sImagePath)
	EndIf
	
	;获取镜像文件后缀名
	Local $aExtArray = StringRegExp($sImagePath, '[^\.]+$', 1, 1)
	$sExt = $aExtArray[0]
	_FileWriteLog($sLogPath, "成功;获取镜像文件后缀名：" & $sExt)
	
	
	_FileWriteLog($sLogPath, "------4.获取镜像路径*完成------")
	_FileWriteLog($sLogPath, "==============================================================================================")
	FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
	
EndFunc   ;==>_ReadImagePath

