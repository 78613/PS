

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



function Test {   
    Echo "==== Unit Test"
    Get-LineNumber; Get-FileName; Get-FunctionName

    Echo "==== Direct Call subfuncs"
    Write-Host $((Get-LineNumber) + ": " + (Get-Filename) + ": " + (Get-FunctionName) +"()")

    Echo "==== Desired API"
    TraceDbg  (Get-LineNumber) (Get-Filename) (Get-FunctionName) "Debug message"
    TraceWarn (Get-LineNumber) (Get-Filename) (Get-FunctionName) "Warning message"
    TraceErr  (Get-LineNumber) (Get-Filename) (Get-FunctionName) "Error message"
}

function Main {
    clear
    Test
} Main #Entry Point