
######################################
function log($line) {
    Write-Host $line
    $line | out-file -filepath $logFile -append
}

######################################
function getSvnBasicAuthVal() {
    $AppProps = convertfrom-stringdata (get-content $PSScriptRoot"\..\private.properties" -raw)
    #log "      Using user: "($AppProps.'svn.user')
    $user_pw = ($AppProps.'svn.user') + ":" + ($AppProps.'svn.pw')
    $encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($user_pw))
    return "Basic $encodedCreds"
}

######################################
function getSvnUser(){
    $AppProps = convertfrom-stringdata (get-content $PSScriptRoot"\..\private.properties" -raw)
    #log "      Using user: "($AppProps.'svn.user')
    return $AppProps.'svn.user'
}

######################################
function getSvnPw(){
    $AppProps = convertfrom-stringdata (get-content $PSScriptRoot"\..\private.properties" -raw)
    #log "      Using user: "($AppProps.'svn.pw')
    return $AppProps.'svn.pw'
}

######################################
# https://docs.bentley.com/LiveContent/web/Bentley%20i-model%20Composition%20Service%20for%20S3D%20Help-v2/en/GUID-AEFD08A2-1EEF-404E-93F9-C069FA46F33C.html
function getOracleClientDllPath() {
    $AppProps = convertfrom-stringdata (get-content $PSScriptRoot"\..\private.properties" -raw)
    $oracleClientDllPath = ($AppProps.'db.oracleClientDllPath')
    return $oracleClientDllPath
}

######################################
function getOracleConnectionString() {
    $AppProps = convertfrom-stringdata (get-content $PSScriptRoot"\..\private.properties" -raw)
    $username = ($AppProps.'db.user')
    $password = ($AppProps.'db.pw')
    $data_source = ($AppProps.'db.dataSource')
    return "User Id=$username;Password=$password;Data Source=$data_source"
}

######################################
function getSvnBranchesUrls() {
    $svnUrlPrefix = "http://il-cvs01/repos/Alma/Alma/";
    $svnUrlSuffix = "/dps-build-runtime/src/main/sql/factory_settings/"

    $branches = @(
        $svnUrlPrefix + "trunk/alma_soft"                               + $svnUrlSuffix
        $svnUrlPrefix + "branches/alma_release"                         + $svnUrlSuffix
        $svnUrlPrefix + "branches/" + (getPreviousBranchName) + "-PROD" + $svnUrlSuffix
    )
    return $branches
}

######################################
function getPreviousBranchName() {
    #return "September2020"
    $baseurl = "http://il-cvs01/repos/Alma/Alma/branches/"

    $basicAuthValue = getSvnBasicAuthVal
    $Headers = @{    Authorization = $basicAuthValue     }

    $html = New-Object -ComObject "HTMLFile";
     # Get responce content as string
    [string]$content = (Invoke-WebRequest -Uri $baseurl  -Headers $Headers -UseBasicParsing).Content 
    $html.IHTMLDocument2_write($content);
    $branches = $html.all.tags("li") | % InnerText

    $PreviousBranchName = "September2020-PROD/"
    foreach ($date in $branches) {
        if($date -match "-PROD/" -and -not ($date -match "clean-PROD/") -and -not ($date -match "update-PROD/")){
			log "date is $date ..."
            if( [datetime]::parseexact(("01" + $PreviousBranchName -replace "-PROD/","").Trim(), 'ddMMMMyyyy',$null) -lt [datetime]::parseexact(("01" + $date -replace "-PROD/","").Trim(), 'ddMMMMyyyy',$null)){
                $PreviousBranchName = $date
            }
         }
    }
    return ($PreviousBranchName -replace "-PROD/","").Trim()
}

######################################
function deepClone($tableCodeToText_DB) {
    # Serialize and Deserialize data using BinaryFormatter
    # https://stackoverflow.com/questions/9204829/deep-copying-a-psobject/9206956#9206956
    $ms = New-Object System.IO.MemoryStream
    $bf = New-Object System.Runtime.Serialization.Formatters.Binary.BinaryFormatter
    $bf.Serialize($ms, $tableCodeToText_DB)
    $ms.Position = 0
    $allEnglishCodeTablesMapping = $bf.Deserialize($ms)
    $ms.Close()
    return $allEnglishCodeTablesMapping
}

######################################
function readConfigurationFile($fileName) {
	$exportFiles = New-Object System.Collections.Generic.List[System.String]
    log "Reading Configuration $fileName ..."
	foreach($line in Get-Content $fileName) {
		$exportFiles.Add($line)
    }
    log ""
    return $exportFiles
}

#getSvnBranchesUrls
#getOracleClientDllPath