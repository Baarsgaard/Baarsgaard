$filePath = [Environment]::GetFolderPath("Desktop") + "\monitors.txt"

if (-Not(Test-Path -Path $filePath -PathType Leaf)) {
  try {
    New-Item -ItemType File -Path $filePath -Force -ErrorAction Stop | Out-Null
    Write-Host "The file monitors.txt has been created."
    Add-Content -Path $filePath -Value "# newline(enter) separates browser windows."
    Add-Content -Path $filePath -Value "# number of monitors equals number of browser windows"
    Add-Content -Path $filePath -Value "# comma(,) separates urls per browser window"
    Add-Content -Path $filePath -Value ""
    Add-Content -Path $filePath -Value "# www.google.com, www.google.com"
    Add-Content -Path $filePath -Value "# www.google.com"
    return;
  }
  catch { throw $_.Exception.Message }
}


$urls = @();
Get-Content $filePath | foreach { 
  if (([string]$_).StartsWith('#') -or ([string]$_).StartsWith('//')) { continue }
  $urls += , $_.Replace(" ", "").split(',') 
}

$monitor_count = (Get-CimInstance Win32_VideoController).Count

For ($i=0; $i -lt $monitor_count; $i++) {
  if (!$urls[$i] -is [string]) { continue }

  foreach ($url in $urls[$i]) {
    Start-Process chrome.exe -ArgumentList ${url},"--start-maximized","--user-data-dir=c:\monitor$i"
  }
}
