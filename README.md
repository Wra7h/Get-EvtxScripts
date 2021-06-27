# Get-EvtxScripts

Get-EvtxScripts creates a list of unique ScriptBlock IDs from 4104 Events. Then it will iterate through each event to identify the messages related to that ID, 
and rebuild each script/module in the correct order.

## Basic Usage:  
PS C:\\> . .\Get-EvtxScripts.ps1  
PS C:\\> Get-EvtxScripts -Output .\OutDir  
  
More Examples:  
PS C:\\> Get-Help Get-EvtxScripts -detailed  

## Specifying ScriptBlock IDs (Optional):  
1. Command line:  
PS C:\\> Get-EvtxScripts -Output .\OutDir -JobCount 5 -ScriptBlockID xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx,yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy  
  
2. Pass from a text file:  
 \- One ID per line \-  
PS C:\\> Get-EvtxScripts -Output .\OutDir -JobCount 5 -ScriptBlockID (Get-content .\scriptblocks.txt).Split("\`r\`n")  

 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\- Multiple IDs comma-separated \-  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;PS C:\\> Get-EvtxScripts -Output .\OutDir -JobCount 5 -ScriptBlockID (Get-content .\scriptblocks.txt).Split(",")  



### Updates:  
- 15 Feb 2021: Added -ScriptBlockID so a user can specify a certain script/scripts to rebuild.
- 26 Jun 2021: Added -JobCount and parallel build support to reduce total time required for builds.  
