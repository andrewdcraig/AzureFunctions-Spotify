$client_ID = $env:APPSETTING_CLIENT_ID;
$client_secret = $env:APPSETTING_CLIENT_SECRET;
$token_endpoint = $env:APPSETTING_TOKEN_ENDPOINT;

if ([bool]($req_query_validationToken)) {
    "Found validation token: $($req_query_validationToken)"
    $result = [PSCustomObject][Ordered]@{
        'Status'    = 200
        'Headers'   = $null
        'Body'      = $req_query_validationToken
    } | ConvertTo-Json
} elseif (test-path $request) {
    $RequestBody = (get-content -raw $request | convertfrom-json)
    'subscriptionId: '+ $RequestBody.value.subscriptionId
    import-module 'D:\home\site\wwwroot\PSModules\PSSpotify\PSSpotify.psd1' -force

    $resource = $RequestBody.value.resource;

    $AuthBody = @{
        grant_type = 'client_credentials'
        client_id = $client_ID
        client_secret = $client_secret
        resource = 'https://graph.microsoft.com'
    }

    $Access = $Authorization = Invoke-RestMethod $token_endpoint `
                -Method Post -ContentType "application/x-www-form-urlencoded" `
                -Body $AuthBody `
                -ErrorAction STOP
    
    $Data = Invoke-RestMethod "https://graph.microsoft.com/v1.0/$resource" -Headers @{Authorization = "bearer $($Access.access_token)"}

    $result = [PSCustomObject][Ordered]@{
        'Status'    = 204
        'Headers'   = $null
        'Body'      = $null
    } | ConvertTo-Json

    if($Data.subject -imatch '^spotify ?request') {
        "Writing request to queue"
        @{subject = $Data.subject; functionkey = $REQ_QUERY_CODE} | convertto-json | Out-File -FilePath $queue -Encoding utf8
    }
    
} else {
    $result = [PSCustomObject][Ordered]@{
        'Status'    = 400
        'Headers'   = $null
        'Body'      = $null
    } | ConvertTo-Json
}

$result | Out-File -FilePath $res -Encoding utf8