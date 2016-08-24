

$servers = @(
"YourHost1",
"YourHost2",
"YourHost3"
)
 
Invoke-Command -ComputerName $Servers -ScriptBlock {
      ForEach ($obj in (Get-NetAdapter -InterfaceDescription *mellanox*)) {
            $val = "Disabled"        
            $nic = $obj.name

            Set-NetAdapterAdvancedProperty -Name $nic -RegistryKeyword "*RscIPv4" -DisplayValue $val
            Set-NetAdapterAdvancedProperty -Name $nic -RegistryKeyword "*RscIPv6" -DisplayValue $val

            Get-NetAdapter -Name $nic | Disable-NetAdapter -Confirm:$false
            Get-NetAdapter -Name $nic | Enable-NetAdapter
            #Get-NetAdapterAdvancedProperty -Name $nic
        }
}  
