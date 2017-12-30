﻿##############################
# created with the help of:
# - https://blog.netnerds.net/2015/01/create-scheduled-task-or-scheduled-job-to-indefinitely-run-a-powershell-script-every-5-minutes/ (mostly copied)
# - http://britv8.com/powershell-create-a-scheduled-task/
#
##############################


##############################
# task options
#
# - WILL DELETE THE TASK IF IT ALREADY EXISTS!!!!
#
# - it is enabled by default
# - does not run on batteries (preserve power). however, if the task is started (while on power), it continues if the user goes on battery (so that a backup would not be incomplete)
# - does not start a new backup until the previous one is finished
# - stars a backup (but only one, not more) if the start-time has passed (eg: start-time = 16:00, computer is only powered on @ 18:21. backup starts @ 18:21)
# - don't wake the computer to run the task (as mentioned above, the task will run whenever the computer is turned on, even after it's normal start time)
# - the task will run for at most 3 days continuously before being quit (Task Scheduler constraint)
#
##############################

##############################
# Change these three variables to whatever you want
$taskName = "zzzzzzzzzzzzzzzzzzzzzzzzz"
$script =  '-NoProfile -ExecutionPolicy Bypass -File "C:\duplicacy repo\backup.ps1" -Verb RunAs'
# $repetitionInterval = (New-TimeSpan -Minutes 1)
$repetitionInterval = (New-TimeSpan -Hours 1)
##############################

function main() {
    ##############################
    # cleanup: Unregister first the ScheduledTask if it already exists
    Unregister-ScheduledTask -TaskName $taskName -Confirm: $false -ErrorAction SilentlyContinue
    ##############################

    # The script below will run as the specified user (you will be prompted for credentials)
    # and is set to be elevated to use the highest privileges.
    # In addition, the task will run however long specified in $repetitionInterval above.
    $task = New-ScheduledTaskAction –Execute "powershell.exe" -Argument  "$script; quit"
    $repetitionDuration = (New-TimeSpan -Days 10000)  # 27 years should be enough
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).Date -RepetitionInterval $repetitionInterval -RepetitionDuration $repetitionDuration


    $msg = "Enter the username and password that will run the task";
    $credential = $Host.UI.PromptForCredential("Task username and password",$msg,"$env:userdomain\$env:username",$env:userdomain)
    $username = $credential.UserName
    $password = $credential.GetNetworkCredential().Password
    $settings = New-ScheduledTaskSettingsSet -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew -StartWhenAvailable

    Register-ScheduledTask -TaskName $taskName -Action $task -Trigger $trigger -RunLevel Highest -User $username -Password $password -Settings $settings
}

main