
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
    # TODO...
    # Maybe using the list from here: http://urmbuild:Alma2017!@il-cvs01/repos/Alma/Alma/branches
    return "September2020"
}


#getSvnBranchesUrls
#getOracleClientDllPath