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

function DbgTrace {
    [CmdletBinding()]
    Param(
         [parameter(Mandatory=$true)] [Int]    $Line
        ,[parameter(Mandatory=$true)] [String] $File
        ,[parameter(Mandatory=$true)] [String] $Func
    )
    Write-Host $([String] $Line + ": " + $File + ": " + $Func + "()")
}
#endregion


function Test {   
    Echo "==== Unit Test"
    Get-LineNumber; Get-FileName; Get-FunctionName

    Echo "==== Direct Call subfuncs"
    Write-Host $((Get-LineNumber) + ": " + (Get-Filename) + ": " + (Get-FunctionName) +"()")

    Echo "==== Desired API"
    DbgTrace (Get-LineNumber) (Get-Filename) (Get-FunctionName)
}

function Main {
    Test
} Main #Entry Point
