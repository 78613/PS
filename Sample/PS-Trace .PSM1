function Trace-Line {
    [String] $MyInvocation.ScriptLineNumber
    #$MyInvocation.ScriptLineNumber
}

function Trace-File {
    $MyInvocation.ScriptName
}

function Trace-Func {
    #FIXME:  Major problem here in obtaining the callers function name.  Seems the scope variable specifies depth
    #        thus unknown how to obtainer the function name N-levels deep when called.  Having this in a PSM1 file
    #        seems to complicate the matter.  Need further research into how to get the caller name without 
    #        requiring the caller to use a local function.
    (Get-Variable MyInvocation -Scope 0).Value.MyCommand.Name
}

<# 
 .Synopsis
  Trace

 .Description
  Displays a trace message to terminal with Line, File, Function, and optional Message.

 .Parameter Line
  Line Number

 .Parameter File
  File

 .Parameter Func
  Function Name

 .Example
    # trace with message
    TraceDbg  (Trace-Line) (Trace-File) (Trace-Func) "Debug message"

 .Example
    # trace without message
    TraceDbg  (Trace-Line) (Trace-File) (Trace-Func)
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

function Trace-UnitTest {   
    Echo "==== Unit Test"
    Trace-Line
    Trace-File
    Trace-Func

    Echo "==== Direct Call subfuncs"
    Write-Host $((Trace-Line) + ": " + (Trace-File) + ": " + (Trace-Func) +"()")

    Echo "==== Desired API"
    Trace-Dbg  (Trace-Line) (Trace-File) (Trace-Func) "Debug message"
    Trace-Warn (Trace-Line) (Trace-File) (Trace-Func) "Warning message"
    Trace-Err  (Trace-Line) (Trace-File) (Trace-Func) "Error message"
}


export-modulemember -function 'Trace-*'
