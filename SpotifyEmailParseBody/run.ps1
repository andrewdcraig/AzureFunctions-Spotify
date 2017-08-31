trap{
  write-host $_.exception.message
}

"getting input"
$RequestBody = Get-Content $request
$RequestBody
"splitting input"

$RequestBody = $RequestBody -split '\\r\\n'

$RequestBody = $RequestBody | ? { $_ -ne "" }

"getting artist by regex"

$artist = $RequestBody -imatch 'Artist:?=? ?(.+)'
if($artist){
  $artist -imatch 'Artist:?=? ?(.+)' | out-null
  $Artist = $matches[1]
}

"getting track by regex"

$track = $RequestBody -match 'track:?=? ?(.+)'
if($track){
  $track -imatch 'track:?=? ?(.+)' | out-null
  $track = $matches[1]
}

"checking in case artist or track wasn't specified"

if($RequestBody.count -eq 2 -and [string]::IsNullOrEmpty($artist) -and [string]::IsNullOrEmpty($track)){
  $artist = $RequestBody[0]
  $track = $RequestBody[1]
}

if($RequestBody.count -eq 1 -and [string]::IsNullOrEmpty($track)){
  $track = $RequestBody[0]
}


"building filter $artist $track"
$filter = "name=$track"

if ([string]::IsNullOrEmpty($Artist) -eq $false) {
    $filter += " artist=$artist"
}

"writing output $filter"

@{filter = $filter; functionkey = $REQ_QUERY_CODE} | convertto-json | Out-File -FilePath $queue -Encoding utf8