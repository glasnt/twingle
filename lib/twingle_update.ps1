##############################################################################
#
# Twingle - Update the Updates list
#
##############################################################################
$env:PSModulePath = $env:PSModulePath + ";c:\twingle\lib"; 
Import-Module twingle; $ini = Parse_IniFile; $twingleDir = twingledir
logging start twingle_update
##############################################################################

$updateCacheFile = getconfig cachefile 
$updateCacheFile = "$twingledir\$updateCacheFile"
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

	Export-Clixml -InputObject $updateList -Path $updateCacheFile

	foreach ($up in $updateList) {
		if ($up.isDownloaded) { $downstatus =  "Already downloaded" } else { $downstatus = "needs to be downloaded"}
		log ("Pending update: KB"+($up.KBarticleIDs)+" : $downstatus")
	}
} else { 
	log "x Cache file doesn't need to be updated"
} 


logging end twingle_update
