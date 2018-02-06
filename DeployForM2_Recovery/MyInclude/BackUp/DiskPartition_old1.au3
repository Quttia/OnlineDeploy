#cs -----------------------------------------------------------------------

	Au3版本:	3.3.14.2
	脚本作者:
	脚本功能:	硬盘分区，包含 GPT 和 MBR 两种分区方式
	更新日志:	2017.10.26---------------创建文件

#ce -----------------------------------------------------------------------


;==========================================================================
; 函数名：_Partition_Disk
; 说明：根据读取的“硬盘分区信息”进行分区
; 参数：无
; 返回值：无
;==========================================================================
Func _Partition_Disk()
	
	_FileWriteLog($sLogPath, "------4.硬盘分区*开始------")
	_FileWriteLog($sLogPath, "成功;正在分区中，请等待。。。")
	FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
	
	Switch StringLower($sExt)
		Case "wim"
			_FileWriteLog($sLogPath, "成功;检测到当前硬盘需要进行GPT分区")
			_Partition_Disk_GPT() ;gpt分区
		Case "gho"
			_FileWriteLog($sLogPath, "成功;检测到当前硬盘需要进行MBR分区")
			_Partition_Disk_MBR() ;mbr分区
		Case Else
			_FileWriteLog($sLogPath, "失败;无法识别镜像类型后缀名：" & $sExt & "，请反馈至开发人员")
			FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
			DirCopy($sLogDirPath, $sServerLogDirPath, $FC_OVERWRITE)
			;Shutdown($SD_SHUTDOWN)
			Exit
	EndSwitch
	
	_FileWriteLog($sLogPath, "------4.硬盘分区*完成------")
	_FileWriteLog($sLogPath, "==============================================================================================")
	FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
	
EndFunc   ;==>_Partition_Disk


;==========================================================================
; 函数名：_Partition_Disk_GPT
; 说明：GPT分区
; 参数：无
; 返回值：无
;==========================================================================
Func _Partition_Disk_GPT()
	Local $iStartLetter = 0
	Local $iCount = UBound($aHDInfoArray)
	Local $iSSDNum = -1
	
	;首先删除所有硬盘分区，如果镜像盘序号为 0，则删除硬盘 1；反之亦然
		$sPartitionScript &= "select disk " & ($aHDInfoArray[$i])[0] & @CRLF
		$sPartitionScript &= "clean" & @CRLF
		$sPartitionScript &= "convert gpt" & @CRLF & @CRLF
	$sPartitionScript &= "exit" & @CRLF
	
	;将删除分区命令写入脚本文件中
	Local $hFileOpen = FileOpen($sCleanScriptPath, $FO_OVERWRITE + $FO_CREATEPATH)
	If $hFileOpen = -1 Then
		_FileWriteLog($sLogPath, "失败;写入删除分区脚本失败，请反馈至开发人员")
		FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
		DirCopy($sLogDirPath, $sServerLogDirPath, $FC_OVERWRITE)
		;Shutdown($SD_SHUTDOWN)
		Exit
	Else
		_FileWriteLog($sLogPath, "成功;写入删除分区脚本成功")
	EndIf
	
	FileWrite($hFileOpen, $sPartitionScript)
	FileClose($hFileOpen)
	
	;执行删除分区脚本，必须与后面分区脚本分开执行，保证程序可以重复运行
	RunWait(@ComSpec & " /c diskpart /s " & $sCleanScriptPath, "")
	_FileWriteLog($sLogPath, "成功;执行删除分区脚本成功")
	
	;清空脚本
	$sPartitionScript = ""
	
	;检测保留分区是否被占用
	Local $aReserveArray = ["W", "R", "S"]
	
	For $s In $aReserveArray
		If DriveStatus($s & ":\") = "READY" Then
			_FileWriteLog($sLogPath, "失败;保留分区：" & $s & "被占用，请反馈至开发人员")
			FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
			DirCopy($sLogDirPath, $sServerLogDirPath, $FC_OVERWRITE)
			;Shutdown($SD_SHUTDOWN)
			Exit
		Else
			_FileWriteLog($sLogPath, "成功;保留分区：" & $s & "可用")
		EndIf
	Next
	
	;查找是否有固态硬盘，如果有，则记录硬盘号，并作为系统盘进行分区，分区后退出循环
	For $i = 0 To $iCount - 1
		If ($aHDInfoArray[$i])[1] = 1 Then ;修改$aHDInfoArray需要修改的点
			_FileWriteLog($sLogPath, "成功;检测到第" & ($aHDInfoArray[$i])[0] & "块硬盘是固态硬盘")
			_Partition_GPT_Detail($aHDInfoArray[$i], $iStartLetter)
			$iSSDNum = $i
			$iSystem = ($aHDInfoArray[$i])[0]
			ExitLoop
		EndIf
	Next
	
	;遍历其它硬盘，进行分区
	For $i = 0 To $iCount - 1
		If $i <> $iSSDNum Then
			_FileWriteLog($sLogPath, "成功;开始对第" & ($aHDInfoArray[$i])[0] & "块硬盘进行分区")
			_Partition_GPT_Detail($aHDInfoArray[$i], $iStartLetter)
		EndIf
	Next
	
	;$sPartitionScript &= "list volume" & @CRLF
	$sPartitionScript &= "exit" & @CRLF
	
	;将分区命令写入脚本文件中
	Local $hFileOpen = FileOpen($sPartScriptPath, $FO_OVERWRITE + $FO_CREATEPATH)
	If $hFileOpen = -1 Then
		_FileWriteLog($sLogPath, "失败;读取分区脚本失败，请反馈至开发人员")
		FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
		DirCopy($sLogDirPath, $sServerLogDirPath, $FC_OVERWRITE)
		;Shutdown($SD_SHUTDOWN)
		Exit
	Else
		_FileWriteLog($sLogPath, "成功;读取分区脚本成功")
	EndIf
	
	FileWrite($hFileOpen, $sPartitionScript)
	FileClose($hFileOpen)
	
	;执行分区脚本
	RunWait(@ComSpec & " /c diskpart /s " & $sPartScriptPath, "")
	
EndFunc   ;==>_Partition_Disk_GPT


;==========================================================================
; 函数名：_Partition_Disk_MBR
; 说明：MBR分区
; 参数：无
; 返回值：无
;==========================================================================
Func _Partition_Disk_MBR()
	Local $iStartLetter = 0
	Local $iCount = UBound($aHDInfoArray)
	Local $iSSDNum = -1
	
	;首先删除所有硬盘分区
	For $i = 0 To $iCount - 1
		RunWait(@ComSpec & " /c " & $sPartAssistExePath & " /hd:" & $i & " /del:all /q", "")
		_FileWriteLog($sLogPath, "成功;删除硬盘" & $i & "所有分区")
		RunWait(@ComSpec & " /c " & $sPartAssistExePath & " /init:" & $i, "")
		_FileWriteLog($sLogPath, "成功;将硬盘" & $i & "转换为MBR分区")
	Next
	
	;查找是否有固态硬盘，如果有，则记录硬盘号，并作为系统盘进行分区，分区后退出循环
	For $i = 0 To $iCount - 1
		If ($aHDInfoArray[$i])[1] = 1 Then ;修改$aHDInfoArray需要修改的点
			_FileWriteLog($sLogPath, "成功;检测到第" & ($aHDInfoArray[$i])[0] & "块硬盘是固态硬盘")
			_Partition_MBR_Detail($aHDInfoArray[$i], $iStartLetter)
			$iSSDNum = $i
			ExitLoop
		EndIf
	Next
	
	;遍历其它硬盘，进行分区
	For $i = 0 To $iCount - 1
		If $i <> $iSSDNum Then
			_FileWriteLog($sLogPath, "成功;开始对第" & ($aHDInfoArray[$i])[0] & "块硬盘进行分区")
			_Partition_MBR_Detail($aHDInfoArray[$i], $iStartLetter)
		EndIf
	Next

EndFunc   ;==>_Partition_Disk_MBR


;==========================================================================
; 函数名：_Partition_GPT_Detail
; 说明：GPT分区详细信息
; 参数：“硬盘分区信息”
; 返回值：无
;==========================================================================
Func _Partition_GPT_Detail($aPartArray, ByRef $iStartLetter)
	
	Local $aLetterArray[] = ["W", "D", "E", "F", "G", "H", "I", "J", "K", "L"] ;目前最多分8个区，考虑到 U盘占用盘符，预留两个盘符
	Local $bFlag = ($iStartLetter = 0) ? True : False ;系统盘标识
	Local $iDiskNo = $aPartArray[0] ;硬盘序号
	Local $iPartNum = $aPartArray[3] ;分区数目
	_FileWriteLog($sLogPath, "成功;硬盘" & $iDiskNo & "分区数目：" & $iPartNum)
	
	$sPartitionScript &= "select disk " & $iDiskNo & @CRLF
	
	If $bFlag Then
		$sPartitionScript &= "create partition efi size=100" & @CRLF
		$sPartitionScript &= 'format quick fs=fat32 label="System"' & @CRLF
		$sPartitionScript &= 'assign letter="S"' & @CRLF & @CRLF
		$sPartitionScript &= "create partition msr size=16" & @CRLF & @CRLF
	EndIf
	
	For $i = 0 To $iPartNum - 1
		If $i = $iPartNum - 1 Then
			$sPartitionScript &= "create partition primary" & @CRLF
		Else
			$sPartitionScript &= "create partition primary size=" & $aPartArray[$i + 4] * 1024 & @CRLF
		EndIf
		
		$sPartitionScript &= "format quick fs=ntfs" & (($iStartLetter = 0) ? ' label="Windows"' : "") & @CRLF
		
		;盘符有可能被 U盘占用，分配前先检测
		For $j = $iStartLetter To UBound($aLetterArray)
			If DriveStatus($aLetterArray[$iStartLetter] & ":\") = "READY" Then
				$iStartLetter += 1 ;分区加1
			Else
				ExitLoop
			EndIf
		Next
		
		$sPartitionScript &= 'assign letter="' & $aLetterArray[$iStartLetter] & '"' & @CRLF & @CRLF
		
		$iStartLetter += 1 ;分区加1
		
		If $iStartLetter = UBound($aLetterArray) Then
			_FileWriteLog($sLogPath, "失败;分区总数：" & $iStartLetter & " 超过范围，请反馈至开发人员")
			FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
			DirCopy($sLogDirPath, $sServerLogDirPath, $FC_OVERWRITE)
			;Shutdown($SD_SHUTDOWN)
			Exit
		EndIf
	Next
	
	If $bFlag Then
		$sPartitionScript &= "shrink minimum=1024" & @CRLF
		$sPartitionScript &= "create partition primary" & @CRLF
		$sPartitionScript &= 'format quick fs=ntfs label="Recovery"' & @CRLF
		$sPartitionScript &= 'assign letter="R"' & @CRLF
		$sPartitionScript &= 'set id="de94bba4-06d1-4d40-a16a-bfd50179d6ac"' & @CRLF
		$sPartitionScript &= "gpt attributes=0x8000000000000001" & @CRLF & @CRLF
		
		;记录还原分区序号
		$iRecovery = 3 + $iPartNum
	EndIf

EndFunc   ;==>_Partition_GPT_Detail


;==========================================================================
; 函数名：_Partition_MBR_Detail
; 说明：MBR分区详细信息
; 参数：“硬盘分区信息”
; 返回值：无
;==========================================================================
Func _Partition_MBR_Detail($aPartArray, ByRef $iStartLetter)
	Local $sCmdStr = ""
	Local $aLetterArray[] = ["C", "D", "E", "F", "G", "H", "I", "J", "K", "L"] ;目前最多分8个区，考虑到 U盘占用盘符，预留两个盘符
	Local $bFlag = ($iStartLetter = 0) ? True : False ;系统盘标识
	Local $iDiskNo = $aPartArray[0] ;硬盘序号
	Local $iPartNum = $aPartArray[3] ;分区数目，修改$aHDInfoArray需要修改的点
	_FileWriteLog($sLogPath, "成功;硬盘" & $iDiskNo & "分区数目：" & $iPartNum)
	
	If $bFlag Then
		RunWait(@ComSpec & " /c " & $sPartAssistExePath & " /rebuildmbr:" & $iDiskNo & " /mbrtype:2", "")
		_FileWriteLog($sLogPath, "成功;重建MBR主引导记录") ;部分主板如技嘉需要重建MBR才能启动
	EndIf
	
	;循环读取分区信息，并进行分区操作：分区规则：
	;1. 如果当前硬盘只分一个区：
	;1.1 如果当前分区是系统盘时，设置此分区为主分区和活动分区，自动分区；
	;1.2 否则，设置分区为主分区，自动分区；
	;2. 如果当前硬盘不止一个分区：
	;2.1 如果当前分区是的第一个分区时：
	;2.1.1 如果当前硬盘是系统盘：设置此分区为主分区和活动分区，分区大小由读取的硬盘分区信息确定
	;2.1.2 否则：设置此分区为主分区，分区大小由读取的硬盘分区信息确定
	;2.2 如果是当前分区的最后一块分区时，设置此分区为扩展分区，自动分区；
	;2.3 否则，设置此分区为扩展分区，分区大小由读取的硬盘分区信息确定
	;3. 下轮循环
	For $i = 0 To $iPartNum - 1
		;盘符有可能被 U盘占用，分配前先检测
		For $j = $iStartLetter To UBound($aLetterArray)
			If DriveStatus($aLetterArray[$iStartLetter] & ":\") = "READY" Then
				$iStartLetter += 1 ;分区加1
			Else
				ExitLoop
			EndIf
		Next
		
		If $iPartNum = 1 Then
			If $iStartLetter = 0 Then
				$sCmdStr = $sPartAssistExePath & " /hd:" & $iDiskNo & " /cre /pri /size:auto /align /fs:ntfs /act /letter:" & $aLetterArray[$iStartLetter]
			Else
				$sCmdStr = $sPartAssistExePath & " /hd:" & $iDiskNo & " /cre /pri /size:auto /align /fs:ntfs /letter:" & $aLetterArray[$iStartLetter]
			EndIf
			RunWait(@ComSpec & " /c " & $sCmdStr, "")
			_Check_Partition($aLetterArray[$iStartLetter], "当前硬盘只分一个区", 0)
		Else
			If $i = 0 Then
				If $iStartLetter = 0 Then
					$sCmdStr = $sPartAssistExePath & " /hd:" & $iDiskNo & " /cre /pri /size:" & $aPartArray[4] & "GB /align /fs:ntfs /act /letter:" & $aLetterArray[$iStartLetter] ;修改$aHDInfoArray需要修改的点
				Else
					$sCmdStr = $sPartAssistExePath & " /hd:" & $iDiskNo & " /cre /pri /size:" & $aPartArray[4] & "GB /align /fs:ntfs /letter:" & $aLetterArray[$iStartLetter] ;修改$aHDInfoArray需要修改的点
				EndIf
				RunWait(@ComSpec & " /c " & $sCmdStr, "")
				_Check_Partition($aLetterArray[$iStartLetter], "主分区", $aPartArray[4])
			ElseIf $i = $iPartNum - 1 Then
				$sCmdStr = $sPartAssistExePath & " /hd:" & $iDiskNo & " /cre /size:auto /align /fs:ntfs /letter:" & $aLetterArray[$iStartLetter]
				RunWait(@ComSpec & " /c " & $sCmdStr, "")
				_Check_Partition($aLetterArray[$iStartLetter], "逻辑分区", 0)
			Else
				$sCmdStr = $sPartAssistExePath & " /hd:" & $iDiskNo & " /cre /size:" & $aPartArray[$i + 4] & "GB /align /fs:ntfs /letter:" & $aLetterArray[$iStartLetter] ;修改$aHDInfoArray需要修改的点
				RunWait(@ComSpec & " /c " & $sCmdStr, "")
				_Check_Partition($aLetterArray[$iStartLetter], "逻辑分区", $aPartArray[$i + 4])
			EndIf
		EndIf
		
		$iStartLetter += 1 ;分区加1
		
		If $iStartLetter = UBound($aLetterArray) Then
			_FileWriteLog($sLogPath, "失败;分区总数：" & $iStartLetter & " 超过范围，请反馈至开发人员")
			FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
			DirCopy($sLogDirPath, $sServerLogDirPath, $FC_OVERWRITE)
			;Shutdown($SD_SHUTDOWN)
			Exit
		EndIf
	Next
	
EndFunc   ;==>_Partition_MBR_Detail


;==========================================================================
; 函数名：_Check_Partition
; 说明：检查分区结果
; 参数：分区盘符
; 返回值：成功: 程序继续运行
;　　　　 失败: 程序终止
;==========================================================================
Func _Check_Partition($sLetter, $sMsg, $iSize)
	
	If $iSize = 0 Then
		_FileWriteLog($sLogPath, "成功;" & $sMsg & $sLetter & "盘分区完成，自动大小")
	Else
		_FileWriteLog($sLogPath, "成功;" & $sMsg & $sLetter & "盘分区完成，大小：" & $iSize & "GB")
	EndIf
	
	;可能是时间的问题，导致分区之后无法立即检测到磁盘状态是否为 READY，所以暂时注释掉
	#CS
		Sleep(1000)
		If DriveStatus($sLetter & ":\") = "READY" Then
		If $iSize = 0 Then
		_FileWriteLog($sLogPath, "成功;" & $sMsg & $sLetter & "盘分区完成，自动大小")
		Else
		_FileWriteLog($sLogPath, "成功;" & $sMsg & $sLetter & "盘分区完成，大小：" & $iSize & "GB")
		EndIf
		Else
		_FileWriteLog($sLogPath, "失败;" & $sMsg & $sLetter & "盘分区失败")
		FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE)
		Exit
		EndIf
	#CE

EndFunc   ;==>_Check_Partition
