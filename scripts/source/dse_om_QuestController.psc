ScriptName dse_om_QuestController extends Quest

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Bool Property DebugMode = TRUE Auto Hidden
Bool Property CheckRootWorldspaces = TRUE Auto Hidden

ReferenceAlias Property PlayerRef Auto
Outfit Property OutfitNone Auto
Container Property ContainOutfitter Auto

Message Property MessageHello Auto
Message Property MessageOutfitChooseCondition1 Auto
Message Property MessageOutfitChooseCondition2 Auto
Message Property MessageOutfitChooseAuto Auto

Keyword Property LocationHome Auto
Keyword Property LocationCity Auto
Keyword Property LocationTown Auto
Keyword Property ArmorTypeShield Auto

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;/*
the root world space array is a list of all the places that i consider to be
the most outside as you could possibly be. i decided to make this configurable
because while we can trust sse has all the dlc, there are still other mods that
can add new worlds. if those worlds are added to this array the "in cities"
detection for outfits will work slightly better.

the only reason this has to exist is because there is no WorldSpace.GetParent().
if it existed i could test the existence of none to determine how worldly we
are.
*/;

WorldSpace[] Property RootWorldSpaces Auto

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

String Property KeyActorList = "DSEOM.ActorList" AutoReadOnly Hidden
String Property KeyActorOutfit = "DSEOM.ActorOutfit" AutoReadOnly Hidden
String Property KeyItemList = "DSEOM.ActorItemList" AutoReadOnly Hidden
String Property KeyOutfitList = "DSEOM.ActorOutfitList" AutoReadOnly Hidden
String Property KeyOutfitTarget = "DSEOM.ActorOutfitTarget" AutoReadOnly Hidden
String Property KeyItemListTemp = "DSEOM.ActorItemListTemp" AutoReadOnly Hidden
String Property KeyOutfitAuto = "DSEOM.ActorOutfitAuto" AutoReadOnly Hidden
String Property KeyActorLocation = "DSEOM.ActorLocationLast" AutoReadOnly Hidden
String Property KeyActorWorldSpace = "DSEOM.ActorWorldSpaceLast" AutoReadOnly Hidden

String Property KeyOutfitWhenHome = "When: At Home" AutoReadOnly Hidden
String Property KeyOutfitWhenCity = "When: In City" AutoReadOnly Hidden
String Property KeyOutfitWhenWilderness = "When: Adventuring" AutoReadOnly Hidden
String Property KeyOutfitWhere = "Where: " AutoReadOnly Hidden

Int Property AutoSwitchType = 1 AutoReadOnly Hidden
Int Property AutoSwitchLocale = 2 AutoReadOnly Hidden

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Event OnInit()

	Return
EndEvent

Event OnGainLOS(Actor Viewer, ObjectReference Who)

	String Oldfit = self.ActorGetCurrentOutfit(Who As Actor)
	String Newfit = self.ActorTryToSetCurrentOutfitByLocationType(Who As Actor)
	Bool DoWeaps = FALSE

	;;;;;;;;
	
	If(Oldfit != Newfit)
		DoWeaps = TRUE
	EndIf

	;;;;;;;;

	self.ActorRefreshOutfit(Who As Actor, WeapsToo=DoWeaps)
	Return
EndEvent

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Function UpdateLoadedActors()

	Int Iter
	Actor Who
	Actor Player = Game.GetPlayer()

	If(Player.IsInCombat())
		;; anti disruption
		Return
	EndIf

	;; quick cleanup. should magic stop tracking actors that were destroyed or
	;; uninstalled from the players game.
	StorageUtil.FormListRemove(NONE,self.KeyActorList,NONE,TRUE)

	Iter = StorageUtil.FormListCount(NONE,self.KeyActorList)
	While(Iter > 0)
		Iter -= 1
		Who = StorageUtil.FormListGet(NONE,self.KeyActorList,Iter) As Actor

		If(Who != None && Who.Is3dLoaded())
			;; here we use the LOS pick to avoid setting actors in
			;; other zones. like when i told my follower to wait outside in
			;; whiterun she would be flipping outfits still for no reason.
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
	ElseIf(Result == 5)
		self.MenuActorOutfitAuto(Who)
	ElseIf(Result == 6)
		Who.OpenInventory(TRUE)
	EndIf

	Return
EndFunction

Function MenuActorOutfitAuto(Actor Who)
{help the player choose what automatic mode to use.}

	Int Result = self.MessageOutfitChooseAuto.Show()
	Int Value = 0

	;; this could have been shortened just using the result value
	;; but this is written future proofed, if any more options are
	;; added it would not work well that way.

	If(Result == 1)
		Value = self.AutoSwitchType
	ElseIf(Result == 2)
		Value = self.AutoSwitchLocale
	ElseIf(Result == 3)
		Value = self.AutoSwitchType + self.AutoSwitchLocale
	ElseIf(Result == 4)
		Value = -1
	EndIf

	If(Value >= 0)
		self.ActorSetOutfitAuto(Who,Value)
		self.ActorUpdateSet(Who,TRUE)
	ElseIf(Value == -1)
		self.ActorUpdateSet(Who,FALSE)
	EndIf

	Return
EndFunction

Function MenuActorOutfitCreate(Actor Who)
{help the player create a new outfit.}

	Int Result = self.MessageOutfitChooseCondition1.Show()

	If(Result == 0)
		self.MenuActorOutfitCreateGeneral(Who)
	ElseIf(Result == 1)
		self.MenuActorOutfitCreateLocationTyped(Who)
	ElseIf(Result == 2)
		self.MenuActorOutfitCreateLocationBased(Who)
	EndIf

	Return
EndFunction

Function MenuActorOutfitEdit(Actor Who)
{help the player choose an outfit to edit.}

	String OutfitName = self.MenuActorOutfitList(Who)

	If(OutfitName != "")
		If(Who != self.PlayerRef.GetActorRef())
			;; equip the requested edit.
			self.ActorSetCurrentOutfit(Who,OutfitName)
			self.ActorRefreshOutfit(Who,FALSE,FALSE,TRUE)

			;; spawn the outfitter box.
			StorageUtil.SetFormValue(NONE,self.KeyOutfitTarget,Who)
			self.PlayerRef.GetActorRef().PlaceAtMe(self.ContainOutfitter)
		Else
			;; update with currently equipped stuff.
			self.ActorSetCurrentOutfit(Who,OutfitName)
			self.ActorRegister(Who)
			Debug.MessageBox("Outfit \"" + self.ActorGetCurrentOutfit(Who) + "\" has been updated with currently equipped items.")
		EndIf
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

	If(OutfitName != "")
		self.ActorCopyOutfit(From,Who,OutfitName,TRUE)
	EndIf

	Return
EndFunction

Function MenuActorOutfitDelete(Actor Who)
{help the player choose an outfit to delete.}

	String OutfitName = self.MenuActorOutfitList(Who)

	If(OutfitName != "")
		self.ActorDeleteOutfit(Who,OutfitName)
	EndIf

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
	Debug.MessageBox("Outfit \"" + self.ActorGetCurrentOutfit(Who) + "\" has been created from currently equipped items.")

	Return
EndFunction

Function MenuActorOutfitCreateLocationBased(Actor Who)
{help the player make a location based outfit.}

	String LocationName = self.MenuLocationTree(Who)

	If(LocationName == "")
		Return
	EndIf

	self.ActorSetCurrentOutfit(Who,(self.KeyOutfitWhere + LocationName))
	self.ActorRegister(Who)
	Debug.MessageBox("Outfit \"" + self.ActorGetCurrentOutfit(Who) + "\" has been created from currently equipped items.")

	Return
EndFunction

Function MenuActorOutfitCreateLocationTyped(Actor Who)
{help the player make a location typed outfit.}
	
	Int Result = self.MessageOutfitChooseCondition2.Show()

	If(Result == 0)
		self.ActorSetCurrentOutfit(Who,self.KeyOutfitWhenHome)
		self.ActorRegister(Who)
	ElseIf(Result == 1)
		self.ActorSetCurrentOutfit(Who,self.KeyOutfitWhenCity)
		self.ActorRegister(Who)
	ElseIf(Result == 2)
		self.ActorSetCurrentOutfit(Who,self.KeyOutfitWhenWilderness)
		self.ActorRegister(Who)
	EndIf

	Debug.MessageBox("Outfit \"" + self.ActorGetCurrentOutfit(Who) + "\" has been created from currently equipped items.")

	Return
EndFunction

Function MenuActorOutfitEquip(Actor Who, Bool FreeShit=FALSE)
{ask player what outfit to wear.}

	String OutfitName = self.MenuActorOutfitList(Who)

	If(OutfitName != "")
		self.PrintDebug(Who.GetDisplayName() + " equipping outfit: " + OutfitName)
		self.ActorSetCurrentOutfit(Who,OutfitName)
		self.ActorRefreshOutfit(Who,FreeShit,FALSE,TRUE)
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

String Function MenuLocationTree(Actor Who)
{display a the location tree and return the name of the selected one.}

	Int Result = 0
	Int LocationCount = 1
	String[] LocationList
	String LocationName
	Location Here

	;;;;;;;;

	;; determine how deep we need to go.

	Here = Who.GetCurrentLocation()
	While(Here != NONE)
		LocationCount += 1
		Here = PO3_SKSEFunctions.GetParentLocation(Here)
	EndWhile

	;;;;;;;;

	;; then go for it.

	If(LocationCount == 1)
		Debug.MessageBox("You don't appear to be anywhere noteworthy.")
		Return ""
	EndIf

	self.PrintDebug("Creating Location List " + LocationCount + " Long")
	LocationList = Utility.CreateStringArray(LocationCount)
	LocationList[0] = "[Cancel]"

	Here = Who.GetCurrentLocation()
	While(Here != NONE)
		If(Here.GetName() != "")
			LocationName = self.GetLocationName(Here)

			If(PO3_SKSEFunctions.ArrayStringCount(LocationName,LocationList) == 0)
				self.PrintDebug("Adding " + LocationName + " to Location List")
				PO3_SKSEFunctions.AddStringToArray(LocationName,LocationList)
			EndIf
		EndIf
		Here = PO3_SKSEFunctions.GetParentLocation(Here)
	EndWhile

	;;;;;;;;

	Result = self.MenuFromList(LocationList)

	If(Result <= 0)
		Return ""
	EndIf

	Return LocationList[Result]
EndFunction

Int Function MenuFromList(String[] Items, Bool AllowEmpty=FALSE)
{display a list from an array of items.}

	UIListMenu Menu = UIExtensions.GetMenu("UIListMenu",TRUE) as UIListMenu
	Int NoParent = -1
	Int Iter = 0
	Int Result

	self.SortStringList(Items)

	;;;;;;;;

	While(Iter < Items.Length)
		If(Items[Iter] != "" || AllowEmpty)
			Menu.AddEntryItem(Items[Iter],NoParent)
		EndIf
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
		;;Who.SetPlayerTeammate(TRUE)
		;;Who.OpenInventory(TRUE)
		;;Utility.Wait(0.20)

		If(ShouldCancel)
		;;	Who.SetPlayerTeammate(FALSE)
		EndIf
	EndIf

	self.ActorUpdateSet(Who,TRUE)
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

Function ActorUnequipUnlistedArmour(Actor Who, Bool WeapsToo=FALSE)

	Form Item
	Int Slot
	Form Weapon1
	Form Weapon2
	String OutfitKey = self.ActorGetCurrentKey(Who)
	Bool Block = !(Who == self.PlayerRef.GetActorRef())

	;;;;;;;;

	;; if we are using the home or city outfits we will allow weapons to be swapped
	;; out as requested. we only really want to stop the swapping of weapons while
	;; we are adventuring and in combat.

	;;If((OutfitKey == self.KeyOutfitWhenHome) || (OutfitKey == self.KeyOutfitWhenCity))
	;;	WeapsToo = TRUE
	;;EndIf

	;;;;;;;;

	Slot = 30
	While(Slot <= 61)
		Item = Who.GetEquippedArmorInSlot(Slot)

		If(Item != None)
			If(!StorageUtil.FormListHas(Who,OutfitKey,Item))
				If(Item.HasKeywordString("zad_Lockable"))
				ElseIf(Item.HasKeyword(ArmorTypeShield) && !WeapsToo)
				Else
					Who.UnequipItem(Item,Block,TRUE)
				EndIf
			EndIf
		EndIf

		Slot += 1
	EndWhile

	If(WeapsToo)
		Weapon1 = Who.GetEquippedWeapon(FALSE)
		Weapon2 = Who.GetEquippedWeapon(TRUE)

		If(Weapon1 != None && !StorageUtil.FormListHas(Who,OutfitKey,Weapon1))
			Who.UnequipItem(Weapon1,TRUE,TRUE)
		EndIf

		If(Weapon2 != None && !StorageUtil.FormListHas(Who,OutfitKey,Weapon2))
			Who.UnequipItem(Weapon2,TRUE,TRUE)
		EndIf
	EndIf

	Return
EndFunction

Function ActorEquipListedArmour(Actor Who, Bool FreeShit=FALSE, Bool WeapsToo=FALSE)

	Int ItemCount
	Form Item
	String OutfitKey = self.ActorGetCurrentKey(Who)
	Bool Lock = !(Who == self.PlayerRef.GetActorRef())

	ItemCount = StorageUtil.FormListCount(Who,OutfitKey)
	self.PrintDebug("ActorRefreshOutfit " + OutfitKey + " " + Who.GetDisplayName() + " " + ItemCount + " Items")

	;;;;;;;;

	;; if we are using the home or city outfits we will allow weapons to be swapped
	;; out as requested. we only really want to stop the swapping of weapons while
	;; we are adventuring and in combat.

	;;If((OutfitKey == self.KeyOutfitWhenHome) || (OutfitKey == self.KeyOutfitWhenCity))
	;;	WeapsToo = TRUE
	;;EndIf

	;;;;;;;;

	While(ItemCount > 0)
		ItemCount -= 1
		Item = StorageUtil.FormListGet(Who,OutfitKey,ItemCount)

		If(Item != None)
			If((Item As Armor != None) || (Item As Weapon != None && WeapsToo))
				If(FreeShit || Who.GetItemCount(Item) > 0)
					If(Item.HasKeywordString("zad_Lockable"))
					ElseIf(Item.HasKeyword(ArmorTypeShield) && !WeapsToo)
					Else
						Who.EquipItem(Item,Lock,TRUE)
					EndIf
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

Function ActorRefreshOutfit(Actor Who, Bool FreeShit=FALSE, Bool Hard=FALSE, Bool WeapsToo=FALSE)

	String OutfitKey = self.ActorGetCurrentKey(Who)

	;; quick cleanup. should remove armour bits that have been uninstalled
	;; from the game mid playthrough.
	StorageUtil.FormListRemove(Who,OutfitKey,None,TRUE)

	If(Hard)
		Who.UnequipAll()
		self.ActorEquipListedArmour(Who,FreeShit,WeapsToo)
	Else
		self.ActorUnequipUnlistedArmour(Who)
		self.ActorEquipListedArmour(Who,FreeShit,WeapsToo)
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

Int Function ActorGetOutfitAuto(Actor Who)

	Return StorageUtil.GetIntValue(Who,self.KeyOutfitAuto,(self.AutoSwitchType + self.AutoSwitchLocale))
EndFunction

Function ActorSetOutfitAuto(Actor Who, Int What)

	self.PrintDebug("ActorSetOutfitAuto: " + Who.GetDisplayName() + " " + What)

	StorageUtil.SetIntValue(Who,self.KeyOutfitAuto,What)

	Return
EndFunction

Function ActorUpdateSet(Actor Who, Bool Update)

	If(Update)
		StorageUtil.FormListAdd(NONE,self.KeyActorList,Who,FALSE)
		self.PrintDebug("ActorUpdateSet: " + Who.GetDisplayName() + " is being managed.")
	Else
		StorageUtil.FormListRemove(NONE,self.KeyActorList,Who,TRUE)
		self.PrintDebug("ActorUpdateSet: " + Who.GetDisplayName() + " is not managed.")
	EndIf

	Return
EndFunction

Function ActorSetCurrentOutfit(Actor Who, String OutfitName)

	StorageUtil.SetStringValue(Who,self.KeyActorOutfit,OutfitName)
	StorageUtil.StringListAdd(Who,self.KeyOutfitList,OutfitName,FALSE)

	;; remember where we were when we set it. this is for the automatic
	;; outfit selection to abandon itself if the location has not changed
	;; for things like on save load.

	StorageUtil.SetFormValue(Who,self.KeyActorLocation,Who.GetCurrentLocation())
	StorageUtil.SetFormValue(Who,self.KeyActorWorldSpace,Who.GetWorldSpace())

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

Function ActorEmptyOutfit(Actor Who, String OutfitName)

	String OutfitKey = self.ActorGetCurrentKey(Who)

	StorageUtil.FormListClear(Who,OutfitKey)
	Return
EndFunction

Function ActorDeleteOutfit(Actor Who, String OutfitName)

	String OutfitKey = self.KeyItemList + "[" + OutfitName + "]"

	StorageUtil.FormListClear(Who,OutfitKey)
	StorageUtil.StringListRemove(Who,self.KeyOutfitList,OutfitName,TRUE)

	;; if we deleted the current outfit censor it out.

	If(self.ActorGetCurrentOutfit(Who) == OutfitName)
		StorageUtil.UnsetStringValue(Who,self.KeyActorOutfit)
	EndIf

	;; if we deleted the last outfit unregister.

	If(StorageUtil.StringListCount(Who,self.KeyOutfitList) == 0)
		self.ActorUnregister(Who)
	EndIf

	Return
EndFunction

Bool Function IsActorReallyInTheCityTho(Actor Who)
{are we really really tho?}

	WorldSpace World = Who.GetWorldSpace()
	Int Iter = 0

	;; the reason this function exists is because a large area outside of
	;; city walls still gets tagged as "city" - like the farms that are
	;; around whiterun. this will help us determine if we actually stepped
	;; outside of city walls.

	If(!self.CheckRootWorldSpaces)
		;; if we don't want to check just lie. this will make you stay in
		;; your city clothes until you get a fair distance away from the
		;; city in question.
		Return TRUE
	EndIf

	While(Iter < self.RootWorldSpaces.Length)
		If(World == self.RootWorldSpaces[Iter])
			self.PrintDebug(Who.GetDisplayName() + " is in open world")
			Return FALSE
		EndIf
		Iter += 1
	EndWhile

	self.PrintDebug(Who.GetDisplayName() + " is not in open world")
	Return TRUE
EndFunction

Bool Function IsPlayerInCity()

	Location Here = self.PlayerRef.GetActorRef().GetCurrentLocation()

	While(Here != None)
		If(Here.HasKeyword(LocationCity))
			Return TRUE
		EndIf

		Here = PO3_SKSEFunctions.GetParentLocation(Here)
	EndWhile

	Return FALSE
EndFunction

String Function ActorTryToSetCurrentOutfitByLocationType(Actor Who)

	Location Here = NONE
	Location Prev = NONE
	WorldSpace PrevWorld = NONE
	WorldSpace HereWorld = NONE
	String KeyWhere = ""
	String OutfitName = ""
	Bool OutfitHome = FALSE
	Bool OutfitCity = FALSE
	Bool InHome = FALSE
	Bool InCity = FALSE
	Int WhoSwitch = 0
	Bool WhoSwitchType
	Bool WhoSwitchLocale

	;;;;;;;;

	WhoSwitch = self.ActorGetOutfitAuto(Who)
	WhoSwitchType = Math.LogicalAnd(WhoSwitch,self.AutoSwitchType)
	WhoSwitchLocale = Math.LogicalAnd(WhoSwitch,self.AutoSwitchLocale)

	If(WhoSwitchType)
		self.PrintDebug(Who.GetDisplayName() + " Auto Switch Type ENABLED")
	Else
		self.PrintDebug(Who.GetDisplayName() + " Auto Switch Type DISABLED")
	EndIf

	If(WhoSwitchLocale)
		self.PrintDebug(Who.GetDisplayName() + " Auto Switch Locale ENABLED")
	Else
		self.PrintDebug(Who.GetDisplayName() + " Auto Switch Locale DISABLED")
	EndIf

	;;;;;;;;

	Here = Who.GetCurrentLocation()
	Prev = StorageUtil.GetFormValue(Who,self.KeyActorLocation) As Location
	HereWorld = Who.GetWorldSpace()
	PrevWorld = StorageUtil.GetFormValue(Who,self.KeyActorWorldSpace) As WorldSpace

	If((Prev != NONE && Here == Prev) && (PrevWorld != None && HereWorld == PrevWorld))
		;; if the location hasn't changed then don't try to recalculate
		;; *which* outfit to wear. e.g. stop putting adventurer on every
		;; time we load a save.
		Return self.ActorGetCurrentOutfit(Who)
	EndIf

	;;;;;;;;

	;; most in game locations are nested such that thanks to the function added to
	;; papyrus extender by powerofthree we can traverse the location tree and determine
	;; if we have an outfit for a specific place.

	;; Bards College > Solitude Avenues > Solitude > Halfingaar > Tamriel

	;; imagine if you will being a stormcloak forced into the army because your dad
	;; was a douche but your passion really lies with singing and telling stories.
	;; with this ability we can do something like set a specific outfit while we are
	;; wandering ANYWHERE in Halfingaar, like a Solitude guard's disguise. we would
	;; continue to wear this entering solitude, and even the bards college. but then
	;; within the bards college we could specify a more casual outfit to switch to.
	;; then we we leave the college it would traverse the tree and find it should be
	;; wearing the halfingaar outfit again.

	;;;;;;;;

	;; try to find an outfit for this specific location, crawling up the location
	;; tree until we find one that matches.

	If(WhoSwitchLocale)
		While(Here != NONE)
			KeyWhere = self.KeyOutfitWhere + self.GetLocationName(Here)
			self.PrintDebug(Who.GetDisplayName() + " checking for: " + KeyWhere)
			
			If(self.ActorHasOutfit(Who,KeyWhere))
				If(StringUtil.Find(KeyWhere,"[City]") >= 0)
					If(self.IsActorReallyInTheCityTho(Who))
						OutfitName = KeyWhere
					EndIf
				Else
					OutfitName = KeyWhere
				EndIf
			EndIf

			If(OutfitName != "")
				self.ActorSetCurrentOutfit(Who,OutfitName)		
				Return OutfitName
			Endif

			Here = PO3_SKSEFunctions.GetParentLocation(Here)
		EndWhile

		self.PrintDebug(Who.GetDisplayName() + " has no location aware outfits")
	EndIf

	;;;;;;;;

	;; try to find an outfit that matches the type of place we are in
	;; crawling up the location tree until we find a match.

	If(WhoSwitchType)
		Here = Who.GetCurrentLocation()

		While(Here != NONE)

			If(Here.HasKeyword(LocationHome))
				If(self.ActorHasOutfit(Who,self.KeyOutfitWhenHome))
					OutfitName = self.KeyOutfitWhenHome
					self.PrintDebug(Who.GetDisplayName() + " found " + OutfitName)
				Else
					self.PrintDebug(Who.GetDisplayName() + " has no home outfit")
				EndIf
			ElseIf(Here.HasKeyword(LocationCity))
				If(self.ActorHasOutfit(Who,self.KeyOutfitWhenCity))
					If(self.IsActorReallyInTheCityTho(Who))
						OutfitName = self.KeyOutfitWhenCity
						self.PrintDebug(Who.GetDisplayName() + " found " + OutfitName)
					Else
						self.PrintDebug(Who.GetDisplayName() + " has no city outfit")
					EndIf
				EndIf
			EndIf

			If(OutfitName != "")
				self.ActorSetCurrentOutfit(Who,OutfitName)		
				Return OutfitName
			Endif

			Here = PO3_SKSEFunctions.GetParentLocation(Here)
		EndWhile


		;;;;;;;;

		;; if we failed to find a specific location or type of place outfit
		;; and we have an adventure outfit, put it on.

		If(self.ActorHasOutfit(Who,self.KeyOutfitWhenWilderness))
			self.PrintDebug(Who.GetDisplayName() + " found " + self.KeyOutfitWhenWilderness)
			self.ActorSetCurrentOutfit(Who,self.KeyOutfitWhenWilderness)
		Else
			self.PrintDebug(Who.GetDisplayName() + " has no type of place outfits")
		EndIf
	EndIf

	Return self.ActorGetCurrentOutfit(Who)
EndFunction

String Function GetLocationName(Location Here)
{this is to try and tell the difference between places like "whiterun" and
"whiterun" where one of them means the greater area and one of them means
the literal downtown.}

	String LocationName = Here.GetName()

		If(Here.HasKeyword(LocationCity))
			LocationName += " [City]"
		ElseIf(Here.HasKeyword(LocationTown))
			LocationName += " [Town]"
		EndIf

	Return LocationName
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

Function SortStringList(String[] ItemName)
{setting UIListMenu sort property to TRUE not only does not sort items but it
also makes the items unselectable. so now i've had to implement my own bubble
sort.}

	String TmpName
	Int Iter
	Bool Changed = TRUE

	While(Changed)
		Iter = 0
		Changed = FALSE

		While(Iter < (ItemName.Length - 1))

			If(ItemName[Iter] > ItemName[(Iter+1)])
				TmpName = ItemName[Iter]
				ItemName[Iter] = ItemName[(Iter+1)]
				ItemName[(Iter+1)] = TmpName
				Changed = TRUE
			EndIf

			Iter += 1
		EndWhile
	EndWhile

	Return
EndFunction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Function StorageFormListClear(Form Who, String Name)

	StorageUtil.FormListClear(Who,Name)
	Return
EndFunction

Function StorageFormListAdd(Form Who, String Name, Form What, Bool AllowDup=TRUE)

	StorageUtil.FormListAdd(Who,Name,What,AllowDup)
	Return
EndFunction

Int Function StorageFormListCount(Form Who, String Name)

	Return StorageUtil.FormListCount(Who,Name)
EndFunction

Form Function StorageFormListGet(Form Who, String Name, Int Which)

	Return StorageUtil.FormListGet(Who,Name,Which)
EndFunction

Form Function StorageFormGet(Form Who, String Name)

	Return StorageUtil.GetFormValue(Who,Name)
EndFunction

Function StorageFormClear(Form Who, String Name)

	StorageUtil.UnsetFormValue(Who,Name)
	Return
EndFunction

