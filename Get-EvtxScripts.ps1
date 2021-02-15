function Get-EvtxScripts(){
<#    
    .NOTES
    FunctionName: Get-EvtxScripts
    Created By: Twitter: @_Wra7h, Github: Wra7h

    .SYNOPSIS
    Rebuild scripts from a Microsoft-Windows-PowerShell/Operational's 4104 events

    .PARAMETER Log
    Specify a Microsoft-Windows-PowerShell/Operational log not stored in C:\Windows\System32\winevt\Logs.

    .PARAMETER Output
    Specify the directory to send the scripts

    .PARAMETER ScriptBlockID
    Specify a certain scriptblock to rebuild.
    
    .EXAMPLE
    Get-EvtxScripts -Output .\testfolder

    Rebuild all scripts and write scripts to C:\Users\user\testfolder\

    .EXAMPLE
    Get-EvtxScripts -Output .\testfolder -ScriptBlockID xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

    Rebuild the specified ScriptBlockID and write file to C:\Users\user\testfolder\

    .EXAMPLE
    Get-EvtxScripts -Output .\testfolder -ScriptBlockID xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx,yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy

    Rebuild the specified ScriptBlockIDs and write file to C:\Users\user\testfolder\
    
    #>

    param(
        [parameter (Mandatory=$true)][ValidateNotNullOrEmpty()][string]$Output,
        [parameter (Mandatory=$false)][ValidateNotNullOrEmpty()][string]$Log,
        [parameter (Mandatory=$false)][ValidateNotNullOrEmpty()][string[]]$ScriptBlockID
    )
 
    if (!(test-path $Output)){
        Write-host "`r`n[*] Creating $Output" -ForegroundColor Yellow
        New-Item $Output -ItemType Directory -ea 0

    }
    $4104ScriptIDs=@()
    if ($Log -ne ""){
        Write-Host -ForegroundColor Yellow "`r`n[*] Grabbing 4104s from: " -NoNewline
        Write-host -ForegroundColor Cyan $Log
    } else {
        Write-Host -ForegroundColor Yellow "`r`n[*] Grabbing 4104s from: " -NoNewline
        Write-Host -ForegroundColor Cyan "Microsoft-Windows-PowerShell/Operational"
    }
    if ($Log -ne ""){
        $4104s= Get-WinEvent -Path $Log | ? Id -EQ 4104 
    } elseif($Log -eq ""){
        $4104s= Get-WinEvent -LogName Microsoft-Windows-PowerShell/Operational | ? Id -EQ 4104
    }
    $4104SplitNewLine= ($4104s | select -ExpandProperty Message | Out-String).Split("`r`n")
    foreach ($line in $4104SplitNewLine){
        if ($line -match ".*ScriptBlock\ ID:\ .*"){
            $4104ScriptIDs += ($line.Split(":")[1]).TrimStart(" ")
        }
    }
    $idCount=1
    foreach ($id in ($4104ScriptIDs | sort -Unique)){
        if ($ScriptBlockID -ne $null){
            if ($id -notin $ScriptBlockID){
                continue
            }
        }
        $n=1
        $scriptBlockCount = $4104ScriptIDs | Group-Object | ? Name -eq $id | select -ExpandProperty Count
        $scriptSet = $4104s | ? {($_.Message -match ".*\ of\ $scriptBlockCount") -and ($_.Message -match ".*$id.*")}
        $fullMessage=""
        for ($i=1;$i -le $scriptBlockCount;$i++){
            Write-Progress -Activity ("Building: $id.ps1 (Script $idCount of "+($4104ScriptIDs | sort -Unique).Count +")") -Status "Added block $n of $scriptBlockCount" -PercentComplete (($n/$scriptBlockCount)*100)
            $eventMessage = $scriptSet | ? {($_.Message -match ".*\($i\ of\ $scriptBlockCount") -and ($_.Message -match ".*$id.*")} | select -ExpandProperty Message
            if ($eventMessage -ne $null){
                if ($fullMessage -eq ""){
                    $fullMessage = (($eventMessage).Split("`r`n")[1..(($eventMessage).Split("`r`n").Count - 7)] | Out-String)
                } elseif($fullMessage -ne ""){                    
                    $midmessage = (($fullMessage.Split("`r`n")[-3]+($eventMessage).Split("`r`n")[2]) | Out-String)
                    $fullMessage = (($fullMessage -split "`r`n" | select -SkipLast 3 | Out-String) + $midmessage)
                    $fullMessage += (($eventMessage).Split("`r`n")[3..(($eventMessage).Split("`r`n").Count - 7)] | Out-String)
                }   
            }
            $n++
        }
        Set-Content -Value $fullMessage "$Output\$id.ps1" -ErrorAction SilentlyContinue
        $idCount++
    }
}
