#
# profile.ps1
#

Import-Module PSColors

$LOCAL_PROGRAMS = "$env:LOCALAPPDATA/Programs"

$PYTHON27_ROOT = "$LOCAL_PROGRAMS/Python/Python27"
$PYTHON36_ROOT = "$LOCAL_PROGRAMS/Python/Python36"

$env:ANDROID_SDK_HOME = "$LOCAL_PROGRAMS/android/sdk"
$env:ANDROID_NDK_HOME = "$LOCAL_PROGRAMS/android/ndk"

function InitializePath {

  $newPaths = @(
    # git and msys
    "$LOCAL_PROGRAMS/Git/bin/",
    "$LOCAL_PROGRAMS/Git/usr/bin/",
    # adb.exe
    "$env:ANDROID_SDK_HOME/platform-tools/",
    # aapt.exe etc.
    "$env:ANDROID_SDK_HOME/build-tools/26.0.0/",
    # ndk-build
    "$env:ANDROID_NDK_HOME",
    # CMake
    "$LOCAL_PROGRAMS/cmake/cmake-3.8.2/bin/",
    # Pandoc
    "$env:LOCALAPPDATA/Pandoc/"
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
  [string]$defaultStorePass = "android",
  [string]$alias = "androiddebugkey")

  $path = Resolve-Path $path
  $file = Get-ChildItem $path
  $newPath = Join-Path $file.DirectoryName "$($file.BaseName)_signed$($file.Extension)"
  if (Test-Path $newPath) {
    Remove-Item -Path $newPath
  }
  Copy-Item -Destination $newPath $path
  zip -d $newPath "META-INF/*.RSA"
  zip -d $newPath "META-INF/*.DSA"
  zip -d $newPath "META-INF/*.SF"
  zip -d $newPath "META-INF/MANIFEST.MF"

  $keystorePath = Resolve-Path $keystorePath

  jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 `
            -keystore $keystorePath -storepass $defaultStorePass $newPath $alias
}

function get_apk_info() {
  param ([string]$path)
  $command = "aapt d badging '{0}'" -f $path
  $default_encoding = [Console]::OutputEncoding
  [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
  $output = Invoke-Expression "$command 2>&1"
  [Console]::OutputEncoding = $default_encoding
  if ($LASTEXITCODE -ne 0) {
    throw $output
  }
  $package_name = [regex]::Match($output, "(?smi)(?<=package:\sname=\')(.*?)(?=\')").Value
  $version_code = [regex]::Match($output, "(?smi)(?<=versionCode=\')(.*?)(?=\')").Value
  $version_name = [regex]::Match($output, "(?smi)(?<=versionName=\')(.*?)(?=\')").Value
  $application_label = [regex]::Match($output, "(?smi)(?<=application:\slabel=\')(.*?)(?=\')").Value
  Write-Host ("Application Label: " + $application_label) -foregroundcolor DarkGray
  Write-Host ("Package Name: " + $package_name) -foregroundcolor DarkGray
  Write-Host ("Version Name: " + $version_name) -foregroundcolor DarkGray
  Write-Host ("Version Code: " + $version_code) -foregroundcolor DarkGray
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
  $env:PYTHONPATH = "$LOCAL_PROGRAMS/Python/Python27/Lib/site-packages;$drozerBasePath/src"
  python2 "$drozerBasePath/bin/drozer" $args
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
  
  if (Test-Path HKCU:"\Software\SweetScape\010 Editor\CLASSES") {
    Remove-Item -Path HKCU:"\Software\SweetScape\010 Editor\CLASSES" -Recurse
  }
  if (Test-Path HKCU:"\SOFTWARE\Scooter Software\Beyond Compare 4") {
    Remove-Item -Path HKCU:"\SOFTWARE\Scooter Software\Beyond Compare 4" -Recurse
  }
  Start-SshAgent -Quiet
}

# Initialize aliases
Set-Alias -name hedit -value "$Env:ProgramFiles/010 Editor/010Editor.exe"
Set-Alias -name bcom -value "$LOCAL_PROGRAMS/Beyond Compare 4/BCompare.exe"
Set-Alias -name idaq32 -value "$LOCAL_PROGRAMS/IDA/IDA.Pro.v6.95/idaq.exe"
Set-Alias -name idaq64 -value "$LOCAL_PROGRAMS/IDA/IDA.Pro.v6.95/idaq64.exe"
Set-Alias -name jeb -value "$LOCAL_PROGRAMS/android/jeb-1.5.201508100/jeb_wincon.bat"
Set-Alias -name jeb2 -value "$LOCAL_PROGRAMS/android/jeb-2.0.6.201508252211/jeb_wincon.bat"
Set-Alias -name ddms -value "$LOCAL_PROGRAMS/android/sdk/tools/monitor.bat"
Set-Alias -name apktool -value "$LOCAL_PROGRAMS/android/apktool/apktool.bat"
Set-Alias -name smali -value "$LOCAL_PROGRAMS/android/apktool/smali.bat"
Set-Alias -name baksmali -value "$LOCAL_PROGRAMS/android/apktool/baksmali.bat"
Set-Alias -name burp -value "$LOCAL_PROGRAMS/burpsuite/burpsuite.bat"
Set-Alias -name zip -value "$LOCAL_PROGRAMS/zip/zip.exe"
Set-Alias -Name python3 -Value "$PYTHON36_ROOT/python.exe"
Set-Alias -Name pip3 -Value "$PYTHON36_ROOT/Scripts/pip3.exe"
Set-Alias -Name python2 -Value "$PYTHON27_ROOT/python.exe"
Set-Alias -Name pip2 -Value "$PYTHON27_ROOT/Scripts/pip2.exe"
Set-Alias -Name pypy -Value "$LOCAL_PROGRAMS/Python/pypy/pypy.exe"