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
	
	_FileWriteLog($sLogPath, "成功;检测到当前硬盘需要进行GPT分区")
	_Partition_Disk_GPT() ;gpt分区
	
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
	Local $iStartLetter = 1
	Local $iCount = UBound($aHDInfoArray)
	Local $iSSDNum = -1
	
	;首先删除所有硬盘分区
	For $i = 0 To $iCount - 1
		$sPartitionScript &= "select disk " & ($aHDInfoArray[$i])[0] & @CRLF
		$sPartitionScript &= "clean" & @CRLF
		$sPartitionScript &= "convert gpt" & @CRLF & @CRLF
	Next
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
	
	;进行分区
		_FileWriteLog($sLogPath, "成功;开始对第" & ($aHDInfoArray[$i])[0] & "块硬盘进行分区")
		_Partition_GPT_Detail($aHDInfoArray[$i], $iStartLetter)
	
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
