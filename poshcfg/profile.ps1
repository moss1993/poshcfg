#
# profile.ps1
#

Import-Module PSColors

$TOOLS_BASE_PATH = "c:/Users/N/AppData/Local/Programs"

function ShowBanner() {
  # Oh no...
  Write-Host " ___________.__           _________      __          " -foregroundcolor blue
  Write-Host " \__    ___/|  |__   ____ \_   ___ \    |__|_  _  __ " -foregroundcolor blue
  Write-Host "   |    |   |  |  \_/ __ \/    \  \/    |  \ \/ \/ / " -foregroundcolor yellow
  Write-Host "   |    |   |   Y  \  ___/\     \____   |  |\     /  " -foregroundcolor yellow
  Write-Host "   |____|   |___|  /\___  >\______  /\__|  | \/\_/   " -foregroundcolor DarkRed
  Write-Host "                 \/     \/        \/\______|         " -foregroundcolor DarkRed
}

function PrintIpAddreses() {
  $ipaddress = [System.Net.DNS]::GetHostByName($null)
  Foreach ($ip in $ipaddress.AddressList) {
    Write-Host (" * " + $ip.IPAddressToString) -foregroundcolor DarkGray
  }
}

function InitializePath {

  $newPaths = @(
    # git and msys
    "$Env:ProgramFiles/Git/bin/",
    "$Env:ProgramFiles/Git/usr/bin/",

    # adb.exe
    "$TOOLS_BASE_PATH/android/sdk/platform-tools/",
    # aapt.exe etc.
    "$TOOLS_BASE_PATH/android/sdk/build-tools/23.0.2/",
    # ndk-build
    "$TOOLS_BASE_PATH/android/ndk/",
    # arm*readelf.exe etc.
    "$TOOLS_BASE_PATH/android/ndk/toolchains/arm-linux-androideabi-4.9/prebuilt/windows-x86_64/bin/",

    "$Env:JAVA_HOME/bin/",

    "$TOOLS_BASE_PATH/Python/pypy-4.0.1-win32/"
  )

  $currentPaths = $Env:Path.Split(";")
  $Env:Path = $currentPaths -join ";"
  if (!$Env:Path.EndsWith(";")) {
    $Env:Path += ";"
  }
  $Env:Path = $Env:Path + ($newPaths -join ";")
}

# Profile entry.

Write-Host "Initializing..." -foregroundcolor DarkGray
Write-Host ("Now: " + [System.DateTime]::Now.toString()) -foregroundcolor DarkGray
Write-Host ("Host: " + $host.Name)

ShowBanner

if ($host.Name -eq "ConsoleHost") {

  InitializePath
  PrintIpAddreses

  # Initialize aliases
  Set-Alias -name subl -value "$Env:ProgramFiles/Sublime Text 3/sublime_text.exe"
  Set-Alias -name hedit -value "$Env:ProgramFiles/010 Editor/010Editor.exe"

  Set-Alias -name bcom -value "$TOOLS_BASE_PATH/Misc/Beyond Compare 4/BCompare.exe"
  Set-Alias -name ida32 -value "$TOOLS_BASE_PATH/IDA/IDA.Pro.v6.8/idaq.exe"
  Set-Alias -name ida64 -value "$TOOLS_BASE_PATH/IDA/IDA.Pro.v6.8/idaq64.exe"

  Set-Alias -name jeb -value "$TOOLS_BASE_PATH/android/jeb-1.5.201408040/jeb_wincon.bat"
  Set-Alias -name ddms -value "$TOOLS_BASE_PATH/android/sdk/tools/monitor.bat"

  Set-Alias -name apktool -value "$TOOLS_BASE_PATH/android/apktool/apktool.bat"
  Set-Alias -name smali -value "$TOOLS_BASE_PATH/android/apktool/smali.bat"
  Set-Alias -name baksmali -value "$TOOLS_BASE_PATH/android/apktool/baksmali.bat"

  Set-Alias -name burp -value "$TOOLS_BASE_PATH/misc/burpsuite/burpsuite.bat"

  Set-Alias -name sourcetree -value "${Env:ProgramFiles(x86)}/Atlassian/SourceTree/SourceTree.exe"

  # Import posh-git from current user module
  $profileDir = Split-Path $PROFILE
  $poshgitModule = Join-Path $profileDir "\Modules\posh-git\0.5.0.2015\posh-git.psm1"
  Import-Module $poshgitModule
  Start-SshAgent -Quiet

  # Update hedit.
  if (Test-Path HKCU:"\Software\SweetScape\010 Editor\CLASSES") {
    Remove-Item -Path HKCU:"\Software\SweetScape\010 Editor\CLASSES" -Recurse
  }
}

# some Git commands.
function gs() {
  git status
}
function gll() {
  git log --oneline --all --graph --decorate $args
}

# run drozer cli
function drozer() {
  adb forward tcp:31415 tcp:31415
  cd "$TOOLS_BASE_PATH/android/drozer"
  .\drozer.bat $args
}

# forward android_server port
function forward_ida() {
  adb forward tcp:23946 tcp:23946
}
