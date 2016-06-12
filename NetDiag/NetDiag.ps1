
# Execute this command on the PS windows to enable execution
#Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process




function ExecCommand {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true)] [String] $Command, 
        [parameter(Mandatory=$true)] [String] $Output
    )

    #Write-Output "Command = $Command " 
    #Write-Output "Output  = $Output "

    # Mirror Prompt info
    $prompt = $env:username + " @ " + $env:computername + ":"
    Write-Output $prompt | out-file -Encoding ascii -Append $Output

    # Mirror Command to execute
    $cmdMirror = "PS " + (Convert-Path .) + "> " + $Command
    Write-Output $cmdMirror | out-file -Encoding ascii -Append $Output

    # Execute Command and redirect to file.  Useful so users know what to run..
    #Invoke-Expression $Command | Out-File -Encoding ascii -Append $Output
    
    #Invoke-Expression $Command | Tee-Object -file $Output
    Invoke-Expression $Command | Out-File -Encoding ascii -Append $Output
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

        if ((Get-NetAdapter -IfIndex $idx).DriverFileName -eq "vmswitch.sys") {
            $nictype = "hNic"
        } else {
            $nictype = "pNic"
        }
        $dir  = (Join-Path -Path $OutDir -ChildPath ("$nictype." + $idx + ".$name"))
        New-Item -ItemType directory -Path $dir | Out-Null
        
        # Execute command list
        $file = "Get-NetAdapter.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapter -InterfaceIndex $idx",
                            "Get-NetAdapter -InterfaceIndex $idx | Format-List",
                            "Get-NetAdapter -InterfaceIndex $idx | Format-Table -View Driver",
                            "Get-NetAdapter -InterfaceIndex $idx | Format-List *"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        # Execute command list
        $file = "Get-NetAdapterAdvancedProperty.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterAdvancedProperty -Name ""$name"" -AllProperties -IncludeHidden",
                            "Get-NetAdapterAdvancedProperty -Name ""$name"" | Format-List",
                            "Get-NetAdapterAdvancedProperty -Name ""$name"" | Format-List *"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        # Execute command list
        $file = "Get-NetAdapterBinding.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterBinding -Name ""$name"" -AllBindings",
                            "Get-NetAdapterBinding -Name ""$name"" | Format-List",
                            "Get-NetAdapterBinding -Name ""$name"" | Format-List *"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        # Execute command list
        $file = "Get-NetAdapterChecksumOffload.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterChecksumOffload -Name ""$name""",
                            "Get-NetAdapterChecksumOffload -Name ""$name"" | Format-List",
                            "Get-NetAdapterChecksumOffload -Name ""$name"" | Format-List *"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        # Execute command list - Detect Property
        $file = "Get-NetAdapterLso.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterLso -Name ""$name""",
                            "Get-NetAdapterLso -Name ""$name"" | Format-List",
                            "Get-NetAdapterLso -Name ""$name"" | Format-List *"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        $file = "Get-NetAdapterRss.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterRss -Name ""$name""",
                            "Get-NetAdapterRss -Name ""$name"" | Format-List",
                            "Get-NetAdapterRss -Name ""$name"" | Format-List *"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        #<##### FIXME!!!!! - Detect properties for all below


        $file = "Get-NetAdapterStatistics.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterStatistics -Name ""$name""",
                            "Get-NetAdapterStatistics -Name ""$name"" | Format-List",
                            "Get-NetAdapterStatistics -Name ""$name"" | Format-List *"

        [String []] $cmds = "Get-NetAdapterStatistics -Name ""$name"""
        ForEach($cmd in $cmds) {
            try {
                ExecCommand -Command ($cmd) -Output $out
            }
            catch [Exception] {
                #Write-Host -ForegroundColor Red "Caught an exception while dealing with VlanID, please reset it back to original settings manually"
                #Write-Host -ForegroundColor Red "Error Message:" $_.Exception.Message
                #Write-Host -ForegroundColor Red "Failed Item:" $_.Exception.ItemName
                Write-Host "Hello world"
                echo $_.Exception.GetType().FullName, $_.Exception.Message
            }
        }

        <#    

        # Execute command list
        $file = "Get-NetAdapterEncapsulatedPacketTaskOffload.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterEncapsulatedPacketTaskOffload -Name ""$name""",
                            "Get-NetAdapterEncapsulatedPacketTaskOffload -Name ""$name"" | Format-List ",
                            "Get-NetAdapterEncapsulatedPacketTaskOffload -Name ""$name"" | Format-List * "
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }
        
        # Execute command list
        $file = "Get-NetAdapterHardwareInfo.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterHardwareInfo -Name ""$name""",
                            "Get-NetAdapterHardwareInfo -Name ""$name"" | Format-List",
                            "Get-NetAdapterHardwareInfo -Name ""$name"" | Format-List *"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        # Execute command list - Detect Property
        $file = "Get-NetAdapterIPsecOffload.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterIPsecOffload -Name ""$name""",
                            "Get-NetAdapterIPsecOffload -Name ""$name"" | Format-List",
                            "Get-NetAdapterIPsecOffload -Name ""$name"" | Format-List *"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        # Execute command list - Detect Property
        $file = "Get-NetAdapterPowerManagment.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterPowerManagment -Name ""$name""",
                            "Get-NetAdapterPowerManagment -Name ""$name"" | Format-List",
                            "Get-NetAdapterPowerManagment -Name ""$name"" | Format-List *"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }
        
        $file = "Get-NetAdapterQos.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterQos -Name ""$name""",
                            "Get-NetAdapterQos -Name ""$name"" | Format-List",
                            "Get-NetAdapterQos -Name ""$name"" | Format-List *"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }
        
        $file = "Get-NetAdapterRdma.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterRdma -Name ""$name""",
                            "Get-NetAdapterRdma -Name ""$name"" | Format-List",
                            "Get-NetAdapterRdma -Name ""$name"" | Format-List *"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        $file = "Get-NetAdapterRsc.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterRsc -Name ""$name""",
                            "Get-NetAdapterRsc -Name ""$name"" | Format-List",
                            "Get-NetAdapterRsc -Name ""$name"" | Format-List *"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        $file = "Get-NetAdapterSriov.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterSriov -Name ""$name""",
                            "Get-NetAdapterSriov -Name ""$name"" | Format-List",
                            "Get-NetAdapterSriov -Name ""$name"" | Format-List *"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }
        
        $file = "Get-NetAdapterSriovVf.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterSriovVf -Name ""$name""",
                            "Get-NetAdapterSriovVf -Name ""$name"" | Format-List",
                            "Get-NetAdapterSriovVf -Name ""$name"" | Format-List *"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        $file = "Get-NetAdapterVmq.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterVmq -Name ""$name""",
                            "Get-NetAdapterVmq -Name ""$name"" | Format-List",
                            "Get-NetAdapterVmq -Name ""$name"" | Format-List *"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        $file = "Get-NetAdapterVmqQueue.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterVmqQueue -Name ""$name""",
                            "Get-NetAdapterVmqQueue -Name ""$name"" | Format-List",
                            "Get-NetAdapterVmqQueue -Name ""$name"" | Format-List *"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        $file = "Get-NetAdapterVPort.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterVPort -Name ""$name""",
                            "Get-NetAdapterVPort -Name ""$name"" | Format-List",
                            "Get-NetAdapterVPort -Name ""$name"" | Format-List *"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }
        #>
    }
}

function NetAdapterSummary {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true)] [String] $OutDir
    )

    $file = "NetAdapter.txt"
    $out  = (Join-Path -Path $OutDir -ChildPath $file)

    # Build the command list
    [String []] $cmds = "Get-NetIPConfiguration",
                        "Get-NetAdapter",
                        "Get-VMSwitch",
                        "Get-VMNetworkAdapter *"
    # Execute each command
    ForEach($cmd in $cmds) {
        ExecCommand -Command $cmd -Output $out
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
        
        # Execute command list
        $file = "Get-VMSwitch.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-VMSwitch -Name $name",
                            "Get-VMSwitch -Name $name | Format-Table -Property *",
                            "Get-VMSwitch -Name $name | Format-List  -Property *",
                            "Get-VMSwitch -Name $name | Get-Member"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        # Execute command list
        $file = "Get-VMSwitchExtension.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-VMSwitch -Name $name | Get-VMSwitchExtension | Format-Table -Property *",
                            "Get-VMSwitch -Name $name | Get-VMSwitchExtension | Format-List  -Property *",
                            "Get-VMSwitch -Name $name | Get-VMSwitchExtension | Get-Member"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        <#
        # Execute command list
        $file = "Get-VMSwitchExtensionPortData.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-VMSwitchExtensionPortData * | Format-Table -Property *",
                            "Get-VMSwitchExtensionPortData * | Format-List  -Property *",
                            "Get-VMSwitchExtensionPortData * | Get-Member"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }
        #>

        # Execute command list
        $file = "Get-VMSwitchExtensionSwitchData.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-VMSwitchExtensionSwitchData -SwitchName $name | Format-Table -Property *",
                            "Get-VMSwitchExtensionSwitchData -SwitchName $name | Format-List  -Property *",
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

        <#
        # Execute command list
        $file = "Get-VMSwitchTeam.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-VMSwitchTeam -SwitchName $name | Format-Table -Property *",
                            "Get-VMSwitchTeam -SwitchName $name | Format-List  -Property *",
                            "Get-VMSwitchTeam -SwitchName $name | Get-Member"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }
        #>

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
        [String []] $cmds = "Get-VMSystemSwitchExtensionSwitchFeature | Format-Table -Property *",
                            "Get-VMSystemSwitchExtensionSwitchFeature | Format-List  -Property *",
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

function PerfCounters {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true)] [String] $OutDir
    )

    [String []] $names = "Hyper-V",
                         "Intel",
                         "Mellanox",
                         "Chelsio"
    ForEach($make in $names) {
        $file = "PerfCounter_$make.txt"
        $out  = (Join-Path -Path $OutDir -ChildPath $file)
        $cmd  = "Get-Counter -Counter (Get-Counter -ListSet *$make*).paths -ErrorAction SilentlyContinue | Format-List -Property *"
        ExecCommand -Command ($cmd) -Output $out
    }
}

<#
function Environment {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true)] [String] $OutDir
    )

    $file = "Environment.txt"
    $out  = (Join-Path -Path $dir -ChildPath $file)
    [String []] $cmds = "Get-ItemProperty -Path ""HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"""
    ForEach($cmd in $cmds) {
        ExecCommand -Command ($cmd) -Output $out
    }
}
#>

function Main {
    $baseDir="C:\Users\LocalAdminUser\Desktop\Test\"

    EnvDestroy -OutDir $baseDir
    EnvCreate  -OutDir $baseDir


    # Add try catch logic for inconsistent PS cmdlets implementation on -Named inputs
    # https://www.leaseweb.com/labs/2014/01/print-full-exception-powershell-trycatch-block-using-format-list/

    #Environment  -OutDir $baseDir
    #PerfCounters -OutDir $baseDir

    #NetAdapterSummary -OutDir $baseDir
    NetAdapterDetail  -OutDir $baseDir
    
    #VMSwitchSummary -OutDir $baseDir
    #VMSwitchDetail  -OutDir $baseDir
    #https://technet.microsoft.com/en-us/library/hh848499.aspx

    #VMNetworkAdapterSummary
    #VMNetworkAdapterDetail
    #https://technet.microsoft.com/en-us/library/hh848516.aspx

    #VMNetworkAdapterVlanSummary
    #VMNetworkAdapterVlanDetail
    #https://technet.microsoft.com/en-us/library/hh848516.aspx

    #samples
    #https://github.com/Microsoft/SDN/blob/master/SDNExpress/scripts/SDNExpress.ps1

    
}

Main #Entry Point
