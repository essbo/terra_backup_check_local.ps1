#Variablen

$ScheduleFile = "C:\Program Files\TERRA Cloud Backup\Agent\Schedule.cfg"
$CurrentDate = (Get-Date).Date.AddHours(-24)
$BackupJob = Select-String -Path $ScheduleFile -Pattern  "backup"
$pattern = 'backup\sintern-securepoint-de-daily\s/deferafter=0'
$matches = [regex]::Matches($BackupJob, $pattern)
$exportPath = "C:\Prometheus\Textfile_Exporter\Terra_Backup_Check.prom"

If (Test-Path $exportPath) {
    Remove-Item $exportPath
}
else {
    New-Item $exportPath -ItemType File
}

# Parse the Schedule.cfg for the Job
if ($matches.Count -gt 0) {
    foreach ($match in $matches) {
        $extractedText = $match.Value
    }
}
# Rewrite Pattern and Match Variable for extended filtering by Regex
$pattern = 'backup\s(.*?)\s/deferafter=0'
$match = [regex]::Match($extractedText, $pattern)
# Get the first entry in the File - eq the Jobname
if ($match.Success) {
    $extractedText = $match.Groups[1].Value
}

$BackupFile = "C:\Program Files\TERRA Cloud Backup\Agent\"+ $extractedText + "\BackupStatus.xml"
$BackupResultCheck = Select-String -Path $BackupFile -Pattern "<agentdata:result>COMPLETED<"
$BackupErrorCheck = Select-String -Path $BackupFile -Pattern "<agentdata:errors>0</agentdata:errors>"

# Write Prometheus Metrics
'# HELP terra_backup_check_win Checks the State of the Terra Backup' | Out-File $exportPath
'# TYPE terra_backup_check_win gauge ' | Out-File $exportPath -Append

if ($BackupResultCheck.Length -gt 0 )
{
    'terra_backup_check_win 0' | Out-File $exportPath -Append
    Write-Output $BackupResultCheck
}
Else
{
    'terra_backup_check_win 1' | Out-File $exportPath -Append
    Write-Output $BackupResultCheck
}

'# HELP terra_backup_error_win Checks the Errors of the Terra Backup' | Out-File $exportPath -Append
'# TYPE terra_backup_error_win gauge ' | Out-File $exportPath -Append

if ($BackupErrorCheck.Length -gt 0 )
{
    'terra_backup_error_win 0' | Out-File $exportPath -Append
    Write-Output $BackupErrorCheck
}
Else
{
    'terra_backup_error_win 1' | Out-File $exportPath -Append
    Write-Output $BackupErrorCheck
}

'# HELP terra_backup_lastbackup_too_old_win Checks the last backup of the Terra Backup' | Out-File $exportPath -Append
'# TYPE terra_backup_lastbackup_too_old_win gauge ' | Out-File $exportPath -Append

if ((Get-Item $BackupFile).LastWriteTime -ge $CurrentDate) 
{
    'terra_backup_lastbackup_win 0' | Out-File $exportPath -Append
}
Else
{
    'terra_backup_lastbackup_win 1' | Out-File $exportPath -Append
}
