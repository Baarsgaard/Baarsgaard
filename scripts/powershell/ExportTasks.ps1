ForEach ($task in Get-ScheduledTask -TaskPath "\Custom\*") {
  Export-ScheduledTask -TaskPath $task.TaskPath -TaskName $task.TaskName | Out-File "H:\Tasks\$($task.TaskName).xml"
};