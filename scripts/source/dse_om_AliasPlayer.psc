ScriptName dse_om_AliasPlayer extends ReferenceAlias

dse_om_QuestController Property Main Auto

Event OnPlayerLoadGame()
	Main.UpdateLoadedActors()
	Return
EndEvent


Event OnLocationChange(Location LocPrev, Location LocNew)
	Main.UpdateLoadedActors()
	Return
EndEvent

