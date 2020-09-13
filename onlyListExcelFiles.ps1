function main() {
    $pathRoot = "C:\Temp\1\small\"
    log "Starting - folder: $pathRoot"
    readExcelFiles
}


######################################
function log($line) {
    Write-Host $line
 }


######################################
function readExcelFiles() {
	$excel = New-Object -Com Excel.Application
	foreach($file in (Get-ChildItem -path "$pathRoot*" -include *.xlsx )) {
		log "Reading $file ..."
		Add-Type -AssemblyName System.Web
		$sh = $excel.Workbooks.Open($file).Sheets.Item(1)
        $lang = $sh.Cells.Item(1,5).Text
		log "Lang: $lang"
		$excel.Workbooks.Close()
	}
	$excel.Quit()  
}

########################
# We run the main() from here to make sure all functions are loaded each time we run this file
main