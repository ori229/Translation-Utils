Set-StrictMode -Version Latest

Import-Module $PSScriptRoot\utils\Utils-Excel.ps1    -Force
Import-Module $PSScriptRoot\utils\Utils-UilFiles.ps1 -Force
Import-Module $PSScriptRoot\utils\Utils-General.ps1  -Force

######################################
function main() {
    $pathRoot = $PSScriptRoot+"\import\"

    $now = Get-Date -format "yyyy-MM-dd_HH-mm-ss"

    $logFile = $pathRoot+$now+".log.txt"
    log "Starting import. Folder: $pathRoot"

    $DEL = " _I_ "
    
    $tableCodeAndLangToText_Excel = new-object System.Collections.Hashtable # case sensitive
    $tableAndCodeToInfo_Excel     = new-object System.Collections.Hashtable # case sensitive
    #$tableCodeAndLangToText_Uil   = new-object System.Collections.Hashtable # case sensitive

    readExcelFiles

    foreach ($branchUrl in (getSvnBranchesUrls).GetEnumerator()) {
        log "_________________________"

        $branchName = getBranchName $branchUrl

        getSvnWorkingCopy $branchUrl $branchName

        createNewUilFiles

        backupOldAndRenameNew $branchName

        commitUpdatedUilFile $branchName
    }

    log "Done!"
    #echo "Press any key to close"
    #cmd /c pause | out-null
}

main