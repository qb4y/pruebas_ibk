$StringKBNames = $args[0]
$KBNames = $StringKBNames.Split(" ")
$AppEvalState0 = "0"
$AppEvalState1 = "1"
$AppEvalState8 = "8"
$AppEvalState9 = "9"
$AppEvalState10 = "10"

If ($StringKBNames -Like "ALL"){
        $Application = (Get-WmiObject -Namespace "root\ccm\clientSDK" -Class CCM_SoftwareUpdate | Where-Object { $_.EvaluationState -like "*$($AppEvalState0)*" -or $_.EvaluationState -like "*$($AppEvalState1)*"})
        if (!$Application){
                Write-Host "NO Updates available"
        }
        Foreach ($App in $Application){
            $App.name
        }
}
Else{
    Foreach ($KBName in $KBNames){
            $Application = (Get-WmiObject -Namespace "root\ccm\clientSDK" -Class CCM_SoftwareUpdate | Where-Object { $_.EvaluationState -like "*$($AppEvalState0)*" -or $_.EvaluationState -like "*$($AppEvalState1)*" -and $_.Name -like "*$($KBName)*"})
            if (!$Application){
                Write-Host $KBName "NOT available"
            }else{
                $Application.name
            }
    }
}

# checking for pending restart
$Application = (Get-WmiObject -Namespace "root\ccm\clientSDK" -Class CCM_SoftwareUpdate | Where-Object { $_.EvaluationState -like "*$($AppEvalState8)*" -or $_.EvaluationState -like "*$($AppEvalState9)*" -or $_.EvaluationState -like "*$($AppEvalState10)*"})
if ($Application){
    Write-Host "`n`nThere are some updates in pending restart.`nPlease reboot the server before to install any updates."
}

# Disk Check
$FreeDisk =[math]::Round(((get-psdrive c).free)/1MB)
$UsedDisk =[math]::Round(((get-psdrive c).used)/1MB)
$TotalSize = $FreeDisk + $UsedDisk
$PercentageFreeSpace = [math]::Round(($FreeDisk/$TotalSize)*100, 2)

Write-Host "`n`nFree Disk Space Check"

if($PercentageFreeSpace -ge 10) {
  Write-Host "OK! There is more than 10% of free space:"$PercentageFreeSpace"%. Available disk space:" $FreeDisk "MB"
}
else {
  Write-Host "NOT OK! There is less than 10% of free space:"$PercentageFreeSpace"%. Available disk space:" $FreeDisk "MB"
}
