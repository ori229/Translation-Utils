Set-StrictMode -Version Latest

Import-Module $PSScriptRoot\Utils-Excel.ps1    -Force
Import-Module $PSScriptRoot\Utils-UilFiles.ps1 -Force
Import-Module $PSScriptRoot\Utils-General.ps1  -Force

# TODO:
# Handle all 3 branches
# Generate UIL file
# Save old UIL file with timestamp

# commit - From which dir?  DESCRIPTION=JIRA: URM-24347 Developer: almatranslation Description: ...
# svn commit --username ${SVN_USER} --password ${SVN_PASS} -m "${DESCRIPTION} build id:${BUILD_ID} " ${WORKSPACE}/factory_settings/alma_labels.uil

# Export:
# From DB? support all filters - perhaps with configuration to allow running just once

######################################
function main() {
    $pathRoot = $PSScriptRoot+"\small_test\"

    $now = Get-Date -format "yyyy-MM-dd_HH-mm-ss"

    $logFile = $pathRoot+$now+".log.txt"
    log "Starting - folder: $pathRoot"

    $DEL = " |-|-| "
    
    $tableCodeAndLangToText_Excel = new-object System.Collections.Hashtable # case sensitive
    $tableCodeAndLangToText_Uil   = new-object System.Collections.Hashtable # case sensitive

    readExcelFiles

    fetchUilFilesFromSvn
    readUilFiles

    verifyExcelsAreInUil

    log "Done!"
}

######################################
function verifyExcelsAreInUil() {
    foreach ($h in $tableCodeAndLangToText_Excel.GetEnumerator()) {
        $hashKey = $($h.Name)
        $translation = $tableCodeAndLangToText_Excel[$hashkey]
        # Write-Host "from the Excel hash: $hashKey : $translation"
        if ($tableCodeAndLangToText_Uil.ContainsKey($hashKey) -and $tableCodeAndLangToText_Uil[$hashkey] -eq $translation) {
            # good
        } else {
            log "For $hashKey :"
            log "    in Excel we have: $translation" 
            log ("         and in UILs: "+ $tableCodeAndLangToText_Uil[$hashkey])
        }
    }

}

########################
# We run the main() from here to make sure all functions are loaded each time we run this file
main