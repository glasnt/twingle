##############################################################################
# 
# Twingle -  Pre reboot hook
#
# This code gets called from a scheduled task created from twingle_reboot.
# Code does stuff before reboot, then reboots the system
##############################################################################
$env:PSModulePath = $env:PSModulePath + ";c:\twingle\lib"; 
Import-Module twingle; $ini = Parse_IniFile; $twingleDir = twingledir
log "*** Pre Twingle Reboot hook start"
##############################################################################


##############################################################################
# YOUR CODE HERE

# e.g. stopping MSSQL before reboot
# $null = invoke-expression "net stop mssqlserver"
# 
# ^^ throw whatever you want after invoke-expression, and it will run as if in Command Prompt

# e.g. stop mssql where there is also a SQL Server Agent
# $stopMSSQLAgent = "net stop `"SQL Server Agent (MSSQLSERVER)`" "
# $stopMSSQL = "net stop mssqlserver"
# $null = invoke-expression $stopmssqlagent
# $null = invoke-expression $stopmssql

##############################################################################

log "*** Completed Twingle Post update reboot hook"

#Schedule the post-reboot items
log "Schedule the post-reboot hook on system start"
schedule_task "TwinglePostReboot" "ONSTART" "" "" "powershell $twingledir\lib\post_reboot_hook.ps1" 
	
#remove current task
log "Remove the PreReboot Scheduled task, we don't need it anymore"
remove_schtask "TwinglePreReboot"

log "*** Twingle pre-reboot hook end"
log "*** INITIATING REBOOT NOW ***"
$rebootme = "shutdown /r /t 10 /c `"Machine rebooting in 10 seconds, to complete windows updates`""
log "Reboot script: $rebootme"
invoke-expression $rebootme
log "Rebooting machine."


exit 0
