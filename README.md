# Get-EvtxScripts

NOTE: There's probably a better alternative out there somewhere, but this is here. 

Get-EvtxScripts creates a list of unique ScriptBlock IDs from 4104 Events. Then it will iterate through each event to identify the messages related to that ID, 
and rebuild each script in the correct order.

These scripts won't be fully functioning (working on that now in my free time), but running this will prevent you from manually
rebuilding the larger ps1 files by hand.
