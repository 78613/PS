



#region Script Diagnostic Functions
function Get-LineNumber {
    [String] $MyInvocation.ScriptLineNumber
    #$MyInvocation.ScriptLineNumber
}

function Get-FileName {
    $MyInvocation.ScriptName
}

function Get-FunctionName {
    (Get-Variable MyInvocation -Scope 1).Value.MyCommand.Name
}


<# 
 .Synopsis
  Trace

 .Description
  Displays a trace message to terminal with Line, File, Function, and optional Message.

 .Parameter Line
  Line Number

 .Parameter File
  Filename

 .Parameter Func
  Function Name

 .Example
    # trace with message
    TraceDbg  (Get-LineNumber) (Get-Filename) (Get-FunctionName) "Debug message"

 .Example
    # trace without message
    TraceDbg  (Get-LineNumber) (Get-Filename) (Get-FunctionName)
#>
function TraceErr {
    [CmdletBinding()]
    Param(
         [parameter(Mandatory=$true)]  [ValidateRange(1, [UInt32]::MaxValue)] [UInt32] $Line
        ,[parameter(Mandatory=$true)]  [ValidateNotNullOrEmpty()]             [String] $File
        ,[parameter(Mandatory=$true)]  [ValidateNotNullOrEmpty()]             [String] $Func
        ,[parameter(Mandatory=$false)] [ValidateNotNullOrEmpty()]             [String] $Message
    )
    Write-Host -ForegroundColor Red $([String] $Line + ": " + $File + ": " + $Func + "()  " + $Message)
}
#export-modulemember -function TraceErr

function TraceWarn {
    [CmdletBinding()]
    Param(
         [parameter(Mandatory=$true)]  [ValidateRange(1, [UInt32]::MaxValue)] [UInt32] $Line
        ,[parameter(Mandatory=$true)]  [ValidateNotNullOrEmpty()]             [String] $File
        ,[parameter(Mandatory=$true)]  [ValidateNotNullOrEmpty()]             [String] $Func
        ,[parameter(Mandatory=$false)] [ValidateNotNullOrEmpty()]             [String] $Message
    )
    Write-Host -ForegroundColor Yellow $([String] $Line + ": " + $File + ": " + $Func + "()  " + $Message)
}
#export-modulemember -function TraceWarn

function TraceDbg {
    [CmdletBinding()]
    Param(
         [parameter(Mandatory=$true)]  [ValidateRange(1, [UInt32]::MaxValue)] [UInt32] $Line
        ,[parameter(Mandatory=$true)]  [ValidateNotNullOrEmpty()]             [String] $File
        ,[parameter(Mandatory=$true)]  [ValidateNotNullOrEmpty()]             [String] $Func
        ,[parameter(Mandatory=$false)] [ValidateNotNullOrEmpty()]             [String] $Message
    )
    Write-Host -ForegroundColor Green $([String] $Line + ": " + $File + ": " + $Func + "()  " + $Message)
}
#export-modulemember -function TraceDbg
#endregion

function traceTest {
    TraceDbg  (Get-LineNumber) (Get-Filename) (Get-FunctionName)
    TraceWarn (Get-LineNumber) (Get-Filename) (Get-FunctionName)
    TraceErr  (Get-LineNumber) (Get-Filename) (Get-FunctionName)
}


function ExecCommand {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true)] [String] $Command, 
        [parameter(Mandatory=$true)] [String] $Output
    )

    #Write-Output "Command = $Command " 
    #Write-Output "Output  = $Output "

    # Mirror Prompt info
    $prompt = $env:username + " @ " + $env:computername + ":"
    Write-Output $prompt | out-file -Encoding ascii -Append $Output

    # Mirror Command to execute
    $cmdMirror = "PS " + (Convert-Path .) + "> " + $Command
    Write-Output $cmdMirror | out-file -Encoding ascii -Append $Output

    # Execute Command and redirect to file.  Useful so users know what to run..
    #Invoke-Expression $Command | Out-File -Encoding ascii -Append $Output
    
    #Invoke-Expression $Command | Tee-Object -file $Output
    Invoke-Expression $Command | Out-File -Encoding ascii -Append $Output
} 

function TestCommand {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [String] $Command
    )

    Try {
        # pre-execution cleanup
        $error.clear()

        # Instrument the validate command for silent output
        $tmp = "$Command -erroraction 'silentlycontinue' | Out-Null"
        #$tmp = "$Command | Out-Null"
        #Write-Host $tmp
        Invoke-Expression $tmp 2> $Null
        #$error | Format-List -Property * -Force
        #$error | Get-Member
        #($error).exception
        #if ($error[0] -ne $null) { 
        #if (($error).exception -ne $null) {
        if ($error -ne $null) {
            #Write-Host -ForegroundColor Yellow "Here"
            throw "Error: $error[0]" 
        }

        # This is only reachable in success case
        Write-Host -ForegroundColor Green "$Command"
        $script:Err = 0
    }Catch {
        Write-Warning "<UNSUPPORTED>`n$Command"
        $script:Err = -1
    }Finally {
        # post-execution cleanup to avoid false positives
        $error.clear()
    }
}

# Powershell cmdlets have inconsistent implementations in command error handling.  This
# function performs a validation of the command prior to formal execution and logs said
# commands in a file suffixed with Not-Supported.txt.
function TestSafeExecCommand {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [String] $Command,
        [parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [String] $Output
    )
    
    # Use temp output to reflect the failed command, otherwise execute the command.
    $out = $Output
    TestCommand -Command ($cmd)
    if ($script:Err -ne 0) {
        $out = $out.Replace(".txt",".UNSUPPORTED.txt")
        Write-Output "$Command" | Out-File -Encoding ascii -Append $out
    }else {
        ExecCommand -Command ($Command) -Output $out
    }
}

function Main {
    #Set-PSDebug -Trace 1 -Step #-Strict
    Set-PSDebug -off
    clear

    $user    = [Environment]::UserName
    $baseDir = "C:\Users\$user\Desktop\Test\"
    $file    = "Get-NetAdapterStatistics.txt"
    $out     = (Join-Path -Path $baseDir -ChildPath $file)


    Write-Output "Control:"
    Write-Output "================"
    # Test the command to work around various limitations in inconsistent cmdlet errors
    #$cmd = "Get-NetAdapterStatistics -Name Secondary" 
    #TestCommand -Command ($cmd)
    #ExecCommand -Command ($cmd) -Output $out

    foreach($nic in Get-NetAdapter) {
        $name    = $nic.Name
        #$cmd     = "Get-NetAdapterStatistics -Name ""$name"" | Format-List -Property *"
        $columns = 4096

        #$cmd = "Get-NetAdapterStatistics -Name ""$name"""
        #$cmd = "Get-NetAdapterStatistics -Name ""$name"""
        $cmd = "Get-NetAdapterStatistics -Name ""$name"""
        #$cmd = "Get-NetAdapterStatistics -Name ""$name"" | Out-String -Width $columns" # width is the problem
        #$cmd = "Get-NetAdapterStatistics -Name ""$name"" | Out-String -Width $columns" # width is the problem
        TestSafeExecCommand -Command ($cmd) -Output $out

    }

    Write-Output "Test:"
    Write-Output "================"
    foreach($nic in Get-NetAdapter) {
        $name    = $nic.Name
        $cmd     = "Get-NetAdapterStatistics -Name ""$name"""
        $columns = 4096
        [String []] $cmds = "Get-NetAdapterStatistics -Name ""$name"" | Out-String -Width $columns",
                            "Get-NetAdapterStatistics -Name ""$name"" | Format-List  -Property *",
                            "Get-NetAdapterStatistics -Name ""$name"" | Format-Table -Property * -AutoSize | Out-String -Width $columns"
        ForEach($cmd in $cmds) {
            TestSafeExecCommand -Command ($cmd) -Output $out
        }   
    }
} Main #Entry Point

