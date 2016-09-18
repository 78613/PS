

# Execute this command on the PS windows to enable execution
#   Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
#

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
function Trace-Err {
    [CmdletBinding()]
    Param(
         [parameter(Mandatory=$true)]  [ValidateRange(1, [UInt32]::MaxValue)] [UInt32] $Line
        ,[parameter(Mandatory=$true)]  [ValidateNotNullOrEmpty()]             [String] $File
        ,[parameter(Mandatory=$true)]  [ValidateNotNullOrEmpty()]             [String] $Func
        ,[parameter(Mandatory=$false)] [ValidateNotNullOrEmpty()]             [String] $Message
    )
    Write-Host -ForegroundColor Red $([String] $Line + ": " + $File + ": " + $Func + "()  " + $Message)
}

function Trace-Warn {
    [CmdletBinding()]
    Param(
         [parameter(Mandatory=$true)]  [ValidateRange(1, [UInt32]::MaxValue)] [UInt32] $Line
        ,[parameter(Mandatory=$true)]  [ValidateNotNullOrEmpty()]             [String] $File
        ,[parameter(Mandatory=$true)]  [ValidateNotNullOrEmpty()]             [String] $Func
        ,[parameter(Mandatory=$false)] [ValidateNotNullOrEmpty()]             [String] $Message
    )
    Write-Host -ForegroundColor Yellow $([String] $Line + ": " + $File + ": " + $Func + "()  " + $Message)
}

function Trace-Dbg {
    [CmdletBinding()]
    Param(
         [parameter(Mandatory=$true)]  [ValidateRange(1, [UInt32]::MaxValue)] [UInt32] $Line
        ,[parameter(Mandatory=$true)]  [ValidateNotNullOrEmpty()]             [String] $File
        ,[parameter(Mandatory=$true)]  [ValidateNotNullOrEmpty()]             [String] $Func
        ,[parameter(Mandatory=$false)] [ValidateNotNullOrEmpty()]             [String] $Message
    )
    Write-Host -ForegroundColor Green $([String] $Line + ": " + $File + ": " + $Func + "()  " + $Message)
}

#export-modulemember -function 'Trace-*'
#endregion



function Trace-UnitTest {   
    Echo "==== Unit Test"
    Get-LineNumber; Get-FileName; Get-FunctionName

    Echo "==== Direct Call subfuncs"
    Write-Host $((Get-LineNumber) + ": " + (Get-Filename) + ": " + (Get-FunctionName) +"()")

    Echo "==== Desired API"
    Trace-Dbg  (Get-LineNumber) (Get-Filename) (Get-FunctionName) "Debug message"
    Trace-Warn (Get-LineNumber) (Get-Filename) (Get-FunctionName) "Warning message"
    Trace-Err  (Get-LineNumber) (Get-Filename) (Get-FunctionName) "Error message"
}

function Main {
    clear
    Trace-UnitTest
} Main #Entry Point