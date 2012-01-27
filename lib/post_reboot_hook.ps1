# Post Twingle Cleanup

function twingleDir {   
	 $curr = Split-Path ([IO.FileInfo] ((Get-Variable MyInvocation -Scope 1).Value).MyCommand.Path).Fullname
	if ($curr -match "lib") { $curr = $curr.substring(0, $curr.length-3) }; return $curr.substring(0,$curr.length-1)
}
$twingledir = twingledir
$common = "$twingledir\lib\twingle_common.psm1"
Import-Module $common
$ini = Parse_IniFile

log "*** Twingle Post update reboot hook"

#Send OK to nagios
set_nagios_status OK "Server rebooted after updates."

log "removing one-off post-twingle-reboot scheduled task" 
$output = invoke-expression "schtasks /delete /tn `"TwinglePostReboot`" /f"
if ($output -match "SUCCESS") { 
	log "Old task deleted successfully" 
} else { 
	log "Old task deletion failed" 
}

#other post reboot stuff here? like restarting services?

log "*** Completed Twingle Post update reboot hook"