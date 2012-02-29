##############################################################################
# 
# Twingle -  Post twingle cleanup
#
##############################################################################
$env:PSModulePath = $env:PSModulePath + ";c:\twingle\lib"; 
Import-Module twingle; $ini = Parse_IniFile; $twingleDir = twingledir
log "*** Post Twingle reboot hook start"
##############################################################################

#Send OK to nagios
set_nagios_status OK "Server rebooted after updates."

log "removing one-off post-twingle-reboot scheduled task" 
remove_schtask TwinglePostReboot

##############################################################################
# YOUR CODE HERE





##############################################################################

log "*** Completed Twingle Post update reboot hook"

exit 0
