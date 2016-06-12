# Execute this command on the PS windows to enable execution
# Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

<#
.SYNOPSIS
Testing the get/set for all NetAdapterAdvancedProperty we are interested

.PARAMETER NicName
The name of the Ethernet connection
#>
[CmdletBinding()]
Param(
  [Parameter(Mandatory=$False)]
  [string]$NicName = "Ethernet"
  )


function NetAdapterAdvancedProperty {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$True)]
        [string]$NicName
    )

    # below is the PS command to get all the NIC advanced property for testing
    # Get-NetAdapterAdvancedProperty -name ""$NicName"" -AllProperties -IncludeHidden

    <#
__      ___             _____ _____  
 \ \    / / |           |_   _|  __ \ 
  \ \  / /| | __ _ _ __   | | | |  | |
   \ \/ / | |/ _` | '_ \  | | | |  | |
    \  /  | | (_| | | | |_| |_| |__| |
     \/   |_|\__,_|_| |_|_____|_____/                                           
    #expectations:
    # - We need to see VlanID there, the test will fail and exit if it is not
    # - Vlan ID of 0, 1, 4095 are reserved, we are are not setting the new values to that
    # - if the original Vlan ID is not 2, we will set the new value to 2, else set it to 3
    #>                      
    try
    {
        # store the original value
        $orgVlandID = Get-NetAdapterAdvancedProperty -Name "$NicName" | Where-Object { $_.RegistryKeyword -eq "VlanID" }

        # if value for this keyword is null
        if ($orgVlandID  -eq $null)
        {
            Write-Host -ForegroundColor Red "VlanID was null for this Server NIC, we expect it to be set"
        }
        else
        {
            if ( $orgVlandID.RegistryValue.GetValue(0) -eq "2" )
            {
                $newVlandID = 3
            }
            else
            {
                $newVlandID = 2
            }

            # set it to the new value
            Set-NetAdapter -Name "$NicName" -VlanID $newVlandID -Confirm:$false

            # get and confirm it is the new value
            if ((Get-NetAdapterAdvancedProperty -Name "$NicName" | Where-Object { $_.RegistryKeyword -eq "VlanID" }).RegistryValue.GetValue(0) -eq $newVlandID)
            {
                Write-Host "Confirmed the VlanID was changed from" $orgVlandID.RegistryValue "to" $newVlandID
            }
            else
            {
                Write-Host -ForegroundColor Red "VlanID was not changed from" $orgVlandID.RegistryValue "to" $newVlandID "as we were expected"
            }

            # reset back to the orginal value
            Set-NetAdapter -Name "$NicName" -VlanID $orgVlandID.RegistryValue.GetValue(0) -Confirm:$false

            # confirmed we have reset back to the original value
            if ((Get-NetAdapterAdvancedProperty -Name "$NicName" | Where-Object { $_.RegistryKeyword -eq "VlanID" }).RegistryValue.GetValue(0) -eq $orgVlandID.RegistryValue.GetValue(0))
            {
                Write-Host "Confirmed the VlanID was changed back to" $orgVlandID.RegistryValue
            }
            else
            {
                Write-Host -ForegroundColor Red "VlanID was not able to changed back to" $orgVlandID.RegistryValue
            }
        }
    }
    catch
    {
        Write-Host -ForegroundColor Red "Caught an exception while dealing with VlanID, please reset it back to original settings manually"
        Write-Host -ForegroundColor Red "Error Message:" $_.Exception.Message
        Write-Host -ForegroundColor Red "Failed Item:" $_.Exception.ItemName
    }


}

function Main 
{
    NetAdapterAdvancedProperty $NicName
}

Main #Entry Point 
