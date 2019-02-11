[CmdletBinding(SupportsShouldProcess)]
# Parameters for script
param (
	# Parameter Indicate whether the Stream Deck application should be restarted
	[switch]
	$RestartStreamDeck = $false,
	[string]
	$ProjectFilename = "",
	[string]
	$UUID = ""
)

Write-Debug "Is What-if: $WhatIfPreference";

Write-Verbose "Script root: $PSScriptRoot`n"
Write-Verbose "[Param] Restrart Stream Deck	: $RestartStreamDeck";
Write-Verbose "[Param] ProjectFile				 	: $ProjectFile";
Write-Verbose "[Param] UUID									: $UUID";

Write-Output "Gathering deployment items..."

$basePath = $PSScriptRoot

if (!($PSSCriptRoot)) {
  $basePath = $PWD.Path;
}

$ProjectFileName = $ProjectFilename.Trim();

If ([string]::IsNullOrEmpty($projectFileName)) {
	$ProjectFileName = "SamplePlugin.csproj";
}

Write-Verbose "Using project file:  `"$ProjectFileName`"";

# Load and parse the plugin project file
$pluginProjectFile = Join-Path $basePath $ProjectFileName;
$projectContent = Get-Content $pluginProjectFile | Out-String;
$projectXML = [xml]$projectContent;

# Get the target .net core framework
$targetFrameworkName = $projectXML.Project.PropertyGroup.TargetFramework;
Write-Debug "The project's target framework is `"$targetFrameworkName`"";

# Set local path references
if ($IsMacOS) {
	Write-Verbose "Using macOS paths";
  $streamDeckExePath = "/Applications/Stream Deck.app"
  $bindir = "$basePath/bin/Debug/$targetFrameworkName/osx-x64"
} else {
	Write-Verbose "Using Windows paths";
  $streamDeckExePath = "$($ENV:ProgramFiles)\Elgato\StreamDeck\StreamDeck.exe"
  $bindir = "$basePath\bin\Debug\$targetFrameworkName\win-x64"
}

# Make sure we actually have a directory/build to deploy
If (-not (Test-Path $bindir)) {
  Write-Error "The output directory `"$bindir`" was not found.`n You must first build the `"SamplePlugin.csproj`" project before calling this script.";
  exit 1;
}

$pluginID = "";

if ([string]::IsNullOrEmpty($UUID)){
	Write-Verbose "Using the UUID from the first action of the manifest."
	# Load and parse the plugin's manifest file
	$manifestPath = Join-Path $bindir "manifest.json";
	$json = Get-Content -Path $manifestPath -Raw | ConvertFrom-Json;

	$uuidAction = $json.Actions[0].UUID;
	Write-Verbose "Action UUID: $uuidAction";

	$pluginID = $uuidAction.substring(0, $uuidAction.LastIndexOf('.'));
} else {
	Write-Verbose "Using UUID value from the `$UUID parameter."
	$pluginID = $UUID.Trim();
}

Write-Verbose "Plugin UUID: $pluginID";


if($IsMacOS) {
  $destDir = "$HOME/Library/Application Support/com.elgato.StreamDeck/Plugins/$pluginID.sdPlugin";
} else {
  $destDir = "$($env:APPDATA)\Elgato\StreamDeck\Plugins\$pluginID.sdPlugin";
}

$pluginName = Split-Path $basePath -leaf;

Write-Verbose "Ending the Stream Deck and plugin ($pluginName) processes";
Get-Process -Name ("StreamDeck", $pluginName) -ErrorAction SilentlyContinue | Stop-Process –force -ErrorAction SilentlyContinue;

# Delete the target directory, make sure the deployment/copy is clean
Write-Output "Removing the currently deployed plugin";
if (-not $WhatIfPreference) {
	Remove-Item -Recurse -Force -Path $destDir -ErrorAction SilentlyContinue;
	$bindir =  Join-Path $bindir "*";
}

# Then copy all deployment items to the plugin directory
Write-Output "Deploying latest build of the plugin";
if (-not $WhatIfPreference) {
	$targetDir = New-Item -Type Directory -Path $destDir -ErrorAction SilentlyContinue | Out-Null;
	Copy-Item -Path $bindir -Destination $targetDir -Recurse;
}


Write-Output "Deployment complete.";
if ($RestartStreamDeck) {
	Write-Output "Restarting the Stream Deck application";
	if (-not $WhatIfPreference){
		Start-Process $streamDeckExePath;
	}
}
else {
	Write-Output "The value of `$RestartStreamDeck was `$false, so the Stream Deck application will not be restarted.`nIf you want this script to restart the application, set `$RestartStreamDeck to `$True.";
}
