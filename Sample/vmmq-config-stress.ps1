#
# This scripts goes through different VMMQ configuration settings and verifies
# that each setting is successful.
#

Param($SkipVMCheck = $False,
      $WithTraffic = $False,
      $VmName=$(throw "VmName is required"),
      $AdapterNames=$(throw "AdapterNames required"))

#
# This function takes in a job ID of a Get-Counter job, and
# retrieve the perfmon output of the job, and computes the
# average values of the samples.
#
function GetAverageFromGetCounterJob($JobId, $seconds)
{
    Stop-Job $JobId
    $statArray = Receive-Job $JobId
    Remove-Job $JobId

    #
    # Get $second samples, 90s from end of trace
    #
    $avg = 0
    $count=0
    $endIndex = $statArray.Count - 90
    $startIndex = [system.math]::Max(0, $endIndex - $seconds)

    Log "Calculating average samples [$startIndex]-[$endIndex]"
    $message = ""
    for ($i=$startIndex; $i -le $endIndex; $i++)
    {
        $value = $statArray[$i].Readings.Split(":")[-1]
        $value = $value.Trim()

        $value = [int64]$value
        $avg += $value

        $message = $message + [string]$value + ", "
        $count++
    }
    Log "`t$message"
    Log ""

    $avg = $avg / $count

    return $avg
}


function CheckValues($Properties, $vrss, $vmmq, $numqueues)
{
    if ($SkipVMCheck)
    {
        Write-Host "Skip VM Check"
        return
    }

    sleep 5

    if ($Properties.VrssEnabled -ne $vrss)
    {
        Write-Host "Unexpected VmNetworkAdapter VRSSEnabled value. Expect $vrss"
        exit
    }

    if ($Properties.VmmqEnabled -ne $vmmq)
    {
        Write-Host "Unexpected VmNetworkAdapter VMMQEnabled value. Expect $vmmq"
        exit
    }

        if ($Properties.VmmqQueuePairs -ne $numqueues)
    {
        Write-Host "Unexpected VmNetworkAdapter num queues. Expect $numqueues"
        exit
    }

    $sendVPs = ValidateSendChannelAssignment($Properties)
    $recvVPs = ValidateRecvChannelAssignment($Properties)
    validatePacketSpreading($Properties, $sendVPs, "send");
    validatePacketSpreading($Properties, $recvVPs, "recv");
    validatePacketSpreading($Properties, $sendVPs, "sendcomplete");

    Write-Host "Validated VMNetworkAdapter VRSSEnabled:$vrss VMMQEnabled:$vmmq NumQueues:$numQueues"
}

function CheckDefaultValues($Properties, $vrss, $vmmq, $numqueues)
{
    sleep 5

    if ($Properties.DefaultQueueVrssEnabled -ne $vrss)
    {
        Write-Host "Unexpected default queue VRSSEnabled value. Expect $vrss"
        exit
    }

    if ($Properties.DefaultQueueVmmqEnabled -ne $vmmq)
    {
        Write-Host "Unexpected VMMQEnabled value. Expect $vmmq\n"
        exit
    }

        if ($Properties.DefaultQueueVmmqQueuePairs -ne $numqueues)
    {
        Write-Host "Unexpected default queue num queues. Expect $numqueues"
        exit
    }

    Write-Host "Validated Default queue VRSSEnabled:$vrss VMMQEnabled:$vmmq NumQueues:$numQueues"
}

function ValidateSendChannelAssignment($Properties)
{
    $vmqOnly = $False
    $vm = get-vm $VmName

    if (!$Properties.VmmqEnabled -and !$Properties.VrssEnabled)
    {
        Write-host "VRss and VMMQ not enabled on the adapter. Validating send traffic sent over vmq proc"
        $vmqOnly = $True
    }

    if ($vm.State -ne "Running")
    {
        Write-host "$VmName is not started. Please restart the vm and re-run the test."
        exit
    }

    $uniqueVPsUsed = 0
    $vpCount = $vm.ProcessorCount
    $baseProcessor = (Get-NetAdapterrss $AdapterNames).BaseProcessorNumber
    $maxProcessor = (Get-NetAdapterrss $AdapterNames).MaxProcessorNumber

    #
    # Create vprocessors:#timesUsed mapping to keep track of all valid processors used
    #
    $vprocessors = @{}

    #
    # Extract the perfmon counters for the vm
    # Update the vprocessors mapping to reflect the vprocessors used
    #
    $sendProcessorCounterNames = (Get-Counter -ListSet "Hyper-V Virtual Network Adapter VRSS").PathsWithInstances | where {$_ -like "*$VmName*\SendProcessor"}

    for($i=0; $i -lt $SendProcessorCounterNames.count; $i++)
    {
        $sendprocessor = (((Get-Counter -Counter $sendProcessorCounterNames[$i]).CounterSamples.GetValue(0)).CookedValue)
       
        if ($sendprocessor -eq -1) {continue; } 

        if (($sendprocessor -lt $baseProcessor) -or ($sendprocessor -gt $maxProcessor))
        {
            Write-Host ("$VmName is sending packets on an invalid processor:$vprocessor. 
                            Expected processors between $baseProcessor and $maxProcessor.")
            exit
        }

        if ($vprocessors.ContainsKey($sendProcessor))
        {
            $vprocessors[$sendProcessor] += 1
        }
        else
        {
            $uniqueVPsUsed++;
            $vprocessors.Add($sendProcessor, 1)
        }
    }

    if ($vmqOnly)
    {
        if (($uniqueVPsUsed -ne 1))
        {
            Write-Host "Incorrect number of processors used to send traffic in vmq mode. Expected 1. Actual $uniqueVPsUsed"
            exit
        }
    }
    else
    {
        if ($uniqueVPsUsed -ne $vpCount)
        {
            Write-Host ("Error: Incorrect number of VP's used during sending packets from $VmName. Expected $vpCount. Used $uniqueVPsUsed")
            #exit
        }

        #
        # Sort the vProcessors array based on count
        #
        $sortedVProcessors = $vprocessors.GetEnumerator() | Sort-Object Value -descending
       
        if (($sortedVProcessors[0].Value - $sortedVProcessors[$sortedVProcessors.Count - 1].Value) -gt 1)
        {
            Write-Host ("CPU Indexes not evenly distributed among VP's for sending packets.")
            exit
        }
    }

    return $vprocessors
}


function ValidateRecvChannelAssignment($Properties, $ValidProcessor)
{
    $vmqOnly = $False;
    $vm = get-vm $VmName
    if (!$Properties.VmmqEnabled -and !$Properties.VrssEnabled)
    {
        Write-host "VmNetworkAdapter VRss and VMMQ not enabled on the adapter. Testing only for vmq proc"
        $vmqOnly = $True
    }

    if ($vm.State -ne "Running")
    {
        Write-host "$VmName is not started. Please restart the vm and re-run the test."
        exit
    }

    $mac = (get-vmnetworkadapter -VMName $VmName).MacAddress
    $vmqProc = [math]::log((Get-NetAdapterVmqQueue | where {$_.FilterList.MacAddress -eq $mac}).ProcessorAffinityMask)/[math]::log(2)

    $uniqueVPsUsed = 0
    $queuePairCount = (get-vmnetworkAdapter -VMName $VmName).VmmqQueuePairs
    $baseProcessor = (Get-NetAdapterrss $AdapterNames).BaseProcessorNumber
    $maxProcessor = (Get-NetAdapterrss $AdapterNames).MaxProcessorNumber

    #
    # Create vprocessors:#timesUsed mapping to keep track of all valid processors used
    #
    $vprocessors = @{}

    #
    # Extract the perfmon counters for the vm
    # Update the vprocessors mapping to reflect the vprocessors used
    #
    $recvProcessorCounterNames = (Get-Counter -ListSet "Hyper-V Virtual Network Adapter VRSS").PathsWithInstances | where {$_ -like "*$VmName*\ReceiveProcessor"}

    for($i=0; $i -lt $recvProcessorCounterNames.count; $i++)
    {
        $recvprocessor = (((Get-Counter -Counter $recvProcessorCounterNames[$i]).CounterSamples.GetValue(0)).CookedValue)
       
        if ($recvprocessor -eq -1) {continue; } 

        if (($recvprocessor -lt $baseProcessor) -or ($recvprocessor -gt $maxProcessor))
        {
            Write-Host ("$VmName is receiving packets on an invalid processor:$vprocessor. 
                         Expected processors between $baseProcessor and $maxProcessor.")
            exit
        }

        if ($vprocessors.ContainsKey($sendProcessor))
        {
            $vprocessors[$recvProcessor] += 1
        }
        else
        {
            $uniqueVPsUsed++;
            $vprocessors.Add($recvProcessor, 1)
        }
    }

    if ($vmqOnly)
    {
        if (($uniqueVPsUsed -ne 1))
        {
            Write-Host "Incorrect number of processors used to recv traffic in vmq mode. Expected 1. Actual $uniqueVPsUsed"
            exit
        }
    }
    else
    {
        if ($uniqueVPsUsed -ne $queuePairCount)
        {
            Write-Host ("ERROR:::Incorrect number of VP's used during receiving packets from $VmName. 
                Expected $queuePairCount. Used $uniqueVPsUsed")
            #exit
        }

        if (!$vprocessors.ContainsKey($vmqProc))
        {
            Write-Host ("Failed to recv traffic on the vmq processor:$vmqProc")
            exit
        }

        #
        # Sort the vProcessors array based on count
        #
        $sortedVProcessors = $vprocessors.GetEnumerator() | Sort-Object Value -descending
       
        if (($sortedVProcessors[0].Value - $sortedVProcessors[$sortedVProcessors.Count - 1].Value) -gt 1)
        {
            Write-Host ("CPU Indexes not evenly distributed among VP's for receiving packets.")
            exit
        }
    }

    return $vprocessors
}

#
# This function validates packet spreading for send/recv/sendcompletions
# $Properties - Adapter properties
# $validProcessors - Output dictionary obtained from
#                    ValidateSendChannelAssignment/ValidateRecvChannelAssignment
# $direction - Type of spreading to be validated. Values- "send"/"recv"/"sendcomplete"
#
function validatePacketSpreading($Properties, $ValidProcessors, $Direction)
{
    $vm = get-vm $VmName

    if ($vm.State -ne "Running")
    {
        Write-host "$VmName is not started. Please restart the vm and re-run the test."
        exit
    }

    #
    # Create a dictionary to store the packet send/recv/sendcomplete rate for each vp
    #
    $pktRatePerVP = @{}

    $counterType = $null
    switch($Direction)
    {
        "send" {$counterType = "SendPacketPerSecond"}
        "recv" {$counterType = "ReceivePacketPerSecond"}
        "sendcomplete" {$counterType = "SendPacketCompletionsPerSecond"}
        default {Write-Host "Failed to validatePacketSpreading. Invalid direction specified."; return}
    }

    #
    # Extract VM specific packet perfmon counters
    #
    $pktCounterNames = (Get-Counter -ListSet "Hyper-V Virtual Network Adapter VRSS").PathsWithInstances | where {$_ -like "*$VmName*\$counterType"}

    for ($i=0; $i -lt $pktCounterNames.count; $i++)
    {
        $job = Start-Job -ScriptBlock {param($counter) Get-Counter -Counter $counter -SampleInterval 1 -Continuous} -ArgumentList $pktsCounterNames[$i]
        $pktPerSecRuntimeJobs = $pktPerSecRuntimeJobs + $job
    }

    #
    # Wait for few minutes
    #
    Write-Host "Sleeping for 180 seconds for $Direction packet spreading test"
    Start-Sleep -Seconds 180

    #
    # Calculate the average packets send/recv per processor for the last 60 seconds
    #
    for ($i=0; $i -lt $pktCounterNames.count; $i++)
    {
        $pktRate = GetAverageFromGetCounterJob($pktPerSecRuntimeJobs[$i].id, 60)
        if ($pktRate -ne 0)
        {
            #
            # First check if it's a valid VM Processor.
            # Note, currently we do not have counters for SendComplete processor
            #
            if ($Direction -eq "recv")
            {
                $processorCounterName = $pktsCounterNames[0].Replace($counterType, "ReceiveProcessor")
            }
            else
            {
                $processorCounterName = $pktsCounterNames[0].Replace($counterType, "SendProcessor")
            }

            $processor = (((Get-Counter -Counter $processorCounterName).CounterSamples.GetValue(0)).CookedValue)

            if (!$ValidProcessors.contain($processor))
            {
                Write-Host "$Direction packets are spread on an invalid proc. ValidProcessors: $ValidProcessors, actualProcessor $processor"
                exit
            }

            if ($pktRatePerVP.ContainsKey($processor))
            {
                $pktRatePerVP[$processor] += $pktRate
            }
            else
            {
                $pktRatePerVP.add($processor, $rate)
            }
        }
    }

    #
    # Get the maximum and minimum packet rates
    # 
    $sortedRatePerVP = $pktRatePerVP.GetEnumerator() | Sort-Object Value -descending

    $threshold = $sortedRatePerVP[0].Value / 10;    # Setting the threshold as 10% of the maximum
    if ($sortedRatePerVP[$sortedRatePerVP.Count-1].Value -lt $threshold)
    {
        Write-Host ("Failed to spread packets across all vprocessors during $Direction operation. 
                    MaxRate(VP:{0} Rate:{1}). MinRate(VP:{2} Rate:{3})" -f 
                    $sortedRatePerVP[0].Key, $sortedRatePerVP[1].Value,
                    $sortedRatePerVP[$sortedRatePerVP.count-1].Key, $sortedRatePerVP[$sortedRatePerVP.count-1].Value)
        exit
    }
}



###
############## START OF MAIN ############
###

Disconnect-VMNetworkAdapter -VMName $VmName
if ($? -eq $False)
{
    Write-Host "Failed to find VM $VmName"
    exit
}

Remove-VMSwitch -Name vmmq -Force
Set-NetAdapterAdvancedProperty $AdapterNames -RegistryKeyword "*RssOnHostVPorts" -RegistryValue 1
Set-NetAdapterAdvancedProperty $AdapterNames -RegistryKeyword "*NumRssQueues" -RegistryValue 8
Set-NetAdapterAdvancedProperty $AdapterNames -RegistryKeyword "*MaxRssProcessors" -RegistryValue 8

Set-VMNetworkAdapter -VMName $VmName -VrssEnabled $True -VmmqEnabled $False -VmmqQueuePairs 16

New-VMSwitch vmmq -NetAdapterName $AdapterNames
$switchProperties = Get-VMSwitch
CheckDefaultValues $switchProperties $True $False 8

Connect-VMNetworkAdapter -VMName $VmName -SwitchName vmmq
$AdapterProperties = Get-VMNetworkAdapter -VMName $VmName
CheckValues $AdapterProperties $True $False 8

if ($WithTraffic) {
Write-Host "Verify vRSS spreading on 8 procs."
Pause
}

Set-VMNetworkAdapter -VMName $VmName -VmmqQueuePairs 6
Set-VMNetworkAdapter -VMName $VmName -VmmqEnabled $True
$AdapterProperties = Get-VMNetworkAdapter -VMName $VmName
CheckValues $AdapterProperties $True $True 6

if ($WithTraffic) {
Write-Host "verify that VM is VMMQ spreading on 6 procs."
Pause
}

Set-VMNetworkAdapter -VMName $VmName -VmmqQueuePairs 4
Set-VMNetworkAdapter -VMName $VmName -VmmqEnabled $False
$AdapterProperties = Get-VMNetworkAdapter -VMName $VmName
CheckValues $AdapterProperties $True $False 4

Disconnect-VMNetworkAdapter -VMName $VmName
Connect-VMNetworkAdapter -VMName $VmName -SwitchName vmmq
$AdapterProperties = Get-VMNetworkAdapter -VMName $VmName
CheckValues $AdapterProperties $True $False 4

if ($WithTraffic) {
Write-Host "Verify that VM is vRSS spreading on 4 procs"
Pause
}

Set-VMNetworkAdapter -VMName $VmName -VmmqQueuePairs 16
$AdapterProperties = Get-VMNetworkAdapter -VMName $VmName
CheckValues $AdapterProperties $True $False 8


$switchProperties = Get-VMSwitch
CheckDefaultValues $switchProperties $True $False 8

Set-VMSwitch -Name vmmq -DefaultQueueVmmqQueuePairs 6
Set-VMSwitch -Name vmmq -DefaultQueueVmmqEnabled $True
$switchProperites = Get-VMSwitch
CheckDefaultValues $switchProperties $True $True 6

if ($WithTraffic) {
Write-Host "Verify that default queue is VMMQ spreading on 6 procs"
Pause
}

Set-VMSwitch -Name vmmq -DefaultQueueVmmqQueuePairs 4
Set-VMSwitch -Name vmmq -DefaultQueueVmmqEnabled $False
$switchProperites = Get-VMSwitch
CheckDefaultValues $switchProperites $True $False 4

Set-VMSwitch -name vmmq -DefaultQueueVmmqQueuePairs 16
$switchProperites = Get-VMSwitch
CheckDefaultValues $switchProperties $True $False 8

if ($WithTraffic) {
Write-Host "Verify that default queue is vRSS spreading on 8 procs"
Pause
}

Set-NetAdapterAdvancedProperty $AdapterNames -RegistryKeyword "*NumRssQueues" -RegistryValue 8
Set-NetAdapterAdvancedProperty $AdapterNames -RegistryKeyword "*MaxRssProcessors" -RegistryValue 8
$AdapterProperties = Get-VMNetworkAdapter -VMName $VmName
CheckValues $AdapterProperties $True $False 8
$switchProperites = Get-VMSwitch
CheckDefaultValues $switchProperties $True $False 8

if ($WithTraffic) {
Write-Host "Verify vRSS spreading on 8 procs."
Pause
}

Set-VMNetworkAdapter -VMName $VmName -VmmqEnabled $True
$AdapterProperties = Get-VMNetworkAdapter -VMName $VmName
CheckValues $AdapterProperties $True $True 8
Set-VMSwitch -Name vmmq -DefaultQueueVmmqEnabled $True
$switchProperties = Get-VMSwitch
CheckDefaultValues $switchProperties $True $True 8

Set-NetAdapterAdvancedProperty $AdapterNames -RegistryKeyword "*RssOnHostVPorts" -RegistryValue 0
$AdapterProperties = Get-VMNetworkAdapter -VMName $VmName
CheckValues $AdapterProperties $True $False 8
$switchProperties = Get-VMSwitch
CheckDefaultValues $switchProperties $True $False 8

Set-VMNetworkAdapter -VMName $VmName -VmmqQueuePairs 8
Set-VMSwitch -Name vmmq -DefaultQueueVmmqQueuePairs 8
Set-NetAdapterAdvancedProperty $AdapterNames -RegistryKeyword "*RssOnHostVPorts" -RegistryValue 1
$AdapterProperties = Get-VMNetworkAdapter -VMName $VmName
CheckValues $AdapterProperties $True $True 8
$switchProperties = Get-VMSwitch
CheckDefaultValues $switchProperties $True $True 8

Set-NetAdapterAdvancedProperty $AdapterNames -RegistryKeyword "*NumRssQueues" -RegistryValue 4
Set-NetAdapterAdvancedProperty $AdapterNames -RegistryKeyword "*MaxRssProcessors" -RegistryValue 4
$AdapterProperties = Get-VMNetworkAdapter -VMName $VmName
CheckValues $AdapterProperties $True $True 4
$switchProperties = Get-VMSwitch
CheckDefaultValues $switchProperties $True $True 4

if ($WithTraffic) {
Write-Host "Verify VMMQ spreading on 4 procs"
Pause
}

#
# return things back to original settings
#
Set-VMNetworkAdapter -VMName $VmName -VmmqQueuePairs 16
Set-VMSwitch -Name vmmq -DefaultQueueVmmqQueuePairs 16
Set-VMNetworkAdapter -VMName $VmName -VmmqEnabled $False
Set-VMSwitch -Name vmmq -DefaultQueueVmmqEnabled $False
Set-NetAdapterAdvancedProperty $AdapterNames -RegistryKeyword "*NumRssQueues" -RegistryValue 8
Set-NetAdapterAdvancedProperty $AdapterNames -RegistryKeyword "*MaxRssProcessors" -RegistryValue 8
$AdapterProperties = Get-VMNetworkAdapter -VMName $VmName
CheckValues $AdapterProperties $True $False 8
$switchProperties = Get-VMSwitch
CheckDefaultValues $switchProperties $True $False 8


#
# Now do multiple settings at once
#
Set-VMNetworkAdapter -VMName $VmName -VrssEnabled $True -VmmqEnabled $False -VmmqQueuePairs 4
Set-VMSwitch vmmq -DefaultQueueVrssEnabled $True -DefaultQueueVmmqEnabled $False -DefaultQueueVmmqQueuePairs 4
$AdapterProperties = Get-VMNetworkAdapter -VMName $VmName
CheckValues $AdapterProperties $True $False 4
$switchProperties = Get-VMSwitch
CheckDefaultValues $switchProperties $True $False 4

if ($WithTraffic) {
Write-Host "Verify vRSS spreading on 4 procs"
Pause
}

Set-VMNetworkAdapter -VMName $VmName -VrssEnabled $True -VmmqEnabled $True -VmmqQueuePairs 4
Set-VMSwitch vmmq -DefaultQueueVrssEnabled $True -DefaultQueueVmmqEnabled $True -DefaultQueueVmmqQueuePairs 4
$AdapterProperties = Get-VMNetworkAdapter -VMName $VmName
CheckValues $AdapterProperties $True $True 4
$switchProperties = Get-VMSwitch
CheckDefaultValues $switchProperties $True $True 4

if ($WithTraffic) {
Write-Host "Verify VMMQ spreading on 4 procs"
Pause
}

Set-VMNetworkAdapter -VMName $VmName -VrssEnabled $True -VmmqEnabled $False -VmmqQueuePairs 8
Set-VMSwitch vmmq -DefaultQueueVrssEnabled $True -DefaultQueueVmmqEnabled $False -DefaultQueueVmmqQueuePairs 8
$AdapterProperties = Get-VMNetworkAdapter -VMName $VmName
CheckValues $AdapterProperties $True $False 8
$switchProperties = Get-VMSwitch
CheckDefaultValues $switchProperties $True $False 8

#
# Do some flags only
#
Set-VMNetworkAdapter -VMName $VmName -VrssEnabled $True -VmmqQueuePairs 4
Set-VMSwitch vmmq -DefaultQueueVrssEnabled $True -DefaultQueueVmmqQueuePairs 4
$AdapterProperties = Get-VMNetworkAdapter -VMName $VmName
CheckValues $AdapterProperties $True $False 4
$switchProperties = Get-VMSwitch
CheckDefaultValues $switchProperties $True $False 4

Set-VMNetworkAdapter -VMName $VmName -VrssEnabled $True -VmmqEnabled $False
Set-VMSwitch vmmq -DefaultQueueVrssEnabled $True -DefaultQueueVmmqEnabled $False
Set-VMNetworkAdapter -VMName $VmName -VrssEnabled $True -VmmqEnabled $True
Set-VMSwitch vmmq -DefaultQueueVrssEnabled $True -DefaultQueueVmmqEnabled $True
$AdapterProperties = Get-VMNetworkAdapter -VMName $VmName
CheckValues $AdapterProperties $True $True 4
$switchProperties = Get-VMSwitch
CheckDefaultValues $switchProperties $True $True 4

if ($WithTraffic) {
Write-Host "Verify VMMQ spreading on 4 procs"
Pause
}

Set-VMNetworkAdapter -VMName $VmName -VrssEnabled $True -VmmqEnabled $False
Set-VMSwitch vmmq -DefaultQueueVrssEnabled $True -DefaultQueueVmmqEnabled $False
Set-VMNetworkAdapter -VMName $VmName -VrssEnabled $True -VmmqQueuePairs 8
Set-VMSwitch vmmq -DefaultQueueVrssEnabled $True -DefaultQueueVmmqQueuePairs 8
$AdapterProperties = Get-VMNetworkAdapter -VMName $VmName
CheckValues $AdapterProperties $True $False 8
$switchProperties = Get-VMSwitch
CheckDefaultValues $switchProperties $True $False 8

if ($WithTraffic) {
Write-Host "verify vRSS spreading on 4 procs"
Pause
}

#
# Toggle VRSS settings
#
Set-VMNetworkAdapter -VMName $VmName -VrssEnabled $False -VmmqEnabled $True
Set-VMSwitch vmmq -DefaultQueueVrssEnabled $False -DefaultQueueVmmqEnabled $True
$AdapterProperties = Get-VMNetworkAdapter -VMName $VmName
CheckValues $AdapterProperties $False $False 1
$switchProperties = Get-VMSwitch
CheckDefaultValues $switchProperties $False $False 1

if ($WithTraffic) {
Write-Host "Verify not spreading"
Pause
}

Set-VMNetworkAdapter -VMName $VmName -VrssEnabled $True
Set-VMSwitch vmmq -DefaultQueueVrssEnabled $True
$AdapterProperties = Get-VMNetworkAdapter -VMName $VmName
CheckValues $AdapterProperties $True $True 8
$switchProperties = Get-VMSwitch
CheckDefaultValues $switchProperties $True $True 8

if ($WithTraffic) {
Write-Host "Verify VMMQ spreading on 8 procs"
Pause
}


Set-NetAdapterAdvancedProperty $AdapterNames -RegistryKeyword "*RssOnHostVPorts" -RegistryValue 0
Set-VMNetworkAdapter -VMName $VmName -VrssEnabled $False -VmmqEnabled $True
Set-VMSwitch vmmq -DefaultQueueVrssEnabled $False -DefaultQueueVmmqEnabled $True
$AdapterProperties = Get-VMNetworkAdapter -VMName $VmName
CheckValues $AdapterProperties $False $False 1
$switchProperties = Get-VMSwitch
CheckDefaultValues $switchProperties $False $False 1

Set-VMNetworkAdapter -VMName $VmName -VrssEnabled $True
Set-VMSwitch vmmq -DefaultQueueVrssEnabled $True -DefaultQueueVmmqEnabled $True
$AdapterProperties = Get-VMNetworkAdapter -VMName $VmName
CheckValues $AdapterProperties $True $False 8
$switchProperties = Get-VMSwitch
CheckDefaultValues $switchProperties $True $False 8

Set-NetAdapterAdvancedProperty $AdapterNames -RegistryKeyword "*RssOnHostVPorts" -RegistryValue 1
$AdapterProperties = Get-VMNetworkAdapter -VMName $VmName
CheckValues $AdapterProperties $True $True 8
$switchProperties = Get-VMSwitch
CheckDefaultValues $switchProperties $True $True 8

Set-VMNetworkAdapter -VMName $VmName -VrssEnabled $False
Set-VMSwitch vmmq -DefaultQueueVrssEnabled $False
$AdapterProperties = Get-VMNetworkAdapter -VMName $VmName
CheckValues $AdapterProperties $False $False 1
$switchProperties = Get-VMSwitch
CheckDefaultValues $switchProperties $False $False 1

Set-VMNetworkAdapter -VMName $VmName -VmmqQueuePairs 4
Set-VMSwitch vmmq -DefaultQueueVmmqQueuePairs 4
$AdapterProperties = Get-VMNetworkAdapter -VMName $VmName
CheckValues $AdapterProperties $False $False 1
$switchProperties = Get-VMSwitch
CheckDefaultValues $switchProperties $False $False 1

if ($WithTraffic) {
Write-Host "Verify not spreading"
Pause
}

Set-VMNetworkAdapter -VMName $VmName -VmmqQueuePairs 4 -VrssEnabled $True
Set-VMSwitch vmmq -DefaultQueueVmmqQueuePairs 4 -DefaultQueueVrssEnabled $True
$AdapterProperties = Get-VMNetworkAdapter -VMName $VmName
CheckValues $AdapterProperties $True $True 4
$switchProperties = Get-VMSwitch
CheckDefaultValues $switchProperties $True $True 4

if ($WithTraffic) {
Write-Host "Verify VMMQ spreading on 4 procs"
Pause
}

Set-VMNetworkAdapter -VMName $VmName -VmmqQueuePairs 16 -VrssEnabled $True -VmmqEnabled $False
Set-VMSwitch vmmq -DefaultQueueVmmqQueuePairs 16 -DefaultQueueVrssEnabled $True -DefaultQueueVmmqEnabled $False
$AdapterProperties = Get-VMNetworkAdapter -VMName $VmName
CheckValues $AdapterProperties $True $False 8
$switchProperties = Get-VMSwitch
CheckDefaultValues $switchProperties $True $False 8

Write-Host "`nTest setting queues to 1`n"

#
#
# Test setting num queues to 1
#
Set-VMNetworkAdapter -VMName $VmName -VmmqQueuePairs 1
Set-VMSwitch vmmq -DefaultQueueVmmqQueuePairs 1
$AdapterProperties = Get-VMNetworkAdapter -VMName $VmName
CheckValues $AdapterProperties $False $False 1
$switchProperties = Get-VMSwitch
CheckDefaultValues $switchProperties $False $False 1

Set-VMNetworkAdapter -VMName $VmName -VmmqQueuePairs 4
Set-VMSwitch vmmq -DefaultQueueVmmqQueuePairs 4
$AdapterProperties = Get-VMNetworkAdapter -VMName $VmName
CheckValues $AdapterProperties $True $False 4
$switchProperties = Get-VMSwitch
CheckDefaultValues $switchProperties $True $False 4

Set-VMNetworkAdapter -VMName $VmName -VmmqQueuePairs 16 -VrssEnabled $True -VmmqEnabled $True
Set-VMSwitch vmmq -DefaultQueueVmmqQueuePairs 16 -DefaultQueueVrssEnabled $True -DefaultQueueVmmqEnabled $True
$AdapterProperties = Get-VMNetworkAdapter -VMName $VmName
CheckValues $AdapterProperties $True $True 8
$switchProperties = Get-VMSwitch
CheckDefaultValues $switchProperties $True $True 8

Set-VMNetworkAdapter -VMName $VmName -VmmqQueuePairs 1 -VrssEnabled $True -VmmqEnabled $True
Set-VMSwitch vmmq -DefaultQueueVmmqQueuePairs 1 -DefaultQueueVrssEnabled $True -DefaultQueueVmmqEnabled $True
$AdapterProperties = Get-VMNetworkAdapter -VMName $VmName
CheckValues $AdapterProperties $False $False 1
$switchProperties = Get-VMSwitch
CheckDefaultValues $switchProperties $False $False 1

Set-VMNetworkAdapter -VMName $VmName -VmmqQueuePairs 8 -VrssEnabled $True -VmmqEnabled $True
Set-VMSwitch vmmq -DefaultQueueVmmqQueuePairs 8 -DefaultQueueVrssEnabled $True -DefaultQueueVmmqEnabled $True
$AdapterProperties = Get-VMNetworkAdapter -VMName $VmName
CheckValues $AdapterProperties $True $True 8
$switchProperties = Get-VMSwitch
CheckDefaultValues $switchProperties $True $True 8

Set-VMNetworkAdapter -VMName $VmName -VmmqQueuePairs 8 -VrssEnabled $True -VmmqEnabled $False
Set-VMSwitch vmmq -DefaultQueueVmmqQueuePairs 8 -DefaultQueueVrssEnabled $True -DefaultQueueVmmqEnabled $False
$AdapterProperties = Get-VMNetworkAdapter -VMName $VmName
CheckValues $AdapterProperties $True $False 8
$switchProperties = Get-VMSwitch
CheckDefaultValues $switchProperties $True $False 8

Set-VMNetworkAdapter -VMName $VmName -VmmqQueuePairs 1 -VmmqEnabled $True
Set-VMSwitch vmmq -DefaultQueueVmmqQueuePairs 1 -DefaultQueueVmmqEnabled $True
$AdapterProperties = Get-VMNetworkAdapter -VMName $VmName
CheckValues $AdapterProperties $False $False 1
$switchProperties = Get-VMSwitch
CheckDefaultValues $switchProperties $False $False 1

Set-VMNetworkAdapter -VMName $VmName -VmmqQueuePairs 8
Set-VMSwitch vmmq -DefaultQueueVmmqQueuePairs 8
$AdapterProperties = Get-VMNetworkAdapter -VMName $VmName
CheckValues $AdapterProperties $True $True 8
$switchProperties = Get-VMSwitch
CheckDefaultValues $switchProperties $True $True 8

Set-VMNetworkAdapter -VMName $VmName -VmmqQueuePairs 1 -VmmqEnabled $True
Set-VMSwitch vmmq -DefaultQueueVmmqQueuePairs 1 -DefaultQueueVmmqEnabled $True
$AdapterProperties = Get-VMNetworkAdapter -VMName $VmName
CheckValues $AdapterProperties $False $False 1
$switchProperties = Get-VMSwitch
CheckDefaultValues $switchProperties $False $False 1

Set-VMNetworkAdapter -VMName $VmName -VmmqQueuePairs 8 -VrssEnabled $False
Set-VMSwitch vmmq -DefaultQueueVmmqQueuePairs 8 -DefaultQueueVrssEnabled $False
$AdapterProperties = Get-VMNetworkAdapter -VMName $VmName
CheckValues $AdapterProperties $False $False 1
$switchProperties = Get-VMSwitch
CheckDefaultValues $switchProperties $False $False 1

Set-VMNetworkAdapter -VMName $VmName -VmmqQueuePairs 1 -VrssEnabled $True
Set-VMSwitch vmmq -DefaultQueueVmmqQueuePairs 1 -DefaultQueueVrssEnabled $True
$AdapterProperties = Get-VMNetworkAdapter -VMName $VmName
CheckValues $AdapterProperties $False $False 1
$switchProperties = Get-VMSwitch
CheckDefaultValues $switchProperties $False $False 1

Set-VMNetworkAdapter -VMName $VmName -VmmqQueuePairs 4
Set-VMSwitch vmmq -DefaultQueueVmmqQueuePairs 4
$AdapterProperties = Get-VMNetworkAdapter -VMName $VmName
CheckValues $AdapterProperties $True $True 4
$switchProperties = Get-VMSwitch
CheckDefaultValues $switchProperties $True $True 4

Set-VMNetworkAdapter -VMName $VmName -VmmqQueuePairs 16 -VmmqEnabled $False
Set-VMSwitch vmmq -DefaultQueueVmmqQueuePairs 16 -DefaultQueueVmmqEnabled $False
$AdapterProperties = Get-VMNetworkAdapter -VMName $VmName
CheckValues $AdapterProperties $True $False 8
$switchProperties = Get-VMSwitch
CheckDefaultValues $switchProperties $True $False 8

Write-Host "`nTest completed successfully`n"