##############################################################################
# 
# Twingle - First Time Setup
#
##############################################################################
$env:PSModulePath = $env:PSModulePath + ";c:\lib"; 
Import-Module twingle; $ini = Parse_IniFile; $twingleDir = twingledir
logging start setup_twingle
##############################################################################

function blankline { out " "}
function out ($text) { 
	$text 
}

function welcome ($text) { 
	if ($text -eq "blank") {$text = ""}
	$char = " "
	if ($text -eq "hashbanner") { $char = "#"; $text = ""}
	$width = 60
	$buff = ($width - $text.length )/2
	for ($i = 0; $i -le $buff; $i++) {
		$buffer += $char
	 } 
	$buffer += $text
	for ($i = 0; $i -le $buff; $i++) {
		$buffer += $char
	} 
	write-host $buffer
}

$global:errorsFound = 0
function error ($text) { 
   write-host "ERROR:" -backgroundcolor "red" -foregroundcolor "white" -NoNewline
   write-host " " -NoNewLine
   write-host $text
   $global:errorsFound++
}

function ok ($text) { 
   write-host "OK:" -backgroundcolor "darkgreen" -foregroundcolor "white" -NoNewline
   write-host " " -NoNewLine
   write-host $text
}

#Twingle setup HAS to run as administrator, exit if not. 
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent()) 
if (!$currentPrincipal.IsInRole( [Security.Principal.WindowsBuiltInRole]::Administrator )) {
	blankline
	error "Twingle Setup has to be run as an administrator"
	blankline
	exit 0
} 

invoke-expression "cls"

#if unattended setup, then auto accept all defaults. 
if ($args -match "-full") { 
	#manual installation
	$TwingleRunType = "Full"
	$computername =  (gc env:computername).tolower()
	log "Manual installation of twingle triggered for server $computername"
	$get = 1 #get content
} elseif ($args -match "-auto"){ 
	$TwingleRunType = "Auto"
	foreach ($a in $args) { 
		if ($a -match "-day") { $autoDay = $a.substring($a.indexOf("=")+1)}
		if ($a -match "-time") { 
			$autoTime =  $a.substring($a.indexOf("=")+1); 
			$autoTime = $autoTime.substring(0,2)+":"+$autoTime.substring(2);
		}
	}
	if (!$autoDay) { out "Automatic installation format: .\twingle.ps1 -setup -auto -day=MON -time=1900"; exit 0} 
} else { 
	$TwingleRunType = "Basic"
	log "Automated Installation of Twingle. All defaults accepted."
}

#########
welcome blank
welcome hashbanner
welcome blank
welcome "TWINGLE SETUP"
welcome "($TwingleRunType)"
welcome blank
welcome hashbanner
welcome blank
#########

$configfile = "$twingledir\twingle.cfg"
#SETUP ALL TEH CONFIGS

# Initialization
$global:ConfigComment = @() 
$global:ConfigKey     = @()  
$global:ConfigValue   = @()  
$global:Enteredvalue  = ""  
$global:configCount   = -1

log "Start config" 

function ask ($type, $Comment, $Key, $Value, $Prompt) { 
	if ($TwingleRunType -eq "Auto") { $ask = 0; 
		if ($Key -eq "installday") { $Value = $autoDay}
		if ($Key -eq "installtime") { $Value = $autoTime}
	}
	
	$global:configComment += $Comment;	$global:configKey += $Key;	$global:configValue += $Value
	if ($TwingleRunType -ne "Auto") { 
		if (($get -eq 1) -or ($type -eq "mandatory")) { $ask = 1}	
		if ($type -eq "default") { $ask = 0 } # just default it, don't ask, don't tell.
		if ($ask -eq 1) { $EnteredValue = Read-Host ("$Prompt ($value)") }
	}
	#process
	if ($EnteredValue.length -ne 0) { $configValue[$configCount] = $EnteredValue; $custom = "(custom setting)" } else { $custom = ""}
	log ("Set config: "+$configKey[$configCount]+", value: "+$configValue[$configCount]+" "+$custom)
} 

if (!$get) { $defaults = "... defaults selected" }

blankline
out "> Install Time Options"
ask mandatory "Update Install Day" "installday" "THU" "Installation day: [MON,TUE,WED,THU]"
$installDay = $configValue[$configCount]

ask mandatory "Update Install Time" "installtime" "19:00" "Installation time: "
if ($installDay -eq "MON" ) { $notifyDay = "WED" } 
elseif ($installDay -eq "TUE" ) { $notifyDay = "THU" } 
elseif ($installDay -eq "WED" ) { $notifyDay = "FRI" }
elseif ($installDay -eq "THU" ) { $notifyDay = "MON" } 

ask mandatory "Check for updates - day" "updateCheckDay" "$notifyDay" "Day to check for pending updates/send maintenance email:"
$notifyDay = $configValue[$configCount] 

ask mandatory "Check for updates - time" "notifytime" "08:00" "Time of day to check for updates on Check day: "
$notifytime = $configValue[$configCount] 

ask default "Twingle Directory" "twingledir" "C:\twingle" "Twingle Installation Directory"
$twingleDir = $configValue[$configCount] 
ask default "Status Log" "statuslog" "status.log" "Status Log name"
ask default "Cache File" "cachefile" "windows_updates.xml" "Windows Cache file name"
blankline
out "> Update Options $defaults"
ask optional "Install optional updates" "installOptionalUpdates" "0" "Do you want to install optional updates? (boolean) "

blankline
out "> Reboot Options $defaults"
	
#MAJOR CHANGE - either reboot or not. Set a delay. 
function reboottype ($type, $option) { 
	ask $type "Reboot Delay or Reboot Time" "reboottype" $option "Do you want to [DELAY] an immediate reboot, or [TIME] a reboot?"
}
function reboottime($type, $option) { 
	ask $type "Reboot Time - 00:00" "reboottime" $option "What time do you want to reboot the server (02:00)?"
}

function rebootdelay ($type, $option) { 
	ask $type "Reboot Delay - seconds" "rebootdelay" $option "How long do you want to delay a server reboot"
}

ask optional "Twingle can has reboot?" "canhasreboot" "1" "Do you want to let twingle nicely reboot the server? (boolean)"
$canhasreboot = $configValue[$configCount] 

if ($canhasreboot -eq 0) { 
	#all other settings are off
	reboottype default "OFF"
	reboottime default "OFF"
	rebootdelay default "OFF"
} else {
	#ok to reboot, but what type?
	reboottype optional "DELAY"
	$reboottype = $configValue[$configCount] 
	
	if ($reboottype -eq "DELAY") {
		rebootdelay optional "300"
		reboottime default "NOW"
	} elseif ($reboottype -eq "TIME") { 
		rebootdelay default "300"
		reboottime optional "02:00"
	} 
}
	
blankline
out "> Notifications $defaults"
ask optional "Email client about pending scheduled updates" "emailclient" "1" "Can twingle notify the client of pending updates? (boolean) "
ask optional "SMTP server for client emails" "smtpserver" "localhost" "SMTP server to use for client emails "

blankline
out "> Nagios Options $defaults"
ask optional "Nagios on/off" "nagios" "1" "Let nagios proclaim status updates? (boolean)"
ask optional "Nagios error severity" "nagioserror" "WARNING" "How loud should nagios errors be? (OK,WARNING,CRITICAL)"
ask optional "Manually update" "noschtask" "0" "Don't create any scheduled tasks, at all (boolean)"
$noschtask = $configValue[$configCount] 

blankline
#AUTOMATED STUFFS NOW

blankline
if (!$get) { 
"Configurations set. Testing server functionality..."
} 

log "end config"
blankline



#Check SMTP is OK for server
out "Testing the ability of this server to send emails... "
$smtpstatus = (get-service | where-object {$_.name -eq "SMTPSVC"}).status
if ( $smtpstatus -eq "stopped")  {
	error "SMTPSVC is stopped. "
	out "This server currently doesn't have SMTPSVC running, and may not be able to send emails. You should probably totally check that."
	blankline
	log "SETUP ERROR: SMTPSVC not running at time of installation"
} else { 
	OK "SMTPSVC is running, so it should/might be able to sent emails ok."
}
blankline
	
# Save configuration to file
out "Saving configs to file.."
out "" | Out-File $configfile	

function cfg ($Text) { 
	$text | Out-File $configfile -Append
}

cfg "# Twingle twingle, little star"
cfg "# ini file is what you are"
cfg " " 
cfg "[config]"
cfg " " 

for ($i = 0; $i -le $configValue.count -1; $i++) { 
	cfg ("# "+$configComment[$i])
	cfg (""+$configKey[$i]+" = "+$configValue[$i])
	cfg (" ")	
}

ok "Saved to file $configfile. "
log "config file $configfile created. "

blankline


$ini = Parse_IniFile
#setup the scheduled task
out "Setting up scheduled task for weekly update checks... "

$return = schedule_task "Twingle Windows Updates - recurring" "WEEKLY" $notifyday $notifytime "powershell.exe $twingledir\twingle.ps1 -check"

if ($return -eq 0 ) { 	
	$msg = "Created Scheduled task, recurring on $notifyday at $notifytime"
	ok $msg
} else { 
	$msg = "Scheduled task could not be created. You might want to manually check that." 
	error $msg
}

blankline

# send passive alerty goodness.
out "Sending first Twingle passive notification to nagios... "

set_nagios_status OK  "Twingle installed. Pending first run"


blankline
if ($errorsFound -eq 0) { OK "Twingle setup A-OK. Have a nice day." }
else { write-host "Twingle did not install correctly." -background "red" -foreground "white"
out "Twingle setup with $errorsFound errors. Please review this output before continuing"
log "Twingle setup with $errorsFound errors." }

log "setup complete."

logging end twingle_setup

pause
exit 0
