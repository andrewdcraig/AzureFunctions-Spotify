trap{
  write-host $_.exception.message
}

$RequestBody = (get-content -raw $request | convertfrom-json)

$RequestBody = $RequestBody -split '\\r\\n'

$RequestBody = $RequestBody | ? { $_ -ne "" }

$artist = $RequestBody -imatch 'Artist:?=? ?(.+)'
if($artist){
  $artist -imatch 'Artist:?=? ?(.+)' | out-null
  $Artist = $matches[1]
}

$track = $RequestBody -match 'track:?=? ?(.+)'
if($track){
  $track -imatch 'track:?=? ?(.+)' | out-null
  $track = $matches[1]
}

if($RequestBody.count -eq 2 -and [string]::IsNullOrEmpty($artist) -and [string]::IsNullOrEmpty($track)){
  $artist = $RequestBody[0]
  $track = $RequestBody[1]
}

if($RequestBody.count -eq 1 -and [string]::IsNullOrEmpty($track)){
  $track = $RequestBody[0]
}

$filter = "name:$track"

if ([string]::IsNullOrEmpty($Artist) -eq $false) {
    $filter += " artist:$artist"
}

@{filter = $filter; functionkey = $REQ_QUERY_CODE} | convertto-json | Out-File -FilePath $queue -Encoding utf8