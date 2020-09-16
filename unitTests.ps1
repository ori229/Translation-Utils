
######################################
function testCreateNewUilFile() {
    Import-Module $PSScriptRoot\Utils-Excel.ps1    -Force
    Import-Module $PSScriptRoot\Utils-UilFiles.ps1 -Force
    Import-Module $PSScriptRoot\Utils-General.ps1  -Force

    $now = Get-Date -format "yyyy-MM-dd_HH-mm-ss"
    $DEL = " _I_ "
    Write-Host testCreateNewUilFile...
    
    $pathRoot = $PSScriptRoot+"\test_small_files\"

    $logFile = $pathRoot+"testCreateNewUilFile."+$now+".log.txt"
    
    $tableAndCodeToInfo_Excel  = new-object System.Collections.Hashtable
    $tableCodeAndLangToText_Excel = new-object System.Collections.Hashtable

    readExcelFiles

    createNewUilFiles

    $diff = diff (cat $pathRoot"code_tables_translation.uil.new.txt") (cat $pathRoot"code_tables_translation.uil.expected.txt")
    if ($diff) {        Write-Host $diff    }  else { "Test OK!" }
}

testCreateNewUilFile