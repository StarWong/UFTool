; #CURRENT# =====================================================================================================================
;~ _MSSQL_Con
;~ _MSSQL_Query
;~ _MSSQL_End
;~ _MSSQL_CreateTable
;~ _MSSQL_CreateColumn
;~ _MSSQL_AddRecord
;~ _MSSQL_GetRecord
;~ _MSSQL_TableExist
;~ _MSSQL_ColumnExist
;~ _MSSQL_ListAllColumns
;~ _MSSQL_ListAllTables
;~ _MSSQL_GetColumninfo
;~ _MSSQL_UpdateRecord
;~ _MSSQL_DeleteRecord
;~ _MSSQL_DropColumn
;~ _MSSQL_DropTable
; ===============================================================================================================================


;===============================================================================
;
; Function Name....:    _MSSQL_CreateTable
; Description......:    Creates a New Table
; Syntax...........:    _MSSQL_CreateTable($oConnectionObj, $sTable, $identity, $Columnname)
; Parameter(s).....:    $oConnectionObj = Object, returned by _MSSQL_Con
;                       $sTable = Tablename to create
;                       $identity = [optional] Should there be a Primarykey (Standard = TRUE)
;                       $Columnname = [optional] If no Primarykey is created, name of the first Column
; Return Value(s)..:    Success - 1
;                       Failure - 0, sets @error
;                       |1 - $oConnectionObj is not an object
;                       |2 - $sTable already exists, @extended
;.........@extended:        |1 - $oConnectionObj is not an object
;                           |2 - $sTable already exists
;                           |3 - $aResult is not an array ( not happened yet, but maybe possible)
;                           |4 - Query Error, Query saved to @extended (Check permissions to sys.tables)
; Author(s)........:    TheLuBu <LuBu@veytal.com>
;
;===============================================================================

Func _MSSQL_CreateTable($oConnectionObj, $sTable, $identity = True, $Columnname = "ID")
    Local $sPrimeKey = "ID", $str, $tableexist
    If IsObj($oConnectionObj) And Not @error Then
        $tableexist = _MSSQL_TableExist($oConnectionObj, $sTable)
        If $tableexist = 1 Then Return SetError(2, @error, 0)
        If $identity = True Then
            $str = "CREATE TABLE " & $sTable & " (" & $sPrimeKey & " int IDENTITY (1,1) PRIMARY KEY) ;"
        Else
            $str = "CREATE TABLE " & $sTable & " (" & $Columnname & ");"
        EndIf
        $oConnectionObj.execute($str)
        Return 1
    ElseIf @error Then
        Return SetError(1, 0, 0)
    EndIf
EndFunc   ;==>_MSSQL_CreateTable

;===============================================================================
;
; Function Name....:    _MSSQL_CreateColumn
; Description......:    Create one or more new Columns
; Syntax...........:    _MSSQL_CreateColumn($oConnectionObj, $sTable, $sColumn, $Null = "NULL", $sDataType = "VARCHAR(45)")
; Parameter(s).....:    $oConnectionObj = Object, returned by _MSSQL_Con
;                       $sTable = Tablename
;                       $sColumn = Columnname and Type
;                       $Null = [optional] Allow Zero (Standard = True)
;                       $sDataType = [optional] If $sColumn is an 1-D Array, sets the Columtype for all Columns (Standard = "VARCHAR(45)")
; Requirement......:    If $sColumn is an array, it has to be indexed 1,
;                           - If $sColumn is an 2-D Array, the Columnname has to be in $avArray[$i][0], the datatype has to be in $avArray[0][$i]
;                       If $sColumn is a String ist, it has to be formated like this:
;                           - "Name1 varchar(50),Name2 varchar(50),Name3 varchar(50),Name4  varchar(50),NameN Datatype"
; Return Value(s)..:    Success - 1
;                       Failure - 0, sets @error
;                       |1 - $oConnectionObj is not an object
;                       |2 - $sColumn has more than 2 dimensions
;                       |3 - A Columnname from $sColumn already exists in Database
;                           - The Columnname is saved in @extended
;                       |4 - A Columnname from $sColumn occurs more than 1 time in the $sColumn
;                           - The Columnname is saved in @extended
; Author(s)........:    TheLuBu <LuBu@veytal.com>
;
;===============================================================================
Func _MSSQL_CreateColumn($oConnectionObj, $sTable, $sColumn, $Null = True, $sDataType = "VARCHAR(45)")
    Local $str, $Result, $Columnsplit, $Columnsplit2
    If IsObj($oConnectionObj) And Not @error Then
        If IsArray($sColumn) Then
            If UBound($sColumn, 2) = 2 Then
                $str = "ALTER TABLE " & $sTable & " ADD "
                If $Null = True Then
                    For $i = 1 To UBound($sColumn) - 1
                        If StringInStr($str, $sColumn[$i][0]) <> 0 Then Return SetError(4, $sColumn[$i][0], 0)
                        $str &= "" & $sColumn[$i][0] & " " & $sColumn[$i][1] & " NULL,"
                    Next
                Else
                    For $i = 1 To UBound($sColumn) - 1
                        If StringInStr($str, $sColumn[$i][0]) <> 0 Then Return SetError(4, $sColumn[$i][0], 0)
                        $str &= "" & $sColumn[$i][0] & " " & $sColumn[$i][1] & ","
                    Next
                EndIf
                For $i = 1 To UBound($sColumn) - 1
                    $Result = _MSSQL_ColumnExist($oConnectionObj, $sTable, $sColumn[$i][0])
                    If $Result = 1 Then Return SetError(3, $sColumn[$i][0], 0)
                Next

            ElseIf UBound($sColumn, 2) = 0 And @error = 2 Then
                $str = "ALTER TABLE " & $sTable & " ADD "
                If $Null = "Null" Then
                    For $i = 1 To UBound($sColumn) - 1
                        If StringInStr($str, $sColumn[$i]) <> 0 Then Return SetError(4, $sColumn[$i], 0)
                        $str &= "" & $sColumn[$i] & " " & $sDataType & " NULL,"
                    Next
                Else
                    For $i = 1 To UBound($sColumn) - 1
                        If StringInStr($str, $sColumn[$i]) <> 0 Then Return SetError(4, $sColumn[$i], 0)
                        $str &= "" & $sColumn[$i] & " " & $sDataType & ","
                    Next
                EndIf
                For $i = 1 To UBound($sColumn) - 1
                    $Result = _MSSQL_ColumnExist($oConnectionObj, $sTable, $sColumn[$i])
                    If $Result = 1 Then Return SetError(3, $sColumn[$i], 0)
                Next
            Else
                Return SetError(2, 0, 0)
            EndIf
            $str = StringTrimRight($str, 1) & ";"
            $oConnectionObj.execute($str)
        Else
            $str = "ALTER TABLE " & $sTable & " ADD " & $sColumn & ";"
            $Columnsplit = StringSplit($sColumn, ",")
            For $i = 1 To $Columnsplit[0]
                $Columnsplit2 = StringSplit($Columnsplit[$i], " ")
                $Result = _MSSQL_ColumnExist($oConnectionObj, $sTable, $Columnsplit2[1])
                If $Result = 1 Then Return SetError(3, $Columnsplit2[1], 0)
            Next
            $oConnectionObj.execute($str)
            Return 1
        EndIf
    Else
        Return SetError(1, 0, 0)
    EndIf
EndFunc   ;==>_MSSQL_CreateColumn
;===============================================================================
;
; Function Name....:    _MSSQL_AddRecord
; Description......:    Creates a new Row in the database
; Syntax...........:    _MSSQL_AddRecord($oConnectionObj, $sTable, $Values, $UNIQUE, $condition)
; Parameter(s).....:    $oConnectionObj = Object, returned by _MSSQL_Con
;                       $sTable = Tablename
;                       $Values = Values to be inserted into the table
;                       $UNIQUE = [optional] Set to True to avoid double data
;                       $condition = [optional] condition, how to determine double data
; Requirement......:    You need to add a Value for each Column in the Table
;                       If $Values is an Array , it has to be indexed 1,
;                       If $Values is a String , it has to be formated like this:
;                       - 'Value1', 'Value2', 'Value3', 'Value4', 'Value5', 'Value n'
; Return Value(s)..:    Success - 1
;                       Failure - 0, sets @error
;                       |1 - $oConnectionObj is not an object
;                       |2 - $condition was not set
;                       |3 - Only returned if $UNIQUE = True
;                               - All Values already in Database
; Author(s)........:    TheLuBu <LuBu@veytal.com>
;
;===============================================================================
Func _MSSQL_AddRecord($oConnectionObj, $sTable, $Values, $UNIQUE = False, $condition = "")
    Local $str, $check
    If IsObj($oConnectionObj) And Not @error Then
        If IsArray($Values) Then
            If UBound($Values, 2) = 0 Then
                $str = "INSERT INTO " & $sTable & " VALUES('"
                For $grades = 1 To UBound($Values) - 1
                    If $UNIQUE = False Then
                        $str &= $Values[$grades] & "', '"
                    Else
                        If $condition = "" Then Return SetError(2, 0, 0)
                        $check = _MSSQL_GetRecord($oConnectionObj, $sTable, "*", $condition)
                        If @error = 4 Then
                            $str &= $Values[$grades] & "', '"
                        EndIf
                    EndIf
                Next
                $str = StringTrimRight($str, 3) & ");"
                ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $str = ' & $str & @crlf & '>Error code: ' & @error & @crlf) ;### Debug Console
                If StringRight($str, 7) = "VALUE);" Then Return SetError(3, 0, 0)
                $oConnectionObj.execute($str)
                Return 1
            Else
                For $rows = 1 To UBound($Values) - 1
                    $str = "INSERT INTO " & $sTable & " VALUES('"
                    For $grades = 1 To UBound($Values, 2) - 1
                        If $UNIQUE = False Then
                            $str &= $Values[$rows][$grades] & "', '"
                        Else
                            If $condition = "" Then Return SetError(2, 0, 0)
                            $check = _MSSQL_GetRecord($oConnectionObj, $sTable, "*", $condition)
                            If @error = 4 Then
                                $str &= $Values[$rows][$grades] & "', '"
                            EndIf
                        EndIf
                    Next
                    $str = StringTrimRight($str, 3) & ");"
                    ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $str = ' & $str & @crlf & '>Error code: ' & @error & @crlf) ;### Debug Console
                    If StringRight($str, 7) = "VALUE);" Then Return SetError(3, 0, 0)
                    $oConnectionObj.execute($str)
                Next
                Return 1
            EndIf
        Else
            If $UNIQUE = False Then
                $str = "INSERT INTO " & $sTable & " VALUES(" & $Values & ");"
            Else
                If $condition = "" Then Return SetError(2, 0, 0)
                $check = _MSSQL_GetRecord($oConnectionObj, $sTable, "*", $condition)
                If @error = 4 Then
                    $str = "INSERT INTO " & $sTable & " VALUES(" & $Values & ");"
                Else
                    Return SetError(3, 0, 0)
                EndIf
            EndIf
            $oConnectionObj.execute($str)
            Return 1
        EndIf
    Else
        Return SetError(1, 0, 0)
    EndIf
EndFunc   ;==>_MSSQL_AddRecord
;===============================================================================
;
; Function Name....:    _MSSQL_GetRecord
; Description......:    Get one or more Values from Database
; Syntax...........:    _MSSQL_GetRecord($oConnectionObj, $sTable, $Columns = "*", $condition = "", $order = "")
; Parameter(s).....:    $oConnectionObj = Object, returned by _MSSQL_Con
;                       $sTable = Tablename
;                       $sColumn = [optional] Name of one or more Columns in the Table [ Standard = "*" (all Columns)]
;                       $condition = [optional] A WHERE Case, to look for special Values [Standard = "" (all Values)]
;                                       - The datafields in the WHERE Case have to be like this:  'VALUE'
;                       $order = [optional] ORDER BY Case, to sort the returned values [Standard = "" (no order)]
; Requirement......:    If $sColumn is an Array it has to be indexed 1,
;                           - $sColumn contains the Columns to read from
; Return Value(s)..:    Success - Returns an array
;                                   - If you searched in only one column, $aResult is a 1-D Array, where $aResult[0] is the number of found values
;                                   - If you searched in more then one column, $aResult is multidimensional, where $aResult[0][n] is the number of found values
;                       Failure - 0, sets @error
;                       |1 - $oConnectionObj is not an object
;                       |2 - $aResult is not an array ( not happened yet, but msaybe possible)
;                       |3 - $sColumn is not an 1-D array
;                       |4 - Query Error, Query saved to @extended
; Author(s)........:    TheLuBu <LuBu@veytal.com>
;
;===============================================================================
Func _MSSQL_GetRecord($oConnectionObj, $sTable, $Columns = "*", $condition = "", $order = "")
    Local $str, $quer, $aResult, $iColumns, $iRows
    If IsObj($oConnectionObj) And Not @error Then
        If IsArray($Columns) Then
            If UBound($Columns, 2) - 1 <> 1 Then Return SetError(3, 0, 0)
            $str = "SELECT '"
            For $i = 1 To UBound($Columns) - 1
                $str &= $Columns[$i] & "','"
            Next
            If $order = "" Then
                $str = StringTrimRight($str, 2) & "FROM " & $sTable & " " & $condition & ";"
            Else
                $str = StringTrimRight($str, 2) & "FROM " & $sTable & " " & $condition & " ORDER BY " & $order & " ;"
            EndIf
            $quer = $oConnectionObj.execute($str)
            With $quer
                If Not .EOF Then
                    $aResult = .GetRows()
                    If IsArray($aResult) And UBound($aResult, 2) > 1 Then
                        $iColumns = UBound($aResult, 2)
                        $iRows = UBound($aResult)
                        ReDim $aResult[$iRows + 1][$iColumns]
                        For $x = $iRows To 1 Step -1
                            For $y = 0 To $iColumns - 1
                                $aResult[$x][$y] = $aResult[$x - 1][$y]
                            Next
                        Next
                        For $i = 0 To $iColumns - 1
                            $aResult[0][$i] = .Fields($i).Name
                        Next
                    ElseIf IsArray($aResult) And UBound($aResult, 2) = 1 Then
                        $iRows = UBound($aResult)
                        Local $bResult[$iRows + 1]
                        For $x = $iRows To 1 Step -1
                            $bResult[$x] = $aResult[$x - 1][0]
                        Next
                        $bResult[0] = $iRows
                        Return $bResult
                    Else
                        Return SetError(2, 0, 0)
                    EndIf
                Else
                    Return SetError(4, $str, 0)
                EndIf
            EndWith
            Return $aResult
        Else
            If $order = "" Then
                If $Columns = "*" Then
                    $quer = $oConnectionObj.execute("SELECT " & $Columns & " FROM " & $sTable & " " & $condition & ";")
                Else
                    $quer = $oConnectionObj.execute("SELECT '" & $Columns & "' FROM " & $sTable & " " & $condition & ";")
                EndIf
            Else
                If $Columns = "*" Then
                    $quer = $oConnectionObj.execute("SELECT " & $Columns & " FROM " & $sTable & " " & $condition & " ORDER BY " & $order & " ;")
                Else
                    $quer = $oConnectionObj.execute("SELECT '" & $Columns & "' FROM " & $sTable & " " & $condition & " ORDER BY " & $order & " ;")
                EndIf
            EndIf
            If Not $quer.EOF Then
                $aResult = $quer.GetRows()
                If IsArray($aResult) And UBound($aResult, 2) > 1 Then
                    $iColumns = UBound($aResult, 2)
                    $iRows = UBound($aResult)
                    ReDim $aResult[$iRows + 1][$iColumns]
                    For $x = $iRows To 1 Step -1
                        For $y = 0 To $iColumns - 1
                            $aResult[$x][$y] = $aResult[$x - 1][$y]
                        Next
                    Next
                    For $i = 0 To $iColumns - 1
                        $aResult[0][$i] = $quer.Fields($i).Name
                    Next
                ElseIf IsArray($aResult) And UBound($aResult, 2) = 1 Then
                    $iRows = UBound($aResult)
                    Local $bResult[$iRows + 1]
                    For $x = $iRows To 1 Step -1
                        $bResult[$x] = $aResult[$x - 1][0]
                    Next
                    $bResult[0] = $iRows
                    Return $bResult
                Else
                    Return SetError(2, 0, 0)
                EndIf
            Else
                Return SetError(4, $str, 0)
            EndIf
            Return $aResult
        EndIf
    EndIf
    Return SetError(1, 0, 0)
EndFunc   ;==>_MSSQL_GetRecord
;===============================================================================
;
; Function Name....:    _MSSQL_TableExist
; Description......:    Checks, if a Table Exists
; Syntax...........:    _MSSQL_TableExist($oConnectionObj, $sTable)
; Parameter(s).....:    $oConnectionObj = Object, returned by _MSSQL_Con
;                       $sTable = Tablename
; Return Value(s)..:    Success - 1
;                       Failure - 0, sets @error
;                       |1 - $oConnectionObj is not an object
;                       |2 - Table not found
;                       |3 - Query Error, Query saved to @extended (Check Permissions on sys.tables)
;                           - also Returned when Table does not exist
; Author(s)........:    TheLuBu <LuBu@veytal.com>
;
;===============================================================================

Func _MSSQL_TableExist($oConnectionObj, $sTable)
    Local $quer
    If IsObj($oConnectionObj) And Not @error Then
        $quer = $oConnectionObj.execute("SELECT TABLE_SCHEMA FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '" & $sTable & "';")
        If Not $quer.EOF Then
            Return 1
        Else
            Return SetError(3, "SELECT TABLE_SCHEMA FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '" & $sTable & "';", 0)
        EndIf
        Return SetError(2, 0, 0)
    Else
        Return SetError(1, 0, 0)
    EndIf
EndFunc   ;==>_MSSQL_TableExist
;===============================================================================
;
; Function Name....:    _MSSQL_ColumnExist
; Description......:    Checks if a Column exists
; Syntax...........:    _MSSQL_ColumnExist($oConnectionObj, $sTable, $sColumn)
; Parameter(s).....:    $oConnectionObj = Object, returned by _MSSQL_Con
;                       $sTable = Tablename
;                       $sColumn = Columnname
; Return Value(s)..:    Success - 1
;                       Failure - 0, sets @error
;                       |1 - $oConnectionObj is not an object
;                       |2 - Column not found
;                       |3 - Table not found
;                       |3 - Query Error, Query saved to @extended (Check Permissions on sys.columns)
;                           - also Returned when Column does not exist
; Author(s)........:    TheLuBu <LuBu@veytal.com>
;
;===============================================================================
Func _MSSQL_ColumnExist($oConnectionObj, $sTable, $sColumn)
    Local $quer
    If IsObj($oConnectionObj) And Not @error Then
        If not _MSSQL_TableExist($oConnectionObj, $sTable) Then Return SetError(3,0,0)
        $quer = $oConnectionObj.execute("SELECT TABLE_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME = '" & $sColumn & "' AND TABLE_NAME = '" & $sTable & "';")
        If Not $quer.EOF Then
            Return 1
        Else
            Return SetError(4, "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME = '" & $sColumn & "' AND TABLE_NAME = '" & $sTable & "';", 0)
        EndIf
        Return SetError(2, 0, 0)
    Else
        Return SetError(1, 0, 0)
    EndIf
EndFunc   ;==>_MSSQL_ColumnExist
;===============================================================================
;
; Function Name....:    _MSSQL_Con
; Description......:    Connect to a Database
; Syntax...........:    _MSSQL_Con($scIP, $scUser, $scPass, $scDB)
; Parameter(s).....:    $scIP = IP adress
;                       $scUser = User
;                       $scPass = Pass
;                       $scDB = Database
; Return Value(s)..:    Success - Returns the Database-"handle"
;
;===============================================================================
Func _MSSQL_Con($scIP, $scUser, $scPass, $scDB)
    Local $sqlCon
    $sqlCon = ObjCreate("ADODB.Connection")
    $sqlCon.Open("Provider=SQLOLEDB; Data Source=" & $scIP & "; User ID=" & $scUser & "; Password=" & $scPass & "; database=" & $scDB & ";")
    Return $sqlCon
EndFunc   ;==>_MSSQL_Con
;===============================================================================
;
; Function Name....:    _MSSQL_Query
; Description......:    Send a Query to the Database
; Syntax...........:    _MSSQL_Query($iSQLCon, $iQuery)
; Parameter(s).....:    $iSQLCon = $oConnectionObj = Object, returned by _MSSQL_Con
;                       $iQuery = MSSQL Query
; Return Value(s)..:    Success - Returns the Response from the server
;
;===============================================================================
Func _MSSQL_Query($iSQLCon, $iQuery)
    If IsObj($iSQLCon) Then
        Return $iSQLCon.execute($iQuery)
    EndIf
EndFunc   ;==>_MSSQL_Query
;===============================================================================
;
; Function Name....:    _MSSQL_End
; Description......:    Close SQL Session
; Syntax...........:    _MSSQL_End($sqlCon)
; Parameter(s).....:    $sqlCon = $oConnectionObj = Object, returned by _MSSQL_Con
; Return Value(s)..:    -
;
;===============================================================================
Func _MSSQL_End($sqlCon)
    If IsObj($sqlCon) Then
        $sqlCon.close
    EndIf
EndFunc   ;==>_MSSQL_End
;===============================================================================
;
; Function Name....:    _MSSQL_ListAllColumns
; Description......:    List all Columns from an existing Table
; Syntax...........:    _MSSQL_ListAllColumns($oConnectionObj, $sTable)
; Parameter(s).....:    $oConnectionObj = Object, returned by _MSSQL_Con
;                       $sTable = Tablename
; Return Value(s)..:    Success - Returns an Array
;                       - $aResult[0] returns the number of Columns
;                       Failure - 0, sets @error
;                       |1 - $oConnectionObj is not an object
;                       |2 - $aResult is not an array ( not happened yet, but maybe possible)
;                       |3 - $sTable does not exist
;                       |4 - Query Error, Query saved to @extended
; Author(s)........:    TheLuBu <LuBu@veytal.com>
;
;===============================================================================
Func _MSSQL_ListAllColumns($oConnectionObj, $sTable)
    Local $quer, $aResult, $iRows
    If IsObj($oConnectionObj) And Not @error Then
        If not _MSSQL_TableExist($oConnectionObj, $sTable) Then Return SetError(3,0,0)
        $quer = $oConnectionObj.execute("SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '" & $sTable & "';")
        If Not $quer.EOF Then
            $aResult = $quer.GetRows()
            If IsArray($aResult) And UBound($aResult, 2) = 1 Then
                $iRows = UBound($aResult)
                Local $bResult[$iRows + 1]
                For $x = $iRows To 1 Step -1
                    $bResult[$x] = $aResult[$x - 1][0]
                Next
                $bResult[0] = $iRows
                Return $bResult
            Else
                Return SetError(2, 0, 0)
            EndIf
        Else
            Return SetError(4, "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '" & $sTable & "';", 0)
        EndIf
    Else
        Return SetError(1, 0, 0)
    EndIf
EndFunc   ;==>_MSSQL_ListAllColumns
;===============================================================================
;
; Function Name....:    _MSSQL_ListAllTables
; Description......:    List all tables from the database
; Syntax...........:    _MSSQL_ListAllTables($oConnectionObj)
; Parameter(s).....:    $oConnectionObj = Object, returned by _MSSQL_Con
; Return Value(s)..:    Success - Returns an 2-D Array
;                                   - $Return[0][0]  = number of tables
;                                   - $Return[$i][n] = Tablename
;                                   - $Return[$i][n] = Table Type
;                       Failure - 0, sets @error
;                       |1 - $oConnectionObj is not an object
;                       |2 - $aResult is not an array ( not happened yet, but maybe possible)
;                       |3 - No permissions to INFORMATION_SCHEMA.TABLES
;                           - also returned, if no Tables exist at all
; Author(s)........:    TheLuBu <LuBu@veytal.com>
;
;===============================================================================
Func _MSSQL_ListAllTables($oConnectionObj)
    Local $quer, $aResult, $iColumns, $iRows
    If IsObj($oConnectionObj) And Not @error Then
        $quer = $oConnectionObj.execute("SELECT TABLE_NAME, TABLE_TYPE FROM INFORMATION_SCHEMA.TABLES;")
        If Not $quer.EOF Then
            $aResult = $quer.GetRows()
            If IsArray($aResult) And UBound($aResult, 2) = 2 Then
                $iColumns = UBound($aResult, 2)
                $iRows = UBound($aResult)
                ReDim $aResult[$iRows + 1][$iColumns]
                For $x = $iRows To 1 Step -1
                    For $y = 0 To $iColumns - 1
                        $aResult[$x][$y] = $aResult[$x - 1][$y]
                    Next
                Next
                $aResult[0][0] = $iRows
                $aResult[0][1] = ""
                Return $aResult
            Else
                Return SetError(2, 0, 0)
            EndIf
        Else
            Return SetError(3, 0, 0)
        EndIf
    Else
        Return SetError(1, 0, 0)
    EndIf
EndFunc   ;==>_MSSQL_ListAllTables
;===============================================================================
;
; Function Name....:    _MSSQL_GetColumninfo
; Description......:    Get Information about a Column
; Syntax...........:    _MSSQL_GetColumninfo($oConnectionObj, $sTable, $sColumn = "Allcolumns")
; Parameter(s).....:    $oConnectionObj = Object, returned by _MSSQL_Con
;                       $sTable = Tablename
;                       $sColumn = [optional] Column to get info about (Standard = AllColumns)
; Return Value(s)..:    Success - Returns an multidimensional Array
;                       - $Return[$i][0] = Name of the Column
;                       - $Return[$i][1] = Allow Zero
;                       - In $Return[$i][2] = Datatype
;                       - In $Return[$i][3] = Max Character Lenght
;                       - In $Return[$i][4] = COLLATION NAME (i.E. latin1)
;                       Failure - 0, sets @error
;                       |1 - $oConnectionObj is not an object
;                       |2 - $aResult is not an array ( not happened yet, but maybe possible)
;                       |3 - $sTable or $sColumn does not exist
; Author(s)........:    TheLuBu <LuBu@veytal.com>
;
;===============================================================================
Func _MSSQL_GetColumninfo($oConnectionObj, $sTable, $sColumn = "Allcolumns")
    Local $quer, $aResult, $iColumns, $iRows
    If IsObj($oConnectionObj) And Not @error Then
        If $sColumn = "Allcolumns" Then
            $quer = $oConnectionObj.execute("SELECT COLUMN_NAME, IS_NULLABLE, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, COLLATION_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '" & $sTable & "';")
        Else
            $quer = $oConnectionObj.execute("SELECT COLUMN_NAME, IS_NULLABLE, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, COLLATION_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '" & $sTable & "' AND COLUMN_NAME = '" & $sColumn & "';")
        EndIf
        If Not $quer.EOF Then
            $aResult = $quer.GetRows()
            If IsArray($aResult) And UBound($aResult, 2) > 1 Then
                $iColumns = UBound($aResult, 2)
                $iRows = UBound($aResult)
                ReDim $aResult[$iRows + 1][$iColumns]
                For $x = $iRows To 1 Step -1
                    For $y = 0 To $iColumns - 1
                        $aResult[$x][$y] = $aResult[$x - 1][$y]
                    Next
                Next
                For $i = 0 To $iColumns - 1
                    $aResult[0][$i] = $quer.Fields($i).Name
                Next
                Return $aResult
            Else
                Return SetError(2, 0, 0)
            EndIf
        Else
            Return SetError(3, 0, 0)
        EndIf
    Else
        Return SetError(1, 0, 0)
    EndIf
EndFunc   ;==>_MSSQL_GetColumninfo
;===============================================================================
;
; Function Name....:    _MSSQL_UpdateRecord
; Description......:    Update one or more Values
; Syntax...........:    _MSSQL_UpdateRecord($oConnectionObj, $sTable, $sColumn , $sValue, $condition = "")
; Parameter(s).....:    $oConnectionObj = Object, returned by _MSSQL_Con
;                       $sTable = Tablename
;                       $sColumn = Columnname to update Value in
;                       $sValue = Value to change into
;                       $condition = [optional] A WHERE Case, to limit the found Values [Standard = "" (all Values in a Column)]
; Return Value(s)..:    Success - 1
;                       Failure - 0, sets @error
;                       |1 - $oConnectionObj is not an object
;                       |2 - $sTable does not exist
;                       |3 - $sColumn does not exist
; Author(s)........:    TheLuBu <LuBu@veytal.com>
;
;===============================================================================
Func _MSSQL_UpdateRecord($oConnectionObj, $sTable, $sColumn, $sValue, $condition = "")
    Local $tableexist, $columnexist, $str, $quer
    If IsObj($oConnectionObj) And Not @error Then
        $tableexist = _MSSQL_TableExist($oConnectionObj, $sTable)
        If $tableexist = 0 Then Return SetError(2, 0, 0)
        $columnexist = _MSSQL_ColumnExist($oConnectionObj, $sTable, $sColumn)
        If $columnexist = 0 Then Return SetError(3, 0, 0)
        If $condition = "" Then
            $str = "UPDATE " & $sTable & " SET " & $sColumn & " = " & $sValue & ";"
            $quer = $oConnectionObj.execute($str)
        Else
            $str = "UPDATE " & $sTable & " SET " & $sColumn & " = " & $sValue & " " & $condition & ";"
            $quer = $oConnectionObj.execute($str)
        EndIf
        Return 1
    Else
        Return SetError(1, 0, 0)
    EndIf
EndFunc   ;==>_MSSQL_UpdateRecord
;===============================================================================
;
; Function Name....:    _MSSQL_DeleteRecord
; Description......:    Delete one or more Rows from a Table
; Syntax...........:    _MSSQL_DeleteRecord($oConnectionObj, $sTable, $condition = "")
; Parameter(s).....:    $oConnectionObj = Object, returned by _MSSQL_Con
;                       $sTable = Tablename
;                       $condition = [optional] A WHERE Case, to limit deleted rows [Standard = "" (all rows in table)]
; Return Value(s)..:    Success - 1
;                       Failure - 0, sets @error
;                       |1 - $oConnectionObj is not an object
;                       |2 - $sTable does not exist
; Author(s)........:    TheLuBu <LuBu@veytal.com>
;
;===============================================================================
Func _MSSQL_DeleteRecord($oConnectionObj, $sTable, $condition = "")
    Local $tableexist, $columnexist, $str, $quer
    If IsObj($oConnectionObj) And Not @error Then
        $tableexist = _MSSQL_TableExist($oConnectionObj, $sTable)
        If $tableexist = 0 Then Return SetError(2, 0, 0)
        If $condition = "" Then
            $str = "DELETE FROM " & $sTable & ";"
            $quer = $oConnectionObj.execute($str)
        Else
            $str = "DELETE FROM " & $sTable & " " & $condition & ";"
            $quer = $oConnectionObj.execute($str)
        EndIf
        Return 1
    Else
        Return SetError(1, 0, 0)
    EndIf
EndFunc   ;==>_MSSQL_DeleteRecord

;===============================================================================
;
; Function Name....:    _MSSQL_DropTable
; Description......:    Delete a Table from Database
; Syntax...........:    _MSSQL_DropTable($oConnectionObj, $sTable)
; Parameter(s).....:    $oConnectionObj = Object, returned by _MSSQL_Con
;                       $sTable = Tablename
; Return Value(s)..:    Success - 1
;                       Failure - 0, sets @error
;                       |1 - $oConnectionObj is not an object
;                       |2 - $sTable does not exist
; Author(s)........:    TheLuBu <LuBu@veytal.com>
;
;===============================================================================
Func _MSSQL_DropTable($oConnectionObj, $sTable)
    If IsObj($oConnectionObj) And Not @error Then
        If Not _MSSQL_TableExist($oConnectionObj, $sTable) Then Return SetError(2, 0, 0)
        $str = "DROP TABLE " & $sTable & ";"
        $quer = $oConnectionObj.execute($str)
        Return 1
    Else
        Return SetError(1, 0, 0)
    EndIf
EndFunc   ;==>_MSSQL_DropTable
;===============================================================================
;
; Function Name....:    _MSSQL_DropColumn
; Description......:    Delete a Column from a Table
; Syntax...........:    _MSSQL_DropColumn($oConnectionObj, $sTable)
; Parameter(s).....:    $oConnectionObj = Object, returned by _MSSQL_Con
;                       $sTable = Tablename
; Return Value(s)..:    Success - 1
;                       Failure - 0, sets @error
;                       |1 - $oConnectionObj is not an object
;                       |2 - $sTable does not exist
;                       |3 - $sColumn does not exist
; Author(s)........:    TheLuBu <LuBu@veytal.com>
;
;===============================================================================
Func _MSSQL_DropColumn($oConnectionObj, $sTable, $sColumn)
    If IsObj($oConnectionObj) And Not @error Then
        If Not _MSSQL_TableExist($oConnectionObj, $sTable) Then Return SetError(2, 0, 0)
        If Not _MSSQL_ColumnExist($oConnectionObj, $sTable, $sColumn) Then Return SetError(3, 0, 0)
        $str = "ALTER TABLE " & $sTable & " DROP COLUMN " & $sColumn & ";"
        $quer = $oConnectionObj.execute($str)
        Return 1
    Else
        Return SetError(1, 0, 0)
    EndIf
 EndFunc   ;==>_MSSQL_DropColumn


 ;===============================================================================
;
; Function Name....:     _MSSQL_GetRecord
; Description......:     Get one or more Values from Database
; Syntax...........:    _MSSQL_GetRecord($oConnectionObj, $sTable, $Columns = "*", $condition = "", $order = "")
; Parameter(s).....:      $oConnectionObj = Object, returned by _MSSQL_Con
;                         $sTable = Tablename
;                        $sColumn = [optional] Name of one or more Columns in the Table [ Standard = "*" (all Columns)]
;                        $condition = [optional] A WHERE Case, to look for special Values [Standard = "" (all Values)]
;                                        - The datafields in the WHERE Case have to be like this:  'VALUE'
;                        $order = [optional] ORDER BY Case, to sort the returned values [Standard = "" (no order)]
; Requirement......:    If $sColumn is an Array it has to be indexed 1,
;                            - $sColumn contains the Columns to read from
; Return Value(s)..:     Success - Returns an array
;                                    - If you searched in only one column, $aResult is a 1-D Array, where $aResult[0] is the number of found values
;                                    - If you searched in more then one column, $aResult is multidimensional, where $aResult[0][n] is the number of found values
;                         Failure - 0, sets @error
;                         |1 - $oConnectionObj is not an object
;                        |2 - $aResult is not an array ( not happened yet, but msaybe possible)
;                        |3 - $sColumn is not an 1-D array
;                        |4 - Query Error, Query saved to @extended
; Author(s)........:     TheLuBu <LuBu@veytal.com>
;
;===============================================================================
Func _MSSQL_GetRecord2($oConnectionObj, $sTable, $Columns = "*", $condition = "", $order = "")

    Local $str, $quer, $aResult, $iColumns, $iRows
    If IsObj($oConnectionObj) And Not @error Then
        If IsArray($Columns) Then
            If UBound($Columns, 0) <> 1 Then Return SetError(3, 0, 0)
            $str = "SELECT "
            For $i = 0 To UBound($Columns) - 1
                $str &= $Columns[$i] & ", "
            Next
            If $order = "" Then
                $str = StringTrimRight($str, 2) & " FROM " & $sTable & " " & $condition & ";"
            Else
                $str = StringTrimRight($str, 2) & " FROM " & $sTable & " " & $condition & " ORDER BY " & $order & " ;"
            EndIf

            $quer = $oConnectionObj.execute($str)
            With $quer
                If Not .EOF Then
                    $aResult = .GetRows()
                    If IsArray($aResult) And UBound($aResult, 2) > 1 Then
                        $iColumns = UBound($aResult, 2)
                        $iRows = UBound($aResult)
                        ReDim $aResult[$iRows + 1][$iColumns]
                        For $x = $iRows To 1 Step -1
                            For $y = 0 To $iColumns - 1
                                $aResult[$x][$y] = $aResult[$x - 1][$y]
                            Next
                        Next
                        For $i = 0 To $iColumns - 1
                            $aResult[0][$i] = .Fields($i).Name
                        Next
                    ElseIf IsArray($aResult) And UBound($aResult, 2) = 1 Then
                        $iRows = UBound($aResult)
                        Local $bResult[$iRows + 1]
                        For $x = $iRows To 1 Step -1
                            $bResult[$x] = $aResult[$x - 1][0]
                        Next
                        $bResult[0] = $iRows
                        Return $bResult
                    Else
                        Return SetError(2, 0, 0)
                    EndIf
                Else
                    Return SetError(4, $str, 0)
                EndIf
            EndWith
            Return $aResult
        Else
            If $order = "" Then
                If $Columns = "*" Then
                    $quer = $oConnectionObj.execute("SELECT " & $Columns & " FROM " & $sTable & " " & $condition & ";")
                Else
                    $quer = $oConnectionObj.execute("SELECT " & $Columns & " FROM " & $sTable & " " & $condition & ";")
                EndIf
            Else
                If $Columns = "*" Then
                    $quer = $oConnectionObj.execute("SELECT " & $Columns & " FROM " & $sTable & " " & $condition & " ORDER BY " & $order & " ;")
                Else
                    $quer = $oConnectionObj.execute("SELECT " & $Columns & " FROM " & $sTable & " " & $condition & " ORDER BY " & $order & " ;")
                EndIf
            EndIf
            If Not $quer.EOF Then
                $aResult = $quer.GetRows()
                If IsArray($aResult) And UBound($aResult, 2) > 1 Then
                    $iColumns = UBound($aResult, 2)
                    $iRows = UBound($aResult)
                    ReDim $aResult[$iRows + 1][$iColumns]
                    For $x = $iRows To 1 Step -1
                        For $y = 0 To $iColumns - 1
                            $aResult[$x][$y] = $aResult[$x - 1][$y]
                        Next
                    Next
                    For $i = 0 To $iColumns - 1
                        $aResult[0][$i] = $quer.Fields($i).Name
                    Next
                ElseIf IsArray($aResult) And UBound($aResult, 2) = 1 Then
                    $iRows = UBound($aResult)
                    Local $bResult[$iRows + 1]
                    For $x = $iRows To 1 Step -1
                        $bResult[$x] = $aResult[$x - 1][0]
                    Next
                    $bResult[0] = $iRows
                    Return $bResult
                Else
                    Return SetError(2, 0, 0)
                EndIf
            Else
                Return SetError(4, $str, 0)
            EndIf
            Return $aResult
        EndIf
    EndIf
    Return SetError(1, 0, 0)
EndFunc   ;==>_MSSQL_GetRecord