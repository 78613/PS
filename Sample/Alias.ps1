



<#
Try {
    #Get-NetAdapter -Name Ethernets
    Get-NetAdapterStatistics -Name Ethernet
} 
Catch {
    #echo $_.Exception.GetType().FullName, $_.Exception.Message
    #echo $_.Exception | format-list -force
    Write-Host "Hello"
} 
Finally {
    #echo $_.Exception | format-list -force
    #Write-Host "Hello"    
    $MyInvocation | Format-List -property
}

#>


<#
#<
#region Script Diagnostic Functions
function Get-CurrentLineNumber {
    $MyInvocation.ScriptLineNumber
}
New-Alias -Name __LINE__ -Value Get-CurrentLineNumber –Description ‘Returns the current line number in a PowerShell script file.‘

function Get-CurrentFileName {
    $MyInvocation.ScriptName
}
New-Alias -Name __FILE__ -Value Get-CurrentFileName -Description ‘Returns the name of the current PowerShell script file.‘
#endregion
#>