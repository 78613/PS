[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True, Position=1, HelpMessage="First physical adapter for the SET vSwitch")]
  [string] $Adapter1,
  [Parameter(Mandatory=$True, Position=2, HelpMessage="Second physical adapter for the SET vSwitch")]
  [string] $Adapter2,
  [Parameter(Mandatory=$True, Position=3, HelpMessage="Priority over which SMB traffic will flow. Physical switch must be configured for the same priorty for PFC (no drop)")]
  [string] $Storage1Vlan,
  [Parameter(Mandatory=$True, Position=4, HelpMessage="IP address of storage 1 vNIC")]
  [string] $Storage1IPAddress,
  [Parameter(Mandatory=$True, Position=5, HelpMessage="Prefix length of storage 1 vNIC")]
  [string] $Storage1IPPrefixLength,
  [Parameter(Mandatory=$True, Position=6, HelpMessage="Vlan configuration of storage 1 vNIC")]
  [string] $Storage2Vlan,
  [Parameter(Mandatory=$True, Position=7, HelpMessage="IP address of storage 2 vNIC")]
  [string] $Storage2IPAddress,
  [Parameter(Mandatory=$True, Position=8, HelpMessage="Prefix length of storage 2 vNIC")]
  [string] $Storage2IPPrefixLength,
  [Parameter(Mandatory=$True, Position=9, HelpMessage="Vlan configuration of storage 2 vNIC")]
  [string] $Priority,
  [Parameter(Mandatory=$False, Position=10, HelpMessage="True if RDMA should be enabled on storage host vNICs; false otherwise. Default is true.")]
  [string] $EnableRdmaOnStoragevNics = $true
)

# Turn on DCB (optional for iWarp)
Install-WindowsFeature Data-Center-Bridging��
�
Remove-NetQosPolicy * -Confirm:$false

Remove-NetQosTrafficClass *

# Set the policies for SMB-Direct
New-NetQosPolicy "SMB" -NetDirectPortMatchCondition 445 -PriorityValue8021Action 3
�
# Set policies for other traffic on the interface�
New-NetQosPolicy "DEFAULT" -Default -PriorityValue8021Action 0
	�
# Make sure flow control is off for other traffic�
Disable-NetQosFlowControl -priority 0,1,2,3,4,5,6,7

# Turn on Flow Control for SMB�
Enable-NetQosFlowControl -priority $Priority
	�
# Turn this on for the target adapter; Slot 4 is a Mellanox adapter in this example
Enable-NetAdapterQos -InterfaceAlias $Adapter1

Enable-NetAdapterQos -InterfaceAlias $Adapter2

# Give SMB Direct 70% of the bandwidth minimum�
New-NetQosTrafficClass "SMB" -priority 3 -bandwidthpercentage 70 -algorithm ETS

$existingvSwitch = Get-VMSwitch -Name SetSwitch -ErrorAction Ignore
if ($existingvSwitch)
{
    Remove-VMSwitch -Name SetSwitch -Force
}
	�
New-VMSwitch -Name SetSwitch -NetAdapterName $adapter1,$adapter2

Sleep 5

Rename-NetAdapter -Name "vEthernet (SetSwitch)" -NewName "ManagementOS"

Add-VMNetworkAdapter -Name Storage1 -SwitchName SetSwitch -ManagementOS

Sleep 5

Rename-NetAdapter -Name "vEthernet (Storage1)" -NewName "Storage1"

Add-VMNetworkAdapter -Name Storage2 -SwitchName SetSwitch -ManagementOS

Sleep 5

Rename-NetAdapter -Name "vEthernet (Storage2)" -NewName "Storage2"

Sleep 5

if ($EnableRdmaOnStoragevNics -ne $False)
{
    Enable-NetAdapterRdma -Name "Storage1"

    Enable-NetAdapterRdma -Name "Storage2"

    Sleep 5
}

Set-VMNetworkAdapterTeamMapping -VMNetworkAdapterName "Storage1" -ManagementOS -PhysicalNetAdapterName $Adapter1

Sleep 5

Set-VMNetworkAdapterTeamMapping -VMNetworkAdapterName "Storage2" -ManagementOS -PhysicalNetAdapterName $Adapter2

New-NetIPAddress $Storage1IPAddress -InterfaceAlias "Storage1" -PrefixLength $Storage1IPPrefixLength
Set-VMNetworkAdapterIsolation -VMNetworkAdapterName "Storage1" -ManagementOS -IsolationMode Vlan -AllowUntaggedTraffic $true -DefaultIsolationID $Storage1Vlan

Sleep 5

New-NetIPAddress $Storage2IPAddress -InterfaceAlias "Storage2" -PrefixLength $Storage2IPPrefixLength
Set-VMNetworkAdapterIsolation -VMNetworkAdapterName "Storage2" -ManagementOS -IsolationMode Vlan -AllowUntaggedTraffic $true -DefaultIsolationID $Storage2Vlan