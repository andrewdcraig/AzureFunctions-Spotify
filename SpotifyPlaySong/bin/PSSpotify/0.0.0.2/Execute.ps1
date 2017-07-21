powershell.exe -ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile -command "& {import-module 'C:\Users\RyanBartram\Source\Repos\PSSpotify\PSSpotify.psd1';Connect-Spotify -ClientIdSecret (new-object pscredential -argumentlist 'bf085d9f6e544698b02838945c23db22', (convertto-securestring -asplaintext -force '723bf10e31424789a11cb25d2387a01c')) -KeepCredential}"

Import-Module .\PSSpotify.psd1 -Force -DisableNameChecking
Connect-Spotify -ClientIdSecret (import-clixml .\Credential.xml) -KeepCredential

$Global:SpotifyCredential = (import-clixml .\Credential.xml)

$p = Get-SpotifyPlaylist -UserId rdbartram91 | ft name

$p | ? { $_.name -like "test*" } | Remove-SpotifyPlaylist

New-SpotifyPlaylist -Name Test1

Get-SpotifyCurrentTrack

$d = Get-SpotifyDevice

Resume-Spotify -DeviceId $d[1].id
Resume-Spotify
Pause-Spotify

Get-SpotifyProfile

$global:SpotifySession

assert-AuthToken

Set-SpotifyPlayer -Volume 200 -DeviceId $d.id

Get-SpotifyDevice -Type Computer | Set-SpotifyPlayer -Play

Get-SpotifyPlayer

Get-SpotifyNewReleases

Find-SpotifyArtist -Filter "justin Bieber"

$Playlist = Find-SpotifyPlaylist -Filter "justin Bieber" | select -first 1

Follow-SpotifyItem -Type playlist -Id $Playlist.id -OwnerId $Playlist.owner.id

Unfollow-SpotifyItem -Type artist -Id 1uNFoZAHBGtllmzznpCI3s

Get-SpotifyFollowedItem -Type Artist

Assert-SpotifyFollowing -Type Artist -Id 1uNFoZAHBGtllmzznpCI3s





Set-SpotifyPlayer -Shuffle $false -Repeat track

Get-SpotifyRecentlyPlayed -Limit 5

Get-SpotifyTopArtist -TimeRange short_term | select -first 1

Find-SpotifyArtist -Filter "Justin Bieber" -Limit 1

Find-SpotifyTrack -Filter "where are u now" -Limit 1

Resume-Spotify -Context 'spotify:track:66hayvUbTotekKU3H4ta1f'

Get-SpotifyAlbum -ArtistId '1uNFoZAHBGtllmzznpCI3s' -Type album -Limit 2 -CountryCode CH

$uri = Get-SpotifyArtistTopTracks -Id 1uNFoZAHBGtllmzznpCI3s -CountryCode CH | select -ExpandProperty uri

Resume-Spotify -Context $uri

Get-SpotifyRelatedArtists -Id 1uNFoZAHBGtllmzznpCI3s

Get-SpotifyTrack -AlbumId 7fZH0aUAjY3ay25obOUf2a

Get-SpotifyFeaturedPlaylists

Get-SpotifyNewReleases

Assert-AuthToken $session $global:SpotifySession

Connect-Spotify -ClientIdSecret $Global:SpotifyCredential `
                        -RefreshToken $global:SpotifySession.RefreshToken