    #Set PowerShell execution policy
    Set-ExecutionPolicy RemoteSigned -Force



    $roceadapters = "Mellanox"



    # clear/normalize pre-existing settings
    $adapters =  Get-NetAdapterRdma |? InterfaceDescription -match $roceadapters

   
  
    # clear/normalize pre-existing settings
    Set-NetQosDcbxSetting -Willing $false -Confirm:$false
    Remove-NetQosPolicy -Confirm:$false
    Disable-NetQosFlowControl
    Disable-NetAdapterQos -InterfaceAlias $adapters.Name -ErrorAction SilentlyContinue    
    
    

    # Enable DCB
    Install-WindowsFeature Data-Center-Bridging


    
    # establish QoS
    New-NetQosPolicy "SMB" -NetDirectPortMatchCondition 445 -PriorityValue8021Action 3
    New-NetQosPolicy "DEFAULT" -Default -PriorityValue8021Action 3
    New-NetQosPolicy "TCP" -IPProtocolMatchCondition TCP -PriorityValue8021Action 1 
    New-NetQosPolicy "UDP" -IPProtocolMatchCondition UDP -PriorityValue8021Action 1

    
    # move adapters into the switch-defined vlan
    $adapters | Set-NetAdapter -VlanID 4 -Confirm:$false
    
   

    # Enable Priority Flow Control (PFC) on a specific priority. Disable for others
    Enable-NetQosFlowControl -Priority 3
    Disable-NetQosFlowControl 0,1,2,4,5,6,7
    Enable-NetAdapterQos -InterfaceAlias $adapters.Name