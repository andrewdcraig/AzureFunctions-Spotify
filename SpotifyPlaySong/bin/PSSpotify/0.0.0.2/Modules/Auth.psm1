$currentPath = Split-Path -Parent $MyInvocation.MyCommand.Path

$_AuthorizationEndpoint = "https://accounts.spotify.com/authorize"
$_TokenEndpoint = "https://accounts.spotify.com/api/token"
$_RootAPIEndpoint = "https://api.spotify.com/v1"
$_RedirectUri = "https://localhost:8001"

Import-LocalizedData -BindingVariable Strings -BaseDirectory $currentPath\..\Localized -FileName Strings.psd1 -UICulture en-US

$ValidPermissions = @(
    "user-read-recently-played",
    "user-read-private",
    "user-read-email",
    "user-read-playback-state",
    "user-modify-playback-state",
    "user-top-read",
    'playlist-modify-public',
    'playlist-modify-private',
    'playlist-read-private',
    'playlist-read-collaborative',
    'user-read-birthdate',
    'user-follow-read',
    'user-follow-modify'
)

function Connect-Spotify {
    [OutputType("PSSpotify.SessionInfo")]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [PSCredential]
        $ClientIdSecret,

        [parameter()]
        [string]
        $RootAPIEndpoint = $_RootAPIEndpoint,

        [parameter()]
        [string]
        $AuthorizationEndpoint = $_AuthorizationEndpoint,

        [parameter()]
        [string]
        $TokenEndpoint = $_TokenEndpoint,

        [parameter()]
        [string]
        $RedirectUri = $_RedirectUri,

        [parameter()]
        [string]
        $RefreshToken,

        [parameter()]
        [switch]
        $KeepCredential
    )

    DynamicParam {
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        $ParameterName = 'Permissions'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $false
        $AttributeCollection.Add($ParameterAttribute)
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($ValidPermissions)
        $AttributeCollection.Add($ValidateSetAttribute)
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string[]], $AttributeCollection)
        $PSBoundParameters["Permissions"] = $ValidPermissions
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)

        return $RuntimeParameterDictionary
    }

    process {
        if ($RefreshToken -eq "") {
            $AuthCode = Get-AuthorizationCode -AuthorizationEndpoint $AuthorizationEndpoint -ClientIdSecret $ClientIdSecret -Permissions $PSBoundParameters["Permissions"] -RedirectUri $RedirectUri
        
            $AccessToken = Get-AccessToken -TokenEndpoint $TokenEndpoint -ClientIdSecret $ClientIdSecret -AuthorizationCode $AuthCode -RedirectUri $RedirectUri
            $RefreshToken = $AccessToken.refresh_token
        }
        else {
            $body = [string]::format("grant_type=refresh_token&client_id={1}&client_secret={2}&refresh_token={0}", `
                    $RefreshToken, `
                    $ClientIdSecret.UserName, `
                    [System.Web.HttpUtility]::UrlEncode($ClientIdSecret.GetNetworkCredential().Password)
            )

            $AccessToken = Invoke-RestMethod $TokenEndpoint `
                -Method Post -ContentType "application/x-www-form-urlencoded" `
                -Body $body `
                -ErrorAction STOP
        }

        $Session = [PSCustomObject]@{
            Headers       = @{Authorization = "$($AccessToken.token_type) $($AccessToken.access_token)"; "content-type" = "application/json"}
            RootUrl       = $RootAPIEndpoint
            Expires       = $AccessToken.expires_in
            RefreshToken  = $RefreshToken
            TokenEndpoint = $TokenEndpoint
        }

        $Profile = Get-SpotifyProfile -Session $Session

        $Session | Add-Member -MemberType NoteProperty -Name CurrentUser -Value $Profile

        $Session.PSObject.TypeNames.Insert(0, "PSSpotify.SessionInfo")
        $Global:SpotifySession = $Session

        if ($KeepCredential) {
            $Global:SpotifyCredential = $ClientIdSecret
        }

        $Session
    }
}

function Assert-AuthToken {
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Session = $Global:SpotifySession
    )

    process {
        try {
            $Url = "$($Session.RootUrl)/me"
            
            Invoke-RestMethod -Headers $Session.Headers `
                -Uri $Url `
                -Method Get | out-null
        }
        catch {
            $Error = ConvertFrom-Json $_.ErrorDetails.Message
            if ($Error.Error.Message -eq "The access token expired") {
                [void]$(
                    If ($Strings -eq $null) {
                        $pscmdlet.WriteVerbose("Session has expired. Requesting new token.")
                    }
                    else {
                        $pscmdlet.WriteVerbose($Strings["TokenExpiredGenerating"])
                    }

                    Connect-Spotify -ClientIdSecret $Global:SpotifyCredential `
                        -RootAPIEndpoint $Session.RootUrl `
                        -RefreshToken $Session.RefreshToken
                )
            }
        }
    }
}