
######################################
function init() {
    $now = Get-Date -format "yyyy-MM-dd_HH-mm-ss"
    $DEL = " zzz "
}

######################################
function log($line) {
    Write-Host $line
    $line | out-file -filepath $logFile -append
}

######################################
function getSvnBasicAuthVal() {
    $AppProps = convertfrom-stringdata (get-content $PSScriptRoot"\private.properties" -raw)
    Write-Host "      Using user: "($AppProps.'svn.user')
    $user_pw = ($AppProps.'svn.user') + ":" + ($AppProps.'svn.pw')
    $encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($user_pw))
    return "Basic $encodedCreds"
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

init
