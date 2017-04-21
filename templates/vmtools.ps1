<#
    Dan Roushey     8/24/2011
   
    Checks the hardware make/model to make sure its a VM.
    Installs VMware Tools, Enables Host Time Sync,
    Disables Windows Time Service, Gets VM UUID, and Restarts computer.
#>

function Reboot-Computer()
{
    #prompt for reboot
    $title = "Reboot System"
    $message = "The system must be rebooted before the change can take effect. Reboot now?"

    $Yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
        "Reboot system now."
    $No = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
        "Reboot system manually."

    $options = [System.Management.Automation.Host.ChoiceDescription[]]($Yes, $No)
    $result = $host.ui.PromptForChoice($title, $message, $options, 1)
    write-host

    switch ($result)
    {
        0 { shutdown -r -t 1 }
        1 { write-host "Please manually reboot machine" }
    }
    Write-Host
}

function Set-TimeSync ()
{
   
    <#
        When using the call operatior (&) it can be tricky when there
        are spaces in the path, or multiple arguments.
        a nice tip (found on the interwebs) is to use an array to hold each argument.
    #>
    $vmservicePath = "C:\Program Files\VMware\VMware Tools\vmwareservice.exe"
    $parameters = "--cmd","`"vmx.set_option synctime 0 1`""
   
    if (Test-Path $vmservicePath)
    {   
        try
        {
            & $vmservicePath $parameters
            write-host "Operation Complete."
        }
        catch
        {
            write-warning "Unable to configure host time sync."
        }
    }
    else
    {
        write-warning "Unable to find vmwareservice.exe. Please Configure Manually."
    }
   
}

function Set-WindowsTimeService ()
{
    $winTimeSvc = Get-Service -name "w32time"
    $winTimeSvc | Stop-Service   
    $winTimeSvc | set-service -StartupType "Disabled"
    Write-Host "Operation Complete." 
}

function Get-OperatingSystem()
{
    $OS = gwmi win32_operatingsystem
   
    return $OS
}

function Test-VirtualMachine()
{
    $computer = Get-WmiObject -Class Win32_computersystem
   
    return ($computer.manufacturer -match "VMware")
}

function Install-VMwareTools()
{
    #relative paths to installers, modify accordingly

    $vmtMsi32 = Get-ChildItem .\VMWareTools | Where-Object {$_.name -match "Vmware Tools.msi"}
    $vmtMsi64 = Get-ChildItem .\VMWareTools | Where-Object {$_.name -match "Vmware Tools64.msi"}
   
    $OS = Get-OperatingSystem
    $vmtInstalled = Test-VMwareTools
    $reboot = $false
   
    if (!$vmtInstalled)
    {
        if ($OS.OSArchitecture -match "64-bit")
        {
            $vmtPath = $vmtMsi64.fullname
        }
        else
        {
            $vmtPath = $vmtMsi32.fullname
        }
       
        #use as one string when using start, use array when using &
        $command = "msiexec.exe"
        $arguments = "/i `"$vmtPath`" /qr /norestart"
       
        if (Test-Path $vmtPath)
        {   
            try
            {
                $process = [diagnostics.process]::start($command, $arguments)
                $process.WaitForExit()
                $reboot = $true
                write-host "Operation Complete."
            }
            catch
            {
                write-warning "Error installing VMwareTools. Please install manually."
            }
        }
        else
        {
            write-warning "Unable to find VMware Tools Installer. Please install manually."
        }
    }
    else
    {
        write-host "VMware Tools is already installed."
    }
    return $reboot
}

function Test-VMwareTools()
{
    $vmtInstall = gwmi "Win32_Product" | Where-Object {$_.Name -match "VMWare Tools"}
   
    return ($vmtInstall -ne $null)
}


Write-Host "==========================="
Write-Host "|  Virtual Machine Setup  |"
Write-Host "==========================="
Write-Host

$virtualMachine = Test-VirtualMachine

if ($virtualMachine)
{
    write-host "Install VMware Tools" -ForegroundColor "white"
    Write-Host "--------------------"
    $reboot = Install-VMwareTools
    Write-Host
   
    write-host "Enable Host Time Sync" -ForegroundColor "white"
    Write-Host "---------------------"
    Set-TimeSync
    Write-Host

    Write-Host "Disable Windows Time Service" -ForegroundColor "white"
    write-host "----------------------------"
    Set-WindowsTimeService
    Write-Host

    if ($reboot) {Reboot-Computer}
}
else
{
    write-warning "This is not a virtual machine."
    write-host "VM setup will be aborted."
}