
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
        [String []] $cmds = "Get-NetAdapter -InterfaceIndex $idx | Out-String -Width $columns",
                            "Get-NetAdapter -InterfaceIndex $idx | Format-Table -View Driver -AutoSize | Out-String -Width $columns",
                            "Get-NetAdapter -InterfaceIndex $idx | Format-List  -Property *",
                            "Get-NetAdapter -InterfaceIndex $idx | Format-Table -Property * -AutoSize | Out-String -Width $columns"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        # Execute command list
        $file = "Get-NetAdapterAdvancedProperty.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterAdvancedProperty -Name ""$name"" -AllProperties -IncludeHidden | Out-String -Width $columns",
                            "Get-NetAdapterAdvancedProperty -Name ""$name"" -AllProperties -IncludeHidden | Format-List  -Property *",
                            "Get-NetAdapterAdvancedProperty -Name ""$name"" -AllProperties -IncludeHidden | Format-Table -Property * -AutoSize | Out-String -Width $columns"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        # Execute command list
        $file = "Get-NetAdapterBinding.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterBinding -Name ""$name"" -AllBindings | Out-String -Width $columns",
                            "Get-NetAdapterBinding -Name ""$name"" -AllBindings | Format-List  -Property *",
                            "Get-NetAdapterBinding -Name ""$name"" -AllBindings | Format-Table -Property * -AutoSize | Out-String -Width $columns"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        # Execute command list
        $file = "Get-NetAdapterChecksumOffload.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterChecksumOffload -Name ""$name"" | Out-String -Width $columns",
                            "Get-NetAdapterChecksumOffload -Name ""$name"" | Format-List  -Property *",
                            "Get-NetAdapterChecksumOffload -Name ""$name"" | Format-Table -Property * -AutoSize | Out-String -Width $columns"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        # Execute command list - Detect Property
        $file = "Get-NetAdapterLso.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterLso -Name ""$name"" | Out-String -Width $columns",
                            "Get-NetAdapterLso -Name ""$name"" | Format-List  -Property *",
                            "Get-NetAdapterLso -Name ""$name"" | Format-Table -Property * -AutoSize | Out-String -Width $columns"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        $file = "Get-NetAdapterRss.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterRss -Name ""$name"" | Out-String -Width $columns",
                            "Get-NetAdapterRss -Name ""$name"" | Format-List  -Property *",
                            "Get-NetAdapterRss -Name ""$name"" | Format-Table -Property * -AutoSize | Out-String -Width $columns"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        #<##### FIXME!!!!! - Detect properties for all below


        $file = "Get-NetAdapterStatistics.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterStatistics -Name ""$name"" | Out-String -Width $columns",
                            "Get-NetAdapterStatistics -Name ""$name"" | Format-List  -Property *",
                            "Get-NetAdapterStatistics -Name ""$name"" | Format-Table -Property * -AutoSize | Out-String -Width $columns"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }   

        # Execute command list
        $file = "Get-NetAdapterEncapsulatedPacketTaskOffload.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterEncapsulatedPacketTaskOffload -Name ""$name"" | Out-String -Width $columns",
                            "Get-NetAdapterEncapsulatedPacketTaskOffload -Name ""$name"" | Format-List  -Property *",
                            "Get-NetAdapterEncapsulatedPacketTaskOffload -Name ""$name"" | Format-Table -Property * -AutoSize | Out-String -Width $columns"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }
        
        # Execute command list
        $file = "Get-NetAdapterHardwareInfo.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterHardwareInfo -Name ""$name"" | Out-String -Width $columns",
                            "Get-NetAdapterHardwareInfo -Name ""$name"" | Format-List  -Property *",
                            "Get-NetAdapterHardwareInfo -Name ""$name"" | Format-Table -Property * -AutoSize | Out-String -Width $columns"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        # Execute command list - Detect Property
        $file = "Get-NetAdapterIPsecOffload.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterIPsecOffload -Name ""$name"" | Out-String -Width $columns",
                            "Get-NetAdapterIPsecOffload -Name ""$name"" | Format-List  -Property *",
                            "Get-NetAdapterIPsecOffload -Name ""$name"" | Format-Table -Property * -AutoSize | Out-String -Width $columns"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        # Execute command list - Detect Property
        $file = "Get-NetAdapterPowerManagment.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterPowerManagment -Name ""$name"" | Out-String -Width $columns",
                            "Get-NetAdapterPowerManagment -Name ""$name"" | Format-List  -Property *",
                            "Get-NetAdapterPowerManagment -Name ""$name"" | Format-Table -Property * -AutoSize | Out-String -Width $columns"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }
        
        $file = "Get-NetAdapterQos.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterQos -Name ""$name"" | Out-String -Width $columns",
                            "Get-NetAdapterQos -Name ""$name"" | Format-List  -Property *",
                            "Get-NetAdapterQos -Name ""$name"" | Format-Table -Property * -AutoSize | Out-String -Width $columns"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }
        
        $file = "Get-NetAdapterRdma.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterRdma -Name ""$name"" | Out-String -Width $columns",
                            "Get-NetAdapterRdma -Name ""$name"" | Format-List  -Property *",
                            "Get-NetAdapterRdma -Name ""$name"" | Format-Table -Property * -AutoSize | Out-String -Width $columns"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        $file = "Get-NetAdapterPacketDirect.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterPacketDirect -Name ""$name"" | Out-String -Width $columns",
                            "Get-NetAdapterPacketDirect -Name ""$name"" | Format-List  -Property *",
                            "Get-NetAdapterPacketDirect -Name ""$name"" | Format-Table -Property * -AutoSize | Out-String -Width $columns"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        $file = "Get-NetAdapterRsc.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterRsc -Name ""$name"" | Out-String -Width $columns",
                            "Get-NetAdapterRsc -Name ""$name"" | Format-List  -Property *",
                            "Get-NetAdapterRsc -Name ""$name"" | Format-Table -Property * -AutoSize | Out-String -Width $columns"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        $file = "Get-NetAdapterSriov.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterSriov -Name ""$name"" | Out-String -Width $columns",
                            "Get-NetAdapterSriov -Name ""$name"" | Format-List  -Property *",
                            "Get-NetAdapterSriov -Name ""$name"" | Format-Table -Property * -AutoSize | Out-String -Width $columns"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }
        
        $file = "Get-NetAdapterSriovVf.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterSriovVf -Name ""$name"" | Out-String -Width $columns",
                            "Get-NetAdapterSriovVf -Name ""$name"" | Format-List  -Property *",
                            "Get-NetAdapterSriovVf -Name ""$name"" | Format-Table -Property * -AutoSize | Out-String -Width $columns"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        $file = "Get-NetAdapterVmq.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterVmq -Name ""$name"" | Out-String -Width $columns",
                            "Get-NetAdapterVmq -Name ""$name"" | Format-List  -Property *",
                            "Get-NetAdapterVmq -Name ""$name"" | Format-Table -Property * -AutoSize | Out-String -Width $columns"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        $file = "Get-NetAdapterVmqQueue.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterVmqQueue -Name ""$name"" | Out-String -Width $columns",
                            "Get-NetAdapterVmqQueue -Name ""$name"" | Format-List  -Property *",
                            "Get-NetAdapterVmqQueue -Name ""$name"" | Format-Table -Property * -AutoSize | Out-String -Width $columns"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        $file = "Get-NetAdapterVPort.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterVPort -Name ""$name"" | Out-String -Width $columns",
                            "Get-NetAdapterVPort -Name ""$name"" | Format-List  -Property *",
                            "Get-NetAdapterVPort -Name ""$name"" | Format-Table -Property * -AutoSize | Out-String -Width $columns"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }
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
    [String []] $cmds = "Get-NetAdapter",
                        "Get-VMSwitch",
                        "Get-VMNetworkAdapter *",
                        "Get-NetIPConfiguration"
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
        [String []] $cmds = "Get-VMSwitch -Name ""$name""",
                            "Get-VMSwitch -Name ""$name"" | Get-Member",
                            "Get-VMSwitch -Name ""$name"" | Format-List  -Property *",
                            "Get-VMSwitch -Name ""$name"" | Format-Table -Property * -AutoSize | Out-String -Width $columns"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        # Execute command list
        $file = "Get-VMSwitchExtension.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-VMSwitch -Name ""$name"" | Get-VMSwitchExtension | Get-Member",
                            "Get-VMSwitch -Name ""$name"" | Get-VMSwitchExtension | Format-List  -Property *",
                            "Get-VMSwitch -Name ""$name"" | Get-VMSwitchExtension | Format-Table -Property * -AutoSize | Out-String -Width $columns"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }

        <#        
        # Execute command list
        $file = "Get-VMSwitchExtensionPortData.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-VMSwitchExtensionPortData -SwitchName $name | Get-Member",
                            "Get-VMSwitchExtensionPortData -SwitchName $name | Format-List  -Property *",
                            "Get-VMSwitchExtensionPortData -SwitchName $name | Format-Table -Property * -AutoSize | Out-String -Width $columns"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }
        #>

        # Execute command list
        $file = "Get-VMSwitchExtensionSwitchData.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-VMSwitchExtensionSwitchData -SwitchName $name | Get-Member",
                            "Get-VMSwitchExtensionSwitchData -SwitchName $name | Format-List  -Property *",
                            "Get-VMSwitchExtensionSwitchData -SwitchName $name | Format-Table -Property * -AutoSize | Out-String -Width $columns"
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
        [String []] $cmds = "Get-VMSystemSwitchExtensionSwitchFeature",
                            "Get-VMSystemSwitchExtensionSwitchFeature | Get-Member",
                            "Get-VMSystemSwitchExtensionSwitchFeature | Format-List  -Property *",
                            "Get-VMSystemSwitchExtensionSwitchFeature | Format-Table -Property * -AutoSize | Out-String -Width $columns"
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

    foreach($nic in Get-NetAdapter) {
        $name = $nic.Name
        $desc = $nic.InterfaceDescription

        #Write-Output $desc
        $make = ""
        if ($desc -like '*Chelsio*') {
            $make = "Chelsio"
        }elseif ($desc -like '*Mellanox*') {
            $make = "Mellanox"
        }elseif ($desc -like '*Intel*') {
            $make = "Intel"    
        }elseif ($desc -like '*Qlogic*') {
            $make = "Qlogic"
        }

        if ($make) {
            $file = "PerfCounter_$make.txt"
            $out  = (Join-Path -Path $OutDir -ChildPath $file)
            $cmd  = "Get-Counter -Counter (Get-Counter -ListSet *$make*).paths -ErrorAction SilentlyContinue | Format-List -Property *"
            ExecCommand -Command ($cmd) -Output $out
        }
    }
}

function Environment {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true)] [String] $OutDir
    )

    $file = "Environment.txt"
    $out  = (Join-Path -Path $OutDir -ChildPath $file)
    [String []] $cmds = "Get-ItemProperty -Path ""HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"""
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

function Main {
    clear
    $columns = 4096

    $user    = [Environment]::UserName
    $baseDir = "C:\Users\$user\Desktop\Test\"

    EnvDestroy -OutDir $baseDir
    EnvCreate  -OutDir $baseDir
    
    # Add try catch logic for inconsistent PS cmdlets implementation on -Named inputs
    # https://www.leaseweb.com/labs/2014/01/print-full-exception-powershell-trycatch-block-using-format-list/

    Environment  -OutDir $baseDir
    PerfCounters -OutDir $baseDir

    NetAdapterSummary -OutDir $baseDir
    NetAdapterDetail  -OutDir $baseDir
    
    VMSwitchSummary -OutDir $baseDir
    VMSwitchDetail  -OutDir $baseDir
    #https://technet.microsoft.com/en-us/library/hh848499.aspx

    #VMNetworkAdapterSummary
    #VMNetworkAdapterDetail
    #https://technet.microsoft.com/en-us/library/hh848516.aspx

    #VMNetworkAdapterVlanSummary
    #VMNetworkAdapterVlanDetail
    #https://technet.microsoft.com/en-us/library/hh848516.aspx

    #samples
    #https://github.com/Microsoft/SDN/blob/master/SDNExpress/scripts/SDNExpress.ps1
    #https://learn-powershell.net/2014/02/04/using-powershell-parameter-validation-to-make-your-day-easier/
    #http://www.powershellmagazine.com/2013/12/09/secure-parameter-validation-in-powershell/
    #https://msdn.microsoft.com/en-us/library/dd878340(v=vs.85).aspx


    
}

Main #Entry Point
