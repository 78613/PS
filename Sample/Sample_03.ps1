


function VmsCreate {
    New-VMSwitch -Name test -AllowManagementOS $true -NetAdapterName "Slot 3" -EnableEmbeddedTeaming $true
    Set-VMSwitchTeam -Name test -LoadBalancingAlgorithm HyperVPort
    Get-VMSwitchTeam | fl
    Restart-Computer
    Get-VMSwitchTeam | fl
}


function Main {
    clear



}

Main #Entry Point