function F_Clean {
     Write-Host -ForegroundColor Green "Clean()"

     Remove-NetQosTrafficClass "SMB"
     Disable-NetAdapterQos *
     Disable-NetQosFlowControl
     Remove-NetQosPolicy "SMB" -Confirm:$false

     Remove-VMSwitch –Name S2DSwitch -Force
     Reset-NetAdapterAdvancedProperty -Name "Mellanox 1" –DisplayName *
     Reset-NetAdapterAdvancedProperty -Name "Mellanox 2" –DisplayName *
}

function F_Repro {
    Write-Host -ForegroundColor Green "Repro()"

    New-NetQosPolicy "SMB" -NetDirectPortMatchCondition 445 -PriorityValue8021Action 3
    Enable-NetQosFlowControl -Priority 3
    Disable-NetQosFlowControl -Priority 0,1,2,4,5,6,7
    Enable-NetAdapterQos -Name "Mellanox 1","Mellanox 2"
    New-NetQosTrafficClass "SMB" -Priority 3 -BandwidthPercentage 50 -Algorithm ETS

    New-VMSwitch –Name S2DSwitch –NetAdapterName "Mellanox 1", "Mellanox 2" -EnableEmbeddedTeaming $true -AllowManagementOS $false

    Add-VMNetworkAdapter –SwitchName S2DSwitch –Name SMB1 –ManagementOS
    Add-VMNetworkAdapter –SwitchName S2DSwitch –Name SMB2 –ManagementOS

    Enable-NetAdapterRDMA -Name “vEthernet (SMB1)”,“vEthernet (SMB2)”

    Set-VMNetworkAdapterVlan -VMNetworkAdapterName SMB1 -VlanId 12 -Access –ManagementOS
    Set-VMNetworkAdapterVlan -VMNetworkAdapterName SMB2 -VlanId 12 -Access –ManagementOS

    Set-NetAdapterVmq -Name "Mellanox 1" -BaseProcessorNumber 2 -MaxProcessors 14
    Set-NetAdapterVmq -Name "Mellanox 2" -BaseProcessorNumber 30 -MaxProcessors 13
}

function F_Test {
    Write-Host -ForegroundColor Green "Test()"
    
    Get-NetAdapterRdma | ? Name -Like *SMB* | ft Name, Enabled
    Get-SmbClientNetworkInterface | ? FriendlyName -Like *SMB*

    $obj = Get-SmbClientNetworkInterface | ? FriendlyName -Like *SMB1* 
    if ($obj.RdmaCapable -Like "False") {
        Write-Host "Terminating: RDMA Not Enabled on (SMB1)"    
        Exit    
    }

    $obj = Get-SmbClientNetworkInterface | ? FriendlyName -Like *SMB2* 
    if ($obj.RdmaCapable -Like "False") {
        Write-Host "Terminating: RDMA Not Enabled on (SMB2)"
        Exit
    }
}

function Main {
    clear
    $iter = 0
    do {
        Write-Host -ForegroundColor Cyan "Iteration: $iter"

        F_Clean
        F_Repro
        F_Test

        sleep (1)
        $iter++
    } while (1)
}
Main #Entry Point 
