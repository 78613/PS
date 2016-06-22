
# Clear error buffer
$error.clear()

# Do something risky
$result = Get-NetAdapterStatistics -InterfaceDescription 133

# On error, throw an exception
if($error[0] -ne $null) { 
    throw "Error: $error[0]" 
}

# If you get this far, $result is safe to use
Write-Output $result
