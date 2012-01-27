##############################################################################
# 
# Warm Cache (download updates) as per cachefile contents (got by twingle_update)
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

nest up; log "start - twingle_warm_cache.ps1" 

# Update before downloading 
invoke-expression "$twingledir\lib\twingle_update.ps1"

$updateCacheFile = getconfig cachefile 
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

log "end - twingle_warm_cache.ps1" ; nest down

exit 0

