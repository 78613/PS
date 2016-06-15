﻿

$servers = @(
"253171R8U02",
"253171R8U04",
"253171R8U06",
"253171R8U08",
"253171R8U10",
"253171R8U12",
"253171R8U14",
"253171R8U16"
)
 
Invoke-Command -ComputerName $Servers -ScriptBlock {
      ForEach ($obj in (Get-NetAdapter -InterfaceDescription *mellanox*)) {
            $val = "Disabled"        
            $nic = $obj.name

            Set-NetAdapterAdvancedProperty -Name $nic -RegistryKeyword "*LsoV2IPv4"                 -DisplayValue $val
            Set-NetAdapterAdvancedProperty -Name $nic -RegistryKeyword "*LsoV2IPv6"                 -DisplayValue $val
            Set-NetAdapterAdvancedProperty -Name $nic -RegistryKeyword "*TCPUDPChecksumOffloadIPv4" -DisplayValue $val
            Set-NetAdapterAdvancedProperty -Name $nic -RegistryKeyword "*TCPUDPChecksumOffloadIPv6" -DisplayValue $val

            Get-NetAdapterAdvancedProperty -Name $nic -RegistryKeyword "*LsoV2IPv4"
            Get-NetAdapterAdvancedProperty -Name $nic -RegistryKeyword "*LsoV2IPv6"
            Get-NetAdapterAdvancedProperty -Name $nic -RegistryKeyword "*TCPUDPChecksumOffloadIPv4"
            Get-NetAdapterAdvancedProperty -Name $nic -RegistryKeyword "*TCPUDPChecksumOffloadIPv6"

            Get-NetAdapter -Name $nic | Disable-NetAdapter -Confirm:$false
            Get-NetAdapter -Name $nic | Enable-NetAdapter
            #Get-NetAdapterAdvancedProperty -Name $nic
        }
}  
