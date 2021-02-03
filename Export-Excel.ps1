Set-StrictMode -Version Latest

Import-Module $PSScriptRoot\utils\Utils-Excel.ps1    -Force
Import-Module $PSScriptRoot\utils\Utils-General.ps1  -Force
Import-Module $PSScriptRoot\utils\Utils-UilFiles.ps1 -Force

# Load EPPlus - can the below DLL and ps1 files can be taken from https://www.powershellgallery.com/packages/ImportExcel/7.1.1
$storageAssemblyPath = $PSScriptRoot+'\utils\EPPlus.dll'
$bytes = [System.IO.File]::ReadAllBytes($storageAssemblyPath)
[System.Reflection.Assembly]::Load($bytes)
Import-Module $PSScriptRoot\utils\Excel-Module.ps1        -Force
Import-Module $PSScriptRoot\utils\Open-ExcelPackage.ps1   -Force
Import-Module $PSScriptRoot\utils\Add-Worksheet.ps1       -Force
Import-Module $PSScriptRoot\utils\Expand-NumberFormat.ps1 -Force 

######################################
function main() {

    $pathRoot = $PSScriptRoot+"\work\"
    $now = Get-Date -format "yyyy-MM-dd_HH-mm-ss"

    $logFile = $pathRoot+$now+".log.txt"
    log "Starting export. Folder: $pathRoot"

    $tableCodeToText_DB = new-object System.Collections.Hashtable
    $tableAndCodeToInfo_Excel  = new-object System.Collections.Hashtable
    $tableCodeAndLangToText_Excel = new-object System.Collections.Hashtable
    $tableCodeAndLangToText_Uil   = new-object System.Collections.Hashtable # case sensitive
    $tableCodeToSubSystem_DB = new-object System.Collections.Hashtable

    $allEnglishCodeTablesMapping = new-object System.Collections.Hashtable

    $DEL = " _I_ "
    
    # Read UilFiles from the Release Branch:
    $releaseBranchUrl = (getSvnBranchesUrls)[1]
    fetchUilFilesFromSvn $releaseBranchUrl
    readUilFiles

    # Read from the DB (because we might have new labels which are not yet in code_table_translation.uil):
    readEnFromDB
    getCodeTablesSubSystem
    

    # Create Excel file. English from the DB, and translation (if exists) from the UIL file:
    exportExcelFiles

    log "Done!"
    #echo "Press any key to close"
    #cmd /c pause | out-null
}

######################################
function exportExcelFiles() {
    $exportFiles = readConfigurationFile($PSScriptRoot+"\export_configuration.txt")

    foreach($line in $exportFiles) {
        if ([string]::IsNullOrEmpty($line) -Or $line.StartsWith("#") -Or -Not ( $line -match "-" -And $line -match ",") ) {
            log "Skipping line $line in export_configuration ..."
            continue;
        } 
        $lang = $line.Substring(0,$line.LastIndexOf('-')).trim()
        $exportFilters = $line.Substring($line.LastIndexOf('-')+1).trim().split(",")
        $isPatronFacing = $exportFilters[0] -eq "pf"
        $labelSets = $exportFilters[1].ToUpper().split("+")
        $isDelta = $exportFilters[2] -eq "Delta"
        $ExportFileName = $pathRoot+$lang+"_"+$exportFilters[0]+"_"+$exportFilters[1]+"_"+$exportFilters[2]+".translations.xlsx"
        $allEnglishCodeTablesMapping = deepClone($tableCodeToText_DB)
        filterCodeTables $labelSets $isPatronFacing
        exportExcelFile $lang $ExportFileName $isDelta
    }
}

######################################
function exportExcelFile($lang,$ExportFileName,$isDelta) {
    [System.String]$langHeader = getLangHeader($lang)
    if (Test-Path $ExportFileName) {
        Remove-Item $ExportFileName
    }
    $results = @()
    foreach ($h in $allEnglishCodeTablesMapping.GetEnumerator()) {
        $key = $($h.Name)
        foreach ($c in $allEnglishCodeTablesMapping.Get_Item($key).GetEnumerator()) {
            $codeValue = $($c.Name)
            $en = $($c.Value)
            if ($en -match ".*[a-zA-Z].*") {
                #log "good - has letters - $en"
            } else {
                #log "skip because the desc for en has no English letters: $en"
                continue
            }
            if ($en.contains("_") -and -not $en.contains(" ")) {
                #log "skip because the desc for en seem like a code: $en"
                continue;
            }

            $keyWithLang =  $key + $DEL + $codeValue +$DEL+$lang
            $translation=""
            if ($tableCodeAndLangToText_Uil.containsKey($keyWithLang)) {
                $translation = $tableCodeAndLangToText_Uil[$keyWithLang]
                #log "Found! $translation"
            }
            if(-Not [string]::IsNullOrEmpty($translation) -And $isDelta -eq $true){
                continue;
            }

            #if($en.startswith("=")){ # in the Export-Excel Module lines that started with "=" where converted to Formulas. When using our Excel-Module.ps1 file we can configure this as well.
                #$en = "'$en"
            #}
            $details = @{            
                    'Code table' = $key
                    'codeValue'  = $codeValue
                    'Sub system' = $tableCodeToSubSystem_DB[$key]
                    'Original text (EN)' = $en
                     $langHeader = $translation
            }                           

            $results += New-Object PSObject -Property $details  
        }
    }
    $results |
    Select-Object "Code table", "codeValue", "Sub system", "Original text (EN)", $langHeader | 
            Sort-Object -Property @{Expression="Code table"; Descending=$false}, @{Expression="codeValue" ;Descending=$false} |
            Export-Excel $ExportFileName -WorksheetName 'Code Table Translation' -NoNumberConversion * -BoldTopRow;
            #Export-Csv $ExportFileName".csv" -NoTypeInformation -Encoding UTF8
    
    log "Finished Exprting File $ExportFileName ..."
   
}

#####################################
function readEnFromDB() {
    add-type -path (getOracleClientDllPath)

    try{
        $con = New-Object Oracle.ManagedDataAccess.Client.OracleConnection -ArgumentList (getOracleConnectionString)
        $con.Open()
        $sql="select CODE_TABLE_NAME,CODE,DESCRIPTION from C_C_CODE_TABLES t where t.lang='en' AND 
             ( t.customerId  = 0 AND t.institutionId  = 11 AND t.libraryId  IS NULL AND t.libraryUnitId  IS NULL )
             order by t.CODE_TABLE_NAME, t.DISPLAY_ORDER, t.description"
        $adap = New-Object Oracle.ManagedDataAccess.Client.OracleDataAdapter($sql,$con)
        $oraCmdBldr = New-Object Oracle.ManagedDataAccess.Client.OracleCommandBuilder($adap)
    
        [System.Data.DataSet]$dataset = New-Object System.Data.DataSet
        $tempNum = $adap.Fill($dataset)
        for($i=0;$i -lt $dataset.Tables[0].Rows.Count;$i++)  { 
            $codeTableName = $($dataset.Tables[0].Rows[$i][0])
            $code          = $($dataset.Tables[0].Rows[$i][1])
            $description   = $($dataset.Tables[0].Rows[$i][2])
            $hashKey = $codeTableName + $DEL + $code
            if( -Not $tableCodeToText_DB.ContainsKey($codeTableName)){
                $currentTableMapping = new-object System.Collections.Hashtable
                $currentTableMapping.Set_Item($code,$description)
                $tableCodeToText_DB.Set_Item($codeTableName,$currentTableMapping )
            }else{
               $currentTableMapping = $tableCodeToText_DB.Get_Item($codeTableName)
               if ($currentTableMapping.ContainsKey($code)) {
                  log " WARNING: Key already in hash: $hashKey "
               }
               $currentTableMapping.Set_Item($code,$description)
               $tableCodeToText_DB.Set_Item($codeTableName,$currentTableMapping )
            }
        }

        Remove-Variable dataset
    } catch {
        Write-Error ("Can't open connection: {0}`n{1}" -f `
            $con.ConnectionString, $_.Exception.ToString())
    } finally{
        if ($con.State -eq 'Open') { $con.close() }
    }

    
}

#####################################
function getCodeTablesSubSystem(){
    add-type -path (getOracleClientDllPath)
    try{
        $con = New-Object Oracle.ManagedDataAccess.Client.OracleConnection -ArgumentList (getOracleConnectionString)
        $con.Open()
        $sql="select t.code_table_name,t.sub_system from C_C_TABLE_OF_TABLES t where t.table_type='C' and
             ( t.customerId  = 0 AND t.institutionId  = 11 AND t.libraryId  IS NULL AND t.libraryUnitId  IS NULL )"
        $adap = New-Object Oracle.ManagedDataAccess.Client.OracleDataAdapter($sql,$con)
        $oraCmdBldr = New-Object Oracle.ManagedDataAccess.Client.OracleCommandBuilder($adap)
    
        [System.Data.DataSet]$dataset = New-Object System.Data.DataSet
        $tempNum = $adap.Fill($dataset)
        for($i=0;$i -lt $dataset.Tables[0].Rows.Count;$i++)  { 
            #write-host "row num $i :    "
            $codeTableName = $($dataset.Tables[0].Rows[$i][0])
            $subSystem = $($dataset.Tables[0].Rows[$i][1])
            $tableCodeToSubSystem_DB.Set_Item($codeTableName,$subSystem )
        }
        
        Remove-Variable dataset
    } catch {
        Write-Error ("Can't open connection: {0}`n{1}" -f `
            $con.ConnectionString, $_.Exception.ToString())
    } finally{
        if ($con.State -eq 'Open') { $con.close() }
    }
}

#####################################
function filterCodeTables($labelSets,$isPatronFacing){
    add-type -path (getOracleClientDllPath)

    try{
        $con = New-Object Oracle.ManagedDataAccess.Client.OracleConnection -ArgumentList (getOracleConnectionString)
        $con.Open()
        $sql="select m.target_code,m.source_code_2 from c_c_mapping_tables m where m.mapping_table_name='TranslationData' and m.source_code_4='N' and
             ( m.customerId  = 0 AND m.institutionId  = 11 AND m.libraryId  IS NULL AND m.libraryUnitId  IS NULL )"
        $adap = New-Object Oracle.ManagedDataAccess.Client.OracleDataAdapter($sql,$con)
        $oraCmdBldr = New-Object Oracle.ManagedDataAccess.Client.OracleCommandBuilder($adap)
    
        [System.Data.DataSet]$dataset = New-Object System.Data.DataSet
        $tempNum = $adap.Fill($dataset)
        for($i=0;$i -lt $dataset.Tables[0].Rows.Count;$i++)  { 
            #write-host "row num $i :    "
            $targetCode = $($dataset.Tables[0].Rows[$i][0])
            $sourceCode2 = $($dataset.Tables[0].Rows[$i][1])
            if ([string]::IsNullOrEmpty($sourceCode2)){
               $allEnglishCodeTablesMapping.Remove($targetCode)
            }elseif($allEnglishCodeTablesMapping.ContainsKey($targetCode)){
               $currentTableMapping = $allEnglishCodeTablesMapping.Get_Item($targetCode)
               $currentTableMapping.Remove($sourceCode2)
               $allEnglishCodeTablesMapping.Set_Item($targetCode,$currentTableMapping )
            }
        }
        
        Remove-Variable dataset
    } catch {
        Write-Error ("Can't open connection: {0}`n{1}" -f `
            $con.ConnectionString, $_.Exception.ToString())
    } finally{
        if ($con.State -eq 'Open') { $con.close() }
    }
    filterByLabelSets($labelSets)
    if($isPatronFacing -eq $true){
       filterPatronFacingCodeTables
    }
    
}

#####################################
function filterByLabelSets($labelSets){
    $almaRequested = $labelSets -contains "ALMA"
    $marcLabelSets = @( "UNIMARC", "CNMARC", "KORMARC", "MARC21", "GND", "DC")
    $marcLabelRequested = @($labelSets | ?{$marcLabelSets -contains $_})
    foreach($key in ($allEnglishCodeTablesMapping.clone()).keys){
      $codeTableName = $key
      if($codeTableName -eq "MARCProfileFieldsDescription"){
        if($marcLabelRequested.Count -eq 0 ){
            $allEnglishCodeTablesMapping.Remove($codeTableName)
        }else{
            $currentTableMapping = $allEnglishCodeTablesMapping.Get_Item($codeTableName) 
            foreach($code in ($currentTableMapping.clone()).keys){
                $save = $false
                for ($i=0; $i -lt $marcLabelRequested.length; $i++) {
	                if($code -Match $marcLabelRequested[$i]){
                        $save = $true
                    }
                }
                if($save -eq $false){
                    $currentTableMapping.Remove($code)
                }
            }
            $allEnglishCodeTablesMapping.Set_Item($codeTableName,$currentTableMapping )
        }
      }else{
        $matchingSets = New-Object System.Collections.Generic.List[System.String]
        if( $codeTableName.StartsWith("UILeganto")){
            $matchingSets.Add('LEGANTO')
        }
        $subsystem = $tableCodeToSubSystem_DB[$codeTableName]
        if ($subsystem -cMatch "PRIMA") {
            $matchingSets.Add('SUPRIMA')
        }
        if ($subsystem -cMatch "RESEARCH") {
            $matchingSets.Add('RESEARCH')
        }
        for ($i=0; $i -lt $marcLabelSets.length; $i++) {
            if ($codeTableName -cMatch $marcLabelSets[$i]) {
                $matchingSets.Add($marcLabelSets[$i])
            }
        }
        $requestedSetsMatched = @($labelSets | ?{$matchingSets -contains $_})
        if ($requestedSetsMatched.Count -eq 0 -And ($almaRequested -eq $false -Or ($almaRequested -And -Not $matchingSets.Count -eq  0))) {
              $allEnglishCodeTablesMapping.Remove($codeTableName)          
        }
      }
    }
}

#####################################
function filterPatronFacingCodeTables(){
    add-type -path (getOracleClientDllPath)
    $patronFacingMap = new-object System.Collections.Hashtable
    try{
        $con = New-Object Oracle.ManagedDataAccess.Client.OracleConnection -ArgumentList (getOracleConnectionString)
        $con.Open()
        $sql="select m.target_code,m.source_code_2 from c_c_mapping_tables m where m.mapping_table_name='TranslationData' and m.source_code_3='Y' and m.source_code_3<>'N' and
             ( m.customerId  = 0 AND m.institutionId  = 11 AND m.libraryId  IS NULL AND m.libraryUnitId  IS NULL )"
        $adap = New-Object Oracle.ManagedDataAccess.Client.OracleDataAdapter($sql,$con)
        $oraCmdBldr = New-Object Oracle.ManagedDataAccess.Client.OracleCommandBuilder($adap)
    
        [System.Data.DataSet]$dataset = New-Object System.Data.DataSet
        $tempNum = $adap.Fill($dataset)
        for($i=0;$i -lt $dataset.Tables[0].Rows.Count;$i++)  { 
            #write-host "row num $i :    "
            $targetCode = $($dataset.Tables[0].Rows[$i][0])
            $sourceCode2 = $($dataset.Tables[0].Rows[$i][1])
            if( -Not $patronFacingMap.ContainsKey($targetCode)){
                $currentTableMapping = New-Object System.Collections.Generic.List[System.String]
                $patronFacingMap.Set_Item($targetCode,$currentTableMapping )
            }
            $currentTableMapping = $patronFacingMap.Get_Item($targetCode)
            if ( -Not  [string]::IsNullOrEmpty($sourceCode2)){
                $currentTableMapping.Add($sourceCode2)
                $patronFacingMap.Set_Item($targetCode,$currentTableMapping )
            }
        }
        Remove-Variable dataset
        foreach($codeTableName in ($allEnglishCodeTablesMapping.clone()).keys){
            if(-Not $patronFacingMap.ContainsKey($codeTableName)){
                $allEnglishCodeTablesMapping.Remove($codeTableName)
                continue;
            }
            if($patronFacingMap.Get_Item($codeTableName).Count -gt 0){
                $currentTableMapping = $allEnglishCodeTablesMapping.Get_Item($codeTableName) 
                foreach($code in ($currentTableMapping.clone()).keys){
                    if(-Not $patronFacingMap.Get_Item($codeTableName).Contains($code)){
                        $currentTableMapping.Remove($code)
                    }
                }
                $allEnglishCodeTablesMapping.Set_Item($codeTableName,$currentTableMapping )
            }
        }
        
        Remove-Variable patronFacingMap
    } catch {
        Write-Error ("Can't open connection: {0}`n{1}" -f `
            $con.ConnectionString, $_.Exception.ToString())
    } finally{
        if ($con.State -eq 'Open') { $con.close() }
    }

    
}

#####################################
function getLangHeader($lang) {
 add-type -path (getOracleClientDllPath)
    [System.String]$description = 'Translation ('+ $lang +')' 
    try{
        $con = New-Object Oracle.ManagedDataAccess.Client.OracleConnection -ArgumentList (getOracleConnectionString)
        $con.Open()
        #Write-Host ("Connected to database: {0} running on host: {1} Servicename: {2} Serverversion: {3}" -f $con.DatabaseName, $con.HostName, $con.ServiceName, $con.ServerVersion) -ForegroundColor Cyan -BackgroundColor Black
        $sql="select description from C_C_CODE_TABLES t 
                where t.CODE_TABLE_NAME='UserPreferredLanguage' and t.lang= 'en' and t.code='"+$lang.ToLower()+"' AND 
                ( ( t.customerId  = 0 AND t.institutionId  = 11 AND t.libraryId  IS NULL AND t.libraryUnitId  IS NULL ) ) order by t.DISPLAY_ORDER"
        $adap = New-Object Oracle.ManagedDataAccess.Client.OracleDataAdapter($sql,$con)
        $oraCmdBldr = New-Object Oracle.ManagedDataAccess.Client.OracleCommandBuilder($adap)
        [System.Data.DataSet]$dataset = New-Object System.Data.DataSet
        $tempNum = $adap.Fill($dataset)
        if($tempNum -gt 0){
            $description = $dataset.Tables[0].rows[0].description +' ('+ $lang +')' 
        }else{
            log ("Invalid language code: {0}" -f` $lang)
        }
        Remove-Variable dataset
    } catch {
        Write-Error ("Can't open connection: {0}`n{1}" -f `
            $con.ConnectionString, $_.Exception.ToString())
    } finally{
        if ($con.State -eq 'Open') { $con.close() }
    }
    #Write-Information $description
    return $description
}


main