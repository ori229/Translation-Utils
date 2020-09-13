
######################################
function readExcelFiles() {
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
            # TODO - print progress every 10,000 lines
		}
		$excel.Workbooks.Close()
        log ""
	}
	$excel.Quit()  
}