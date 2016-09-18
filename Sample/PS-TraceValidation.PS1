# Execute this command on the PS windows to enable execution
#   Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

Import-Module 'C:\DELETEME\PS-Trace .PSM1'

function Main {
    clear
    #Trace-UnitTest

    Trace-Dbg  (Trace-Line) (Trace-File) (Trace-Func) "Debug message"
    Trace-Warn (Trace-Line) (Trace-File) (Trace-Func) "Warning message"
    Trace-Err  (Trace-Line) (Trace-File) (Trace-Func) "Error message"

    #(Get-Variable MyInvocation -Scope 0).Value.MyCommand.Name

} Main #Entry Pointu