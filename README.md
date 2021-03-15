# Get-EvtxScripts

Get-EvtxScripts creates a list of unique ScriptBlock IDs from 4104 Events. Then it will iterate through each event to identify the messages related to that ID, 
and rebuild each script/module in the correct order.

To-Dos:  
~~These rebuilt scripts and modules won't be fully functioning (working on that now in my free time), but running this will prevent you from manually
rebuilding the larger files by hand.~~ (Updated 14 Feb 2021)

Updates:  
- 15 Feb 2021: Added -ScriptBlockID so a user can specify a certain script/scripts to rebuild.
