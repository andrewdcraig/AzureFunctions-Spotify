$in = (Get-Content $triggerInput -raw | convertfrom-json)

$SessionData = convertfrom-json (get-content -raw $sessiondoc)

import-module 'D:\home\site\wwwroot\PSModules\PSSpotify\0.0.0.2\PSSpotify.psd1' -force

$Global:SpotifyCredential = new-object pscredential -argumentlist $SessionData.ClientId, (convertto-securestring -asplaintext -force $SessionData.Secret)

Connect-Spotify -ClientIdSecret $Global:SpotifyCredential -RefreshToken $SessionData.RefreshToken | out-null

$Song = $in.Subject.ToUpper().replace("SPOTIFY REQUEST:","").trim()

$Track = Find-SpotifyTrack -Filter $Song -Limit 1

Resume-Spotify -context $Track.uri