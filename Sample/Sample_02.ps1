$nics = "Test-40G-2"
 ForEach($nic in $nics) {
    Set-NetAdapterAdvancedProperty -Name $nic -RegistryKeyword "*TCPUDPChecksumOffloadIPv4" -DisplayValue "Tx Enabled"
    Set-NetAdapterAdvancedProperty -Name $nic -RegistryKeyword "*TCPUDPChecksumOffloadIPv6" -DisplayValue "Tx Enabled"
    Get-NetAdapter -Name $nic | Disable-NetAdapter -Confirm:$false
    Get-NetAdapter -Name $nic | Enable-NetAdapter
}