
######################################
function fetchUilFilesFromSvn($baseurl) {
    Write-Host "Fetching the files from "$branchUrl
    $basicAuthValue = getSvnBasicAuthVal
    $Headers = @{    Authorization = $basicAuthValue     }

    if ((Test-Path $pathRoot"alma_labels.uil"))             {    Remove-Item $pathRoot"alma_labels.uil" }
    if ((Test-Path $pathRoot"code_tables_translation.uil")) {    Remove-Item $pathRoot"code_tables_translation.uil" }

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
    log "Reading $fileName ..."
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
