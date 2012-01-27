##############################################################################
# 
# Reboot - check it's nessesary, then reboot as required.
#
##############################################################################

function twingleDir {   
	 $curr = Split-Path ([IO.FileInfo] ((Get-Variable MyInvocation -Scope 1).Value).MyCommand.Path).Fullname
	if ($curr -match "lib") { $curr = $curr.substring(0, $curr.length-3) }; return $curr.substring(0,$curr.length-1)
}
$twingledir = twingledir
$common = "$twingledir\lib\twingle_common.psm1"
Import-Module $common
$ini = Parse_IniFile

nest up; log "start - twingle_reboot.ps1" 

# Do the reboot logic

$kindlyreboot = getconfig kindlyreboot
$noreboot = getconfig noreboot

#confirm reboot is required before continuing
if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"){ 

	if ($noreboot -eq 1) {
		log "Twingle isn't allowed to reboot this server. Let's tell someone about it"
		
		set_nagios_status WARNING "Updates applied, server needs manual reboot."
		# email someone here too
	}
	if ($kindlyreboot -eq 1) {
		log "Going to nicely tell the user that shit's going down"
		
		set_nagios_status WARNING "Updates applied. Automatic reboot pending..."
		
		# setup the post reboot clearing. 
		$TwinglePostReboot = "schtasks /create /tn `"TwinglePostReboot`" /tr `"powershell $twingledir\lib\post_reboot_hook.ps1`"  /sc ONSTART /ru system"
		$null = invoke-expression $TwinglePostReboot
		
		#schedule a delayed reboot, but delay by whatever time.
		$computername = gc env:computername
		$rebootdelay = getConfig rebootdelay
		$reboottime = (Get-Date).AddSeconds($rebootDelay).ToShortTimeString()
		
		#And shut it down
		$rebootme = "shutdown /r /t $rebootdelay /c `"Dear User, $computername is rebooting at $reboottime for Windows Updates. Love, Twingle <3.`""
		log $rebootme
		invoke-expression $rebootme
		
		exit 0
	}
	
} else {
	log " x No reboot required by update."
}



log "end - twingle_reboot.ps1"; nest down
exit 0

