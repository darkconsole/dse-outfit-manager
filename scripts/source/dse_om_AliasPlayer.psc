ScriptName dse_om_AliasPlayer extends ReferenceAlias

dse_om_QuestController Property Main Auto

Event OnPlayerLoadGame()
	PO3_SKSEfunctions.a_UnregisterForCellFullyLoaded(self)
	PO3_SKSEfunctions.a_RegisterForCellFullyLoaded(self)

	Main.UpdateLoadedActors()
	Return
EndEvent

Event __OnCellLoad()

	;; the thing about this event, and the wiki seems to be right about this, is
	;; that it does not "fire reliable" as in like, if the cell was already in
	;; memory it will not fire. i can demonstrate this by walking in and out of
	;; my house in whiterun. it'll fire the first two load screens but not the
	;; third. however, when i was walking in and out of whiterun crossing the
	;; worldspace barrier, it always fired for me.

	Main.PrintDebug("OnCellLoad")
	Utility.Wait(0.20)
	Main.UpdateLoadedActors()
	Return
EndEvent

Event OnCellFullyLoaded(Cell Where)

	If(Where == Game.GetPlayer().GetParentCell())
		Main.PrintDebug("OnCellFullyLoaded " + Where.GetName())
		Main.UpdateLoadedActors()
	EndIf

	Return
EndEvent

Event OnLocationChange(Location LocPrev, Location LocNew)

	If(LocNew != None)
		Main.PrintDebug("OnLocationChange " + LocNew.GetName())
	Else
		Main.PrintDebug("OnLocationChange to Nowhere")
	EndIf

	Main.UpdateLoadedActors()
	Return
EndEvent

;/*
Event OnCellAttach()
	Main.Print("OnCellAttached")
	Return
EndEvent

Event OnCellDetach()
	Main.Print("OnCellDetached")
	Return
EndEvent

Event OnAttachedToCell()
	Main.Print("OnAttachedToCell")
	Return
EndEvent

Event OnNiNodeUpdate(Actor Who)
	Main.Print("OnNiNodeUpdate")
	Return
EndEvent
*/;
