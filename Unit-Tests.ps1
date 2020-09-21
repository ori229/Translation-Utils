
######################################
function testCreateNewUilFile() {
    Import-Module $PSScriptRoot\utils\Utils-Excel.ps1    -Force
    Import-Module $PSScriptRoot\utils\Utils-UilFiles.ps1 -Force
    Import-Module $PSScriptRoot\utils\Utils-General.ps1  -Force

    $now = Get-Date -format "yyyy-MM-dd_HH-mm-ss"
    $DEL = " _I_ "
    Write-Host testCreateNewUilFile...
    
    $pathRoot = $PSScriptRoot+"\test_small_files\"

    $logFile = $pathRoot+"testCreateNewUilFile."+$now+".log.txt"
    
    $tableAndCodeToInfo_Excel  = new-object System.Collections.Hashtable
    $tableCodeAndLangToText_Excel = new-object System.Collections.Hashtable

    readExcelFiles

    createNewUilFiles

    $diff = diff (cat $pathRoot"alma_labels.uil.new.txt") (cat $pathRoot"alma_labels.uil.expected.txt")
    if ($diff) {        Write-Host $diff    }  else { "Test OK!    - alma_labels.uil" }

    $diff = diff (cat $pathRoot"code_tables_translation.uil.new.txt") (cat $pathRoot"code_tables_translation.uil.expected.txt")
    if ($diff) {        Write-Host $diff    }  else { "Test OK!    - code_tables_translation.uil" }
}

testCreateNewUilFile