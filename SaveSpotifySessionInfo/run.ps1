# POST method: $req
$requestBody = Get-Content $req -Raw | ConvertFrom-Json
$ClientId = $requestBody.ClientId
$Secret = $requestBody.Secret
$RefreshToken = $requestBody.RefreshToken

if([bool]$ClientId -and [bool]$Secret -and [bool]$RefreshToken) {
    $Data = @{
        ClientId = $requestBody.ClientId
        Secret = $requestBody.Secret
        RefreshToken = $requestBody.RefreshToken
        id = (get-variable -name "REQ_HEADERS_X-FUNCTIONS-KEY" -valueonly)
    }
    Out-File -Encoding Ascii -FilePath $Session -inputObject ($Data | convertto-json)
} else {
    throw "Missing data"
}