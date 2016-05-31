

#Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process



<#
function test {
    ForEach($Switch in Get-VMSwitch) {
        Get-VMSwitch -name $Switch.name     
    }
}
#>




function ExecCommand {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true)] [String] $Command, 
        [parameter(Mandatory=$true)] [String] $Output
    )

    Write-Output "Command = $Command " 
    Write-Output "Output  = $Output "

    # Mirror Prompt info
    $prompt = $env:username + " @ " + $env:computername + ":"
    Write-Output $prompt | out-file -Encoding ascii -Append $Output

    # Mirror Command to execute
    $cmdMirror = "PS " + (Convert-Path .) + "> " + $Command
    Write-Output $cmdMirror | out-file -Encoding ascii -Append $Output

    # Execute Command and redirect to file.  Useful so users know what to run..
    Invoke-Expression $Command | out-file -Encoding ascii -Append $Output
} 

function test {
        $name = "Primary"
        $dir="C:\Users\ocardona\Desktop\"
        $file = "Get-NetAdapterStatistics.txt"
        $out  = (Join-Path -Path $dir -ChildPath $file)
        [String []] $cmds = "Get-NetAdapterStatistics -Name ""$name""",
                            "Get-NetAdapterStatistics -Name ""$name"" | Format-List",
                            "Get-NetAdapterStatistics -Name ""$name"" | Format-List *"
        ForEach($cmd in $cmds) {
            ExecCommand -Command ($cmd) -Output $out
        }
 }

function Main {
    Clear
    #$dir="C:\Users\ocardona\Desktop\Test"
    
    #Remove-Item $dir -Recurse
    #New-Item -ItemType directory -Path $dir

    #$cmd = "Get-NetAdapter"
    #$out = (Join-Path -Path $dir -ChildPath tmp.txt)

    #$tmp = Get-NetAdapterRss | Get-Member
    #Echo $tmp
    #Echo $tmp.PSobject
    #(Get-NetAdapterRss | Get-Member)

    #Get-Member -InputObject Get-NetAdapterRss 
    
    #ExecCommand -Command $cmd -Output $out

    #test
    <#
    Get-NetAdapter -Name "vEthernet (VMS-Primary) 2"
    Get-NetAdapterStatistics -Name "vEthernet (VMS-Primary) 2"

    $var = Get-NetAdapterStatistics -Name Primary | Get-WmiObject *
    if(Get-Member -inputobject $var -name "Property" -Membertype Properties){
        Echo "Present"
    }else {
        Echo "Missing"
    }
    #>

    <#
    Echo "Control"
    Get-NetAdapterStatistics -Name "vEthernet (VMS-Primary) 2"

    Echo "Test"
    Get-NetAdapterStatistics -Name "vEthernet (VMS-Primary) 2"
    #(Get-NetAdapterStatistics -Name Secondary).CimClass -match '*MSFT_NetAdapterStatistics*'
    Get-NetAdapter -Name "vEthernet (VMS-Primary) 2" | Format-List -Property *
    Get-NetAdapter -Name "vEthernet (VMS-Primary) 2" | Get-WmiObject "MSFT_NetAdapter" | Format-List -Property *

    
    #if ($var.PSObject.Properties['']
    #>
    
    Echo Control
    Get-NetAdapterStatistics -Name Secondary
    Echo Test
    #Get-NetAdapterStatistics -Name Secondaryx 2>&1 | Out-File -Encoding ascii -Append deleteme.txt
    $command = "Get-NetAdapterStatistics -Name ""Secondary"""
    #Invoke-Expression $Command 2>&1 | Out-File -Encoding ascii -Append $Output
    $ret = Invoke-Expression $command 2>&1 | Out-File -Encoding ascii -Append deleteme.txt
    Echo $ret

} #Main()

#Entry Point
Main
