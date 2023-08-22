
######################################
function fetchUilFilesFromSvn($baseurl) {
    log ("Fetching the files from "+$baseurl)
    $basicAuthValue = getSvnBasicAuthVal
    $Headers = @{    Authorization = $basicAuthValue     }

    if ((Test-Path $pathRoot"alma_labels.uil"))             {    Remove-Item $pathRoot"alma_labels.uil" }
    if ((Test-Path $pathRoot"code_tables_translation.uil")) {    Remove-Item $pathRoot"code_tables_translation.uil" }

    #$progressPreference = 'silentlyContinue'
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

    $sizeOfHash = $tableCodeAndLangToText_Uil.Count
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
# The order is important, because after handling both files, we have the special case for code_tables_translation
# (adding lines when it's the first translation).
#
# Note: if code apears in both files - we'll update in both places. Alma's code only updates code_tables_translation
function createNewUilFiles() {
    createNewUilFile ($pathRoot+"alma_labels.uil")
    createNewUilFile ($pathRoot+"code_tables_translation.uil")
}

######################################
function createNewUilFile($filename) {
	$lineNum = 0
	$langCodes = @()
    $outFile = $filename+".new.txt"
    Clear-Content $outFile -ErrorAction SilentlyContinue
    $stream = [IO.StreamWriter]::new($outFile, $false, [Text.Encoding]::BigEndianUnicode)


    log "Reading      $fileName `n and writing $outFile ..."
	foreach($line in Get-Content $fileName) {
		$lineNum++
        if ($lineNum%10000 -eq 0) { log "...done reading $lineNum lines" }
		if ($lineNum -lt 2) {
            writeLineFromString $line $outFile
			$langCodes = $line.split("`t")
            #log(" Found " + $langCodes.length + " languages, including the table, code (and en in code-table-uil)")
		}
		if ($lineNum -gt 1) {
			$cols = $line.split("`t")
            if ($cols.Length -gt $langCodes.Length) {
                log "WARNING: More columns than languages in line $lineNum of $fileName"
            }
            $codeTableName = $cols[0]
            $code = $cols[1].Trim()

            $smallHashKey = $codeTableName + $DEL + $code
            if (-not $tableAndCodeToInfo_Excel.ContainsKey($smallHashKey)) {
                #log " No changes for this line - simply print it as is $smallHashKey"
                appendLineFromString $line $outFile
                continue
            }
             
            #log " Need to update some translations $smallHashKey"
            $updatedLineArray = [System.Collections.ArrayList]@()
            $tempNum = $updatedLineArray.Add($cols[0])
            $tempNum = $updatedLineArray.Add($cols[1])
            for ($j = 2; $j -lt $langCodes.length; $j++) {
                $existingTranslation = ""
                if ($j -lt $cols.length) {
                    $existingTranslation = $cols[$j]
                }
                $langCodeForCol = $langCodes[$j]
                $hashKey = $codeTableName + $DEL + $code + $DEL + $langCodeForCol
                if ($tableCodeAndLangToText_Excel.ContainsKey($hashKey) -and $tableCodeAndLangToText_Excel[$hashKey].Trim() -ne $existingTranslation.Trim() ) {
                    $newTranslation = $tableCodeAndLangToText_Excel[$hashKey].Trim([char]0x000A, [char]0x0020, [char]0x200B) -replace '(\n|\r|\t)',' '
                    log " We have new translation for this lang - $hashKey : $newTranslation"
                    $tempNum = $updatedLineArray.Add($newTranslation)
                } else {
                    #log " No new translation for this lang - $hashKey - using existing: $existingTranslation"
                    $tempNum = $updatedLineArray.Add($existingTranslation)
                }
            }
            appendLineFromArray $updatedLineArray $outFile
	        $tableAndCodeToInfo_Excel[$smallHashKey] = '__added__'
		}
	}
    if ($lineNum -eq 0) { 
        log "file $filename is empty" 
        return
    }
    # handling code-table labels which are translated for the first time
    if ([io.path]::GetFileNameWithoutExtension($filename)  -eq 'code_tables_translation') {
        foreach ($h in $tableAndCodeToInfo_Excel.GetEnumerator()) {
            $smallHashKey = $($h.Name)
            $value = $tableAndCodeToInfo_Excel[$smallHashKey]
            if ($value -ne '__added__') {
                log " Line from the Excel which was not found in any UIL file: $smallHashKey"
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
                        #log " We have NEW translation for this lang - $hashKey : $newTranslation"
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
    log "...done reading $lineNum lines"
    $stream.close()
}

######################################
function writeLineFromString ($str, $outFile) {
    $stream.WriteLine($str)
}

######################################
function appendLineFromArray ($arr, $outFile) {
    $str = $arr -join "`t"
    appendLineFromString $str $outFile
}

######################################
function appendLineFromString ($str, $outFile) {
    $stream.WriteLine($str)
}

######################################
function backupOldAndRenameNew($branchUrl) {
    log "Saving UIL files for $branchUrl"

    Rename-Item $pathRoot"code_tables_translation.uil" $pathRoot"code_tables_translation.uil.$branchUrl.$now"
    Rename-Item $pathRoot"alma_labels.uil"             $pathRoot"alma_labels.uil.$branchUrl.$now"

    Rename-Item $pathRoot"code_tables_translation.uil.new.txt" $pathRoot"code_tables_translation.uil.$branchUrl.$now.new"
    Rename-Item $pathRoot"alma_labels.uil.new.txt"             $pathRoot"alma_labels.uil.$branchUrl.$now.new"
}

######################################
function commitUpdatedUilFile($branchName, $fileNames) {

    $workingCopyDir= $pathRoot+$branchName+"\"
    Copy-Item $pathRoot"code_tables_translation.uil.$branchName.$now.new"    $workingCopyDir"factory_settings\code_tables_translation.uil"  -Force
    Copy-Item $pathRoot"alma_labels.uil.$branchName.$now.new"                $workingCopyDir"factory_settings\alma_labels.uil"              -Force

    $user = getSvnUser
    $pw = getSvnPw

    svn commit --username $user --password $pw -m "JIRA: URM-24347 Developer: almatranslation Description: Merge new translations $now Files: $fileNames"  $pathRoot$branchName"\factory_settings\code_tables_translation.uil"
    svn commit --username $user --password $pw -m "JIRA: URM-24347 Developer: almatranslation Description: Merge new translations $now Files: $fileNames"  $pathRoot$branchName"\factory_settings\alma_labels.uil"
    	
    log "END Saving UIL files for $branchName"
}


######################################
function getBranchName($branchUrl){

    $branchUrl = $branchUrl -replace ".*branches.",''
    $branchUrl = $branchUrl -replace ".*trunk.",''
    $branchUrl = $branchUrl -replace ".dps-build-runtime.*",''

    return $branchUrl
}


######################################
function getSvnWorkingCopy($branchUrl, $branchName){

    log ("Fetching the files from "+$branchUrl)

    $workingCopyDir= $pathRoot+$branchName+"\"
    
    if ((Test-Path $workingCopyDir)){
        Remove-Item -LiteralPath $workingCopyDir -Force -Recurse
    }
    New-Item -ItemType directory -Path $workingCopyDir

	$user = getSvnUser
    $pw = getSvnPw
	
    cd $workingCopyDir
    svn checkout --username $user --password $pw $branchUrl --depth empty
    cd "factory_settings"
     
    #get UIL files from the svn
    svn --username $user --password $pw up "alma_labels.uil"
    svn --username $user --password $pw up "code_tables_translation.uil"

    cd $pathRoot

    cd ..

    Move-Item -Path $workingCopyDir"factory_settings\code_tables_translation.uil" -Destination $pathRoot"code_tables_translation.uil" -Force
    Move-Item -Path $workingCopyDir"factory_settings\alma_labels.uil"             -Destination $pathRoot"alma_labels.uil" -Force

}

