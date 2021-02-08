function Get-EvtxScripts(){
<#    
    .NOTES
    FunctionName: Get-EvtxScripts
    Created By: Twitter: @_Wra7h, Github: Wra7h

    .SYNOPSIS
    Rebuild Unique scripts from a Microsoft-Windows-PowerShell/Operational's 4104s

    .PARAMETER Log
    Specify a Microsoft-Windows-PowerShell/Operational log not stored in C:\Windows\System32\winevt\Logs.

    .PARAMETER Output
    Specify the directory to send the scripts
    
    .EXAMPLE
    Get-EvtxScripts -Output .\testfolder

    Rebuild all scripts and write scripts to C:\Users\<user>\testfolder\
    
    #>

    param(
        [parameter (Mandatory=$false)][ValidateNotNullOrEmpty()][string]$Log,
        [parameter (Mandatory=$true)][ValidateNotNullOrEmpty()][string]$Output

    )
 
    if (!(test-path $Output)){
        Write-host "`r`n[*] Creating $output" -ForegroundColor Yellow
        New-Item $Output -ItemType Directory -ea 0

    }

    $scriptIds=@()
    if ($Log -ne ""){
        Write-Host -ForegroundColor Yellow "`r`n[*] Grabbing 4104s from: $Log"
    } else {
        Write-Host -ForegroundColor Yellow "`r`n[*] Grabbing 4104s from: Microsoft-Windows-PowerShell/Operational"
    }
    if ($Log -ne ""){
        $4104s= Get-WinEvent -Path $Log | ? Id -EQ 4104 
    } elseif($Log -eq ""){
        $4104s= Get-WinEvent -LogName Microsoft-Windows-PowerShell/Operational | ? Id -EQ 4104
    }

    $4104Split= ($4104s | select -ExpandProperty Message | Out-String).Split("`r`n")

    foreach ($line in $4104Split){
        if ($line -match ".*ScriptBlock\ ID:\ .*"){
            $scriptIds += ($line.Split(":")[1]).TrimStart(" ")
        }
    }

    if ($verbose){
        $scriptIds | Group-Object | select Name,Count | Sort-Object -Descending Count
    }
    $idcount=1
    foreach ($id in ($scriptIds | sort -Unique)){
        $n=1
        $ScriptBlockCount = $scriptIds | Group-Object | ? Name -eq $id | select -ExpandProperty Count
        $scriptset = $4104s | ? {($_.Message -match ".*\ of\ $ScriptBlockCount") -and ($_.Message -match ".*$id.*")}
        for ($i=1;$i -le $ScriptBlockCount;$i++){
            Write-Progress -Activity ("Building: $id.ps1 (Script $idcount of "+($scriptIds | sort -Unique).Count +")") -Status "Added block $n of $ScriptBlockCount" -PercentComplete (($n/$ScriptBlockCount)*100)
            $message = $scriptset | ? {($_.Message -match ".*\($i\ of\ $ScriptBlockCount") -and ($_.Message -match ".*$id.*")} | select -ExpandProperty Message
            if ($message -ne $null){
                $message = (($message).Split("`r`n")[1..(($message).Split("`r`n").Count - 4)])
                Add-Content -Value $message "$Output\$id.ps1" -ErrorAction SilentlyContinue
            }
            $n++
        }
        $idcount++
    }
}
