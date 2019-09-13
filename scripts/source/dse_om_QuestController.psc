ScriptName dse_om_QuestController extends Quest

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Bool Property DebugMode = TRUE Auto

ReferenceAlias Property PlayerRef Auto
Outfit Property OutfitNone Auto

Message Property MessageHello Auto
Message Property MessageOutfitChooseCondition1 Auto
Message Property MessageOutfitChooseCondition2 Auto

Keyword Property LocationHome Auto
Keyword Property LocationCity Auto

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

Function Hello(Actor Who)
{show the main menu.}

	Int Result = self.MessageHello.Show()

	If(Result == 0)
		self.MenuActorOutfitEquip(Who)
	ElseIf(Result == 1)
		self.MenuActorOutfitEdit(Who)
	ElseIf(Result == 2)
		self.MenuActorOutfitCreate(Who)
	ElseIf(Result == 3)
		self.MenuActorOutfitCopy(Who)
	ElseIf(Result == 4)
		self.MenuActorOutfitDelete(Who)
	EndIf

	Return
EndFunction

Function MenuActorOutfitCreate(Actor Who)
{help the player create a new outfit.}

	Int Result = self.MessageOutfitChooseCondition1.Show()

	If(Result == 0)
		self.MenuActorOutfitCreateLocationBased(Who)
	ElseIf(Result == 1)
		self.MenuActorOutfitCreateLocationTyped(Who)
	ElseIf(Result == 2)
		self.MenuActorOutfitCreateGeneral(Who)
	EndIf

	Return
EndFunction

Function MenuActorOutfitEdit(Actor Who)
{help the player choose an outfit to edit.}

	String OutfitName = self.MenuActorOutfitList(Who)

	If(OutfitName != "")
		self.ActorSetCurrentOutfit(Who,OutfitName)
		self.ActorRegister(Who)
	EndIf

	Return
EndFunction

Function MenuActorOutfitCopy(Actor Who)
{help the player choose an outfit to copy.}

	Actor From
	String OutfitName

	Debug.MessageBox("Select who to copy from...")
	Utility.Wait(0.10)
	From = self.MenuRegisteredActorList()
	OutfitName = self.MenuActorOutfitList(Who)

	self.ActorCopyOutfit(From,Who,OutfitName,TRUE)

	Return
EndFunction

Function MenuActorOutfitDelete(Actor Who)
{help the player choose an outfit to delete.}

	Debug.MessageBox("TODO: Delete Outfit")

	Return
EndFunction

Function MenuActorOutfitCreateGeneral(Actor Who)
{help the player make a general outfit.}

	String OutfitName

	Debug.MessageBox("Enter Outfit Name...")
	Utility.Wait(0.10)
	OutfitName = self.MenuTextInput()

	self.ActorSetCurrentOutfit(Who,OutfitName)
	self.ActorRegister(Who)

	Return
EndFunction

Function MenuActorOutfitCreateLocationBased(Actor Who)
{help the player make a location based outfit.}

	Debug.MessageBox("TODO: Make Location Based Outfit")

	Return
EndFunction

Function MenuActorOutfitCreateLocationTyped(Actor Who)
{help the player make a location typed outfit.}
	
	Int Result = self.MessageOutfitChooseCondition2.Show()

	If(Result == 0)
		Debug.MessageBox("TODO: Make Home Outfit")
	ElseIf(Result == 1)
		Debug.MessageBox("TODO: Make City Outfit")
	ElseIf(Result == 2)
		Debug.MessageBox("TODO: Make Adventuring Outfit")
	EndIf

	Return
EndFunction

Function MenuActorOutfitEquip(Actor Who, Bool FreeShit=FALSE)
{ask player what outfit to wear.}

	String OutfitName = self.MenuActorOutfitList(Who)

	If(OutfitName != "")
		self.PrintDebug(Who.GetDisplayName() + " equipping outfit: " + OutfitName)
		self.ActorSetCurrentOutfit(Who,OutfitName)
		self.ActorRefreshOutfit(Who,FreeShit,FALSE)
	EndIf

	Return
EndFunction

Actor Function MenuRegisteredActorList()
{display a list of registered actors and return the selected one.}

	Form[] ActorList = StorageUtil.FormListToArray(NONE,self.KeyActorList)
	String[] NameList = Utility.CreateStringArray(ActorList.Length)
	Int Iter = 0
	Int Result = -1

	While(Iter < ActorList.Length)
		NameList[Iter] = (ActorList[Iter] As Actor).GetDisplayName()
		Iter += 1
	EndWhile

	Result = self.MenuFromList(NameList)

	If(Result == -1)
		Return NONE
	EndIf

	Return (ActorList[Result] As Actor)
EndFunction

String Function MenuActorOutfitList(Actor Who)
{display a list of outfits and return the name of the selected one.}

	Int Result = 0
	String[] OutfitList = StorageUtil.StringListToArray(Who,self.KeyOutfitList)

	If(OutfitList.Length == 0)
		Debug.MessageBox(Who.GetDisplayName() + " has no outfits yet.")
		Return ""
	EndIf

	;;;;;;;;

	Result = self.MenuFromList(OutfitList)

	If(Result < 0)
		Return ""
	EndIf

	Return OutfitList[Result]
EndFunction

Int Function MenuFromList(String[] Items)
{display a list from an array of items.}

	UIListMenu Menu = UIExtensions.GetMenu("UIListMenu",TRUE) as UIListMenu
	Int NoParent = -1
	Int Iter = 0
	Int Result

	;;;;;;;;

	While(Iter < Items.Length)
		Menu.AddEntryItem(Items[Iter],NoParent)
		Iter += 1
	EndWhile

	;;;;;;;;

	Menu.OpenMenu()
	Result = Menu.GetResultInt()

	If(Result < 0)
		Return -1
	EndIf

	Return Result
EndFunction

String Function MenuTextInput()
{rename this animal.}

	String Result

	UIExtensions.InitMenu("UITextEntryMenu")
	UIExtensions.OpenMenu("UITextEntryMenu")
	Result = UIExtensions.GetMenuResultString("UITextEntryMenu")

	Return Result
EndFunction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Function ActorRegister(Actor Who)

	Bool ShouldCancel = !Who.IsPlayerTeammate()
	String OutfitName = self.ActorGetCurrentOutfit(Who)

	;; register the outfit if first time use on actor.
	self.ActorSetCurrentOutfit(Who,OutfitName)

	If(Who != self.PlayerRef.GetActorRef())
		;; tell them to stop dressing.
		Who.SetOutfit(self.OutfitNone,FALSE)
		Who.SetOutfit(self.OutfitNone,TRUE)

		;; open their inventory.
		Who.SetPlayerTeammate(TRUE)
		Who.OpenInventory(TRUE)
		Utility.Wait(0.20)

		If(ShouldCancel)
			Who.SetPlayerTeammate(FALSE)
		EndIf
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
	Form Weapon1
	Form Weapon2
	;; Form[] ListedWeapons
	String OutfitKey = self.ActorGetCurrentKey(Who)
	Bool Block = !(Who == self.PlayerRef.GetActorRef())

	Slot = 30
	While(Slot <= 61)
		Item = Who.GetEquippedArmorInSlot(Slot)

		If(Item != None)
			If(!StorageUtil.FormListHas(Who,OutfitKey,Item))
				Who.UnequipItem(Item,Block,TRUE)
			EndIf
		EndIf

		Slot += 1
	EndWhile

	;;ListedWeapons = StorageUtil.FormListFilterByType(Who,OutfitKey,41)
	;;If(ListedWeapons != None && ListedWeapons.Length > 0)
		Weapon1 = Who.GetEquippedWeapon(FALSE)
		Weapon2 = Who.GetEquippedWeapon(TRUE)

		If(Weapon1 != None && !StorageUtil.FormListHas(Who,OutfitKey,Weapon1))
			Who.UnequipItem(Weapon1,TRUE,TRUE)
		EndIf

		If(Weapon2 != None && !StorageUtil.FormListHas(Who,OutfitKey,Weapon2))
			Who.UnequipItem(Weapon2,TRUE,TRUE)
		EndIf
	;;EndIf

	Return
EndFunction

Function ActorEquipListedArmour(Actor Who, Bool FreeShit=FALSE)

	Int ItemCount
	Form Item
	String OutfitKey = self.ActorGetCurrentKey(Who)
	Bool Lock = !(Who == self.PlayerRef.GetActorRef())

	ItemCount = StorageUtil.FormListCount(Who,OutfitKey)
	self.PrintDebug("ActorRefreshOutfit " + OutfitKey + " " + Who.GetDisplayName() + " " + ItemCount + " Items")	

	While(ItemCount > 0)
		ItemCount -= 1
		Item = StorageUtil.FormListGet(Who,OutfitKey,ItemCount)

		If(Item != None)
			If((Item As Armor != None) || (Item As Weapon != None))
				If(FreeShit || Who.GetItemCount(Item) > 0)
					Who.EquipItem(Item,Lock,TRUE)
				EndIf
			EndIf
		EndIf
	EndWhile

	Return
EndFunction

Function ActorStoreOutfit(Actor Who)

	Int Slot
	Form Worn
	Form Weapon1
	Form Weapon2
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

	Weapon1 = Who.GetEquippedWeapon(FALSE)
	Weapon2 = Who.GetEquippedWeapon(TRUE)

	If(Weapon1 != None)
		StorageUtil.FormListAdd(Who,OutfitKey,Weapon1,FALSE)
	EndIf

	If(Weapon2 != None && Weapon2 != Weapon1)
		StorageUtil.FormListAdd(Who,OutfitKey,Weapon2,FALSE)
	EndIf

	self.PrintDebug(Who.GetDisplayName() + " " + OutfitKey + " has " + StorageUtil.FormListCount(Who,OutfitKey))
	Return
EndFunction

Function ActorRefreshOutfit(Actor Who, Bool FreeShit=FALSE, Bool Hard=FALSE)

	String OutfitKey = self.ActorGetCurrentKey(Who)

	;; quick cleanup. should remove armour bits that have been uninstalled
	;; from the game mid playthrough.
	StorageUtil.FormListRemove(Who,OutfitKey,None,TRUE)

	If(Hard)
		Who.UnequipAll()
		self.ActorEquipListedArmour(Who,FreeShit)
	Else
		self.ActorUnequipUnlistedArmour(Who)
		self.ActorEquipListedArmour(Who,FreeShit)
	EndIf

	Return
EndFunction

Bool Function ActorHasOutfit(Actor Who, String OutfitName)

	Int Result = StorageUtil.StringListFind(Who,self.KeyOutfitList,OutfitName)

	If(Result >= 0)
		Return TRUE
	EndIf

	Return FALSE
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

Function ActorCopyOutfit(Actor From, Actor To, String OutfitName, Bool FreeShit=FALSE)

	String OutfitKey = self.KeyItemList + "[" + OutfitName + "]"
	Form[] ItemList = StorageUtil.FormListToArray(From,OutfitKey)

	self.ActorSetCurrentOutfit(To,OutfitName)

	StorageUtil.FormListClear(To,OutfitKey)
	StorageUtil.FormListCopy(To,OutfitKey,ItemList)

	self.ActorRefreshOutfit(To,FreeShit)

	Return
EndFunction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Function Print(String Msg)
{print messages to the notification tray.}

	Debug.Notification("[DOM] " + Msg)
	Return
EndFunction

Function PrintDebug(String Msg)
{print messages to the console and log.}

	If(self.DebugMode)
		MiscUtil.PrintConsole("[DOM] " + Msg)
		Debug.Trace("[DOM] " + Msg)
	EndIf

	Return
EndFunction
