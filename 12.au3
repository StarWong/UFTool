#include <GuiListBox.au3>
#include <WinAPISysWin.au3>
#include <GuiListBox.au3>
WinWait("选择备份目标:")
$HwndBK = WinGetHandle("选择备份目标:")
WinActivate($HwndBK)
WinWaitActive($HwndBK )
ConsoleWrite($HwndBK & @LF)
$DriveListID = ControlGetHandle($HwndBK,"","ThunderRT6DriveListBox1")
ConsoleWrite($DriveListID & @LF)
;if Not FileExists ("C:\GIF\UFBak\ZT001") THEN
;   if not  DirCreate("C:\GIF\UFBak\ZT001") then Exit
;   Else
;	  Exit
;   EndIf
ControlFocus($HwndBK, "", $DriveListID)
Send("D:")
$DirListID = ControlGetHandle($HwndBK,"","ThunderRT6DirListBox1")
ControlFocus($HwndBK, "", $DirListID)
Send("D:\")
Sleep(1000)
$s = ControlCommand($HwndBK,"",$DirListID,"FindString","UFBak")
ControlCommand($HwndBK,"",$DirListID,"SetCurrentSelection",$S)
ConsoleWrite($s)
Exit
$I =_GUICtrlListBox_FindString($DirListID,"c:\")
ConsoleWrite("-" &$i)
_GUICtrlListBox_ClickItem($DirListID,$I,"left",False,2)

$I =_GUICtrlListBox_FindString($DirListID,"gif")

_GUICtrlListBox_ClickItem($DirListID,$I,"left",False,2)

$I =_GUICtrlListBox_FindString($DirListID,"UFBAK")

_GUICtrlListBox_ClickItem($DirListID,$I,"left",False,2)

$I =_GUICtrlListBox_FindString($DirListID,"ZT001")

_GUICtrlListBox_ClickItem($DirListID,$I,"left",False,2)

$BntID =  ControlGetHandle($HwndBK,"","ThunderRT6CommandButton2")

ControlCommand($HwndBK, '', $BntID, "Check", "")

WinWait("UFBack")

;ControlClick($HwndBK,"Gif",$DirListID,"left", 2)
;ControlTreeView($HwndBK,"",$DirListID,"Expand", "Gif")
