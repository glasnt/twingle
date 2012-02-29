##############################################################################
# 
# Twingle - Reboot - check it's nessesary, then reboot as required.
#
##############################################################################
$env:PSModulePath = $env:PSModulePath + ";c:\lib"; 
Import-Module twingle; $ini = Parse_IniFile; $twingleDir = twingledir
logging start twingle_reboot
##############################################################################

# Do the reboot logic
$canhasreboot = getconfig canhasreboot

#confirm reboot is required before continuing
#if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"){ 

	if ($canhasreboot -eq 1) {
		log "Rebooting process start."
		
	
        # Work out when and where to reboot.
		$reboottype = getconfig reboottype
		$rebootdelay = getConfig rebootdelay
		$reboottime = getconfig reboottime
				
		if ($reboottype -eq "DELAY") { 
			#rebooting NOW
			log "Rebooting machine in $rebootdelay seconds (DELAY)"
			$schedreboot = (Get-Date).AddSeconds($rebootDelay)			
			$schedreboottime = ""+(($schedreboot).Hour)+":"+(($schedreboot).Minute)
			$Schedrebootdate =  $schedreboot.ToShortDateString()
			
		} elseif ($reboottype -eq "TIME") {
			#Reboot at next TIME
			log "Rebooting machine at $reboottime (TIME)"
			$timenow = ""+((Get-Date).Hour).toString("00")+":"+((Get-Date).Minute).ToString("00")
			$Schedrebootdate = (Get-Date)
			if ( ($reboottime  -replace ':','') -lt ($timenow -replace ':','')) { 
				$Schedrebootdate = $Schedrebootdate.AddDays(1).ToShortDateString()
			}
			$schedreboottime = $reboottime
		}
		
		log "Reboot date: $Schedrebootdate, reboot time $schedreboottime"
		$prerebootscript = "powershell $twingledir\lib\pre_reboot_hook.ps1"
		schedule_task "TwinglePreReboot" "ONCE" $Schedrebootdate $schedreboottime $prerebootscript
		
		#msg people
		log "Sending system wide message notifying of date/time of reboot."
		$computer = gc env:computername
		$msgcode = "msg * Warning: $computer will be rebooting at $schedreboottime on $Schedrebootdate for scheduled updates. To cancel, remove the scheduled task 'TwinglePreReboot', or run C:\twingle\Cancel Pending Maintenance.bat"
		invoke-expression $msgcode

        set_nagios_status WARNING "Server updated, rebooting at $schedreboottime on $Schedrebootdate"

		log "Reboot setup complete"
	}
	else { #can't reboot
	
		log "Twingle isn't allowed to reboot this server. Let's tell someone about it"
		
		set_nagios_status WARNING "Updates applied, server needs manual reboot."
		
	}
	
#} else {
#	log " x No reboot required by update."
#}

logging end twingle_reboot

exit 0
