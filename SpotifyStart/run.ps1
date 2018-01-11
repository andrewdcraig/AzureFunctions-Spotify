$SessionData = convertfrom-json (get-content -raw $sessiondoc)

import-module 'D:\home\site\wwwroot\PSModules\PSSpotify\PSSpotify.psd1' -force

$Global:SpotifyCredential = new-object pscredential -argumentlist $SessionData.ClientId, (convertto-securestring -asplaintext -force $SessionData.Secret)

Connect-Spotify -ClientIdSecret $Global:SpotifyCredential -RefreshToken $SessionData.RefreshToken | out-null

Resume-Spotify