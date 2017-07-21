Add-Type -AssemblyName System.Web
function Get-AuthorizationCode {
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [string]
        $AuthorizationEndpoint,

        [parameter(Mandatory)]
        [pscredential]
        $ClientIdSecret,

        [parameter(Mandatory)]
        [string[]]
        $Permissions = "-",

        [parameter(Mandatory)]
        [string]
        $RedirectUri
    )

    begin {
        $redirectUriEncoded = [System.Web.HttpUtility]::UrlEncode($redirectUri)
    }

    process {
        [void]$(
            $url = [string]::Format("{0}?response_type=code&redirect_uri={1}&client_id={2}&scope={3}", `
                    $AuthorizationEndpoint, `
                    $redirectUriEncoded, `
                    $ClientIdSecret.UserName, `
                ($Permissions -join '%20'))

            Add-Type -AssemblyName System.Windows.Forms
            $form = New-Object -TypeName System.Windows.Forms.Form -Property @{Width = 440; Height = 640}
            $web = New-Object -TypeName System.Windows.Forms.WebBrowser -Property @{Width = 420; Height = 600; Url = $Url }

            $DocComp = {
                $ReturnUrl = $web.Url.AbsoluteUri
                if ($ReturnUrl -match "error=[^&]*|code=[^&]*") {
                    $form.Close()
                }
            }

            $web.ScriptErrorsSuppressed = $true
            $web.Add_DocumentCompleted($DocComp)
            $form.Controls.Add($web)
            $form.Add_Shown( {$form.Activate()})
            $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
            $form.ShowDialog()

            $queryOutput = [System.Web.HttpUtility]::ParseQueryString($web.Url.Query)

            $output = @{}

            foreach ($key in $queryOutput.Keys) {
                $output["$key"] = $queryOutput[$key]
            }

            $PSCmdlet.WriteObject($output["Code"])
        )
    }
}

function Get-AccessToken {
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [string]
        $TokenEndpoint,

        [parameter(Mandatory)]
        [pscredential]
        $ClientIdSecret,

        [parameter(Mandatory)]
        [string]
        $AuthorizationCode,

        [parameter(Mandatory)]
        [string]
        $RedirectUri
    )

    begin {
        $redirectUriEncoded = [System.Web.HttpUtility]::UrlEncode($redirectUri)
    }

    process {
        [void]$(
            $body = [string]::format("grant_type=authorization_code&redirect_uri={0}&client_id={1}&client_secret={2}&code={3}", `
                    $redirectUriEncoded, `
                    $ClientIdSecret.UserName, `
                    [System.Web.HttpUtility]::UrlEncode($ClientIdSecret.GetNetworkCredential().Password), `
                    $AuthorizationCode
            )

            $Authorization = Invoke-RestMethod $TokenEndpoint `
                -Method Post -ContentType "application/x-www-form-urlencoded" `
                -Body $body `
                -ErrorAction STOP

            $PSCmdlet.WriteObject($Authorization)
        )
    }
}
