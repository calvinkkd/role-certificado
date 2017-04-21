Param([Parameter(Mandatory=$true)][string]$server)
 $ErrorActionPreference = "SilentlyContinue"

Try{
 $LastReboot = Get-EventLog -ComputerName $server -LogName system | Where-Object {$_.EventID -eq '6005'} | Select-Object -ExpandProperty TimeGenerated | Select-Object -first 1

 (Invoke-WmiMethod -ComputerName $server -Path "Win32_Service.Name='HealthService'" -Name PauseService).ReturnValue | Out-Null

Restart-Computer -ComputerName $server -Force

#New loop with counter, exit script if server did not reboot.
$max = 20;$i = 0
 DO{
 IF($i -gt $max){
        $hash = @{
             "Server" =  $server
             "Status" = "FailedToReboot!"
             "LastRebootTime" = "$LastReboot"
             "CurrentRebootTime" = "FailedToReboot!"
          }
$newRow = New-Object PsObject -Property $hash
 $rnd = Get-Random -Minimum 5 -Maximum 40
 Start-Sleep -Seconds $rnd
 Export-Csv D:\RebootResults.csv -InputObject $newrow -Append -Force
    "Failed to reboot $server"
    exit}#exit script and log failed to reboot.
    $i++
"Wait for server to reboot"
    Start-Sleep -Seconds 15
}#end DO
While (Test-path "\\$server\c$")

$max = 20;$i = 0
 DO{
 IF($i -gt $max){
        $hash = @{
             "Server" =  $server
             "Status" = "FailedToComeOnline!"
             "LastRebootTime" = "$LastReboot"
             "CurrentRebootTime" = "FailedToReboot!"
          }
$newRow = New-Object PsObject -Property $hash
 $rnd = Get-Random -Minimum 5 -Maximum 40
 Start-Sleep -Seconds $rnd
Export-Csv D:\RebootResults.csv -InputObject $newrow -Append -Force
    "$server did not come online"
    exit}#exit script and log failed to come online.
    $i++
    "Wait for [$server] to come online"
    Start-Sleep -Seconds 15
}#end DO
While (-not(Test-path "\\$server\c$"))

$CurrentReboot = Get-EventLog -ComputerName $server -LogName system | Where-Object {$_.EventID -eq '6005'} | Select -ExpandProperty TimeGenerated | select -first 1
    $hash = @{
             "Server" =  $server
             "Status" = "RebootSuccessful"
             "LastRebootTime" = $LastReboot
             "CurrentRebootTime" = "$CurrentReboot"
              }

$newRow = New-Object PsObject -Property $hash
 $rnd = Get-Random -Minimum 5 -Maximum 40
 Start-Sleep -Seconds $rnd
Export-Csv D:\RebootResults.csv -InputObject $newrow -Append -Force

}#End Try.

Catch{
 $errMsg = $_.Exception
 "Failed with $errMsg"
}