

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
                            "Get-NetAdapterAdvancedProperty -Name ""$name"" -AllProperties -IncludeHidden | Format-List  -Property *",
                            "Get-NetAdapterAdvancedProperty -Name ""$name"" -AllProperties -IncludeHidden | Format-Table -Property * -AutoSize | Out-String -Width $width"
        ForEach($cmd in $cmds) {
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
    $width = 4096

    #Set-PSDebug -Trace 1

    $user    = [Environment]::UserName
    $baseDir = "C:\Users\$user\Desktop\Test\"

    EnvDestroy -OutDir $baseDir
    EnvCreate  -OutDir $baseDir
    
    # Add try catch logic for inconsistent PS cmdlets implementation on -Named inputs
    # https://www.leaseweb.com/labs/2014/01/print-full-exception-powershell-trycatch-block-using-format-list/

    Environment  -OutDir $baseDir

    NetAdapterDetail -OutDir $baseDir
  
}

Main #Entry Point