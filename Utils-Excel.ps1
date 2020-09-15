
######################################
function readExcelFiles() {
	foreach($file in (Get-ChildItem -path "$pathRoot*" -include *.xlsx )) {
        readExcelFile($file)
	}
}

######################################
function readExcelFile($file) {
		log "Reading Excel $file ..."

        $intRow = 2
        $content = Import-Excel $file
        $cols = $content[0].psobject.properties.name

    	# Read the lang code from the first line:
        $lang = $cols[4]
        log "Lang: $lang"
		$lang = $lang -replace ".*\(",''
		$lang = $lang -replace "\).*",''

        $linesWithTranslations = 0
        $intRow=0
        $content | Foreach-Object { 
            $intRow++;
            if ($intRow%10000 -eq 0) { log "...done reading $intRow lines" }

            $codeTableName  = $_.$($cols[0])
            $code           = $_.$($cols[1]).Trim()
			$translation    = $_.$($cols[4])

            if ([string]::IsNullOrEmpty($translation)) {
                #log "Skip empty translation for $code"
                return
            }
            $linesWithTranslations++
                        
            $smallHashKey = $codeTableName + $DEL + $code

            if ($tableAndCodeToNothing_Excel.ContainsKey($smallHashKey)) {
                # OK - probably other excel had translation for it to another lang
            } else {
                #log "adding $smallHashKey"
                $tableAndCodeToNothing_Excel.add($smallHashKey, 'exists')
            }

            $hashKey = $codeTableName + $DEL + $code + $DEL + $lang
            if ($tableCodeAndLangToText_Excel.ContainsKey($hashKey)) {
                log "  WARNING: key twice in Excel files: $hashKey" #TODO test
            } else {
                $tableCodeAndLangToText_Excel.add($hashKey, $translation)
                #log "...........added to Excel hash:", $hashKey, $translation
            }

        }
        log "  Found $linesWithTranslations lines with translations"
}

function Import-Excel([string]$FilePath, [string]$SheetName = "")
{
    $csvFile = Join-Path $env:temp ("{0}.csv" -f (Get-Item -path $FilePath).BaseName)
    if (Test-Path -path $csvFile) { Remove-Item -path $csvFile }
    #Write-Host "Temp file in $csvFile"

    # convert Excel file to CSV file
    $xlCSVType = 62 # SEE: http://msdn.microsoft.com/en-us/library/bb241279.aspx
    $excelObject = New-Object -ComObject Excel.Application  
    $excelObject.Visible = $false 
    $workbookObject = $excelObject.Workbooks.Open($FilePath)
    SetActiveSheet $workbookObject $SheetName | Out-Null
    $workbookObject.SaveAs($csvFile,$xlCSVType) 
    $workbookObject.Saved = $true
    $workbookObject.Close()

     # cleanup 
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($workbookObject) |
        Out-Null
    $excelObject.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excelObject) |
        Out-Null
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()

    # now import and return the data 
    Import-Csv -path $csvFile
}

function FindSheet([Object]$workbook, [string]$name)
{
    $sheetNumber = 0
    for ($i=1; $i -le $workbook.Sheets.Count; $i++) {
        if ($name -eq $workbook.Sheets.Item($i).Name) { $sheetNumber = $i; break }
    }
    return $sheetNumber
}

function SetActiveSheet([Object]$workbook, [string]$name)
{
    if (!$name) { return }
    $sheetNumber = FindSheet $workbook $name
    if ($sheetNumber -gt 0) { $workbook.Worksheets.Item($sheetNumber).Activate() }
    return ($sheetNumber -gt 0)
}






































# Slow method:
######################################
function readExcelFiles_slow() {
	$excel = New-Object -Com Excel.Application

	foreach($file in (Get-ChildItem -path "$pathRoot*" -include *.xlsx )) {
		log "Reading $file ..."

		Add-Type -AssemblyName System.Web
		$sh = $excel.Workbooks.Open($file).Sheets.Item(1)
		
		# Read the lang code from the first line:
		$lang = $sh.Cells.Item(1,5).Text
        log "Lang: $lang"
		$lang = $lang -replace ".*\(",''
		$lang = $lang -replace "\).*",''

		# read the rest of the lines:
		for ($intRow = 2 ; $intRow -le ($sh.UsedRange.Rows).Count ; $intRow++) {
			$codeTableName    = $sh.Cells.Item($intRow,1).Text
			$code         = $sh.Cells.Item($intRow,2).Text.Trim() # .Trim() ?
			$translation  = $sh.Cells.Item($intRow,5).Text.Trim()

            #TODO :
            #translation = translation.replaceAll("[\n\r\f\t]", " ");
            #// backspace to ""
            #translation = translation.replaceAll("\b", "");

            if ([string]::IsNullOrEmpty($translation)) {
                #log "Skip empty translation for $code"
                continue
            }
                        
            $hashKey = $codeTableName + $DEL + $code + $DEL + $lang
            if ($tableCodeAndLangToText_Excel.ContainsKey($hashKey)) {
                log "key twice in Excel files: $hashKey" #TODO test
            } else {
                $tableCodeAndLangToText_Excel.add($hashKey, $translation)
                #log "...........added to Excel hash:", $hashKey, $translation
            }
		}
		$excel.Workbooks.Close()
        log ""
	}
	$excel.Quit()  
}
