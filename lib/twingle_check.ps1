##############################################################################
# 
# Weekly Update processing. Runs directly from Task Scheduler.
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

nest up; log "start - twingle_check.ps1" 

invoke-expression "$twingledir\lib\twingle_update.ps1"

$updateCacheFile = getconfig cachefile 
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
		log "Sending maintenance notification email now..."

		# CUSTOMIZE THIS YOURSELF!

		$emailSubject = "Yo! Stuff's happening on your server at $installtime on "+($installday.toLower())
		$emailBody = "Content goes here"
		$emailFrom = "skynet@yourcompany.com"
		$emailTo = "victim@anothercompany.com"
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
	
	if ($today -eq $installdaynum) { $installdaynum += 7} 
	if ($today -gt $installdaynum) { $installdaynum += 7}
	$datediff = ($installdaynum - $today)
	
	$installdate = (Get-Date).AddDays($datediff).ToShortDateString()
	
	log "Install day is $installday, next installation date is $installdate"
		
	if ($installdate.length -eq 9) { $installdate = "0"+$installdate} # /o_O\
		
	$schedtaskname = "Twingle Windows updates for next $installday" 
	
	$existingtask = get_task $schedtaskname
	if ($existingtask) { 
		log "task already exists. Removing old task"; 
		$output = invoke-expression "schtasks /delete /tn `"$schedtaskname`" /f"
		if ($output -match "SUCCESS") { 
			log "Old task deleted successfully" 
		} else { 
			log "Old task deletion failed" 
	}
	}

	
	$schedtask = "schtasks /create /tn `"$schedtaskname`" "
	$schedtask += "/TR `"powershell.exe $twingledir\twingle.ps1 $action`" "
	$schedtask += "/sc ONCE /st $installtime /sd $installdate /f"

	log "going to run this code to create the task: $schedtask"
	
	$output = invoke-expression $schedtask	
	if ($output -match "SUCCESS") { 
		log "Scheduled task successfully created, will execute in $datediff days, on $installdate at $installtime" 
	} else { 
		log "Scheduled task could not be created." 
	}
	
	set_nagios_status OK "Updates scheduled for $installday on $installtime"
	
	
	
} else {
	#no updates pending
	log "No updates pending, not going to schedule any installation."
	set_nagios_status OK "No updates pending"
}

log "end twingle_weekly_update_check.ps1";nest down
