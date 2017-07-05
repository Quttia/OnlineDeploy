#Region
#AccAu3Wrapper_Icon=logo.ico								 ;程序图标
#AccAu3Wrapper_UseX64=y										 ;是否编译为64位程序(y/n)注：这个地方一定要改，否则调用comspec会出错
#AccAu3Wrapper_OutFile=										 ;输出的Exe名称
#AccAu3Wrapper_OutFile_x64=									 ;64位输出的Exe名称
#AccAu3Wrapper_UseUpx=n										 ;是否使用UPX压缩(y/n) 注:开启压缩极易引起误报问题
#AccAu3Wrapper_Res_Comment=									 ;程序注释
#AccAu3Wrapper_Res_Description=								 ;程序描述
#AccAu3Wrapper_Res_Fileversion=1.0.0.319
#AccAu3Wrapper_Res_FileVersion_AutoIncrement=y				 ;自动更新版本 y/n/p=自动/不自动/询问
#AccAu3Wrapper_Res_ProductVersion=1.0						 ;产品版本
#AccAu3Wrapper_Res_Language=2052							 ;资源语言, 英语=2057/中文=2052
#AccAu3Wrapper_Res_LegalCopyright=							 ;程序版权
#AccAu3Wrapper_Res_RequestedExecutionLevel=					 ;请求权限: None/asInvoker/highestAvailable/requireAdministrator
#AccAu3Wrapper_Run_Tidy=y									 ;编译前自动整理脚本(y/n)
#Obfuscator_Parameters=/cs=1 /cn=1 /cf=1 /cv=1 /sf=1 /sv=1	 ;脚本加密参数: 0/1不加密/加密, /cs字符串 /cn数字 /cf函数名 /cv变量名 /sf精简函数 /sv精简变量
#AccAu3Wrapper_DBSupport=y									 ;使字符串加密支持双字节字符(y/n) <- 可对中文字符等实现字符串加密
#AccAu3Wrapper_AntiDecompile=y								 ;是否启用防反功能(y/n) <- 简单防反, 用于应对傻瓜式反编译工具
;#NoTrayIcon
#AutoIt3Wrapper_Change2CUI=y
#EndRegion

#cs -----------------------------------------------------------------------

	Au3版本:	3.3.14.2
	脚本作者:
	脚本功能:	批量灌装系统
	更新日志:	2017.05.24---------------创建文件

#ce -----------------------------------------------------------------------

#include <MsgBoxConstants.au3>
#include <StringConstants.au3>
#include <AutoItConstants.au3>
#include <FileConstants.au3>
#include <File.au3>
#include <Array.au3>

;注：全局变量必须声明在 #include自定义的函数 前面

Global $hDeployTimer ;计时器
Global $sMac ; 物理地址
Global $sShareMapPath ;服务器映射地址
Global $sUser ;服务器用户名
Global $sPsd ;服务器密码
Global $sLogPath ;本地日志文件路径
Global Const $sLogDirPath = @ScriptDir & "\ConfigFile" ;本地日志文件路径
Global $sServerLogPath ;服务器日志文件路径
Global $sServerLogDirPath ;服务器日志文件夹路径
Global $aBasicInfoArray ;二维数组，存储“订单基本信息”
Global $aHDInfoArray ;一维数组，元素也为一维数组，从配置文件读取的“硬盘分区信息”
Global $aDiskArray = [] ;实际硬盘列表
;Global Const $sPartAssistExePath = @ScriptDir & "\PETools\PACMDforUSB\PartAssist.exe" ;分区工具路径
Global Const $sPartAssistExePath = @ScriptDir & "\PETools\PA_WinPE_x64\PartAssist.exe" ;分区工具路径

Global Const $sCleanScriptPath = @ScriptDir & "\ConfigFile\CleanDiskScript.bat" ;删除分区脚本文件路径
Global Const $sPartScriptPath = @ScriptDir & "\ConfigFile\DiskPartitionScript.bat" ;分区脚本文件路径
Global Const $sImageScriptPath = @ScriptDir & "\ConfigFile\ApplyImage.bat" ;还原镜像脚本
Global Const $sHidePartScriptPath = @ScriptDir & "\ConfigFile\HidePartitionScript.bat" ;隐藏分区脚本

Global $sPartitionScript = "" ;分区脚本
Global $iSystem = 0 ;系统盘硬盘序号
Global $iRecovery = 0 ;还原分区序号

Global $aServerArray ;下载服务器列表
Global $sImagePath ;镜像路径
Global $sExt ;镜像后缀名，用于判断镜像还原方式
Global Const $sDownloadDrive = "D" ;下载镜像所在盘符
Global $sDownloadImagePath ;下载镜像到本地的地址

#include ".\MyInclude\InitialiseDeploy.au3"
#include ".\MyInclude\ReadOrderConfig.au3"
#include ".\MyInclude\DiskPartition.au3"
#include ".\MyInclude\DownloadRecovery.au3"

_Main()

Func _Main()
	
	$hDeployTimer = TimerInit() ;开始计时
	
	_InitialiseDeploy() ;初始化程序运行环境
	
	_Read_OrderConfig() ;读取订单配置文件
	
	_Validate_OrderConfig() ;校验订单配置文件
	
	_ReadImagePath() ;读取镜像路径，判断分区类型
	
	_Partition_Disk() ;GPT分区或 MBR分区
	
	_DownloadImageByAria2c() ;下载镜像
	
	_RecoveryImage() ;还原镜像
	
EndFunc   ;==>_Main
