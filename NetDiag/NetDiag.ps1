

function PerfCounters {
    $Cnts = (Get-Counter -ListSet *mellanox*).paths
    Get-Counter -Counter $Cnts -ErrorAction SilentlyContinue | out-file -Encoding ascii $RootDir\MLXstats.txt
}

function DetailNetAdapter {
    # Each adapter has adapter specific directory
    ForEach($Adapter in Get-NetAdapter) {
        $CurrIndex   = $Adapter.IfIndex
        $DirName     = "IfIndex_" + $CurrIndex
        $DetailFile  = "Detail.txt"

        New-Item -ItemType directory -Path $DirName

        cd $DirName
        Get-NetAdapter -Ifindex $CurrIndex | fl * | out-file -Encoding ascii -Append $DetailFile
        cd ..
    }
}

function EnvDestroy {
    If (Test-Path $RootDir) {
        Remove-Item $RootDir -Recurse
    }
}

#function EnvCreate([String] $RootDir) {
function EnvCreate {
    New-Item -ItemType directory -Path $RootDir
    cd $RootDir

    $RootFile="Summary.txt"
    $Command = "Get-NetAdapter | out-file -Encoding ascii -Append $RootFile"


    $CommandMirror = "PS > " + $Command
    Echo $CommandMirror | out-file -Encoding ascii -Append $RootFile
    Invoke-Expression $Command
}

function Cleanup {
    cd $Base
}

function Main {
    # Starting path
    $Base=$PWD  

    # Workspace
    $RootDir="C:\Users\ocardona\Desktop\Test"

    EnvDestroy

    EnvCreate

    DetailNetAdapter

    Cleanup
}

#Entry Point
Main