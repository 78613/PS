
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



function test {

    Try {
        #Get-NetAdapter -Name Ethernets
        Get-NetAdapterStatistics -Name Ethernet       
        #TraceDbg  (Get-LineNumber) (Get-Filename) (Get-FunctionName)

        #if ($_.PSMessageDetails)
        #echo $_
    } 
    Catch {
        TraceWarn  (Get-LineNumber) (Get-Filename) (Get-FunctionName) "Debug message"
        echo $_.ErrorCategory_Message
        #echo $_.Exception.GetType().FullName, $_.Exception.Message
        #echo $_.Exception | format-list -force
        #TraceErr  (Get-LineNumber) (Get-Filename) (Get-FunctionName)
    } 
    Finally {
        #echo $_.Exception | format-list -force
        #Write-Host "Hello"    
        #$MyInvocation | Format-List -property
        TraceDbg  (Get-LineNumber) (Get-Filename) (Get-FunctionName)
    }
}

function Main {
    Set-PSDebug -Trace 1 -Step #-Strict
    clear
    Test
} Main #Entry Point
