#Run as administrator and stays in the current directory
if (-Not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
        Start-Process PowerShell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"cd '$pwd'; & '$PSCommandPath' >log 2>&1 ;`"";
        Exit;
    }
}

# settings
$relay_server='RELAYSERVER'
$relay_key='KEY'
$webusername = 'WEB_USERNAME'
$webpassword = 'WEB_PASSWORD'
$version = 'RUSTDESK_VERSION'

function Get-RandomPassword {
    param (
        [Parameter(Mandatory)]
        [int] $length,
        [int] $amountOfNonAlphanumeric = 1
    )
    Add-Type -AssemblyName 'System.Web'
    return [System.Web.Security.Membership]::GeneratePassword($length, $amountOfNonAlphanumeric)
}


# conf file for relay server
$RustDesk2_toml = @"
rendezvous_server = '$relay_server'
nat_type = 1
serial = 0
[options]
custom-rendezvous-server = '$relay_server'
key =  '$relay_key'
"@

If (!(Test-Path $env:AppData\RustDesk\config\RustDesk2.toml)) {
  New-Item $env:AppData\RustDesk\config -ItemType Directory
  New-Item $env:AppData\RustDesk\config\RustDesk2.toml
}
Set-Content $env:AppData\RustDesk\config\RustDesk2.toml $RustDesk2_toml

If (!(Test-Path $env:WinDir\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk2.toml)) {
  New-Item $env:WinDir\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config -ItemType Directory
  New-Item $env:WinDir\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk2.toml
}
Set-Content $env:WinDir\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk2.toml $RustDesk2_toml

# config file for local machine
$Password = Get-RandomPassword 10 0
$RustDesk_toml = @"
password = '$Password'
"@
If (!(Test-Path $env:AppData\RustDesk\config\RustDesk.toml)) {
  New-Item $env:AppData\RustDesk\config\RustDesk.toml
}
Set-Content $env:AppData\RustDesk\config\RustDesk.toml $RustDesk_toml

If (!(Test-Path $env:WinDir\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk.toml)) {
  New-Item $env:WinDir\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk.toml
}
Set-Content $env:WinDir\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk.toml $RustDesk_toml

# install rustdesk
$cred = "$($webusername):$($webpassword)"
$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($cred))
$basicAuthValue = "Basic $encodedCreds"
$Headers = @{
	Authorisation = $basicAuthValue
}

$secpasswd = ConvertTo-SecureString $webpassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($webusername, $secpasswd)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri https://$relay_server/windows/rustdesk-$version-windows_x64.zip -Credential $credential -Outfile rustdesk.zip
Expand-Archive rustdesk.zip
cd rustdesk
Start-Process "rustdesk-$version-putes.exe" -argumentlist "--silent-install" -wait
cd ..
Remove-Item rustdesk -Force -Recurse
Remove-Item rustdesk.zip -Force

# start RustDesk
Start-Process "$env:ProgramFiles\RustDesk\RustDesk.exe"
Start-Sleep 30

$rustdesk_id = (Get-Content $env:AppData\RustDesk\config\RustDesk.toml | Where-Object { $_.Contains("id") })
$rustdesk_id = $rustdesk_id.Split("'")[1]
$rustdesk_pw = (Get-Content $env:AppData\RustDesk\config\RustDesk.toml | Where-Object { $_.Contains("password") })
$rustdesk_pw = $rustdesk_pw.Split("'")[1]

Write-Output("######################################################")
Write-Output("")
Write-Output("  RustDesk-ID:       $rustdesk_id")
Write-Output("  RustDesk-Password: $rustdesk_pw")
Write-Output("")

