#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <ListViewConstants.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include<_MSSQL.AU3>
#include <File.au3>
#include<array.au3>
#include <GuiListView.au3>
#include <GuiListBox.au3>
#include <GuiComboBox.au3>
#include <GuiComboBoxEx.au3>
#include <GuiButton.au3>
#include <GuiMenu.au3>
#include <MsgBoxConstants.au3>
#include<_delfile.au3>
Opt("WinTitleMatchMode", 2)
Opt("GUIOnEventMode", False)
Opt("GUICloseOnESC", False)
Opt("MustDeclareVars", True)
Global $Form1,$ListView1,$Button1,$Button2,$Edit1,$Label1,$Label2,$Input1,$nMsg,$AcctInfo,$RDCount,$UFDir,$FileSnap,$LV[1],$W,$H,$BW,$BL
#Region ### START Koda GUI section ### Form=C:\Users\Administrator\Desktop\Form1.kxf
$Form1 = GUICreate("用友账套自动备份工具 Ver 1.0  -by Ranger", 801, 437, 192, 124,BitOR($GUI_SS_DEFAULT_GUI,$WS_MAXIMIZEBOX,$WS_MAXIMIZE,$WS_TABSTOP))
$W = @DesktopWidth*2/3
$H = @DesktopHeight*735/800
$ListView1 = GUICtrlCreateListView("序号|账套号|账套名称|是否备份成功", 0,0, $W, $H)
GUICtrlSendMsg(-1, $LVM_SETCOLUMNWIDTH, 0, ($W-4)*3/20)
GUICtrlSendMsg(-1, $LVM_SETCOLUMNWIDTH, 1, ($W-4)*3/20)
GUICtrlSendMsg(-1, $LVM_SETCOLUMNWIDTH, 2, ($W-4)*9/20)
GUICtrlSendMsg(-1, $LVM_SETCOLUMNWIDTH, 3, ($W-4)*5/20)
;$ListView1_0 = GUICtrlCreateListViewItem("1|2|3", $ListView1)
;GUICtrlSetBkColor($ListView1_0, 0xff0000)
$Button1 = GUICtrlCreateButton("连接数据库", 13 * @DesktopWidth / 15 + 1, $H/30 + 1, 2 * @DesktopWidth / 15 -2, $H/12)
$Button2 = GUICtrlCreateButton("开始备份", 13 * @DesktopWidth / 15 + 1, $H/5 + 1, 2 * @DesktopWidth / 15 -2, $H/12)
GUICtrlSetState(-1,$GUI_DISABLE)
$BW = $W + 1
$BL = @DesktopWidth * 2 / 3 + (@DesktopWidth / 60) + 1

$Edit1 = GUICtrlCreateEdit("",$BW, $H/3 + 2, $W/2 - 2, $H*2/3 -2)
GUICtrlSetData(-1, "")
$Label1 = GUICtrlCreateLabel("数据库未连接", $BL, $H*20/800,  @DesktopWidth/6 - 2, $H /12 -2 )
$Input1 = GUICtrlCreateInput("", $BW, $H*4/15+1 , @DesktopWidth /6, $H/24 -2,BitOR($GUI_SS_DEFAULT_INPUT,$ES_PASSWORD))
$Label2 = GUICtrlCreateLabel("数据库密码:", @DesktopWidth*7 /10 + 2, $H/5 + 1, 2 * @DesktopWidth / 15 -2, $H/24 -2)
GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###

While 1
	$nMsg = GUIGetMsg()
	Switch $nMsg
		Case $GUI_EVENT_CLOSE
			Exit

		Case $Button1
		   _IniListv($ListView1)
		   $UFDir = RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\UFSOFT\UF2000\2.0\Install\CurrentInst", "UFOCONFIGFILE")
		   if $UFDir == "" then exit
			  ;_CleanTmp()
		   ;$FileSnap = _FileListToArray($UFDir,Default,$FLTA_FOLDERS )
		Case $Button2
		   ControlDisable($Form1,"",$Button1)
		   _CleanTmp()
		   _Main()
		   ControlEnable($Form1,"",$Button1)
	EndSwitch
 WEnd

 Func _IniListv($ListView1)
Local $Con,$I
$Con =_MSSQL_Con(".","Sa",GUICtrlRead($Input1),"UFSYSTEM")
$AcctInfo = _MSSQL_GetRecord2($Con,"UA_Account","cAcc_Id,cAcc_Name","where cAcc_Id <998","cAcc_ID")
_MSSQL_End($Con)
$RDCount = UBound($AcctInfo,$UBOUND_ROWS)
if $RDCount < 2 then Exit
   $LV[0] = $RDCount -1
   Dim $LV[$RDCount]
   For $I = 1 TO $RDCount -1
	  ConsoleWrite($I)
	 $LV[$I] = GUICtrlCreateListViewItem($I &"|" & $AcctInfo[$I][0] & "|" & $AcctInfo[$I][1] & "|" & "未更新", $ListView1)
   Next
if @error  then
   Return -1
Else
  GUICtrlSetData($Label1,"已经连接数据库")
  ControlDisable($Form1,"",$Button1)
  ControlEnable($Form1,"",$Button2)
   Return 0
   EndIf
EndFunc

Func _Main()
   ;Step 0,Open dir
   ;===========================================================
       Local Const $sMessage = "请选择一个文件夹"
	   Local $DirArr,$sFileSelectFolder,$SendRootText
   ;===========================================================
    ; Display an open dialog to select a file.
    $sFileSelectFolder = FileSelectFolder($sMessage, "")
    If @error Then
        ; Display the error message.
        MsgBox($MB_SYSTEMMODAL, "", "您取消了选择文件夹.")
		Return 0
	 Else
		;^[a-zA-Z]:(\\([^\\/:*?"<>|\r\n]*))*$
		if $sFileSelectFolder == "" then Return 0
		$DirArr = StringSplit($sFileSelectFolder,"\")
        ConsoleWrite(@LF & $sFileSelectFolder & @LF)
		$SendRootText = $DirARR[1]
	    $DirARR[1] = $DirARR[1] & "\"
		IF (($DirArr[0] == 2) and ($DirArr[2] =="")) Then
		   _ArrayDelete($DirARR,2)
		   $DirARR[0] = 1
		Else
		   $sFileSelectFolder = $sFileSelectFolder & "\"
		EndIf
		$DirARR[0] = $DirARR[0] + 1 ;Inc For ZTXXX To Storage

    EndIf
   ;Step 1
   ;============================================================
   Local $hWnd,$hMain,$t1,$hFile,$t2,$Comboid,$ComboCount
   Local $hLabel,$ListID,$ListCount,$BntID,$I
   Local $accid,$J,$DirIndex,$Hwnd2
   Local $HwndBK,$DriveListID,$DirListID,$BackHwnd
   Local $NoticeText;
   ;============================================================
if ProcessExists("Admin.exe") == 0 then
   MsgBox(0,"出错了~ ","请打开系统管理")
   Exit
EndIf
ConsoleWrite("打开系统管理" &@LF)
WinActivate("T3-用友通标准版10.8plus2〖系统管理〗")
Sleep(250)
if WinWaitActive("T3-用友通标准版10.8plus2〖系统管理〗") == 0 Then
   MsgBox(0,"出错了~","激活系统管理窗口失败")
   Exit
   EndIf
ConsoleWrite("打开系统管理成功" &@LF)
$hWnd = WinGetHandle("T3-用友通标准版10.8plus2〖系统管理〗")
ConsoleWrite("RDCount=" & $RDCount)
;********************************************************************
;********************************************************************
;****************************For to next ****************************
;********************************************************************
;********************************************************************
 For $I = 1 To $RDCount -1
$hMain = _GUICtrlMenu_GetMenu($hWnd)
$t1 = _GUICtrlMenu_GetItemText($hMain, 1)
$hFile = _GUICtrlMenu_GetItemSubMenu($hMain, 1)
$t2 = _GUICtrlMenu_GetItemText($hFile, 4)
WinMenuSelectItem($hWnd, "", $t1, $t2)
WinActivate($Form1)
WinWaitActive($Form1)
WinSetOnTop($Form1,"",1)
Sleep(1000)
GUICtrlSetBkColor($LV[$I], 0xff0000)
Sleep(2000)
WinSetOnTop($Form1,"",0)
WinActivate($hWnd)
WinWaitActive($hWnd)
$Hwnd2 = WinGetHandle("账套输出")
WinActivate($hWnd2)
WinWaitActive($hWnd2)
$Comboid = ControlGetHandle($hWnd2,"","ThunderRT6ComboBox1")

$ComboCount= _GUICtrlComboBox_GetCount($Comboid)

		$accid = $AcctInfo[$I][0]
		$hLabel = "[" & $accid & "]" & $AcctInfo[$I][1]

		ControlFocus($Hwnd2,"",$Comboid)
		Sleep(1000)
		ControlCommand($hWnd2, '', $Comboid, 'SelectString', $hLabel)
		if @error Then Exit
		Sleep(2000)
        $BntID =  ControlGetHandle($hwnd2,"","ThunderRT6CommandButton3")

        ControlCommand($Hwnd2, '', $BntID, "Check", "")
	;Step 2
    WinWaitActive("拷贝进程...")
	WinWaitActive("压缩进程,请等待...")
	;$HwndBK = WinWait("选择备份目标:")
	;Sleep(250)
;WinActivate($HwndBK)
;WinWaitActive($HwndBK)
WinWaitActive("选择备份目标:")
Sleep(1000)
ConsoleWrite("waiting")
$DriveListID = ControlGetHandle($HwndBK,"","ThunderRT6DriveListBox1")

if Not FileExists ($sFileSelectFolder & "ZT" & $accid) THEN
   if not  DirCreate($sFileSelectFolder & "ZT" & $accid) then Exit
   Else
	  Exit
   EndIf
Sleep(2000)
ControlFocus($HwndBK, "", $DriveListID)
 ConsoleWrite($HwndBK)
 Sleep(2000)

ControlSend($HwndBK,"",$DriveListID,$SendRootText) ;Choose a DirveDir
Sleep(2000)
$DirListID = ControlGetHandle($HwndBK,"","ThunderRT6DirListBox1")
Sleep(2000)
ControlFocus($HwndBK, "", $DirListID)

Sleep(2000)


ConsoleWrite(@lf & "p: " & $Dirarr[0] & @LF)

For $J = 1 TO $DirARR[0]

   IF $J == $DirARR[0] THEN
ControlSend($HwndBK,"",$DirListID,"ZT" & $accid)
$DirIndex =_GUICtrlListBox_FindString($DirListID,"ZT" & $accid)
ConsoleWrite(@LF & "Find last dir:" & $DirIndex & @lf)
Else
ControlSend($HwndBK,"",$DirListID,$DirARR[$J])
$DirIndex =_GUICtrlListBox_FindString($DirListID,$DirARR[$J])
ConsoleWrite(@lf & "j: " & $J & ",iNDEX:=" & $DirIndex & "," & $DirARR[$J] & @LF)
EndIf
Sleep(2000)
_GUICtrlListBox_ClickItem($DirListID,$DirIndex,"left",False,2)
Next
Sleep(1000)
$BntID =  ControlGetHandle($HwndBK,"","ThunderRT6CommandButton2")
Sleep(1000)
ControlCommand($HwndBK, '', $BntID, "Check", "")

Local $BackHwnd = WinWait("UFBack")
if WinActivate($BackHwnd) = 0 then Exit
WinWaitActive($BackHwnd)
ConsoleWrite($BackHwnd)
$NoticeText = ControlGetText($BackHwnd,"","Static2")
if StringCompare($NoticeText,"硬盘备份完毕！") <> 0 then Exit

$BntID =  ControlGetHandle($BackHwnd,"","Button1")

ControlCommand($BackHwnd, '', $BntID, "Check", "")

$BackHwnd = WinWait("提示信息")

if WinActivate($BackHwnd) = 0 then Exit

WinWaitActive($BackHwnd)

$BntID =  ControlGetHandle($BackHwnd,"","ThunderRT6CommandButton1")

ControlCommand($BackHwnd, '', $BntID, "Check", "")

Sleep(50)
_CleanTmp()

GUICtrlSetBkColor($LV[$I], 0x7CFC00)
_GUICtrlListView_SetItemText($ListView1,$I-1,"√",3)
    Next
	WinActivate($Form1)
	MsgBox(0,"Finished","Done!")
 EndFunc


Func _CleanTmp()
   Local $ARR,$I
 ;  if not IsArray($FileSnap) then Exit
;
$arr = _FileListToArray($UFDir,Default,$FLTA_FOLDERS )
if not IsArray($arr) then Exit
For $I = 1 TO $ARR[0]
if StringRegExp($arr[$I],'(^\d{8,8}$)',0) == 1 then
   ;if _ArrayBinarySearch($FileSnap,$arr[$I]) == -1 Then
   _DeleteFile( $UFDir& "\" & $arr[$I])
   ;EndIf
   EndIf
   Next
   EndFunc



