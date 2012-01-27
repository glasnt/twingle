##############################################################################
# 
#	Twingle firsttime setup
#
#	setup configs, create scheduled task for the weekly update checks
#
#   If run without parmaters, will automatically accept all defaults.
#   Run with "-attended" to customise installation.
#
##############################################################################


function log ($text) {
	$logfile = "C:\twingle\twingle.log"
	$date = Get-Date -format G
	$output = "$date - $Text"
	$output | Out-File $logfile -Append
}

function out ($text) { 
	if ($get) { $text } 
}

#if unattended setup, then auto accept all defaults. 
if ($args -match "-attended") { 
	#manual installation
	" ################################################## "
	" #                                                # "
	" #                  TWINGLE                       # "
	" #                                                # "
	" ################################################## "
	" "
	" Twingle setup file. "
	" Accept the defaults, or override them. "
	" These will be used for the config file."
	" "
	" "
	$computername =  (gc env:computername).tolower()
	log "Manual installation of twingle triggered for server $computername"
	$get = 1 #get content

} else { 
	log "Automated Installation of Twingle. All defaults accepted."
}

$file = "twingle.cfg"


#SETUP ALL TEH CONFIGS

# Initialization
$ConfigComment = @()
$ConfigKey     = @()
$ConfigValue   = @()
$Enteredvalue  = ""
$configCount   = -1

function process {
	if ($EnteredValue.length -ne 0) { $configValue[$configCount] = $EnteredValue; $custom = "(custom setting)" } else { $custom = ""}
	log ("Config #$configCount : "+$configKey[$configCount]+", value: "+$configValue[$configCount]+" "+$custom)
	
}

log "Start config" 

#Twingle Directory
$configCount++
$configComment += "Twingle directory"
$configKey 	   += "twingledir"
$configValue   += "C:\twingle"
if ($get) { $EnteredValue = Read-Host ("Please enter the location you copied twingle to ("+$configValue[$configCount]+")") }
process


#Status Log
$configCount++
$configComment += "Status Log"
$configKey 	   += "statuslog"
$configValue   += "status.log"
if ($get) { $EnteredValue = Read-Host ("Please enter name for the status log ("+$configValue[$configCount]+")") }
process

#Cache File
$configCount++
$configComment += "Cache File"
$configKey 	   += "cachefile"
$configValue   += "windows_updates.xml"
if ($get) { $EnteredValue = Read-Host ("Please enter name for the update cache file ("+$configValue[$configCount]+")")}
process

#Old update Warning/Critical buffers 
$configCount++
$configComment += "Age buffer for warning about oldish updates"
$configKey 	   += "oldUpdateWarningBuffer"
$configValue   += "28"
if ($get) { $EnteredValue = Read-Host ("Warn about old-ish updates after how many days ("+$configValue[$configCount]+")")}
process

$configCount++
$configComment += "Age buffer for critical about really old updates"
$configKey 	   += "oldUpdateCriticalBuffer"
$configValue   += "54"
if ($get) { $EnteredValue = Read-Host ("Critical over really old updates after how many days ("+$configValue[$configCount]+")")}
process

#Cache file age # NOT APPLICABLE ANYMORE?
$configCount++
$configComment += "Update windows cache file after X hours"
$configKey 	   += "updateCacheExpireHours"
$configValue   += "1"
if ($get) { $EnteredValue = Read-Host ("How old can the windows cache be before you want to recheck it? (hours) ("+$configValue[$configCount]+")")}
process

#Install optional updates!
$configCount++
$configComment += "Install optional updates"
$configKey 	   += "installOptionalUpdates"
$configValue   += "0"
if ($get) { $EnteredValue = Read-Host ("Do you want to install optional updates? (boolean) ("+$configValue[$configCount]+")")}
process

#Reboot Options
$configCount++
$configComment += "Kindly reboot?"
$configKey 	   += "kindlyreboot"
$configValue   += "1"
if ($get) { $EnteredValue = Read-Host ("Do you want to let twingle nicely reboot the server? (boolean) ("+$configValue[$configCount]+")")}
process

$configCount++
$configComment += "Reboot Delay - seconds"
$configKey 	   += "rebootdelay"
$configValue   += "300"
if ($get) { $EnteredValue = Read-Host ("How long do you want to delay a server reboot, if allowed? (seconds) ("+$configValue[$configCount]+")")}
process


$configCount++
$configComment += "No Reboot - do not allow twingle to reboot. "
$configKey 	   += "noreboot"
$configValue   += "0"
if ($get) { $EnteredValue = Read-Host ("Can twingle reboot the server? (boolean) ("+$configValue[$configCount]+")")}
process


# Email settings
$configCount++
$configComment += "Email client about pending scheduled updates  "
$configKey 	   += "emailclient"
$configValue   += "1"
if ($get) { $EnteredValue = Read-Host ("Can twingle notify the client of pending updates? (boolean) ("+$configValue[$configCount]+")")}
process

$configCount++
$configComment += "SMTP server for client emails"
$configKey 	   += "smtpserver"
$configValue   += "localhost"
if ($get) { $EnteredValue = Read-Host ("SMTP server to use for client emails ("+$configValue[$configCount]+")")}
process

# Scheduled Update times
$configCount++
$configComment += "Update Install Day"
$configKey 	   += "installday"
$configValue   += "THU"
#if ($get) { $EnteredValue = Read-Host ("Installation day: [MON,TUE,WED,THU] ("+$configValue[$configCount]+")")}
$EnteredValue = Read-Host ("Installation day: [MON,TUE,WED,THU] ("+$configValue[$configCount]+")")
process
$installDay = $configValue[$configCount]

$configCount++
$configComment += "Update Install Time"
$configKey 	   += "installtime"
$configValue   += "19:00"
#if ($get) { $EnteredValue = Read-Host ("Installation time: ("+$configValue[$configCount]+")")}
$EnteredValue = Read-Host ("Installation time: ("+$configValue[$configCount]+")")
process

$configCount++
$configComment += "Check for updates - day"
$configKey 	   += "updateCheckDay"
if ($installDay -eq "MON" ) { $notifyDay = "WED" } 
elseif ($installDay -eq "TUE" ) { $notifyDay = "THU" } 
elseif ($installDay -eq "WED" ) { $notifyDay = "FRI" }
elseif ($installDay -eq "THU" ) { $notifyDay = "MON" } 
$configValue += $notifyDay
#if ($get) { $EnteredValue = Read-Host ("Day to check for pending updates (3 business days before install day): ("+$notifyDay+")")}
$EnteredValue = Read-Host ("Day to check for pending updates/send maintenance email: ("+$notifyDay+")")
process
$notifyDay = $configValue[$configCount] 

$configCount++
$configComment += "Check for updates - time"
$configKey 	   += "notifytime"
$configValue += "08:00"
#if ($get) { $EnteredValue = Read-Host ("Time of day to check for updates on Check day : ("+$configValue[$configCount]+")")}
$EnteredValue = Read-Host ("Time of day to check for updates on Check day: ("+$configValue[$configCount]+")")
process

$notifytime = $configValue[$configCount] 

#AUTOMATED STUFFS NOW

if ( $get) { 
".. and that's all the input we need. Doing smart things now"
} 

log "end config"

#Check SMTP is OK for server
$smtpstatus = (get-service | where-object {$_.name -eq "SMTPSVC"}).status
if ( $smtpstatus -eq "stopped")  {
	out " "
	out "NOTICE: This server currently doesn't have SMTPSVC running, and may not be able to send emails. You should probably totally check that."
	out " "
	log "SMTPSVC not running at time of installation"
} else { 
	out "SMTPSVC is running, so it should/might be able to sent emails ok."
}

#setup the scheduled task

$twingledir = "C:\twingle"
$schedtaskName = "Twingle Windows Updates - recurring"
$schedtask = "schtasks /create /tn `"$schedtaskName`" "
$schedtask += "/TR `"powershell.exe $twingledir\twingle.ps1 -check`" "
$schedtask += "/sc weekly /d $notifyday /st $notifytime /f"
log "Sched task: $schedtask"

$output = invoke-expression $schedtask

if ($output -match "SUCCESS") { 	
	$msg = "Created Scheduled task: '$schedtaskname', recurring on $notifyday at $notifytime"
} else { 
	$msg = "Scheduled task could not be created. You might want to manually check that." 
}
log $msg; out $msg
out " "

# Save configuration to file
out "Saving configs to file.."
out "" | Out-File $file	

function cfg ($Text) { 
	$text | Out-File $file -Append
}

cfg "# Twingle twingle, little star"
cfg "# ini file is what you are"
cfg " " 
cfg "[config]"
cfg " " 

for ($i = 0; $i -le $configCount; $i++) { 
	cfg ("# "+$configComment[$i])
	cfg (""+$configKey[$i]+" = "+$configValue[$i])
	cfg (" ")	
}

out " "
out ".. Saved to file $file. "

log "config file $file created. "
log "setup complete."



# send passive alerty goodness.
out "Assuming you've added the ANCHOR_TWINGLE to nagios already.."

Import-Module "$twingledir\lib\twingle_common.psm1"  
set_nagios_status OK  "Twingle installed. Pending first run"

out "Passive check sent. Should be appearing in nagios soon"

exit 0
