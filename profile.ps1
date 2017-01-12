#
# profile.ps1
#

Import-Module PSColors

$TOOLS_BASE = "$env:LOCALAPPDATA/Programs"
$NDK_ROOT = "C:/ProgramData/Microsoft/AndroidNDK64/android-ndk-r11c"

$PYTHON27_ROOT = "$TOOLS_BASE/Python/Python27"
$PYTHON36_ROOT = "$TOOLS_BASE/Python/Python36"

function InitializePath {

  $newPaths = @(
    # git and msys
    "$TOOLS_BASE/Git/bin/",
    "$TOOLS_BASE/Git/usr/bin/",
    # adb.exe
    "$TOOLS_BASE/android/sdk/platform-tools/",
    # aapt.exe etc.
    "$TOOLS_BASE/android/sdk/build-tools/25.0.2/",
    # ndk-build
    $NDK_ROOT,
    # FIXME: support aarch64 & arm.
    # pypy
    "$TOOLS_BASE/Python/pypy/"
  )

  $currentPaths = $Env:Path.Split(";")
  $Env:Path = ($currentPaths += $newPaths) -join ";"
}

# some Git commands.
function gs {
  git status
}

function gll {
  git log --oneline --all --graph --decorate $args
}

# forward android_server port
function forward_ida {
  adb forward tcp:23946 tcp:23946
}

function forward_frida {
  adb forward tcp:27042 tcp:27042
  adb forward tcp:27043 tcp:27043
}

# Base64 encode/decode helper.
function b64encode {
  param ([string]$content)
  $bytes = [System.Text.Encoding]::ASCII.GetBytes($content)
  $encodedText = [Convert]::ToBase64String($bytes)
  Write-Host $encodedText
}

function b64decode {
  param ([string]$content)
  $decodedText = [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($content))
  Write-Host $decodedText
}

# Print signature info of PE file.
function pe_signature {
  param ([string]$path)
  Get-AuthenticodeSignature $path | Format-List
}

function jar_signature {
  param ([string]$path)
  jarsigner -verify $path
}

# Copy and sign APK with default keystore.

function sign_apk() {
  param ([string]$path,
  [string]$keystorePath = "~/.android/debug.keystore",
  [string]$defaultStorePass = "android")

  $path = Resolve-Path $path
  $file = Get-ChildItem $path
  $newPath = Join-Path $file.DirectoryName "$($file.BaseName)_signed$($file.Extension)"
  if (Test-Path $newPath) {
    Remove-Item -Path $newPath
  }
  Copy-Item -Destination $newPath $path
  7z d $newPath "META-INF/*"

  $keystorePath = Resolve-Path $keystorePath

  jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 `
            -keystore $keystorePath -storepass $defaultStorePass $newPath androiddebugkey
}

# python staff

function clear_python() {
  $entries = $env:Path.Split(";") | Where-Object {
    ($_.ToLower().IndexOf("python27") -eq -1) -and
      ($_.ToLower().IndexOf("python36") -eq -1)
  }
  $Env:Path = $entries -join ";"
}

function use_py2() {
  clear_python
  $paths = @("$PYTHON27_ROOT",
    "$PYTHON27_ROOT/Scripts")

 $entries = $env:Path.Split(";")
 $Env:Path = ($entries += $paths) -join ";"
}

function use_py3() {
  clear_python
  $paths = @("$PYTHON36_ROOT",
    "$PYTHON36_ROOT/Scripts")

 $entries = $env:Path.Split(";")
 $Env:Path = ($entries += $paths) -join ";"
}

function drozer {
  adb forward tcp:31415 tcp:31415
  $drozerBasePath = "$env:USERPROFILE/Documents/code/python/drozer"
  $env:PYTHONPATH = "$TOOLS_BASE/Python/Python27/Lib/site-packages;$drozerBasePath/src"
  python2 "$drozerBasePath/bin/drozer" $args
}

function enjarify() {
  $enjarifyPath = "$env:USERPROFILE/Documents/code/python/enjarify"
  $env:PYTHONPATH = "$TOOLS_BASE/Python/Python36/Lib/site-packages;$enjarifyPath"
  python3 -O -m enjarify.main $args
}

function sqlmap() {
  python2 "$env:USERPROFILE/Documents/code/python/sqlmap/sqlmap.py" $args
}

# IDA
function ida32() {
  use_py2
  idaq32 $args
  use_py3
}

function ida64() {
  use_py2
  idaq64 $args
  use_py3
}

# Profile entry.

Write-Host "Initializing..." -foregroundcolor DarkGray
Write-Host "Now:" ([System.DateTime]::Now.toString()) -foregroundcolor DarkGray
Write-Host "Host:" $host.Name
Write-Host
Write-Host "Current ip:"
[System.Net.DNS]::GetHostByName($null).AddressList | ForEach-Object {
  Write-Host (" * " + $_.IPAddressToString) -foregroundcolor DarkGray
}

InitializePath

# use python3 as default.
use_py3

if ($host.Name -eq "ConsoleHost") {

  # Initialize aliases
  Set-Alias -name subl -value "$Env:ProgramFiles/Sublime Text 3/sublime_text.exe"
  Set-Alias -name vscode -value "$TOOLS_BASE/VSCode/code.exe"

  Set-Alias -name hedit -value "$Env:ProgramFiles/010 Editor/010Editor.exe"
  Set-Alias -name sourcetree -value "${Env:ProgramFiles(x86)}/Atlassian/SourceTree/SourceTree.exe"

  Set-Alias -name bcom -value "$TOOLS_BASE/Beyond Compare 4/BCompare.exe"

  Set-Alias -name idaq32 -value "$TOOLS_BASE/IDA/IDA.Pro.v6.95/idaq.exe"
  Set-Alias -name idaq64 -value "$TOOLS_BASE/IDA/IDA.Pro.v6.95/idaq64.exe"

  Set-Alias -name jeb -value "$TOOLS_BASE/android/jeb-1.5.201508100/jeb_wincon.bat"
  Set-Alias -name jeb2 -value "$TOOLS_BASE/android/jeb-2.0.6.201508252211/jeb_wincon.bat"
  Set-Alias -name ddms -value "$TOOLS_BASE/android/sdk/tools/monitor.bat"

  Set-Alias -name apktool -value "$TOOLS_BASE/android/apktool/apktool.bat"
  Set-Alias -name smali -value "$TOOLS_BASE/android/apktool/smali.bat"
  Set-Alias -name baksmali -value "$TOOLS_BASE/android/apktool/baksmali.bat"
  Set-Alias -name axmlprinter -value "$TOOLS_BASE/android/apktool/axmlprinter.bat"

  Set-Alias -name burp -value "$TOOLS_BASE/burpsuite/burpsuite.bat"

  Set-Alias -name 7z -value "$TOOLS_BASE/7-Zip/7z.exe"

  Set-Alias -Name python3 -Value "$PYTHON36_ROOT/python.exe"
  Set-Alias -Name pip3 -Value "$PYTHON36_ROOT/Scripts/pip3.exe"

  Set-Alias -Name python2 -Value "$PYTHON27_ROOT/python.exe"
  Set-Alias -Name pip2 -Value "$PYTHON27_ROOT/Scripts/pip2.exe"

  Set-Alias -Name pypy -Value "$TOOLS_BASE/Python/pypy/pypy.exe"

  if (Test-Path HKCU:"\Software\SweetScape\010 Editor\CLASSES") {
    Remove-Item -Path HKCU:"\Software\SweetScape\010 Editor\CLASSES" -Recurse
  }
  if (Test-Path HKCU:"\SOFTWARE\Scooter Software\Beyond Compare 4") {
    Remove-Item -Path HKCU:"\SOFTWARE\Scooter Software\Beyond Compare 4" -Recurse
  }
  Start-SshAgent -Quiet
}
