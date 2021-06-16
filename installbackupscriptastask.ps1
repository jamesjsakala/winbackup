$Trigger= New-ScheduledTaskTrigger -At 05:30pm -Daily
$User= "NT AUTHORITY\SYSTEM"
$Action= New-ScheduledTaskAction -WorkingDirectory "C:\JBACKUP" -Execute "C:\JBACKUP\jwinbackup.cmd"
Register-ScheduledTask -TaskName "JBackup Light Script" -Trigger $Trigger -User $User -Action $Action -RunLevel Highest -Force 
