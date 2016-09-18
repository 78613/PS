

function Setup {
    New-VMSwitch –Name S2DSwitch –NetAdapterName "Test-40G-1", "Test-40G-2" -EnableEmbeddedTeaming $true -AllowManagementOS $true
    Add-VMNetworkAdapter –SwitchName S2DSwitch –Name SMB1 –ManagementOS
    Add-VMNetworkAdapter –SwitchName S2DSwitch –Name SMB2 –ManagementOS
} 

Function Cleanup {
    Remove-VMSwitch –Name S2DSwitch -Force
}

function Test {
    New-NetIPAddress -InterfaceIndex 36 -IPAddress 192.168.100.1 -PrefixLength 24 -DefaultGateway 192.168.100.0
    New-NetIPAddress -InterfaceIndex 32 -IPAddress 192.168.100.1 -PrefixLength 24 -DefaultGateway 192.168.100.0
}

function Main {
    Cleanup
    Setup
    Test
} Main

