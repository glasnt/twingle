##############################################################################
# 
# Twingle (proper)
#
##############################################################################
# 
# Things twingle can do for you! (command line args)
#  -setup   : setup scheduled tasks, check SMTP, create config file
#  -check   : the weekly check for updates, downloading them, scheduling the installation, etc 
# 
#  -warm    : downloads the updates that "-update" logic'd
#  -install : install any and all downloaded updates
#  -reboot  : reboot the server, if required, to apply/finish updates.
#
##############################################################################

# Skip straight to setup if required
if ($args -match "-setup") { 
	.\setup_twingle.ps1 $args
	exit 0
} 



function usage { 
	"Twingle - tingle for windows."
	"Accepts the following parameters: -warm or -install or -reboot"
	exit 0
}

# Setup Twingle Environment
function getConfig ($config){ 
	$value = $ini["config"][$config]
	if ($value.length -eq 0) { "Config not found: $config"}	
	return $value
}

function twingleDir {   
	 $curr = Split-Path ([IO.FileInfo] ((Get-Variable MyInvocation -Scope 1).Value).MyCommand.Path).Fullname
	if ($curr -match "lib") { $curr = $curr.substring(0, $curr.length-3) }; if ($curr.substring($curr.length) -eq "\") { $curr = $curr.substring(0,$curr.length-1) } return $curr
}
$twingledir = twingledir
$common = "$twingledir\lib\twingle_common.psm1"
Import-Module $common
$ini = Parse_IniFile

#debug bonanza
if ($args -match "-debug") { 
	debug_mode
}

log "*******************************************************"
log "Starting a new twingle run; args: $args"


# Arg Parse.
if ($args) {
  
	if ($args -match "-warm") {
		$warm = 1;
	} elseif ($args -match "-install") {
		$install = 1;
	} elseif ($args -match "-reboot") {
		$reboot = 1; 
	} elseif ($args -match "-update") {
		$update = 1; 		
	} elseif ($args -match "-check") {
		$check = 1; 
	} else { 
		log ("Input can't be understood. You said "+$args[0]+"")
	}	
} else { 
	usage
}

$twingledir = getconfig twingledir

if ($warm) { 
	log "Input parameters say: download pending updates"
	invoke-expression "$twingledir\lib\twingle_warm_cache.ps1"
}

if ($install) {
	log "Input parameters say: download pending updates, then install"
	invoke-expression "$twingledir\lib\twingle_warm_cache.ps1"
	invoke-expression "$twingledir\lib\twingle_install.ps1"
}

if ($reboot) {
	log "Input parameters say:  download updates, install them, then reboot"
	invoke-expression "$twingledir\lib\twingle_warm_cache.ps1"
	invoke-expression "$twingledir\lib\twingle_install.ps1"
	invoke-expression "$twingledir\lib\twingle_reboot.ps1"
}

if ($check) { 
	log "Input parameters say: do the weekly check for updates" 
	invoke-expression "$twingledir\lib\twingle_check.ps1"
}

log "Finished the twingle run."

exit 0
