##############################################################################
# 
# Update that cache file
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

nest up; log "start - twingle_update.ps1" 

# Update the update listing of updates.

$updateCacheFile = getconfig cachefile 
$updateCacheExpireHours = getconfig updateCacheExpireHours

if (-not (Test-Path $updateCacheFile)) { 
	log "Cache file not found, going to do update."
	$updateRequired = 1 
}
elseif ((Get-Date) -gt ((Get-Item $updateCacheFile).LastWriteTime.AddHours($updateCacheExpireHours))) {
	log "Cache file too old, going to do update."
    $updateRequired = 1 
}


if ($updateRequired) {
	#actually update things	

	log "Getting a current list of updates from Windows Update..." 
	$updateSession = new-object -com "Microsoft.Update.Session"
	$availableUpdates=$updateSession.CreateupdateSearcher().Search(("IsInstalled=0 and Type='Software'")).Updates
	log "... complete." 	
	
	# establish what updates we actually want.
	$updateList = new-object -com "Microsoft.Update.UpdateColl"
	foreach ($update in $availableUpdates) {
		#keep critical updates
		if (($update.AutoSelectOnWebSites)) {
			$surpress = $updateList.Add($update)
		}
		else {		
			if ((getConfig installOptionalUpdates) -eq 1) {
				$surpress = $updateList.Add($update)
			}
		}	
	}

	$updateCacheFile = getconfig cachefile
	Export-Clixml -InputObject $updateList -Path $updateCacheFile

	foreach ($up in $updateList) {
		if ($up.isDownloaded) { $downstatus =  "Already downloaded" } else { $downstatus = "needs to be downloaded"}
		log ("Pending update: KB"+($up.KBarticleIDs)+" : $downstatus")
	}
} else { 
	log "x Cache file doesn't need to be updated"
} 

log "end - twingle_update.ps1"; nest down

exit 0
