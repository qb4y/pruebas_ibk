$Searcher = New-Object -ComObject Microsoft.Update.Searcher
  $SearchResult = $Searcher.Search('IsInstalled=0').Updates
  $ucount = $searchresult.count

  if ($ucount -eq 0) {
      Write-Host "NO updates available"
  }
  else {
      $patchsize = 0
      $spaceneed = 0
      foreach ($winupdate in $SearchResult) {
          $size = [System.Math]::Round($winupdate.MaxDownloadSize / 1MB)
          $patchsize += $size
          $spaceneed += $size*5
      }
      $freedisk =[math]::Round(((get-psdrive c).free)/1MB)
      if($spaceneed -lt $freedisk) {
          Write-Host "OK! Patches size:" $patchsize "MB - Suggested disk space needed:" $spaceneed "MB - Available disk space:" $freedisk "MB"
      }
      else {
          Write-Host "NOT OK! Patches size:" $patchsize "MB - Suggested disk space needed:" $spaceneed "MB - Available disk space:" $freedisk "MB"
      }
  }
