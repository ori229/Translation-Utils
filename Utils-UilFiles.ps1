
######################################
function fetchUilFilesFromSvn($baseurl) {
    Write-Host "Fetching the files from "$branchUrl
    $basicAuthValue = getSvnBasicAuthVal
    $Headers = @{    Authorization = $basicAuthValue     }

    if ((Test-Path $pathRoot"alma_labels.uil"))             {    Remove-Item $pathRoot"alma_labels.uil" }
    if ((Test-Path $pathRoot"code_tables_translation.uil")) {    Remove-Item $pathRoot"code_tables_translation.uil" }

    $progressPreference = 'silentlyContinue'
    Invoke-WebRequest -Uri $baseurl'alma_labels.uil'             -Headers $Headers -OutFile $pathRoot"alma_labels.uil"
    Invoke-WebRequest -Uri $baseurl'code_tables_translation.uil' -Headers $Headers -OutFile $pathRoot"code_tables_translation.uil"
}

######################################
function readUilFiles() {
    $dir = $pathRoot
    #$sandUilFilesDir = "C:\\urm\\workspace-1.0.0.2-URM\\dps-build-runtime\\src\\main\\sql\\factory_settings\\"
    #$prodUilFilesDir = "C:\\urm\\workspace_release\\dps-build-runtime\\src\\main\\sql\\factory_settings\\"
    #$dir = $prodUilFilesDir

	readOneUilFile $dir"alma_labels.uil"
    readOneUilFile $dir"code_tables_translation.uil"

    $sizeOfHash = $tableCodeAndLangToText_Excel.Count
    log "All translation in UIL files: $sizeOfHash"
}

######################################
function readOneUilFile($fileName) {
	$lineNum = 0
	$langCodes = @()
    log "Reading UIL $fileName ..."
	foreach($line in Get-Content $fileName) {
		$lineNum++
		if ($lineNum -lt 2) {
			$langCodes = $line.split("`t")
			#log $langCodes[3]
		}
		if ($lineNum -gt 1) {
			$cols = $line.split("`t")
            $codeTableName = $cols[0]
            $code = $cols[1].Trim() # .Trim() ?

            if ($codeTableName -eq "accessionGeneratorMethodOptions" -or $codeTableName -eq "CitationTrail") {
                #log $codeTableName
            }
            if ($code -eq "c.cb.label.recommended" ) {
                #log $codeTableName
            }

            for ($j = 2; $j -lt $cols.length -and $j -lt $langCodes.length; $j++) {
                $translation = $cols[$j].Trim()
                $langCodeForCol = $langCodes[$j]
                $hashKey = $codeTableName + $DEL + $code + $DEL + $langCodeForCol
                if ($tableCodeAndLangToText_Uil.ContainsKey($hashKey)) {
                    #log "key already in hash: $hashKey "
                } else {
                    $tableCodeAndLangToText_Uil.add($hashKey, $translation)
                    #log "...........added to hash:", $hashKey, $translation
                }
                
            }
            # TODO - print progress every 10,000 lines
	
		}
	}
    log ""
}

######################################
function createNewUilFiles() {
    createNewUilFiles $dir"alma_labels.uil"
    createNewUilFiles $dir"code_tables_translation.uil"
}

######################################
function createNewUilFile($filename) {
	$lineNum = 0
	$langCodes = @()
    $outFile = $filename+".new.txt"
    log "Reading $fileName and writing $outFile ..."
	foreach($line in Get-Content $fileName) {
		$lineNum++
		if ($lineNum -lt 2) {
            writeLineFromString $line $outFile
			$langCodes = $line.split("`t")
		}
		if ($lineNum -gt 1) {
			$cols = $line.split("`t")
            $codeTableName = $cols[0]
            $code = $cols[1].Trim()

            $smallHashKey = $codeTableName + $DEL + $code
            if (-not $tableAndCodeToNothing_Excel.ContainsKey($smallHashKey)) {
                #log " No changes for this line - simply print it as is $smallHashKey"
                appendLineFromString $line $outFile
                continue
            }
             
            #log " Need to update some translations $smallHashKey"
            $updatedLineArray = [System.Collections.ArrayList]@()
            $tempNum = $updatedLineArray.Add($cols[0])
            $tempNum = $updatedLineArray.Add($cols[1])
            for ($j = 2; $j -lt $cols.length -and $j -lt $langCodes.length; $j++) {
                if ($j -lt $cols.length) {
                    $existingTranslation = $cols[$j].Trim()
                }
                $langCodeForCol = $langCodes[$j]
                $hashKey = $codeTableName + $DEL + $code + $DEL + $langCodeForCol
                if ($tableCodeAndLangToText_Excel.ContainsKey($hashKey)) {
                    $newTranslation = $tableCodeAndLangToText_Excel[$hashKey]
                    log " We have new translatino for this lang - $hashKey : $newTranslation"
                    $tempNum = $updatedLineArray.Add($newTranslation)
                } else {
                    #log " No new translatino for this lang - $hashKey"
                    $tempNum = $updatedLineArray.Add($existingTranslation)
                }
            }
            appendLineFromArray $updatedLineArray $outFile
	        $tableAndCodeToNothing_Excel[$smallHashKey] = 'added'
		}
	}

    # handling code-table labels which are translated for the first time
    if ([io.path]::GetFileNameWithoutExtension($filename)  -eq 'code_tables_translation') {
        foreach ($h in $tableAndCodeToNothing_Excel.GetEnumerator()) {
            $smallHashKey = $($h.Name)
            $value = $tableAndCodeToNothing_Excel[$smallHashKey]
            if ($value -ne 'added') {
                log " Line from the Excel which were not found in any UIL file: $smallHashKey"
                $newLineArray = [System.Collections.ArrayList]@()
                
                $newTable = $smallHashKey -replace "$DEL.*",""
                $newCode  = $smallHashKey -replace ".*$DEL",""
                $tempNum = $newLineArray.Add($newTable)
                $tempNum = $newLineArray.Add($newCode)

                for ($j = 2; $j -lt $langCodes.length; $j++) {
                    $langCodeForCol = $langCodes[$j]
                    $hashKey = $smallHashKey + $DEL + $langCodeForCol
                    if ($tableCodeAndLangToText_Excel.ContainsKey($hashKey)) {
                        $newTranslation = $tableCodeAndLangToText_Excel[$hashKey]
                        log " We have NEW translatino for this lang - $hashKey : $newTranslation"
                        $tempNum = $newLineArray.Add($newTranslation)
                    } else {
                        #log " No NEW translatino for this lang - $hashKey"
                        $tempNum = $newLineArray.Add("")
                    }
                }
                appendLineFromArray $newLineArray $outFile
            }
        }
    }
}

######################################
function writeLineFromString ($str, $outFile) {
    $str | out-file -filepath $outFile -Encoding BigEndianUnicode
}

######################################
function appendLineFromArray ($arr, $outFile) {
    $str = $arr -join "`t"
    appendLineFromString $str $outFile
}

######################################
function appendLineFromString ($str, $outFile) {
    $str | out-file -filepath $outFile -append  -Encoding BigEndianUnicode
}

######################################
function testCreateNewUilFile() {
    Import-Module $PSScriptRoot\Utils-Excel.ps1    -Force
    Import-Module $PSScriptRoot\Utils-General.ps1  -Force
    Write-Host testCreateNewUilFile...
    $pathRoot = $PSScriptRoot+"\test_small_files\"
    $now = Get-Date -format "yyyy-MM-dd_HH-mm-ss"
    $logFile = $pathRoot+"testCreateNewUilFile."+$now+".log.txt"
    $DEL = " zzz "
    $tableAndCodeToNothing_Excel  = new-object System.Collections.Hashtable
    $tableCodeAndLangToText_Excel = new-object System.Collections.Hashtable

    $excelFileName = $pathRoot+"translation_test_hebrew.xlsx"
    readExcelFile $excelFileName


    $uilFileName = $pathRoot+"alma_labels.uil"
    createNewUilFile $uilFileName

    $uilFileName = $pathRoot+"code_tables_translation.uil"
    createNewUilFile $uilFileName
}

testCreateNewUilFile