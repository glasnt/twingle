##############################################################################
# 
# Any function that's used more than once in twingle should go here. 
# Unless it's awesome enough for it's own file.
#
##############################################################################

$iniGlob = @{}

function twingleDir {   
	 $curr = Split-Path ([IO.FileInfo] ((Get-Variable MyInvocation -Scope 1).Value).MyCommand.Path).Fullname
	if ($curr -match "lib") { $curr = $curr.substring(0, $curr.length-3) }; return $curr.substring(0,$curr.length-1)
}

$twingleDir = twingleDir

# Parse the INI configuration file into a nice thing.
Function Parse_IniFile  ($file) {
  if (!$file) { $file = "$twingleDir\twingle.cfg"} 
  $ini = @{}
  switch -regex -file $file {
    "^\[(.+)\]$" {
      $section = $matches[1].Trim()
      $ini[$section] = @{}
    }
    "^\s*([^#].+?)\s*=\s*(.*)" {
      $name,$value = $matches[1..2]
      $ini[$section][$name] = $value.Trim()
    }
  }  
  
  set-variable -name iniGlob -value $ini  -scope 1 
  return $ini
}


function getConfig ($config){ 
	$value = $iniGlob["config"][$config]
	if ($value.length -eq 0) { "Config not found: $config"}	
	return $value
}


#Passive Nagios Check submit
function set_nagios_status ($result, $Text) {
	#CUSTOMISE THIS YOURSELF!
	
	# You can send passive checks to nagios here. This is left as an exercise for the reader.


	#save a copy to the log file
	$logfile = "$twingleDir\twingle.log"
	log "Nagios Passive Check submitted: $result : $Text"
}

$debug = 0
function debug_mode { 
	set-variable -name debug -value 1 -scope 1
}

$nesting = ""

#Log otuput to file, with nice date stamps
function log ($text) {
	$logfile = "$twingleDir\twingle.log"
	$date = Get-Date -format G
	if ($nesting.length -ne 0) { $buff = "  "} 
	$output = "$date - $buff$nesting $Text"
	$output | Out-File $logfile -Append
	if ($debug -eq 1) { $output }
}

# functionality to allow nested output (calls to new files have ">>", amount determined by depth)
function nest ($direction) {
	#set-variable -name exefile -value  $file  -scope 1
	if ($direction -eq "up") {
		$new = $nesting + ">"; set-variable -name nesting -value $new  -scope 1 }
	if ($direction -eq "down") { 
		$c = $nesting.length; $new = $nesting.substring(0,$c-1); set-variable -name nesting -value $new  -scope 1 }
}

