# Get-EvtxScripts

Get-EvtxScripts creates a list of unique ScriptBlock IDs from 4104 Events. Then it will iterate through each event to identify the messages related to that ID, 
and rebuild each script/module in the correct order.

## Basic Usage:  
PS C:\\> . .\Get-EvtxScripts.ps1  
PS C:\\> Get-EvtxScripts -Output .\OutDir  
--OR--  
PS C:\\> Get-EvtxScripts -Output .\OutDir -Log .\Users\User\Desktop\OfflineLogs\Microsoft-Windows-PowerShell%4Operational.evtx  

### Updates:  
- 15 Feb 2021: Added -ScriptBlockID so a user can specify a certain script/scripts to rebuild.
- 26 Jun 2021: Added -JobCount and parallel build support to reduce total time required for builds.  
