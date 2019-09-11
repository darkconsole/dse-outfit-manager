ScriptName dse_om_QuestController extends Quest

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReferenceAlias Property PlayerRef Auto
Outfit Property OutfitNone Auto

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

String Property KeyActorList = "DSEOM.ActorList" AutoReadOnly Hidden
String Property KeyActorOutfit = "DSEOM.ActorOutfit" AutoReadOnly Hidden
String Property KeyItemList = "DSEOM.ActorItemList" AutoReadOnly Hidden
String Property KeyOutfitList = "DSEOM.ActorOutfitList" AutoReadOnly Hidden

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Event OnInit()

	Return
EndEvent

Event OnGainLOS(Actor Viewer, ObjectReference Who)

	Int Count = 0

	;;While(!Who.Is3dLoaded() && Count < 10)
	;;	Count += 1
	;;	Utility.Wait(0.5)
	;;EndWhile

	self.ActorRefreshOutfit(Who As Actor)
	Return
EndEvent

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Function UpdateLoadedActors()

	Int Iter
	Actor Who
	Actor Player = Game.GetPlayer()

	;; quick cleanup. should magic stop tracking actors that were destroyed or
	;; uninstalled from the players game.
	StorageUtil.FormListRemove(NONE,self.KeyActorList,NONE,TRUE)

	Iter = StorageUtil.FormListCount(NONE,self.KeyActorList)
	While(Iter > 0)
		Iter -= 1
		Who = StorageUtil.FormListGet(NONE,self.KeyActorList,Iter) As Actor

		If(Who != None && Who.Is3dLoaded())
			self.UnregisterForLOS(Player,Who)
			self.RegisterForSingleLOSGain(Player,Who)
		EndIf
	EndWhile

	Return
EndFunction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Function ActorRegister(Actor Who)

	Bool ShouldCancel = !Who.IsPlayerTeammate()
	String OutfitName = self.ActorGetCurrentOutfit(Who)

	;; tell them to stop dressing.
	Who.SetOutfit(self.OutfitNone,FALSE)
	Who.SetOutfit(self.OutfitNone,TRUE)

	;; register the outfit if first time use on actor.
	self.ActorSetCurrentOutfit(Who,OutfitName)

	;; open their inventory.
	Who.SetPlayerTeammate(TRUE)
	Who.OpenInventory(TRUE)
	Utility.Wait(0.25)

	If(ShouldCancel)
		Who.SetPlayerTeammate(FALSE)
	EndIf

	StorageUtil.FormListAdd(NONE,self.KeyActorList,Who,FALSE)
	self.ActorStoreOutfit(Who)
	self.ActorRefreshOutfit(Who)

	Return
EndFunction

Function ActorUnregister(Actor Who)
	
	String OutfitKey = self.ActorGetCurrentKey(Who)

	StorageUtil.FormListRemove(NONE,self.KeyActorList,Who,TRUE)
	StorageUtil.FormListClear(Who,OutfitKey)
	Return
EndFunction

Function ActorUnequipUnlistedArmour(Actor Who)

	Form Item
	Int Slot
	String OutfitKey = self.ActorGetCurrentKey(Who)

	Slot = 30
	While(Slot <= 61)
		Item = Who.GetEquippedArmorInSlot(Slot)

		If(Item != None)
			If(!StorageUtil.FormListHas(Who,OutfitKey,Item))
				Who.UnequipItem(Item,TRUE,TRUE)
			EndIf
		EndIf

		Slot += 1
	EndWhile

	Return
EndFunction

Function ActorEquipListedArmour(Actor Who)

	Int ItemCount
	Form Item
	Armor Atem
	String OutfitKey = self.ActorGetCurrentKey(Who)

	ItemCount = StorageUtil.FormListCount(Who,OutfitKey)
	Debug.Notification("[DOM] ActorRefreshOutfit " + OutfitKey + " " + Who.GetDisplayName() + " " + ItemCount + " Items")	

	While(ItemCount > 0)
		ItemCount -= 1
		Item = StorageUtil.FormListGet(Who,OutfitKey,ItemCount)

		If(Item != None)
			Atem = Item as Armor
			If((Atem != None) && (Atem.GetNumArmorAddons() > 0))
				Who.EquipItem(Atem,TRUE,TRUE)
			EndIf
		EndIf
	EndWhile

	Return
EndFunction

Function ActorStoreOutfit(Actor Who)

	Int Slot
	Form Worn
	String OutfitKey = self.ActorGetCurrentKey(Who)

	;;;;;;;;

	StorageUtil.FormListClear(Who,OutfitKey)

	Slot = 30
	While(Slot <= 61)
		Worn = Who.GetEquippedArmorInSlot(Slot)

		If(Worn != NONE)
			StorageUtil.FormListAdd(Who,OutfitKey,Worn,FALSE)
		EndIf

		Slot += 1
	EndWhile

	Debug.Notification(Who.GetDisplayName() + " " + OutfitKey + " has " + StorageUtil.FormListCount(Who,OutfitKey))
	Return
EndFunction

Function ActorRefreshOutfit(Actor Who)

	String OutfitKey = self.ActorGetCurrentKey(Who)

	;; quick cleanup. should remove armour bits that have been uninstalled
	;; from the game mid playthrough.
	StorageUtil.FormListRemove(Who,OutfitKey,None,TRUE)

	self.ActorEquipListedArmour(Who)
	self.ActorUnequipUnlistedArmour(Who)

	Return
EndFunction

String Function ActorGetCurrentOutfit(Actor Who)

	Return StorageUtil.GetStringValue(Who,self.KeyActorOutfit,"Default")
EndFunction

Function ActorSetCurrentOutfit(Actor Who, String OutfitName)

	StorageUtil.SetStringValue(Who,self.KeyActorOutfit,OutfitName)
	Storageutil.StringListAdd(Who,self.KeyOutfitList,OutfitName,FALSE)

	Return
EndFunction

String Function ActorGetCurrentKey(Actor Who)

	String OutfitName = self.ActorGetCurrentOutfit(Who)
	String Output = self.KeyItemList + "[" + OutfitName + "]"

	Return Output
EndFunction
