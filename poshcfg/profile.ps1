#
# profile.ps1
#

Import-Module PSColors

$TOOLS_BASE_PATH = "$env:LOCALAPPDATA/Programs"

function InitializePath {

  $newPaths = @(
    # git and msys
    "$TOOLS_BASE_PATH/Git/bin/",
    "$TOOLS_BASE_PATH/Git/usr/bin/",
    # adb.exe
    "$TOOLS_BASE_PATH/android/sdk/platform-tools/",
    # aapt.exe etc.
    "$TOOLS_BASE_PATH/android/sdk/build-tools/24.0.0/",
    # ndk-build
    "$TOOLS_BASE_PATH/android/ndk/",
    # arm*readelf.exe etc.
    "$TOOLS_BASE_PATH/android/ndk/toolchains/arm-linux-androideabi-4.9/prebuilt/windows-x86_64/bin/",
    "$Env:JAVA_HOME/bin/",
    "$TOOLS_BASE_PATH/Python/Launcher"
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
Write-Host "Now:" ([System.DateTime]::Now.toString()) -foregroundcolor DarkGray
Write-Host "Host:" $host.Name
Write-Host
Write-Host "Current ip:"
[System.Net.DNS]::GetHostByName($null).AddressList | ForEach-Object {
  Write-Host (" * " + $_.IPAddressToString) -foregroundcolor DarkGray
}

InitializePath

if ($host.Name -eq "ConsoleHost") {

  # Initialize aliases
  Set-Alias -name subl -value "$Env:ProgramFiles/Sublime Text 3/sublime_text.exe"
  Set-Alias -name hedit -value "$Env:ProgramFiles/010 Editor/010Editor.exe"
  Set-Alias -name sourcetree -value "${Env:ProgramFiles(x86)}/Atlassian/SourceTree/SourceTree.exe"

  Set-Alias -name bcom -value "$TOOLS_BASE_PATH/Misc/Beyond Compare 4/BCompare.exe"
  Set-Alias -name ida32 -value "$TOOLS_BASE_PATH/IDA/IDA.Pro.v6.8/idaq.exe"
  Set-Alias -name ida64 -value "$TOOLS_BASE_PATH/IDA/IDA.Pro.v6.8/idaq64.exe"

  Set-Alias -name jeb -value "$TOOLS_BASE_PATH/android/jeb-1.5.201508100/jeb_wincon.bat"
  Set-Alias -name ddms -value "$TOOLS_BASE_PATH/android/sdk/tools/monitor.bat"

  Set-Alias -name apktool -value "$TOOLS_BASE_PATH/android/apktool/apktool.bat"
  Set-Alias -name smali -value "$TOOLS_BASE_PATH/android/apktool/smali.bat"
  Set-Alias -name baksmali -value "$TOOLS_BASE_PATH/android/apktool/baksmali.bat"

  Set-Alias -name burp -value "$TOOLS_BASE_PATH/misc/burpsuite/burpsuite.bat"

  Set-Alias -name 7z -value "$TOOLS_BASE_PATH/misc/7-Zip/7z.exe"

  Set-Alias -Name python3 -Value "$TOOLS_BASE_PATH/Python/Python35-32/python.exe"
  Set-Alias -Name pip3 -Value "$TOOLS_BASE_PATH/Python/Python35-32/Scripts/pip3.exe"

  Set-Alias -Name pypy -Value "$TOOLS_BASE_PATH/Python/pypy/pypy.exe"
  Set-Alias -Name pypy3 -Value "$TOOLS_BASE_PATH/Python/pypy3/pypy.exe"

  if (Test-Path HKCU:"\Software\SweetScape\010 Editor\CLASSES") {
    Remove-Item -Path HKCU:"\Software\SweetScape\010 Editor\CLASSES" -Recurse
  }
  if (Test-Path HKCU:"\SOFTWARE\Scooter Software\Beyond Compare 4") {
    Remove-Item -Path HKCU:"\SOFTWARE\Scooter Software\Beyond Compare 4" -Recurse
  }
  Start-SshAgent -Quiet
}

# some Git commands.
function gs {
  git status
}
function gll {
  git log --oneline --all --graph --decorate $args
}

function drozer {
  adb forward tcp:31415 tcp:31415
  cd "$env:USERPROFILE/Documents/code/python/drozer"
  .\drozer.py $args
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
  param ([string]$path)

  $path = Resolve-Path $path
  $file = Get-ChildItem $path
  $newPath = Join-Path $file.DirectoryName "$($file.BaseName)_signed$($file.Extension)"
  if (Test-Path $newPath) {
    Remove-Item -Path $newPath
  }
  Copy-Item -Destination $newPath $path
  7z d $newPath "META-INF/*"

  $keystorePath = Resolve-Path "~/.android/debug.keystore"
  $defaultStorePass = "android"

  jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 `
            -keystore $keystorePath -storepass $defaultStorePass $newPath androiddebugkey
}
