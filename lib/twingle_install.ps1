##############################################################################
#
# Twingle - Install Updates - installs anything downloaded in the Windows Update thingy.
#
##############################################################################
$env:PSModulePath = $env:PSModulePath + ";c:\lib"; 
Import-Module twingle; $ini = Parse_IniFile; $twingleDir = twingledir
logging start twingle_install
##############################################################################

#cleanup the sch. task
$installDay = getconfig installDay
remove_schtask "Twingle Windows updates for next $installday" 

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
	set_nagios_status OK "No updates to install"
}

logging end twingle_install

exit 0

