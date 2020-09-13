
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