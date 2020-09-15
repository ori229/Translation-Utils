Set-StrictMode -Version Latest

Import-Module $PSScriptRoot\Utils-Excel.ps1    -Force
Import-Module $PSScriptRoot\Utils-UilFiles.ps1 -Force
Import-Module $PSScriptRoot\Utils-General.ps1  -Force

######################################
function main() {
    $pathRoot = $PSScriptRoot+"\small_test\"

    $now = Get-Date -format "yyyy-MM-dd_HH-mm-ss"

    $logFile = $pathRoot+$now+".log.txt"
    log "Starting import. Folder: $pathRoot"

    $DEL = " zzz "
    
    $tableCodeAndLangToText_Excel = new-object System.Collections.Hashtable # case sensitive
    $tableAndCodeToInfo_Excel     = new-object System.Collections.Hashtable # case sensitive
    #$tableCodeAndLangToText_Uil   = new-object System.Collections.Hashtable # case sensitive

    readExcelFiles

    foreach ($branchUrl in (getSvnBranchesUrls).GetEnumerator()) {
        Write-Host "_________________________"

        fetchUilFilesFromSvn $branchUrl

        createNewUilFiles

        #backupOldAndRenameNew

        #commitUpdatedUilFile
    }

    log "Done!"
    #echo "Press any key to close"
    #cmd /c pause | out-null
}

main