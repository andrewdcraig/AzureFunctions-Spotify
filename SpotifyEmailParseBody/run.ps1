$RequestBody = (get-content -raw $request | convertfrom-json)

$RequestBody = $RequestBody.trim()

$RequestBody -match 'Artist:?=? ?(.+)' | out-null
$Artist = $matches[1]

$RequestBody -match 'track:?=? ?(.+)' | out-null
$Track = $matches[1]

if ([string]::IsNullOrEmpty($Artist)) {
    $artist = $RequestBody.split()[0]
}

if ([string]::IsNullOrEmpty($track)) {
    $track = $RequestBody.split()[1]
}

if ([string]::IsNullOrEmpty($track)) {
    $track = $Artist
    $Artist = $null
}

$filter = "name:$track"

if ([string]::IsNullOrEmpty($Artist) -eq $false) {
    $filter += " artist:$artist"
}

@{filter = $filter; functionkey = $REQ_QUERY_CODE} | convertto-json | Out-File -FilePath $queue -Encoding utf8