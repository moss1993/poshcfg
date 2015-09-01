﻿#
# profile.ps1
#

Import-Module PSColors

$TOOLS_BASE_PATH = "D:/tools"

function InitializePath {

  $newPaths = @(
    # git and msys
    "C:/Program Files/Git/bin/",
    "C:/Program Files/Git/usr/bin",

    # adb.exe
    "$TOOLS_BASE_PATH/android/sdk/platform-tools/",
    # aapt.exe etc.
    "$TOOLS_BASE_PATH/android/sdk/build-tools/23.0.0/",
    # ndk-build
    "$TOOLS_BASE_PATH/android/ndk/",
    # arm*readelf.exe etc.
    "$TOOLS_BASE_PATH/android/ndk/toolchains/arm-linux-androideabi-4.9/prebuilt/windows-x86_64/bin/"
  )

  $currentPaths = $env:Path.Split(";")

  $env:Path = ""
  Foreach ($path in $currentPaths) {
    $env:Path = $env:Path + ";" + $path
  }

  Foreach ($path in $newPaths) {
    $env:Path = $env:Path + ";" + $path
  }
}

function PrintIpAddreses() {
  $ipaddress = [System.Net.DNS]::GetHostByName($null)
  Foreach ($ip in $ipaddress.AddressList) {
    Write-Host (" * " + $ip.IPAddressToString) -foregroundcolor DarkGray
  }
}

# Profile entry.

Write-Host "Initializing..." -foregroundcolor DarkGray
Write-Host ("Now: " + [System.DateTime]::Now.toString()) -foregroundcolor DarkGray
Write-Host ("Host: " + $host.Name)

if ($host.Name -eq "ConsoleHost") {

  # Oh no...
  Write-Host " ___________.__           _________      __          " -foregroundcolor blue
  Write-Host " \__    ___/|  |__   ____ \_   ___ \    |__|_  _  __ " -foregroundcolor blue
  Write-Host "   |    |   |  |  \_/ __ \/    \  \/    |  \ \/ \/ / " -foregroundcolor yellow
  Write-Host "   |    |   |   Y  \  ___/\     \____   |  |\     /  " -foregroundcolor yellow
  Write-Host "   |____|   |___|  /\___  >\______  /\__|  | \/\_/   " -foregroundcolor DarkRed
  Write-Host "                 \/     \/        \/\______|         " -foregroundcolor DarkRed

  Import-Module xPSDesiredStateConfiguration
  Import-Module Posh-SSH
  Import-Module PoshNet
  Import-Module x7Zip
  Import-Module Find-String

  InitializePath
  PrintIpAddreses

  # Initialize aliases
  Set-Alias -name subl -value "C:/Program Files/Sublime Text 3/sublime_text.exe"
  Set-Alias -name hedit -value "C:/Program Files/010 Editor/010Editor.exe"

  Set-Alias -name bcom -value "$TOOLS_BASE_PATH/Misc/Beyond Compare 4/BCompare.exe"
  Set-Alias -name ida32 -value "$TOOLS_BASE_PATH/Debuggers/IDA.Pro.v6.6/idaq.exe"
  Set-Alias -name ida64 -value "$TOOLS_BASE_PATH/Debuggers/IDA.Pro.v6.6/idaq64.exe"

  Set-Alias -name jeb -value "$TOOLS_BASE_PATH/android/jeb-1.5.201408040/jeb_wincon.bat"
  Set-Alias -name ddms -value "$TOOLS_BASE_PATH/android/sdk/tools/monitor.bat"
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

# 
function forward_ida() {
  adb forward tcp:23946 tcp:23946
}
