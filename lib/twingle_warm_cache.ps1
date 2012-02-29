##############################################################################
#
# Twingle - Warm Cache - Download updates
#
##############################################################################
$env:PSModulePath = $env:PSModulePath + ";c:\twingle\lib"; 
Import-Module twingle; $ini = Parse_IniFile; $twingleDir = twingledir
logging start twingle_warm_cache
##############################################################################

$updateCacheFile = getconfig cacheFile
$updateCacheFile = "$twingledir\$updateCacheFile"
$updateList = Import-Clixml $updateCacheFile

# I'm sorry, I'm so sorry.
# Re-create the update collection from file
$wantedUpdateTitles = @()
foreach ($update in $updateList) { 
	$wantedUpdateTitles += $update.title
} 

$updateSession = new-object -com "Microsoft.Update.Session"

log "getting list of updates to download... "
$availableUpdates=$updateSession.CreateupdateSearcher().Search(("IsInstalled=0 and Type='Software'")).Updates
$downloads = new-object -com "Microsoft.Update.UpdateColl"
foreach ($available in $availableUpdates) {
	if ($wantedUpdateTitles -contains $available.title ) {
		if (!$available.isDownloaded) {
			log ("Adding KB"+$available.KBArticleIDs+" to update list to download")
			$null = $downloads.add($available)
		}
	}
}
log "... done."


$downloader = $updateSession.CreateUpdateDownloader()
$downloader.updates = $downloads

if ($downloads.count -ne 0) {
	log "Now downloading the updates, stand by... "
	$null = $downloader.download() #actual download is here
	log ("... "+$downloads.count+" updates downloaded.")
} else {
	log "x No updates to download"
}

logging end twingle_warm_cache

exit 0

