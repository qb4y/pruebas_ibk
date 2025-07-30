$StringKBNames = $args[0]
$KBNames = $StringKBNames.Split(" ")
$AppEvalState0 = "0"
$AppEvalState1 = "1"

If ($StringKBNames -Like "ALL"){
    $Application = (Get-WmiObject -Namespace "root\ccm\clientSDK" -Class CCM_SoftwareUpdate | Where-Object { $_.EvaluationState -like "*$($AppEvalState0)*" -or $_.EvaluationState -like "*$($AppEvalState1)*" })
}
Else{
    [System.Collections.ArrayList]$Updates = @()
    Foreach ($KBName in $KBNames){
        $Application = (Get-WmiObject -Namespace "root\ccm\clientSDK" -Class CCM_SoftwareUpdate | Where-Object { $_.EvaluationState -like "*$($AppEvalState0)*" -or $_.EvaluationState -like "*$($AppEvalState1)*" -and $_.Name -like "*$($KBName)*"})
        if ($Application){
            $Updates.Add($Application.name) > $null
        }Else{
            Write-Host $KBName "NOT available"
        }
    }
    $Application = (Get-WmiObject -Namespace "root\ccm\clientSDK" -Class CCM_SoftwareUpdate | Where-Object { $_.EvaluationState -like "*$($AppEvalState0)*" -or $_.EvaluationState -like "*$($AppEvalState1)*" -and $_.Name -In $Updates })
}

if(!$Application){
    Write-Host "NO Updates Available"
    Exit
}

$Install = Invoke-WmiMethod -Class CCM_SoftwareUpdatesManager -Name InstallUpdates -ArgumentList (,$Application) -Namespace root\ccm\clientsdk

# Waiting updates installation
$Result = $true
while ($Result -eq $true) {
    $ApplicationCheck = Get-WmiObject -Namespace "root\ccm\clientSDK" -Class CCM_SoftwareUpdate | Where-Object { $_.name -In $Application.name }
    $Result = if (@($ApplicationCheck | where-object { $_.EvaluationState -ne 8 -and  $_.EvaluationState -ne 9 -and  $_.EvaluationState -ne 10 -and  $_.EvaluationState -ne 12 -and  $_.EvaluationState -ne 13 })) {$true} else {$false}
}


$ApplicationResult = Get-WmiObject -Namespace "root\ccm\clientSDK" -Class CCM_SoftwareUpdate | Where-Object { $_.name -In $Application.name }
$ApplicationResultCheck = $ApplicationResult
Foreach ($AllApp in $Application){
    if ($ApplicationResultCheck | where-object { $_.name -eq $AllApp.name }) {}
    Else {
        Write-Host $AllApp.name "- Installed Successfully"
    }
}

Foreach ($App in $ApplicationResult){
    if($App.EvaluationState -eq 8 -or $App.EvaluationState -eq 9 -or $App.EvaluationState -eq 10){
        Write-Host $App.name "- Installed Successfully - Reboot Required"
    }
    if($App.EvaluationState -eq 13){
        Write-Host $App.name "- ERROR: " $App.ErrorCode
    }
}
