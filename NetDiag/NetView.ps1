



# Execute this command on the PS windows to enable execution
#   Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

<#
 # INSTRUCTIONS:
    #Summary
    Use this tool to acquire OS and Platform data via PowerShell:

	Set the PS execution policy on target machines as follows:
		Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
	Run the script on each target machines of interest:
        NetView.ps1

        A working directory will be placed on the desktop.
        The script will reap the system data of interest (currently scoped to network and platform)
    
    After script complete a *.zip file will be placed on the desktop.
    Send this file to Microsoft.

    Output is most efficiently viewed with Visual Studio Code or equivalent editor with a navigation panel.
        Unzip the output file
        Open the base directory with Visual Studio Code and review via the Navigation Panel 
#>


function ExecCommandPrivate {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [String] $Command, 
        [parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [String] $Output
    )

    # Mirror Prompt info
    $prompt = $env:username + " @ " + $env:computername + ":"
    Write-Output $prompt | out-file -Encoding ascii -Append $Output

    # Mirror Command to execute
    $cmdMirror = "PS " + (Convert-Path .) + "> " + $Command
    Write-Output $cmdMirror | out-file -Encoding ascii -Append $Output

    # Execute Command and redirect to file.  Useful so users know what to run..
    Invoke-Expression $Command | Out-File -Encoding ascii -Append $Output
} 

function ExecCommandTrusted {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [String] $Command, 
        [parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [String] $Output
    )
    Write-Host -ForegroundColor Cyan "$Command"
    ExecCommandPrivate -Command ($Command) -Output $Output
}

function TestCommand {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [String] $Command
    )

    Try {
        # pre-execution cleanup
        $error.clear()

        # Instrument the validate command for silent output
        #$tmp = "$Command -erroraction 'silentlycontinue' | Out-Null"
        $tmp = "$Command | Out-Null"

        # Redirect all error output to $Null to encompass all possible errors
        #Write-Host $tmp -ForegroundColor Yellow
        Invoke-Expression $tmp 2> $Null
        if ($error -ne $null) {
            throw "Error: $error[0]" 
        }

        # This is only reachable in success case
        Write-Host -ForegroundColor Green "$Command"
        $script:Err = 0
    }Catch {
        Write-Warning "UNSUPPORTED: $Command"
        $script:Err = -1
    }Finally {
        # post-execution cleanup to avoid false positives
        $error.clear()
    }
}

# Powershell cmdlets have inconsistent implementations in command error handling.  This
# function performs a validation of the command prior to formal execution and logs said
# commands in a file suffixed with Not-Supported.txt.
function ExecCommand {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [String] $Command,
        [parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [String] $Output
    )
    
    # Use temp output to reflect the failed command, otherwise execute the command.
    $out = $Output
    TestCommand -Command ($cmd)
    if ($script:Err -ne 0) {
        $out = $out.Replace(".txt",".UNSUPPORTED.txt")
        Write-Output "$Command" | Out-File -Encoding ascii -Append $out
    }else {
        ExecCommandPrivate -Command ($Command) -Output $out
    }
}

function NetAdapterDetail {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true)] [String] $OutDir
    )

    ForEach($nic in Get-NetAdapter) {
        # Create dir for each NIC
        $idx  = $nic.IfIndex
        $name = $nic.Name
        $desc = $nic.InterfaceDescription

        if ((Get-NetAdapter -IfIndex $idx).DriverFileName -eq "vmswitch.sys") {
            $nictype = "hNic"
        } else {
            $nictype = "pNic"
        }
        $title = "$nictype." + $idx + ".$name" + ".$desc"
        $dir   = (Join-Path -Path $OutDir -ChildPath ("$title"))
        New-Item -ItemType directory -Path $dir | Out-Null
        
        Write-Output "Processing: $title"
        Write-Output "----------------------------------------------"

        # Execute command list
        $file = "Get-NetAdapter.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapter -InterfaceIndex $idx | Out-String -Width $columns",
                            "Get-NetAdapter -InterfaceIndex $idx | Format-Table -View Driver -AutoSize | Out-String -Width $columns",
                            "Get-NetAdapter -InterfaceIndex $idx | Format-List  -Property *",
                            "Get-NetAdapter -InterfaceIndex $idx | Format-Table -Property * -AutoSize | Out-String -Width $columns",
                            "Get-NetAdapter | Get-Member"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        # Execute command list
        $file = "Get-NetAdapterAdvancedProperty.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterAdvancedProperty -Name ""$name"" -AllProperties -IncludeHidden | Out-String -Width $columns",
                            "Get-NetAdapterAdvancedProperty -Name ""$name"" -AllProperties -IncludeHidden | Format-List  -Property *",
                            "Get-NetAdapterAdvancedProperty -Name ""$name"" -AllProperties -IncludeHidden | Format-Table -Property * -AutoSize | Out-String -Width $columns",
                            "Get-NetAdapterAdvancedProperty | Get-Member"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        # Execute command list
        $file = "Get-NetAdapterBinding.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterBinding -Name ""$name"" -AllBindings | Out-String -Width $columns",
                            "Get-NetAdapterBinding -Name ""$name"" -AllBindings | Format-List  -Property *",
                            "Get-NetAdapterBinding -Name ""$name"" -AllBindings | Format-Table -Property * -AutoSize | Out-String -Width $columns",
                            "Get-NetAdapterBinding | Get-Member"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        # Execute command list
        $file = "Get-NetAdapterChecksumOffload.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterChecksumOffload -Name ""$name"" | Out-String -Width $columns",
                            "Get-NetAdapterChecksumOffload -Name ""$name"" | Format-List  -Property *",
                            "Get-NetAdapterChecksumOffload -Name ""$name"" | Format-Table -Property * -AutoSize | Out-String -Width $columns",
                            "Get-NetAdapterChecksumOffload | Get-Member"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        # Execute command list - Detect Property
        $file = "Get-NetAdapterLso.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterLso -Name ""$name"" | Out-String -Width $columns",
                            "Get-NetAdapterLso -Name ""$name"" | Format-List  -Property *",
                            "Get-NetAdapterLso -Name ""$name"" | Format-Table -Property * -AutoSize | Out-String -Width $columns",
                            "Get-NetAdapterLso | Get-Member"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        $file = "Get-NetAdapterRss.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterRss -Name ""$name"" | Out-String -Width $columns",
                            "Get-NetAdapterRss -Name ""$name"" | Format-List  -Property *",
                            "Get-NetAdapterRss -Name ""$name"" | Format-Table -Property * -AutoSize | Out-String -Width $columns",
                            "Get-NetAdapterRss | Get-Member"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        #<##### FIXME!!!!! - Detect properties for all below


        $file = "Get-NetAdapterStatistics.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterStatistics -Name ""$name"" | Out-String -Width $columns",
                            "Get-NetAdapterStatistics -Name ""$name"" | Format-List  -Property *",
                            "Get-NetAdapterStatistics -Name ""$name"" | Format-Table -Property * -AutoSize | Out-String -Width $columns",
                            "Get-NetAdapterStatistics | Get-Member"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }   


        # Execute command list
        $file = "Get-NetAdapterEncapsulatedPacketTaskOffload.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterEncapsulatedPacketTaskOffload -Name ""$name"" | Out-String -Width $columns",
                            "Get-NetAdapterEncapsulatedPacketTaskOffload -Name ""$name"" | Format-List  -Property *",
                            "Get-NetAdapterEncapsulatedPacketTaskOffload -Name ""$name"" | Format-Table -Property * -AutoSize | Out-String -Width $columns",
                            "Get-NetAdapterEncapsulatedPacketTaskOffload | Get-Member"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        # Execute command list
        $file = "Get-NetAdapterHardwareInfo.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterHardwareInfo -Name ""$name"" | Out-String -Width $columns",
                            "Get-NetAdapterHardwareInfo -Name ""$name"" | Format-List  -Property *",
                            "Get-NetAdapterHardwareInfo -Name ""$name"" | Format-Table -Property * -AutoSize | Out-String -Width $columns",
                            "Get-NetAdapterHardwareInfo | Get-Member"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        # Execute command list - Detect Property
        $file = "Get-NetAdapterIPsecOffload.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterIPsecOffload -Name ""$name"" | Out-String -Width $columns",
                            "Get-NetAdapterIPsecOffload -Name ""$name"" | Format-List  -Property *",
                            "Get-NetAdapterIPsecOffload -Name ""$name"" | Format-Table -Property * -AutoSize | Out-String -Width $columns",
                            "Get-NetAdapterIPsecOffload | Get-Member"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        # Execute command list - Detect Property
        $file = "Get-NetAdapterPowerManagment.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterPowerManagment -Name ""$name"" | Out-String -Width $columns",
                            "Get-NetAdapterPowerManagment -Name ""$name"" | Format-List  -Property *",
                            "Get-NetAdapterPowerManagment -Name ""$name"" | Format-Table -Property * -AutoSize | Out-String -Width $columns",
                            "Get-NetAdapterPowerManagment | Get-Member"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }
        
        $file = "Get-NetAdapterQos.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterQos -Name ""$name"" | Out-String -Width $columns",
                            "Get-NetAdapterQos -Name ""$name"" | Format-List  -Property *",
                            "Get-NetAdapterQos -Name ""$name"" | Format-Table -Property * -AutoSize | Out-String -Width $columns",
                            "Get-NetAdapterQos | Get-Member"                            
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }
        
        $file = "Get-NetAdapterRdma.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterRdma -Name ""$name"" | Out-String -Width $columns",
                            "Get-NetAdapterRdma -Name ""$name"" | Format-List  -Property *",
                            "Get-NetAdapterRdma -Name ""$name"" | Format-Table -Property * -AutoSize | Out-String -Width $columns",
                            "Get-NetAdapterRdma | Get-Member"                                                        
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        $file = "Get-NetAdapterPacketDirect.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterPacketDirect -Name ""$name"" | Out-String -Width $columns",
                            "Get-NetAdapterPacketDirect -Name ""$name"" | Format-List  -Property *",
                            "Get-NetAdapterPacketDirect -Name ""$name"" | Format-Table -Property * -AutoSize | Out-String -Width $columns",
                            "Get-NetAdapterPacketDirect | Get-Member"                            
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        $file = "Get-NetAdapterRsc.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterRsc -Name ""$name"" | Out-String -Width $columns",
                            "Get-NetAdapterRsc -Name ""$name"" | Format-List  -Property *",
                            "Get-NetAdapterRsc -Name ""$name"" | Format-Table -Property * -AutoSize | Out-String -Width $columns",
                            "Get-NetAdapterRsc | Get-Member" 
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        $file = "Get-NetAdapterSriov.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterSriov -Name ""$name"" | Out-String -Width $columns",
                            "Get-NetAdapterSriov -Name ""$name"" | Format-List  -Property *",
                            "Get-NetAdapterSriov -Name ""$name"" | Format-Table -Property * -AutoSize | Out-String -Width $columns",
                            "Get-NetAdapterSriov | Get-Member" 
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }
        
        $file = "Get-NetAdapterSriovVf.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterSriovVf -Name ""$name"" | Out-String -Width $columns",
                            "Get-NetAdapterSriovVf -Name ""$name"" | Format-List  -Property *",
                            "Get-NetAdapterSriovVf -Name ""$name"" | Format-Table -Property * -AutoSize | Out-String -Width $columns",
                            "Get-NetAdapterSriovVf | Get-Member" 
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        $file = "Get-NetAdapterVmq.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterVmq -Name ""$name"" | Out-String -Width $columns",
                            "Get-NetAdapterVmq -Name ""$name"" | Format-List  -Property *",
                            "Get-NetAdapterVmq -Name ""$name"" | Format-Table -Property * -AutoSize | Out-String -Width $columns",
                            "Get-NetAdapterVmq | Get-Member" 
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        $file = "Get-NetAdapterVmqQueue.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterVmqQueue -Name ""$name"" | Out-String -Width $columns",
                            "Get-NetAdapterVmqQueue -Name ""$name"" | Format-List  -Property *",
                            "Get-NetAdapterVmqQueue -Name ""$name"" | Format-Table -Property * -AutoSize | Out-String -Width $columns",
                            "Get-NetAdapterVmqQueue | Get-Member" 
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        $file = "Get-NetAdapterVPort.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterVPort -Name ""$name"" | Out-String -Width $columns",
                            "Get-NetAdapterVPort -Name ""$name"" | Format-List  -Property *",
                            "Get-NetAdapterVPort -Name ""$name"" | Format-Table -Property * -AutoSize | Out-String -Width $columns",
                            "Get-NetAdapterVPort | Get-Member" 
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }
    }
}

function IPinfo {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true)] [String] $OutDir
    )

    $dir    = (Join-Path -Path $OutDir -ChildPath ("IPInfo"))
    New-Item -ItemType directory -Path $dir | Out-Null

    $file = "ipconfig.txt"
    $out  = (Join-Path -Path $dir -ChildPath $file)
    [String []] $cmds = "ipconfig /all",
                        "ipconfig /allcompartments" 
    ForEach($cmd in $cmds) {
        ExecCommandTrusted -Command ($cmd) -Output $out
    }

    $file = "Get-NetCompartment.txt"
    $out  = (Join-Path -Path $dir -ChildPath $file)
    [String []] $cmds = "Get-NetCompartment",
                        "Get-NetCompartment | Format-List -Property *",
                        "Get-NetCompartment | Format-Table -Property * -AutoSize | Out-String -Width $columns",
                        "Get-NetCompartment | Get-Member"
    ForEach($cmd in $cmds) {
        ExecCommand -Command ($cmd) -Output $out
    }

    $file = "Get-NetIpConfiguration.txt"
    $out  = (Join-Path -Path $dir -ChildPath $file)
    [String []] $cmds = "Get-NetIPConfiguration",
                        "Get-NetIPConfiguration -all",
                        "Get-NetIPConfiguration | Format-List -Property *",
                        "Get-NetIPConfiguration | Format-Table -Property * -AutoSize | Out-String -Width $columns",
                        "Get-NetIPConfiguration | Get-Member"
    ForEach($cmd in $cmds) {
        ExecCommandTrusted -Command ($cmd) -Output $out
    }
    
    $file = "Get-NetIpAddress.txt"
    $out  = (Join-Path -Path $dir -ChildPath $file)
    [String []] $cmds = "Get-NetIPAddress –AddressFamily IPv4",
                        "Get-NetIPAddress –AddressFamily IPv6",
                        "Get-NetIPAddress | Sort-Object -Property InterfaceIndex | Format-Table",
                        "Get-NetIPAddress | Where-Object -FilterScript { $_.ValidLifetime -Lt ([TimeSpan]::FromDays(1)) }",
                        "Get-NetIPAddress | Where-Object -FilterScript { $_.ValidLifetime -Eq ([TimeSpan]::MaxValue) }",
                        "Get-NetIPAddress | Get-Member" 
    ForEach($cmd in $cmds) {
        ExecCommand -Command ($cmd) -Output $out
    }

    $file = "Get-NetIpInterface.txt"
    $out  = (Join-Path -Path $dir -ChildPath $file)
    [String []] $cmds = "Get-NetIPInterface -AddressFamily IPv4",
                        "Get-NetIPInterface -AddressFamily IPv6",
                        "Get-NetIPInterface | Sort-Object –Property InterfaceIndex | Format-Table",
                        "Get-NetIPInterface | Get-Member" 
    ForEach($cmd in $cmds) {
        ExecCommand -Command ($cmd) -Output $out
    }

    $file = "Get-NetIPv4Protocol.txt"
    $out  = (Join-Path -Path $dir -ChildPath $file)
    [String []] $cmds = "Get-NetIPv4Protocol",
                        "Get-NetIPv4Protocol | Format-List –Property *",
                        "Get-NetIPv4Protocol | Get-Member" 
    ForEach($cmd in $cmds) {
        ExecCommand -Command ($cmd) -Output $out
    }

    $file = "Get-NetIPv6Protocol.txt"
    $out  = (Join-Path -Path $dir -ChildPath $file)
    [String []] $cmds = "Get-NetIPv6Protocol",
                        "Get-NetIPv6Protocol | Format-List –Property *",
                        "Get-NetIPv6Protocol | Get-Member" 
    ForEach($cmd in $cmds) {
        ExecCommand -Command ($cmd) -Output $out
    }

    $file = "Get-NetNeighbor.txt"
    $out  = (Join-Path -Path $dir -ChildPath $file)
    [String []] $cmds = "Get-NetNeighbor",
                        "Get-NetNeighbor | Format-List –Property *",
                        "Get-NetNeighbor –AddressFamily IPv4",
                        "Get-NetNeighbor –AddressFamily IPv6",
                        "Get-NetNeighbor –State Reachable | Get-NetAdapter",
                        "Get-NetNeighbor | Get-Member" 
    ForEach($cmd in $cmds) {
        ExecCommand -Command ($cmd) -Output $out
    }

    $file = "Get-NetOffloadGlobalSetting.txt"
    $out  = (Join-Path -Path $dir -ChildPath $file)
    [String []] $cmds = "Get-NetOffloadGlobalSetting",
                        "Get-NetOffloadGlobalSetting | Get-Member" 
    ForEach($cmd in $cmds) {
        ExecCommand -Command ($cmd) -Output $out
    }
}

function NetAdapterSummary {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true)] [String] $OutDir
    )

    $file = "Summary.txt"
    $out  = (Join-Path -Path $OutDir -ChildPath $file)

    # Build the command list
    [String []] $cmds = "Get-NetAdapter",
                        "Get-VMSwitch",
                        "Get-VMNetworkAdapter *"
                        "net statistics workstation"
    # Execute each command
    ForEach($cmd in $cmds) {
        ExecCommandTrusted -Command ($cmd) -Output $out
    }
}

function VMSwitchDetail {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true)] [String] $OutDir
    )

    ForEach($switch in Get-VMSwitch) {
        # Create dir for each Switch
        $name = $switch.Name
        $type = $switch.SwitchType
 
        $dir  = (Join-Path -Path $OutDir -ChildPath ("vms.$type.$name"))
        New-Item -ItemType directory -Path $dir | Out-Null
        
        Write-Output "Processing: $name"
        Write-Output "----------------------------------------------"      

        # Execute command list
        $file = "Get-VMSwitch.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-VMSwitch -Name ""$name""",
                            "Get-VMSwitch -Name ""$name"" | Format-List  -Property *",
                            "Get-VMSwitch -Name ""$name"" | Format-Table -Property * -AutoSize | Out-String -Width $columns",
                            "Get-VMSwitch -Name ""$name"" | Get-Member"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        # Execute command list
        $file = "Get-VMSwitchExtension.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-VMSwitch -Name ""$name"" | Get-VMSwitchExtension | Format-List  -Property *",
                            "Get-VMSwitch -Name ""$name"" | Get-VMSwitchExtension | Format-Table -Property * -AutoSize | Out-String -Width $columns",
                            "Get-VMSwitch -Name ""$name"" | Get-VMSwitchExtension | Get-Member"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

                
        <#
        #Get-VMSwitchExtensionPortData -ComputerName $env:computername *
        # Execute command list
        $file = "Get-VMSwitchExtensionPortData.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-VMSwitchExtensionPortData -SwitchName $name | Format-List  -Property *",
                            "Get-VMSwitchExtensionPortData -SwitchName $name | Format-Table -Property * -AutoSize | Out-String -Width $columns",
                            "Get-VMSwitchExtensionPortData -SwitchName $name | Get-Member"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }
        #>
        
        
        # Iterate through all ports in a vSwitch and dump command output
        # Execute command list
        $file = "Get-VMSwitchExtensionSwitchData.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-VMSwitchExtensionSwitchData -SwitchName $name | Format-List  -Property *",
                            "Get-VMSwitchExtensionSwitchData -SwitchName $name | Format-Table -Property * -AutoSize | Out-String -Width $columns",
                            "Get-VMSwitchExtensionSwitchData -SwitchName $name | Get-Member"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }
        

        # Execute command list
        $file = "Get-VMSwitchExtensionSwitchFeature.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-VMSwitchExtensionSwitchFeature -SwitchName $name | Format-Table -Property *",
                            "Get-VMSwitchExtensionSwitchFeature -SwitchName $name | Format-List  -Property *"
                            #"Get-VMSwitchExtensionSwitchFeature -SwitchName $name | Get-Member"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        
        # Execute command list
        $file = "Get-VMSwitchTeam.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-VMSwitchTeam -SwitchName $name | Format-Table -Property *",
                            "Get-VMSwitchTeam -SwitchName $name | Format-List  -Property *",
                            "Get-VMSwitchTeam -SwitchName $name | Get-Member"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }
        

        # Execute command list
        $file = "Get-VMSystemSwitchExtension.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-VMSystemSwitchExtension | Format-Table -Property *",
                            "Get-VMSystemSwitchExtension | Format-List  -Property *",
                            "Get-VMSystemSwitchExtension | Get-Member"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        # Execute command list
        $file = "Get-VMSwitchExtensionPortFeature.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-VMSwitchExtensionPortFeature * | Format-Table -Property *",
                            "Get-VMSwitchExtensionPortFeature * | Format-List  -Property *",
                            "Get-VMSwitchExtensionPortFeature * | Get-Member"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        # Execute command list
        $file = "Get-VMSystemSwitchExtensionSwitchFeature.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-VMSystemSwitchExtensionSwitchFeature",
                            "Get-VMSystemSwitchExtensionSwitchFeature | Format-List  -Property *",
                            "Get-VMSystemSwitchExtensionSwitchFeature | Format-Table -Property * -AutoSize | Out-String -Width $columns",
                            "Get-VMSystemSwitchExtensionSwitchFeature | Get-Member"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }
    }
}

function VMSwitchSummary {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true)] [String] $OutDir
    )
    
    ##See this command to get VFs on vSwitch
    #Get-NetAdapterSriovVf -SwitchId 2

    $file = "VMSwitch.txt"
    $out  = (Join-Path -Path $OutDir -ChildPath $file)

    # Build the command list
    [String []] $cmds = "Get-VMSwitch"

    # Execute each command
    ForEach($cmd in $cmds) {
        ExecCommand -Command $cmd -Output $out
    }
}

function VMNetworkAdapterSummary {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true)] [String] $OutDir
    )

    $file = "VMNetworkAdapterSummary.txt"
    $out  = (Join-Path -Path $OutDir -ChildPath $file)
    [String []] $cmds = "Get-VMNetworkAdapter -All",
                        "Get-VMNetworkAdapter -All | Format-List  -Property *",
                        "Get-VMNetworkAdapter -All | Format-Table -Property * -AutoSize | Out-String -Width $columns",
                        "Get-VMNetworkAdapter * | Get-Member"
    ForEach($cmd in $cmds) {
        ExecCommand -Command $cmd -Output $out
    }
}

function VMNetworkAdapterDetail {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true)] [String] $OutDir
    )

    ForEach($vm in Get-VM) {
        $vmname = $vm.name
        $dir    = (Join-Path -Path $OutDir -ChildPath ("VM.$vmname"))
        New-Item -ItemType directory -Path $dir | Out-Null
          
        Write-Output "Processing: VM.$vmname.$nicname"
        Write-Output "--------------------------------------"

        # Execute command list
        $file = "Get-VMNetworkAdapterAcl.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-VMNetworkAdapterAcl -VMName $vmname | Out-String -Width $columns",
                            "Get-VMNetworkAdapterAcl -VMName $vmname | Format-List  -Property *",
                            "Get-VMNetworkAdapterAcl -VMName $vmname | Format-Table -Property * -AutoSize | Out-String -Width $columns",
                            "Get-VMNetworkAdapterAcl | Get-Member"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        # Execute command list
        $file = "Get-VMNetworkAdapterExtendedAcl.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-VMNetworkAdapterExtendedAcl -VMName $vmname | Out-String -Width $columns",
                            "Get-VMNetworkAdapterExtendedAcl -VMName $vmname | Format-List  -Property *",
                            "Get-VMNetworkAdapterExtendedAcl -VMName $vmname | Format-Table -Property * -AutoSize | Out-String -Width $columns",
                            "Get-VMNetworkAdapterExtendedAcl | Get-Member"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        # Execute command list
        $file = "Get-VMNetworkAdapterFailoverConfiguration.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-VMNetworkAdapterFailoverConfiguration -VMName $vmname | Out-String -Width $columns",
                            "Get-VMNetworkAdapterFailoverConfiguration -VMName $vmname | Format-List  -Property *",
                            "Get-VMNetworkAdapterFailoverConfiguration -VMName $vmname | Format-Table -Property * -AutoSize | Out-String -Width $columns",
                            "Get-VMNetworkAdapterFailoverConfiguration -VMName * | Get-Member"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        # Execute command list
        $file = "Get-VMNetworkAdapterIsolation.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-VMNetworkAdapterIsolation -VMName $vmname | Out-String -Width $columns",
                            "Get-VMNetworkAdapterIsolation -VMName $vmname | Format-List  -Property *",
                            "Get-VMNetworkAdapterIsolation -VMName $vmname | Format-Table -Property * -AutoSize | Out-String -Width $columns",
                            "Get-VMNetworkAdapterIsolation | Get-Member"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        # Execute command list
        $file = "Get-VMNetworkAdapterRoutingDomainMapping.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-VMNetworkAdapterRoutingDomainMapping -VMName $vmname | Out-String -Width $columns",
                            "Get-VMNetworkAdapterRoutingDomainMapping -VMName $vmname | Format-List  -Property *",
                            "Get-VMNetworkAdapterRoutingDomainMapping -VMName $vmname | Format-Table -Property * -AutoSize | Out-String -Width $columns",
                            "Get-VMNetworkAdapterRoutingDomainMapping | Get-Member"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        # Execute command list
        $file = "Get-VMNetworkAdapterTeamMapping.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-VMNetworkAdapterTeamMapping -VMName $vmname | Out-String -Width $columns",
                            "Get-VMNetworkAdapterTeamMapping -VMName $vmname | Format-List  -Property *",
                            "Get-VMNetworkAdapterTeamMapping -VMName $vmname | Format-Table -Property * -AutoSize | Out-String -Width $columns",
                            "Get-VMNetworkAdapterTeamMapping -VMName * | Get-Member"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        # Execute command list
        $file = "Get-VMNetworkAdapterVlan.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-VMNetworkAdapterVlan -VMName $vmname | Out-String -Width $columns",
                            "Get-VMNetworkAdapterVlan -VMName $vmname | Format-List  -Property *",
                            "Get-VMNetworkAdapterVlan -VMName $vmname | Format-Table -Property * -AutoSize | Out-String -Width $columns",
                            "Get-VMNetworkAdapterVlan | Get-Member"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }
    }
}

function VMSummary {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true)] [String] $OutDir
    )

    $file = "VM.txt"
    $out  = (Join-Path -Path $OutDir -ChildPath $file)

    # Build the command list
    [String []] $cmds = "Get-VM",
                        "Get-VM | Format-List  -Property *",
                        "Get-VM | Format-Table -Property * -AutoSize | Out-String -Width $columns",
                        "Get-VM | Get-Member"
    ForEach($cmd in $cmds) {
        ExecCommand -Command $cmd -Output $out
    }
}


function LbfoSummary {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true)] [String] $OutDir
    )

    $file = "LBFO.txt"
    $out  = (Join-Path -Path $OutDir -ChildPath $file)

    # Build the command list
    [String []] $cmds = "Get-NetLbfoTeam –Name *",
                        "Get-NetLbfoTeam –Name * | Format-List  -Property *",
                        "Get-NetLbfoTeam –Name * | Format-Table -Property * -AutoSize | Out-String -Width $columns",
                        "Get-NetLbfoTeam | Get-Member"
    ForEach($cmd in $cmds) {
        ExecCommand -Command $cmd -Output $out
    }
}

function LbfoDetail {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true)] [String] $OutDir
    )

    #To Do....
    #Get-NetLbfoTeam
    #Get-NetLbfoTeamMember
    #Get-NetLbfoTeamNic   
    #Get-VMSwitchTeam
    #Get-VMSwitch | fl NetAdapterDescriptions
}

function QosDetail {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true)] [String] $OutDir
    )

    $dir    = (Join-Path -Path $OutDir -ChildPath ("NetQoS"))
    New-Item -ItemType directory -Path $dir | Out-Null

    $file = "Get-NetQosDcbxSetting.txt"
    $out  = (Join-Path -Path $dir -ChildPath $file)
    [String []] $cmds = "Get-NetQosDcbxSetting",
                        "Get-NetQosDcbxSetting | Format-List  -Property *",
                        "Get-NetQosDcbxSetting | Format-Table -Property *  -AutoSize | Out-String -Width $columns",
                        "Get-NetQosDcbxSetting | Get-Member"
    ForEach($cmd in $cmds) {
        ExecCommand -Command $cmd -Output $out
    }

    $file = "Get-NetQosFlowControl.txt"
    $out  = (Join-Path -Path $dir -ChildPath $file)
    [String []] $cmds = "Get-NetQosFlowControl",
                        "Get-NetQosFlowControl | Format-List  -Property *",
                        "Get-NetQosFlowControl | Format-Table -Property *  -AutoSize | Out-String -Width $columns",
                        "Get-NetQosFlowControl | Get-Member"
    ForEach($cmd in $cmds) {
        ExecCommand -Command $cmd -Output $out
    }

    $file = "Get-NetQosPolicy.txt"
    $out  = (Join-Path -Path $dir -ChildPath $file)
    [String []] $cmds = "Get-NetQosPolicy",
                        "Get-NetQosPolicy | Format-List  -Property *",
                        "Get-NetQosPolicy | Format-Table -Property *  -AutoSize | Out-String -Width $columns",
                        "Get-NetQosPolicy | Get-Member"
    ForEach($cmd in $cmds) {
        ExecCommand -Command $cmd -Output $out
    }

    $file = "Get-NetQosTrafficClass.txt"
    $out  = (Join-Path -Path $dir -ChildPath $file)
    [String []] $cmds = "Get-NetQosTrafficClass",
                        "Get-NetQosTrafficClass | Format-List  -Property *",
                        "Get-NetQosTrafficClass | Format-Table -Property *  -AutoSize | Out-String -Width $columns",
                        "Get-NetQosTrafficClass | Get-Member"
    ForEach($cmd in $cmds) {
        ExecCommand -Command $cmd -Output $out
    }
}

function SMBDetail {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true)] [String] $OutDir
    )

    $dir    = (Join-Path -Path $OutDir -ChildPath ("SMB"))
    New-Item -ItemType directory -Path $dir | Out-Null
    
    $file = "Get-SmbClientNetworkInterface.txt"
    $out  = (Join-Path -Path $dir -ChildPath $file)
    [String []] $cmds = "Get-SmbClientNetworkInterface",
                        "Get-SmbClientNetworkInterface | Format-List  -Property *",
                        "Get-SmbClientNetworkInterface | Format-Table -Property * -AutoSize | Out-String -Width $columns",
                        "Get-SmbClientNetworkInterface | Get-Member"
    ForEach($cmd in $cmds) {
        ExecCommand -Command $cmd -Output $out
    }        
}

function PerfCounters {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true)] [String] $OutDir
    )

    $dir    = (Join-Path -Path $OutDir -ChildPath ("PerfMon"))
    New-Item -ItemType directory -Path $dir | Out-Null
    
    $make = "VmSwitch"
    $file = "PerfCounter_$make.txt"
    $out  = (Join-Path -Path $dir -ChildPath $file)
    $cmd  = "Get-Counter -Counter (Get-Counter -ListSet *'Hyper-V Virtual Switch'*).paths -ErrorAction SilentlyContinue | Format-List -Property *"
    ExecCommand -Command ($cmd) -Output $out

    $make = "hNIC"
    $file = "PerfCounter_$make.txt"
    $out  = (Join-Path -Path $dir -ChildPath $file)
    $cmd  = "Get-Counter -Counter (Get-Counter -ListSet *'Hyper-V Virtual Network'*).paths -ErrorAction SilentlyContinue | Format-List -Property *"
    ExecCommand -Command ($cmd) -Output $out

    $make = "Mellanox"
    $file = "PerfCounter_$make.txt"
    $out  = (Join-Path -Path $dir -ChildPath $file)
    $cmd  = "Get-Counter -Counter (Get-Counter -ListSet *Mellanox*).paths -ErrorAction SilentlyContinue | Format-List -Property *"
    ExecCommandTrusted -Command ($cmd) -Output $out

    $make = "Intel"
    $file = "PerfCounter_$make.txt"
    $out  = (Join-Path -Path $dir -ChildPath $file)
    $cmd  = "Get-Counter -Counter (Get-Counter -ListSet *Intel*).paths -ErrorAction SilentlyContinue | Format-List -Property *"
    ExecCommand -Command ($cmd) -Output $out

    $make = "Chelsio"
    $file = "PerfCounter_$make.txt"
    $out  = (Join-Path -Path $dir -ChildPath $file)
    $cmd  = "Get-Counter -Counter (Get-Counter -ListSet *Chelsio*).paths -ErrorAction SilentlyContinue | Format-List -Property *"
    ExecCommand -Command ($cmd) -Output $out

    $make = "Qlogic"
    $file = "PerfCounter_$make.txt"
    $out  = (Join-Path -Path $dir -ChildPath $file)
    $cmd  = "Get-Counter -Counter (Get-Counter -ListSet *Qlogic*).paths -ErrorAction SilentlyContinue | Format-List -Property *"
    ExecCommand -Command ($cmd) -Output $out

    $make = "Broadcom"
    $file = "PerfCounter_$make.txt"
    $out  = (Join-Path -Path $dir -ChildPath $file)
    $cmd  = "Get-Counter -Counter (Get-Counter -ListSet *Broadcom*).paths -ErrorAction SilentlyContinue | Format-List -Property *"
    ExecCommand -Command ($cmd) -Output $out

    $make = "Emulex"
    $file = "PerfCounter_$make.txt"
    $out  = (Join-Path -Path $dir -ChildPath $file)
    $cmd  = "Get-Counter -Counter (Get-Counter -ListSet *Emulex*).paths -ErrorAction SilentlyContinue | Format-List -Property *"
    ExecCommand -Command ($cmd) -Output $out
}

function Environment {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true)] [String] $OutDir
    )

    $file = "Environment.txt"
    $out  = (Join-Path -Path $OutDir -ChildPath $file)
    [String []] $cmds = "Get-ItemProperty -Path ""HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion""",
                        "date",
                        #"Get-WinEvent -ProviderName eventlog | Where-Object {$_.Id -eq 6005 -or $_.Id -eq 6006}",
                        "wmic os get lastbootuptime",
                        "systeminfo"
    ForEach($cmd in $cmds) {
        ExecCommand -Command ($cmd) -Output $out
    }
}

function EnvDestroy {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true)] [String] $OutDir
    )
    If (Test-Path $OutDir) {
        Remove-Item $OutDir -Recurse
    }
}

function EnvCreate {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true)] [String] $OutDir
    )
    New-Item -ItemType directory -Path $OutDir | Out-Null
}


function CreateZip {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true)] [String] $Src,
        [parameter(Mandatory=$true)] [String] $Dest,
        [parameter(Mandatory=$true)] [String] $ZipName
    )

    $timestamp = $(get-date -f yyyy.MM.dd_hh.mm.ss)
    $out       = "$Dest" + "$ZipName" + "-$timestamp" + ".zip"

    If(Test-path $out) {
        Remove-item $out
    }

    add-Type -assembly "system.io.compression.filesystem"
    [io.compression.zipfile]::CreateFromDirectory($Src, $out)
}


function Worker {
    clear
    $columns = 4096

    $user        = [Environment]::UserName
    $workDirName = "msdbg." + $env:computername
    $baseDir     = "C:\Users\$user\Desktop\"
    $workDir     = "$baseDir" + "$workDirName"

    EnvDestroy -OutDir $workDir
    EnvCreate  -OutDir $workDir
    
    # Add try catch logic for inconsistent PS cmdlets implementation on -Named inputs
    # https://www.leaseweb.com/labs/2014/01/print-full-exception-powershell-trycatch-block-using-format-list/

    Environment       -OutDir $workDir
    PerfCounters      -OutDir $workDir

    NetAdapterSummary -OutDir $workDir
    NetAdapterDetail  -OutDir $workDir

    QosDetail         -OutDir $workDir
    SMBDetail         -OutDir $workDir

    VMSummary         -OutDir $workDir

    VMSwitchSummary   -OutDir $workDir
    VMSwitchDetail    -OutDir $workDir  

    VMNetworkAdapterSummary -OutDir $workDir
    VMNetworkAdapterDetail  -OutDir $workDir

    LbfoSummary  -OutDir $workDir
    LbfoDetail   -OutDir $workDir
    
    IPinfo -OutDir $workDir

    #samples
    #https://github.com/Microsoft/SDN/blob/master/SDNExpress/scripts/SDNExpress.ps1
    #https://learn-powershell.net/2014/02/04/using-powershell-parameter-validation-to-make-your-day-easier/
    #http://www.powershellmagazine.com/2013/12/09/secure-parameter-validation-in-powershell/
    #https://msdn.microsoft.com/en-us/library/dd878340(v=vs.85).aspx

    CreateZip -Src $workDir -Dest $baseDir -ZipName $workDirName
}

function Main {
    # If it moves, measure it.  We should know how long this takes...
    Measure-Command { Worker }
}

Main #Entry Point


