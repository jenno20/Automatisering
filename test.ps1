#Script to backup folder once a day
#Only saves the last 7 backups, and deletes any older ones

$sourcefolder = "C:\Automatisering\test1"
$backupfolder = "C:\Automatisering\Backup"
$max_backup = 7

#Timestamp
$timestamp = Get-Date -Format "yyyyMMDDmmss"
Write-Host "test"
