##############################################################################
# 
# Twingle - Weekly Update processing. Runs directly from Task Scheduler.
#
##############################################################################
$env:PSModulePath = $env:PSModulePath + ";c:\twingle\lib"; 
Import-Module twingle; $ini = Parse_IniFile; $twingleDir = twingledir
logging start twingle_check
##############################################################################

# Check for updates
invoke-expression "$twingledir\lib\twingle_update.ps1"

$updateCacheFile = getconfig cachefile 
$updateCacheFile = "$twingledir\$updateCacheFile"
$updateList = Import-Clixml $updateCacheFile

if ($updateList.count -gt 0) { 
	#update time!
	
	invoke-expression "$twingledir\lib\twingle_warm_cache.ps1"
	
	#set up the variables. 
	$emailclient = getconfig emailclient
	$installDay = getconfig installday
	$installtime = getconfig installtime
	$noreboot = getconfig noreboot
	$computername = (gc env:computername).toLower()
	
	
	if ($emailclient -eq 1) {
		# CUSTOMISE THIS YOURSELF! 
		log "Sending maintenance notification email now..."
		$emailSubject = "Maintenance notification for event at $installtime on "+($installday.toLower())
		$emailBody = ""
		$emailFrom = "root@$computername.YOURCOMPANY.net.au"
		$emailTo = "YOURSuperImportantEmailAddressHere@Lolcakes.com"
		$smtpServer = "localhost"
		
		$smtp = new-object Net.Mail.SmtpClient($smtpServer)
		$emailresult = $smtp.Send($emailFrom, $emailTo, $emailSubject, $emailBody)
		
		log "email sent."
	} else { 
		log "No email going to be sent to client, because of config"
	}

	#set up scheduled task for updates. 
	#requireing - code to allow it to run w/out login, other nice scheduled task things. 

	if ($noreboot -eq 1) { $action = "-install" } else { $action = "-reboot"} 

	$today = (Get-Date -uformat %u)
	if ($installday -eq "MON") { $installdaynum = 1 } 	
	if ($installday -eq "TUE") { $installdaynum = 2 } 
	if ($installday -eq "WED") { $installdaynum = 3 } 	
	if ($installday -eq "THU") { $installdaynum = 4 } 
	
	if ($today -gt $installdaynum) { $installdaynum += 7}
	if ($today -eq $installdaynum) { $installdaynum += 7} 
	$datediff = ($installdaynum - $today)
	
	$installdate = (Get-Date).AddDays($datediff).ToShortDateString()
	
	log "Install day is $installday, next installation date is $installdate"
		
	if ($installdate.length -eq 9) { $installdate = "0"+$installdate} # /o_O\
		
	$schedtaskname = "Twingle Windows updates for next $installday" 
	schedule_task $schedtaskname "ONCE" $installdate $installtime "powershell.exe $twingledir\twingle.ps1 $action"
	set_nagios_status OK "Updates scheduled for $installtime on $installdate"
		
} else {
	#no updates pending
	log "x No updates pending, not going to schedule any installation."
	set_nagios_status OK "No updates pending"
}

logging end twingle_check

exit 0
