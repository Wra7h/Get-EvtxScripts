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
    .PARAMETER JobCount
    Specify the max number of jobs to run simultaneously (Default: 3)
    
    .EXAMPLE
    Get-EvtxScripts -Output .\testfolder -JobCount 10
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
        [parameter (Mandatory=$false)][ValidateNotNullOrEmpty()][string[]]$ScriptBlockID,
        [parameter (Mandatory=$false)][int]$JobCount=3
    )
 
    Write-Host "`r`n"

    if (!(test-path $Output)){
        New-Item $Output -ItemType Directory -ea 0 | Out-Null
        Write-Host "[*] Created Directory: " -ForegroundColor Yellow -NoNewline
        Write-Host $(Convert-Path $Output) -ForegroundColor Cyan
    }

    $4104ScriptIDs=@()
    if ($Log -ne ""){
        Write-Host -ForegroundColor Yellow "[*] Grabbing 4104s from: " -NoNewline
        Write-host -ForegroundColor Cyan $(Convert-Path $Log)
    } else {
        Write-Host -ForegroundColor Yellow "[*] Grabbing 4104s from: " -NoNewline
        Write-Host -ForegroundColor Cyan "Microsoft-Windows-PowerShell/Operational"
    }
    if ($Log -ne ""){
        $4104s= Get-WinEvent -Path $Log | Where-Object Id -EQ 4104 
    } elseif($Log -eq ""){
        $4104s= Get-WinEvent -LogName Microsoft-Windows-PowerShell/Operational | Where-Object Id -EQ 4104
    }
    
    
    #Get Scriptblock IDs from 4104 events
    $4104SplitNewLine= ($4104s | select -ExpandProperty Message | Out-String).Split("`r`n")
    foreach ($line in $4104SplitNewLine){
        if ($line -match ".*ScriptBlock\ ID:\ .*"){
            $4104ScriptIDs += ($line.Split(":")[1]).TrimStart(" ")
        }
    }
    
    Write-Host -ForegroundColor Yellow "[*] Unique ScriptBlock IDs: " -NoNewline
    Write-host -ForegroundColor Cyan ($4104ScriptIDs | sort -Unique).Count


    $index = 0
    while ($index -le ($4104ScriptIDs | sort -Unique).Count){
        Write-Progress -Activity "Queueing Rebuilds: ($index/$(($4104ScriptIDs | sort -Unique).Count))" -Status "$((Get-Job -Name "EvtxScript*").Count) Jobs Queued -- $((Get-ChildItem $Output *.ps1).Count) Jobs Completed" -PercentComplete "$((((Get-ChildItem $Output *.ps1).Count)/$($4104ScriptIDs | sort -Unique).Count) * 100)" -ErrorAction SilentlyContinue
        if ((Get-Job -Name "EvtxScript*" -InformationAction SilentlyContinue).Count -lt $JobCount){
            if ($ScriptBlockID.Count -ne 0){
                if (($4104ScriptIDs | sort -Unique)[$index] -notin $ScriptBlockID){
                    $index++
                    continue
                }
            }
            Start-Job -Name $("EvtxScript" + $index) -ArgumentList $4104s,$4104ScriptIDs,$($4104ScriptIDs | sort -Unique)[$index],$(Convert-path $Output) -ScriptBlock {
                param($events,$ScriptIDs,$id,$Out)
                $scriptBlockCount = $ScriptIDs | Group-Object | Where-Object Name -eq $id | select -ExpandProperty Count
                $scriptSet = $events | Where-Object {($_.Message -match ".*\ of\ $scriptBlockCount") -and ($_.Message -match ".*$id.*")}
                $fullContents=""
                for ($i=1;$i -le $scriptBlockCount;$i++){
                    $eventMessage = $scriptSet | Where-Object {($_.Message -match ".*\($i\ of\ $scriptBlockCount") -and ($_.Message -match ".*$id.*")} | select -ExpandProperty Message
                    if ($eventMessage -ne $null){
                        if ($fullContents -eq ""){
                            $fullContents = (($eventMessage).Split("`r`n")[1..(($eventMessage).Split("`r`n").Count - 7)] | Out-String)
                        } elseif ($fullContents -ne ""){                    
                            $fullContents = (($fullContents -split "`r`n" | select -SkipLast 3 | Out-String) + (($fullContents.Split("`r`n")[-3]+($eventMessage).Split("`r`n")[2]) | Out-String))
                            $fullContents += (($eventMessage).Split("`r`n")[3..(($eventMessage).Split("`r`n").Count - 7)] | Out-String)
                        }   
                    }
                }
                if (($fullContents -ne "") -and ($fullContents -ne $null)){
                    Set-Content -Value $fullContents -Path ($Out+"\\$id.ps1") -ErrorAction SilentlyContinue
                }
            } | Out-Null
            $index++
        } else {
            Get-Job -State Completed | Receive-Job -AutoRemoveJob -Wait
        }
    }

    #Final check to cleanup lingering jobs
    Receive-Job -Name "EvtxScript*" -Wait -AutoRemoveJob -InformationAction SilentlyContinue
    Write-Host "[*] Done!" -ForegroundColor Yellow
}