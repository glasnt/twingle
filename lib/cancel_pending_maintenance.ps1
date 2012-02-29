##############################################################################
# 
# Twingle - Cancel Pending Maintenance
#
##############################################################################
$env:PSModulePath = $env:PSModulePath + ";c:\twingle\lib"; 
Import-Module twingle; $ini = Parse_IniFile; $twingleDir = twingledir
log "*** Cancelling pending maintenance... "
##############################################################################

invoke-expression "cls"
banner hashbanner
banner blank
banner "Cancel Pending Maintenace Tasks" red
banner blank
banner hashbanner

write-host " "

function remove_tasks ($twingleTasks) { 
	$twingletasks = get_task $twingleTasks
	if ($twingletasks) { 
		if ($twingletasks.count -ne 0) { 
		
			write-host "There are pending maintenance tasks to be deleted...  "
			write-host " "
			foreach ($task in $twingletasks) { 
				$taskname = $task.TaskName
				Write-host ("Pending Task '$taskname': ")
				Write-host (" > Scheduled for "+($task.StartDate)+" at "+($task.StartTime)+".")
				" "
				$response = Read-Host "Do you want to remove this task? (Y/N)"
				
				if ($response.toLower() -eq "y") { 
					$rmtask =  "schtasks /delete /tn `"$taskname`" /f"
					write-host "Removing task.. "
					$output = invoke-expression $rmtask
					if ($output -match "SUCCESS") { 
						log "..Task deleted successfully" 
					} else { 
					log "..Could not delete task $taskname" 
					}
				}
			} 
			
			Write-Host "No more pending tasks to remove"
			set_nagios_status OK ("Maintenance for "+($task.StartDate)+" at "+($task.StartTime)+" cancelled")
			pause
		}
	} else { return "none" }
}

#Remove the installs
" "
Write-host "Checking for update tasks..."

$result = remove_tasks  "Twingle Windows updates for next"
if ( $result -eq "none" ) { "No update tasks exist."}
#Remove reboot tasks

" "
Write-host "Checking for reboot tasks..."
$result = remove_tasks "TwinglePreReboot"
if ( $result -eq "none" ) { "No reboot tasks exist."}
 
" "
Write-Host "Checks complete."

pause
