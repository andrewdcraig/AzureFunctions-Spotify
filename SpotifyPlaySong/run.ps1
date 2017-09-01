$in = (Get-Content $triggerInput | convertfrom-json)
$in
$SessionData = convertfrom-json (get-content -raw $sessiondoc)
$SessionData
$SessionData.ClientId
$SessionData.Secret
$SessionData.RefreshToken
import-module 'D:\home\site\wwwroot\PSModules\PSSpotify\PSSpotify.psd1' -force

$Global:SpotifyCredential = new-object pscredential -argumentlist $SessionData.ClientId, (convertto-securestring -asplaintext -force $SessionData.Secret)

Connect-Spotify -ClientIdSecret $Global:SpotifyCredential -RefreshToken $SessionData.RefreshToken #| out-null

$filter = $in.filter
$filter

if($in.subject){

  $filter = $in.Subject.ToUpper().replace("SPOTIFY REQUEST:","").trim()
}


$Track = Find-SpotifyTrack -Filter $filter -Limit 1

Resume-Spotify -context $Track.uri