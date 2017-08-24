trap{
  write-host $_.exception.message
}

write-verbose "getting input" -Verbose

$RequestBody = (get-content -raw $request | convertfrom-json)

write-verbose "splitting input" -Verbose

$RequestBody = $RequestBody -split '\\r\\n'

$RequestBody = $RequestBody | ? { $_ -ne "" }

write-verbose "getting artist by regex" -Verbose

$artist = $RequestBody -imatch 'Artist:?=? ?(.+)'
if($artist){
  $artist -imatch 'Artist:?=? ?(.+)' | out-null
  $Artist = $matches[1]
}

write-verbose "getting track by regex" -Verbose

$track = $RequestBody -match 'track:?=? ?(.+)'
if($track){
  $track -imatch 'track:?=? ?(.+)' | out-null
  $track = $matches[1]
}

write-verbose "checking in case artist or track wasn't specified" -Verbose

if($RequestBody.count -eq 2 -and [string]::IsNullOrEmpty($artist) -and [string]::IsNullOrEmpty($track)){
  $artist = $RequestBody[0]
  $track = $RequestBody[1]
}

if($RequestBody.count -eq 1 -and [string]::IsNullOrEmpty($track)){
  $track = $RequestBody[0]
}


write-verbose "building filter" -Verbose
$filter = "name:$track"

if ([string]::IsNullOrEmpty($Artist) -eq $false) {
    $filter += " artist:$artist"
}

write-verbose "writing output" -Verbose

@{filter = $filter; functionkey = $REQ_QUERY_CODE} | convertto-json | Out-File -FilePath $queue -Encoding utf8