clear

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
         [parameter(Mandatory=$true)]  [Int]    $Line
        ,[parameter(Mandatory=$true)]  [String] $File
        ,[parameter(Mandatory=$true)]  [String] $Func
        ,[parameter(Mandatory=$false)] [String] $Message
    )
    Write-Host -ForegroundColor Red $([String] $Line + ": " + $File + ": " + $Func + "()  " + $Message)
}

function TraceWarn {
    [CmdletBinding()]
    Param(
         [parameter(Mandatory=$true)]  [Int]    $Line
        ,[parameter(Mandatory=$true)]  [String] $File
        ,[parameter(Mandatory=$true)]  [String] $Func
        ,[parameter(Mandatory=$false)] [String] $Message
    )
    Write-Host -ForegroundColor Yellow $([String] $Line + ": " + $File + ": " + $Func + "()  " + $Message)
}

function TraceDbg {
    [CmdletBinding()]
    Param(
         [parameter(Mandatory=$true)]  [Int]    $Line
        ,[parameter(Mandatory=$true)]  [String] $File
        ,[parameter(Mandatory=$true)]  [String] $Func
        ,[parameter(Mandatory=$false)] [String] $Message
    )
    Write-Host -ForegroundColor Green $([String] $Line + ": " + $File + ": " + $Func + "()  " + $Message)
}
#endregion


function Test {   
    Echo "==== Unit Test"
    Get-LineNumber; Get-FileName; Get-FunctionName

    Echo "==== Direct Call subfuncs"
    Write-Host $((Get-LineNumber) + ": " + (Get-Filename) + ": " + (Get-FunctionName) +"()")

    Echo "==== Desired API"
    TraceDbg (Get-LineNumber) (Get-Filename) (Get-FunctionName)  "Debug message"
    TraceWarn (Get-LineNumber) (Get-Filename) (Get-FunctionName) "Warning message"
    TraceErr (Get-LineNumber) (Get-Filename) (Get-FunctionName)  "Error message"
}

function Main {
    Test
} Main #Entry Point