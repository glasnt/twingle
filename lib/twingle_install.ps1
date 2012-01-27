##############################################################################
# 
# Install Updates - installs anything downloaded in the Windows Update thingy.
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

nest up; log "start - twingle_install.ps1" 

# Do the installation dance

log "getting current list of downloaded updates to install... "
$updateSession = new-object -com "Microsoft.Update.Session"
$criteria = "IsInstalled=0 and Type='Software'"
$updateList = $updateSession.CreateupdateSearcher().Search($criteria).Updates
$updatesToInstall = New-object -com "Microsoft.Update.UpdateColl"
$updateList | where {$_.isdownloaded} | foreach-Object {$updatesToInstall.Add($_) | out-null }
log "... complete."


if ($updatesToInstall.count -gt 0 ) { 
	log ("There are going to be "+$updatesToInstall.count+" updates installed")

	$installer = $updateSession.CreateUpdateInstaller()
	$installer.updates = $updatesToInstall
	set_nagios_status WARNING "Twingle is installing "+$updatesToInstall.count+" updates now..."
	
	log "installing updates now..."
	$null = $installer.install() #Oh lordy, actual installation!
	log "...updates completed"
	
	set_nagios_status OK (""+$updatesToInstall.count+" updates installed.")
	
} else { 
	log "No updates to install."
}

log "end - twingle_install.ps1" ; nest down

exit 0

