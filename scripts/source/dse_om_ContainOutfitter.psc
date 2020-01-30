ScriptName dse_om_ContainOutfitter extends ObjectReference

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dse_om_QuestController Property Main Auto

Actor Property Who Auto Hidden

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Event OnLoad()
{when this container is placed in the game world.}

	;; figure out who we wanted to shove this into.

	self.Who = Main.StorageFormGet(None,Main.KeyOutfitTarget) as Actor
	Main.StorageFormClear(None,Main.KeyOutfitTarget)

	;; put the destionations shit in the box.

	self.TakeFromDest()

	;; open the box.

	self.SetActorOwner(Game.GetPlayer().GetActorBase())
	self.Activate(Game.GetPlayer())
	Return
EndEvent

Event OnItemAdded(Form Type, Int Count, ObjectReference What, ObjectReference Source)
{when an item is added to this container.}


	Return
EndEvent

Event OnItemRemoved(Form Type, int Count, ObjectReference What, ObjectReference Dest)
{when an item is removed from this container.}

	Return
EndEvent

Event OnActivate(ObjectReference What)
{when this chest is opened.}

	Int CountType
	Int CountItem
	Int TypeVal

	Int IterType
	Int IterItem

	Form Type
	Int Iter
	String OutfitKey = Main.ActorGetCurrentKey(Who)

	;; trick to lock up this processing until we close the menu.

	Main.PrintDebug("Outfitting " + self.Who.GetDisplayName() + "...")
	Utility.Wait(0.1)
	self.Who.UnequipAll()
	Utility.Wait(0.1)
	self.Who.UnequipAll()
	Utility.Wait(0.1)

	;; process the contents.

	CountType = self.GetNumItems()
	CountItem = 0
	IterType = 0

	;; empty the current outfit of its items.

	Main.StorageFormListClear(Who,OutfitKey)

	;; push the outfit items into the outfit storage. then transfer the
	;; one that is in the container to the destination actor.

	While(self.GetNthForm(0) != NONE)
		Type = self.GetNthForm(0)
		Main.StorageFormListAdd(self.Who,OutfitKey,Type,FALSE)
		self.RemoveItem(Type,1,TRUE,self.Who)
	EndWhile

	;; then let the outfit system itself do the equipping work.

	Main.ActorRefreshOutfit(self.Who)

	;; and clean ourselves up.

	self.Disable()
	self.Delete()
	Return
EndEvent

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Function TakeFromDest()

	Int Iter = 0
	Form Worn = NONE
	Form Weapon1 = self.Who.GetEquippedWeapon(FALSE)
	Form Weapon2 = self.Who.GetEquippedWeapon(TRUE)

	;; loop through equipped armours and make a note of them.
	;; we don't want to start taking things off before we notice what
	;; is there because followers start re-equipping their best in slot
	;; when you fuck with their inventory.

	Iter = 30
	While(Iter <= 61)
		Worn = self.Who.GetEquippedArmorInSlot(Iter)
		If(Worn != NONE)
			Main.StorageFormListAdd(self.Who,Main.KeyItemListTemp,Worn)
		EndIf
		Iter += 1
	EndWhile

	If(Weapon1 != NONE)
		Main.StorageFormListAdd(self.Who,Main.KeyItemListTemp,Weapon1)
	EndIf

	If(Weapon2 != None)
		Main.StorageFormListAdd(self.Who,Main.KeyItemListTemp,Weapon2)
	EndIf

	;; now go through everything we noticed and put all those things in the
	;; box. the follower will likely start requipping random things during
	;; this. that is fine.

	Iter = Main.StorageFormListCount(self.Who,Main.KeyItemListTemp)
	While(Iter > 0)
		Iter -= 1

		Worn = Main.StorageFormListGet(self.Who,Main.KeyItemListTemp,Iter)
		self.Who.RemoveItem(Worn,1,TRUE,self)
	EndWhile

	Main.StorageFormListClear(self.Who,Main.KeyItemListTemp)
	self.Who.UnequipAll()

	Return
EndFunction
