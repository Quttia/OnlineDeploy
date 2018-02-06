#cs -----------------------------------------------------------------------

	Au3版本:	3.3.14.2
	脚本作者:
	脚本功能:	1.获取实际硬盘列表，生成查找关键字
	~			2.读取分区规则配置文件，通过关键字查找到对应的分区规则
	~			3.校验分区规则是否可行
	更新日志:	2017.10.26---------------创建文件

#ce -----------------------------------------------------------------------


;==========================================================================
; 函数名：_Get_DiskInfo
; 说明：获取实际硬盘列表，生成查找关键字
; 参数：无
; 返回值：无
;==========================================================================
Func _Get_DiskInfo()
	
	_FileWriteLog($sLogPath, "------3.读取分区规则*开始------")
	
	;获取实际硬盘列表
	If Not FileExists($sPartAssistExePath) Then
		_FileWriteLog($sLogPath, "失败;获取实际硬盘列表工具路径错误，请反馈至开发人员")
		FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
		DirCopy($sLogDirPath, $sServerLogDirPath, $FC_OVERWRITE)
		;MsgBox($MB_OK + $MB_ICONERROR, "Error", "Failed To Get Disk Partition Tools Path")
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
		_FileWriteLog($sLogPath, "失败;获取实际硬盘列表")
		FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
		DirCopy($sLogDirPath, $sServerLogDirPath, $FC_OVERWRITE)
		;MsgBox($MB_OK + $MB_ICONERROR, "Error", "Failed To Get Disk Info List")
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
	
	;检测是否存在硬盘
	If $aArray[0] <= 5 Then
		_FileWriteLog($sLogPath, "失败;未检测到要拷的M.2盘，请确认硬盘是否正确安装")
		FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
		DirCopy($sLogDirPath, $sServerLogDirPath, $FC_OVERWRITE)
		Exit
	EndIf

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
			$aTempArray = StringSplit($aArray[$i], "|", $STR_NOCOUNT)
			
			;镜像盘加入黑名单，不参与分区
			If $sImageDiskNo = $i - 5 Then
				_FileWriteLog($sLogPath, "成功;当前硬盘序号和镜像盘序号相同，不参与分区")
				ContinueLoop
			Else
				_FileWriteLog($sLogPath, "成功;当前硬盘序号：" & $i - 5 & "和镜像盘序号不同，参与分区")
			EndIf
			
			$sDiskSpace = StringStripWS($aTempArray[1], $STR_STRIPALL)
			$sUnit = StringRight($sDiskSpace, 2)
			
			ReDim $aDiskArray[$iDiskCount + 1][5]
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
					DirCopy($sLogDirPath, $sServerLogDirPath, $FC_OVERWRITE)
					;MsgBox($MB_OK + $MB_ICONERROR, "Error", "Failed To Recongnise Current Disk Space, Please Feed Back To Developer")
					Exit
			EndSwitch
			
			$iDiskCount += 1
		EndIf
	Next
	
	;_ArrayDisplay($aDiskArray)
	
	;生成查找关键字数组，为了快速查询，先将关键字排序
	Local $aTempDiskArray = $aDiskArray
	Local $aFastKeyArray[UBound($aDiskArray)]
	
	_ArraySort($aTempDiskArray, 0, 0, 0, 3) ;将 $aDiskArray 顺序排列
	
	For $i = 0 To UBound($aTempDiskArray) - 1
		$aFastKeyArray[$i] = (($aTempDiskArray[$i][0] = "1") ? "SSD" : "HDD") & "-" & $aTempDiskArray[$i][3]
	Next
	
	$aFindKeyArray = _ArrayPermute($aFastKeyArray, ",") ;列出所有可能的排列
	
	FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
	
EndFunc   ;==>_Get_DiskInfo


;==========================================================================
; 函数名：_Read_PartitionConfig
; 说明：获取存储在本地的分区规则配置文件信息，存储到 $aHDInfoArray
; 参数：无
; 返回值：无
;==========================================================================
Func _Read_PartitionConfig()

	;检查分区规则配置文件是否存在
	Local Const $sConfigFilePath = $sShareMapPath & "PartitionRule.ini"
	If FileExists($sConfigFilePath) Then
		_FileWriteLog($sLogPath, "成功;检查分区规则文件是否存在")
	Else
		_FileWriteLog($sLogPath, "失败;分区规则配置文件不存在")
		FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
		DirCopy($sLogDirPath, $sServerLogDirPath, $FC_OVERWRITE)
		;MsgBox($MB_OK + $MB_ICONERROR, "Error", "Failed to Detect The Partition Config File")
		Exit
	EndIf

	;根据查找关键字数组，读取分区规则配置文件
	Local $aRawHDInfoArray
	Local $bFlag = True
	
	For $i = 1 To $aFindKeyArray[0]
		$aRawHDInfoArray = IniReadSection($sConfigFilePath, $aFindKeyArray[$i])
		If @error Then
			_FileWriteLog($sLogPath, "重试;分区规则配置文件中找不到对应的分区规则：[" & $aFindKeyArray[$i] & "]")
		Else
			_FileWriteLog($sLogPath, "成功;读取到分区规则配置文件中对应的分区规则：[" & $aFindKeyArray[$i] & "]")
			$bFlag = False
			ExitLoop
		EndIf
	Next
	
	If $bFlag Then
		_FileWriteLog($sLogPath, "失败;分区规则配置文件中找不到对应的分区规则：[" & $aFindKeyArray[1] & "]")
		FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
		DirCopy($sLogDirPath, $sServerLogDirPath, $FC_OVERWRITE)
		;MsgBox($MB_OK + $MB_ICONERROR, "Error", "Failed To Find The Rule : [" & $aFindKeyArray[1] & "] In The Partition Config File, Please Add It")
		Exit
	EndIf
	
	;存储为一个一维数组，注意不是二维的，注意取值加括号：MsgBox(0,0,($aTempArray[1])[1])
	Local $iCount = $aRawHDInfoArray[0][0]
	Local $aTempArray[$iCount]
	For $i = 1 To $iCount
		$aTempArray[$i - 1] = StringSplit($aRawHDInfoArray[$i][1], ",", $STR_NOCOUNT) ; 禁用返回表示元素数量的第一个元素 - 方便使用基于 0 开始的数组.
	Next
	$aHDInfoArray = $aTempArray
	
	FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)

EndFunc   ;==>_Read_PartitionConfig


;==========================================================================
; 函数名：_Validate_OrderConfig
; 说明：校验读取的分区规则是否有误，按照机器硬盘顺序重新组合分区规则
; 参数：无
; 返回值：无
;==========================================================================
Func _Validate_OrderConfig()

	;1.实际硬盘数目校验
	Local $iHDCount = UBound($aHDInfoArray)
	If $iHDCount <> UBound($aDiskArray) Then
		_FileWriteLog($sLogPath, "失败;分区规则配置文件中硬盘数目：" & $iHDCount & " 与实际检测到的硬盘数目：" & UBound($aDiskArray) & " 不一致")
		FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
		DirCopy($sLogDirPath, $sServerLogDirPath, $FC_OVERWRITE)
		;MsgBox($MB_OK + $MB_ICONERROR, "Error", "Disk Count In Partition Config File : " & $iHDCount & " Discord WIth Which In Reality ：" & UBound($aDiskArray))
		Exit
	Else
		_FileWriteLog($sLogPath, "成功;分区规则配置文件中硬盘数目：" & $iHDCount & " 与实际检测到的硬盘数目一致")
	EndIf
	
	;2.分区数目校验，本工具目前最多只能分8个区
	Local $iStartLetter = 0
	
	For $i = 0 To $iHDCount - 1
		$iStartLetter += ($aHDInfoArray[$i])[2]
	Next
	
	If $iStartLetter > 8 Then
		_FileWriteLog($sLogPath, "失败;分区总数：" & $iStartLetter & " 超过范围，本工具目前最多只能分8个区")
		FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
		DirCopy($sLogDirPath, $sServerLogDirPath, $FC_OVERWRITE)
		;MsgBox($MB_OK + $MB_ICONERROR, "Error", "Partition Total Count : " & $iStartLetter & " Out Of Range, Only Support 8 Partition At Most")
		Exit
	EndIf

	;3.硬盘是不是固态硬盘，硬盘大小对不对
	Local $bFlag ;是否存在该硬盘标志量
	For $i = 0 To $iHDCount - 1
		$bFlag = False
		For $j = $i To $iHDCount - 1
			If $aDiskArray[$i][0] = ($aHDInfoArray[$j])[0] And $aDiskArray[$i][3] = ($aHDInfoArray[$j])[1] Then
				;如果顺序不等，将换顺序达到和实际硬盘顺序一致
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
			_FileWriteLog($sLogPath, "失败;实际硬盘" & $i & "没有匹配到分区规则配置文件中硬盘，硬盘大小：" & $aDiskArray[$i][3] & "GB")
			FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
			DirCopy($sLogDirPath, $sServerLogDirPath, $FC_OVERWRITE)
			;MsgBox($MB_OK + $MB_ICONERROR, "Error", "Actual Disk " & $i & " Failed To Match It In The Partition Config File, Disk Space : " & $aDiskArray[$i][3] & "GB")
			Exit
		EndIf
	Next
	
	_FileWriteLog($sLogPath, "------3.读取分区规则*结束------")
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
	
	_FileWriteLog($sLogPath, "------2.获取镜像路径*开始------")
	
	;检查镜像配置文件是否存在
	Local Const $sFilePath = $sShareMapPath & "image_config.ini"
	If FileExists($sFilePath) Then
		_FileWriteLog($sLogPath, "成功;检查镜像配置文件是否存在")
	Else
		_FileWriteLog($sLogPath, "失败;镜像配置文件image_config.ini不存在，请反馈至开发人员")
		FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
		DirCopy($sLogDirPath, $sServerLogDirPath, $FC_OVERWRITE)
		;Shutdown($SD_SHUTDOWN)
		Exit
	EndIf
	
	;读取镜像路径，操作系统类型做参数
	$sImagePath = IniRead($sFilePath, "ImagePath", "path", "Error")

	If $sImagePath = "Error" Then
		_FileWriteLog($sLogPath, "失败;读取镜像路径失败，请反馈至开发人员")
		FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
		DirCopy($sLogDirPath, $sServerLogDirPath, $FC_OVERWRITE)
		;Shutdown($SD_SHUTDOWN)
		Exit
	Else
		_FileWriteLog($sLogPath, "成功;读取镜像路径：" & $sImagePath)
	EndIf
	
	;获取镜像文件后缀名
	Local $aExtArray = StringRegExp($sImagePath, '[^\.]+$', 1, 1)
	$sExt = $aExtArray[0]
	_FileWriteLog($sLogPath, "成功;获取镜像文件后缀名：" & $sExt)
	
	;获取镜像文件名
	Local $aImageNameArray = StringSplit($sImagePath, "/")
	$sImageName = $aImageNameArray[$aImageNameArray[0]]
	_FileWriteLog($sLogPath, "成功;获取镜像文件名：" & $sImageName)
	
	;检查镜像文件，获取镜像路径
	_Get_ImagePath()
	
	_FileWriteLog($sLogPath, "------2.获取镜像路径*完成------")
	_FileWriteLog($sLogPath, "==============================================================================================")
	FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
	
EndFunc   ;==>_ReadImagePath


;==========================================================================
; 函数名：_Get_ImagePath
; 说明：获取镜像路径
; 参数：无
; 返回值：无
;==========================================================================
Func _Get_ImagePath()
	
	;获取所有驱动器
	Local $aDriveArray = DriveGetDrive($DT_ALL)
	If @error Then
		_FileWriteLog($sLogPath, "失败;获取驱动器数组失败，请联系IT人员")
		FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
		DirCopy($sLogDirPath, $sServerLogDirPath, $FC_OVERWRITE)
		Exit
	Else
		;如果没有检测到驱动器
		If $aDriveArray[0] = 0 Then
			_FileWriteLog($sLogPath, "失败;没有检测到镜像盘，请检查主板上是否接有镜像盘")
			Exit
		EndIf
		
		;检查是否有镜像文件
		Local $bExistsImage = False
		For $i = 1 To $aDriveArray[0]
			$sDownloadImagePath = $aDriveArray[$i] & "\" & $sImageName
			If FileExists($sDownloadImagePath) Then
				$bExistsImage = True
				_FileWriteLog($sLogPath, "成功;检测到目标镜像：" & $sDownloadImagePath)
				
				;获得镜像硬盘序号
				$sImageDiskNo = _GetDiskNumberForDrive($aDriveArray[$i])
				If @error Then
					_FileWriteLog($sLogPath, "失败;获得镜像硬盘序号，请联系IT人员")
					FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
					DirCopy($sLogDirPath, $sServerLogDirPath, $FC_OVERWRITE)
					Exit
				Else
					_FileWriteLog($sLogPath, "成功;获取目标镜像硬盘序号：" & $sImageDiskNo)
				EndIf
				
				ExitLoop
			EndIf
		Next
		
		If Not $bExistsImage Then
			_FileWriteLog($sLogPath, "失败;没有检测到目标镜像：" & $sImageName & "，请联系镜像维护人员")
			FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
			DirCopy($sLogDirPath, $sServerLogDirPath, $FC_OVERWRITE)
			Exit
		EndIf
	EndIf
	
EndFunc   ;==>_Get_ImagePath


;==========================================================================
; 函数名：_GetDiskNumberForDrive
; 说明：根据驱动器卷号获得硬盘序号
; 参数：驱动器卷号
; 返回值：硬盘序号
;==========================================================================
Func _GetDiskNumberForDrive($sDriveLetter)

	Local $a_hCall = DllCall("kernel32.dll", "hwnd", "CreateFile", _
			"str", "\\.\" & $sDriveLetter, _ ; logical drive
			"dword", 0, _
			"dword", 0, _
			"ptr", 0, _
			"dword", 3, _ ; OPEN_EXISTING
			"dword", 128, _ ; FILE_ATTRIBUTE_NORMAL
			"ptr", 0)

	If @error Then
		Return SetError(1, 0, -1) ; your system is very old. Do something.
	EndIf

	If $a_hCall[0] = -1 Then
		Return SetError(2, 0, -1) ; non-existing drive
	EndIf

	Local $hDevice = $a_hCall[0]

	Local $tIOCTL_STORAGE_GET_DEVICE_NUMBER = DllStructCreate("dword DeviceType;" & _
			"dword DeviceNumber;" & _
			"int PartitionNumber")

	Local $a_iCall = DllCall("kernel32.dll", "int", "DeviceIoControl", _
			"hwnd", $hDevice, _
			"dword", 0x2D1080, _ ; IOCTL_STORAGE_GET_DEVICE_NUMBER
			"ptr", 0, _
			"dword", 0, _
			"ptr", DllStructGetPtr($tIOCTL_STORAGE_GET_DEVICE_NUMBER), _
			"dword", DllStructGetSize($tIOCTL_STORAGE_GET_DEVICE_NUMBER), _
			"dword*", 0, _
			"ptr", 0)

	If @error Or Not $a_hCall[0] Then
		DllCall("kernel32.dll", "int", "CloseHandle", "hwnd", $hDevice)
		Return SetError(3, 0, -1) ; DeviceIoControl failed for some reason
	EndIf

	DllCall("kernel32.dll", "int", "CloseHandle", "hwnd", $hDevice)

	If DllStructGetData($tIOCTL_STORAGE_GET_DEVICE_NUMBER, "DeviceType") = 7 Then ; FILE_DEVICE_DISK
		Return SetError(0, 0, DllStructGetData($tIOCTL_STORAGE_GET_DEVICE_NUMBER, "DeviceNumber"))
	EndIf

	Return SetError(4, 0, -1) ; not a disk partition

EndFunc   ;==>_GetDiskNumberForDrive

