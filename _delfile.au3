Func _DeleteFile($sFile, $sExclude = "", $iFlag = 0)
	Local $Path, $FileList[1], $ExcludeList[1] = [0], $FileSystem = "", $Element, $FileAttrib, $Result = 0

	If StringRight($sFile, 1) = "\" Then $sFile = StringTrimRight($sFile, 1)
	$Path = StringLeft($sFile, StringInStr($sFile, "\", 0, -1))
	$sFile = StringTrimLeft($sFile, StringInStr($sFile, "\", 0, -1))
	If $Path = "" Then $Path = @WorkingDir & "\"
	If Not FileExists($Path) Or Not StringInStr(FileGetAttrib($Path), "D") Or $sFile = "" Then Return 1
	If StringRegExp($sExclude, '^.*[\\/:*?"<>]+.*$') Then Return SetError(2, 0, 0)
	If $iFlag <> 0 And $iFlag <> 1 And $iFlag <> 2 Then Return SetError(3, 0, 0)

	$FileList = _FileListToArray($Path, $sFile, $iFlag)
	If @error Then Return 1

	If $sExclude <> "" Then $ExcludeList = StringSplit($sExclude, "|")
	$FileSystem = DriveGetFileSystem($Path)
	If $FileSystem = "NTFS" Then
		_ArrayAdd($ExcludeList, "System Volume Information")
		$ExcludeList[0] = UBound($ExcludeList) - 1
	EndIf

	For $i = 1 To $ExcludeList[0]
		$Element = _ArraySearch($FileList, $ExcludeList[$i], 1)
		If $Element <> -1 Then _ArrayDelete($FileList, $Element)
	Next
	$FileList[0] = UBound($FileList) - 1

	For $i = 1 To $FileList[0]
		If $FileList[$i] = "RECYCLER" And $FileSystem <> "" Then
			_DeleteFile($Path & $FileList[$i] & "\*.*")
			If @error Then $Result = 1
			ContinueLoop
		EndIf

		$FileAttrib = FileGetAttrib($Path & $FileList[$i])
		If StringRegExp($FileAttrib, ".*[RSH]+.*") Then FileSetAttrib($Path & $FileList[$i], "-RSH")
		If StringInStr($FileAttrib, "D") Then
			If Not DirRemove($Path & $FileList[$i], 1) Then
				_DeleteFile($Path & $FileList[$i] & "\*.*")
				$Result = 1
			EndIf
		Else
			If Not FileDelete($Path & $FileList[$i]) Then $Result = 1
		EndIf
	Next

	If $Result Then
		Return SetError(1, 0, 0)
	Else
		Return 1
	EndIf
EndFunc   ;==>_DeleteFile