#Parameters block for one liners

$adapter_name = "nic1"
$ipaddress = 10.38.8.144 
$subnet = 255.225.255.192
$gateway = 10.38.8.129
$adapter_number = ""
$dnsserver = ""

param
(
[Parameter(position=1)]
[string]$adapternum,
[Parameter(position=2)]
[string]$ipaddress,
[Parameter(position=3)]
[string]$subnet,
[Parameter(position=4)]
[string]$gateway,
[Parameter(position=5)]
[string]$dnsserver,
[Parameter(position=6)]
[switch]$force,
[Parameter(position=7)]
[switch]$list,
[Parameter(position=8)]
[switch]$help
)

If ($help)
{
    Write-Host 
    Write-host "Network Adapter Configurator"
    Write-Host
    Write-host "Change your IP Address, Subnet Mask, Default Gateway or DNS Servers Easy!"
    Write-host
    Write-host "Wizard Mode: Simply type change-net.ps1 and follow the wizard to change your settings."
    Write-host
    Write-host "Powershell one-liner: change-net.ps1 -adapternum x -ipaddress x.x.x.x -subnet x.x.x.x -gateway x.x.x.x -dnsserver x.x.x.x"
    Write-host
    write-host "add -force to the end of any command to skip the confirmation prompt"
    Write-host
    Write-host "change-net.ps1 -list will show a list of available adapters and their adapter number"
    Write-host 
    Write-host "NOTE:CHANGE IPV4 ADDRESSES ONLY"
    Write-host
    Exit
}


cls
function Get-AdaptersWMI
{
#Get Current Network Configs
$wmiadapters = Get-WmiObject win32_networkadapterconfiguration -filter "ipenabled = 'true'"
Write-Output $wmiadapters
}


$wmi = get-adaptersWMI

function get-currentConfigs
{
    #Show Current Network Configs
    Write-Host
    Write-Host "Available Adapters"
    Write-Host "---------------------------------------------------"
    for ($i=0; $i -lt $wmi.length; $i++)
    {
        Write-Host
        Write-host "Adapter Name:(adapter_name)    "$wmi[$i].Description
        Write-host "IP Address:(ip_address)      "$wmi[$i].IPAddress
        Write-host "Default Gateway: (default_gateway) "$wmi[$i].DefaultIPGateway
        Write-Host "Adapter Number: (adapter_number) "$i
        Write-Host
    }
}

If ($list)
{
    get-currentConfigs
    exit
}

function verify-configs
{
#Show and confirm new configs
Write-Host
Write-host "The following settings will be applied to" $wmi[$adapternum].Description
Write-host "New IP Address:"      $ipaddress
Write-host "New Subnet Mask:"     $subnet
Write-host "New Default Gateway:" $gateway
Write-Host "New DNS Server:"      $dnsserver
Write-host
If (!$force)
{
    $areyousure = Read-Host "Are you sure? Y/N"
}
Else
{
    $areyousure = "y"
}
Write-Output $areyousure
}


If (!$adapternum)
{
    get-currentConfigs
    Write-Host
    $adapternum = Read-Host "Enter adapter number to modify"
    Write-host

    #Enter new configs
    $ipaddress = Read-host "New IP Address:"
    $subnet = Read-Host "New Subnet Mask:"
    $gateway = Read-Host "New Default Gateway:"
    $dnsserver = Read-Host "New DNS Server:"
    $confirm = verify-configs
}
Else
{
    get-currentConfigs
    $confirm = verify-configs

}





Function Set-NewConfigs
{
#Set Adapter Configs
    $wmiIPresult = $wmi[$adapternum].EnableStatic("$ipaddress", "$subnet")
    If ($wmiIPresult.ReturnValue -eq "0")
    {
        Write-host "IP Address and Subnet Mask set. WMI Return Value:  " $wmiIPresult.ReturnValue
    }
    Else
    {
        Write-host "IP Address not set. WMI Return Value:   "
    }
    $wmiGWresult = $wmi[$adapternum].SetGateways("$gateway", 1)
    If ($wmiGWresult.ReturnValue -eq "0")
    {
        Write-Host "Default Gateway set. WMI Return Value:   " $wmiGWresult.ReturnValue
    }
    Else
    {
        Write-Host "Default Gateway not set. WMI Return Value:   " $wmiGWresult.ReturnValue
    }
    $wmiDNSresult = $wmi[$adapternum].SetDNSServerSearchOrder("$dnsserver")
    If ($wmiDNSresult.ReturnValue -eq "0")
    {
        Write-Host "DNS Server set. WMI Return Value:   " $wmiDNSresult.ReturnValue
    }
    Else
    {
        Write-Host "DNS Server not set. WMI Return Value:   " $wmiDNSresult.ReturnValue
    }
}

If ($confirm -eq "y")
{
    Set-NewConfigs
}
Else
{
    write-host "No Changes made. Quiting...."
    Exit
}