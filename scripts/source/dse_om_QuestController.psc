ScriptName dse_om_QuestController extends Quest

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Bool Property DebugMode = TRUE Auto Hidden
{should we spam the console with a bazillion debugging messages?}

Bool Property CheckRootWorldspaces = TRUE Auto Hidden
{should we check known root worldspaces to determine if we are "outside"?}

Bool Property UseLOS = TRUE Auto Hidden
{if we should use the los or force in parallel.}

Bool Property DisableAutoWhenTold = TRUE Auto Hidden
{should we stop auto switching when manually told to wear an outfit.}

Float Property EquipDelay = 0.05 Auto Hidden
{a delay to let scripts breathe.}

Bool Property WeaponsOut = FALSE Auto Hidden
{should we swap weapons out if we have them out?}

Bool Property WeaponsHome = FALSE Auto Hidden
{should we allow weapons in our homes?}

Bool Property WeaponsCity = FALSE Auto Hidden
{should we allow weapons in our cities?}

Bool Property WeaponsEver = FALSE Auto Hidden
{should we ever attempt to manage weapons?}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReferenceAlias Property PlayerRef Auto
Outfit Property OutfitNone Auto
Container Property ContainOutfitter Auto
Weapon Property WeapNull Auto

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
String Property KeyActorLocationHome = "DSEOM.ActorLocationHome" AutoReadOnly Hidden
String Property KeyActorLocationCity = "DSEOM.ActorLocationCity" AutoReadOnly Hidden

String Property KeyOutfitWhenHome = "When: At Home" AutoReadOnly Hidden
String Property KeyOutfitWhenCity = "When: In City" AutoReadOnly Hidden
String Property KeyOutfitWhenWilderness = "When: Adventuring" AutoReadOnly Hidden
String Property KeyOutfitWhere = "Where: " AutoReadOnly Hidden

Int Property AutoSwitchNone = 0 AutoReadOnly Hidden
Int Property AutoSwitchType = 1 AutoReadOnly Hidden
Int Property AutoSwitchLocale = 2 AutoReadOnly Hidden
Int Property AutoSwitchWeapons = 4 AutoReadOnly Hidden
Int Property AutoSwitchShields = 8 AutoReadOnly Hidden

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Event OnInit()

	Return
EndEvent

Event OnGainLOS(Actor Viewer, ObjectReference Who)

	;;String Oldfit = self.ActorGetCurrentOutfit(Who As Actor)
	String Newfit = self.ActorTryToSetCurrentOutfitByLocationType(Who As Actor)

	self.ActorRefreshOutfit(Who As Actor)
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

		If(Who != None && Who.IsNearPlayer())
			If(self.UseLOS)
				;; this will cause the actor to update the next time we can actually
				;; see them. potentially allowing us to avoid doing it a few times
				;; and also multi-thread it.
				self.UnregisterForLOS(Player,Who)
				self.RegisterForSingleLOSGain(Player,Who)
			Else
				;; this will cause all actors in range to get updated right now in
				;; sequence.
				self.OnGainLOS(Who,Who)
			EndIf

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
		Value = AutoSwitchType + AutoSwitchWeapons + AutoSwitchShields
	ElseIf(Result == 2)
		Value = AutoSwitchLocale + AutoSwitchWeapons + AutoSwitchShields
	ElseIf(Result == 3)
		Value = AutoSwitchType + AutoSwitchLocale + AutoSwitchWeapons + AutoSwitchShields
	ElseIf(Result == 4)
		Value = -1
	EndIf

	If(Value >= 0)
		self.ActorSetOutfitAuto(Who,Value)
		self.ActorUpdateSet(Who,TRUE)
		self.ActorTryToSetCurrentOutfitByLocationType(Who)
		self.ActorRefreshOutfit(Who)
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
			self.ActorRefreshOutfit(Who,FALSE,FALSE)

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

		If(self.DisableAutoWhenTold)
			self.ActorSetOutfitAuto(Who,self.AutoSwitchNone)
		EndIf

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

	;; track them, store the outfit.

	self.ActorUpdateSet(Who,TRUE)
	self.ActorStoreOutfit(Who)

	;; disable the default outfits and force a full refresh.

	If(Who != self.PlayerRef.GetActorRef())
		;; one interesting thing is when this was called before
		;; storing the outfit, it would cause the skin of the
		;; currently equipped armour to bug out and also some
		;; of the items would no longer be "equipped" according
		;; to the game api.

		;; so when we first register an outfit we will do a full
		;; on full refresh.

	EndIf

	self.ActorRefreshOutfit(Who,FALSE,FALSE)

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
	String OutfitName = self.ActorGetCurrentOutfit(Who)
	String OutfitKey = self.ActorGetCurrentKey(Who)
	Bool Block = !(Who == self.PlayerRef.GetActorRef())
	Bool IsWeapHome = self.ActorGetInHome(Who) && !self.WeaponsHome
	Bool IsWeapCity = self.ActorGetInCity(Who) && !self.WeaponsCity
	Bool IsWeapCombat = Who.IsInCombat()
	Bool IsWeapStowed = !Who.IsWeaponDrawn() || self.WeaponsOut

	;;;;;;;;

	self.PrintDebug("ActorUnquipListedArmour: " + OutfitKey + " " + Who.GetDisplayName())

	;;;;;;;;

	;; short circuit unequips for home/city weapons.
	;; intentionally called before doing the armour because giving and taking
	;; things from npcs triggers them to self re-evaluate their loadouts.

	If(IsWeapHome || IsWeapCity)
		If(IsWeapStowed)
			self.ActorUnequipWeapons(Who)
		EndIf
	EndIf

	;;;;;;;;

	;; unequip the basic armour slots.

	Slot = 30
	While(Slot <= 61)
		Item = Who.GetEquippedArmorInSlot(Slot)

		If(Item == None)
			;; skip an invalid item.
		ElseIf(Item.HasKeywordString("zad_Lockable"))
			;; skip devious device devices.
		ElseIf(StorageUtil.FormListHas(Who,OutfitKey,Item))
			;; skip if outfit reuses it.
		ElseIf(Item.HasKeywordString("ArmorShield") && ((!IsWeapHome && !IsWeapCity) || IsWeapCombat))
			;; skip shields if we are not doing them.
		Else
			self.PrintDebug("ActorUnquipListedArmour: " + Who.GetDisplayName() + ", " + Item.GetName())
			Who.UnequipItem(Item,Block,TRUE)
		EndIf

		Slot += 1
	EndWhile

	Return
EndFunction

Function ActorEquipListedArmour(Actor Who, Bool FreeShit=FALSE)

	Int ItemCount
	Form Item
	String OutfitName = self.ActorGetCurrentOutfit(Who)
	String OutfitKey = self.ActorGetCurrentKey(Who)
	Bool Lock = !(Who == self.PlayerRef.GetActorRef())
	Bool IsWeapHome = self.IsHomeOutfit(OutfitName) && !self.WeaponsHome
	Bool IsWeapCity = self.IsCityOutfit(OutfitName) && !self.WeaponsCity
	Bool IsWeapCombat = Who.IsInCombat()
	Form[] ItemList = StorageUtil.FormListToArray(Who,OutfitKey)

	;;;;;;;;

	ItemCount = ItemList.Length
	self.PrintDebug("ActorEquipListedArmour: " + OutfitKey + " " + Who.GetDisplayName() + " " + ItemCount + " Items")

	;;;;;;;;

	While(ItemCount > 0)
		ItemCount -= 1
		;;Item = StorageUtil.FormListGet(Who,OutfitKey,ItemCount)
		Item = ItemList[ItemCount]

		If(Item == None)
			;; skip an item that is invalid.
		ElseIf(Who.IsEquipped(Item))
			;; skip things you are already wearing ya tard.
		ElseIf((Item As Armor == None) && (Item As Weapon == None))
			;; skip an item that is not an equippable type.
		ElseIf(Who.GetItemCount(Item) == 0 && !FreeShit)
			;; skip an item we have none of.
		ElseIf(Item.HasKeywordString("zad_Lockable"))
			;; skip a devious devices item.
		ElseIf(Item.HasKeywordString("ArmorShield") && (!self.WeaponsEver || IsWeapHome || IsWeapCity || IsWeapCombat))
			;; skip a shield if we are not doing weapons.
		ElseIf((Item As Weapon != None) && (!self.WeaponsEver || IsWeapHome || IsWeapCity || IsWeapCombat))
			;; skip weapons if we are not doing weapons.
		Else
			self.PrintDebug("ActorEquipListedArmour: " + Who.GetDisplayName() + ", " + Item.GetName())
			Who.EquipItem(Item,Lock,TRUE)
		EndIf

		If(self.EquipDelay != 0.0)
			Utility.Wait(self.EquipDelay)
		EndIf
	EndWhile

	Return
EndFunction

Function ActorUnequipWeapons(Actor Who)
{so unequipping weapons in skyrim is stupid. if you unequip an item, it will re-equip
the last thing you used prior to that, which even if i am playing normally has never
once been useful.}

	;; iT FuCKiNG mADe Me DO iT

	;; sober explanation: silently equipping an invisible dagger and then silently
	;; unequipping it to prevent the game from falling back to the previous weapon.

	self.PrintDebug("ActorUnequipWeapons: " + Who.GetDisplayName() + " Equip Null Weap: " + self.WeapNull.GetName())

	If(Who.GetItemCount(self.WeapNull) < 2)
		Who.AddItem(self.WeapNull,2,TRUE)
	EndIf

	Who.EquipItemEx(self.WeapNull,1,TRUE,FALSE)
	Who.EquipItemEx(self.WeapNull,2,TRUE,FALSE)
	Who.UnequipItemEx(self.WeapNull,1,TRUE)
	Who.UnequipItemEx(self.WeapNull,2,TRUE)

	Who.UnequipItemSlot(39) ;; shield

	;; removing the item kicks npcs into re-evaluating their loadouts undoing what we
	;; just did, so i've made this dagger weightless and non-playable. we'll just leave
	;; them hidden in the actor's inventory.
	;;Who.RemoveItem(self.WeapNull,2,TRUE)

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
		;;Worn = Who.GetEquippedArmorInSlot(Slot)
		Worn = Who.GetWornForm(Armor.GetMaskForSlot(Slot))

		If(Worn != NONE)
			StorageUtil.FormListAdd(Who,OutfitKey,Worn,FALSE)
			self.PrintDebug("ActorStoreOutfit: " + Who.GetDisplayName() + " " + Worn.GetName())
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
		;;Who.SetOutfit(self.OutfitNone,FALSE)
		;;Who.SetOutfit(self.OutfitNone,TRUE) ;; SetOutfit in SSE seems to not be good.
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

Int Function ActorGetOutfitAuto(Actor Who)

	Int Default = AutoSwitchType + AutoSwitchLocale + AutoSwitchWeapons + AutoSwitchShields

	Return StorageUtil.GetIntValue(Who,self.KeyOutfitAuto,Default)
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

Function ActorSetInHome(Actor Who, Bool Yep)

	StorageUtil.SetIntValue(Who,self.KeyActorLocationHome,(Yep As Int))
	Return
EndFunction

Bool Function ActorGetInHome(Actor Who)

	Return StorageUtil.GetIntValue(Who,self.KeyActorLocationHome,0) As Bool
EndFunction

Function ActorSetInCity(Actor Who, Bool Yep)

	StorageUtil.SetIntValue(Who,self.KeyActorLocationCity,(Yep As Int))
	Return
EndFunction

Bool Function ActorGetInCity(Actor Who)

	Return StorageUtil.GetIntValue(Who,self.KeyActorLocationCity,0) As Bool
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
			;;self.PrintDebug(Who.GetDisplayName() + " is in open world")
			Return FALSE
		EndIf
		Iter += 1
	EndWhile

	;;self.PrintDebug(Who.GetDisplayName() + " is not in open world")
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
	;;Location Prev = NONE
	;;WorldSpace PrevWorld = NONE
	;;WorldSpace HereWorld = NONE
	String KeyWhere = ""
	String OutfitName = ""
	;;Bool OutfitHome = FALSE
	;;Bool OutfitCity = FALSE
	Bool IsInHome = FALSE
	Bool IsInCity = FALSE
	Int WhoSwitch = 0
	Bool WhoSwitchType
	Bool WhoSwitchLocale

	;;;;;;;;

	WhoSwitch = self.ActorGetOutfitAuto(Who)
	WhoSwitchType = Math.LogicalAnd(WhoSwitch,self.AutoSwitchType)
	WhoSwitchLocale = Math.LogicalAnd(WhoSwitch,self.AutoSwitchLocale)

	;;;;;;;;

	;/*
	;; todo - instead of this, disable the actor's auto setting when telling them
	;; to use a specific outfit.

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
	*/;

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

	;; run the tests to find out if we are in a house or city now.

	Here = Who.GetCurrentLocation()
	While(Here != NONE)

		If(Here.HasKeyword(LocationHome))
			IsInHome = TRUE
		ElseIf(Here.HasKeyword(LocationCity) && self.IsActorReallyInTheCityTho(Who))
			IsInCity = TRUE
		EndIf

		Here = PO3_SKSEFunctions.GetParentLocation(Here)
	EndWhile

	self.ActorSetInHome(Who,IsInHome)
	self.ActorSetInCity(Who,IsInCity)

	;;;;;;;;

	;; try to find an outfit for this specific location, crawling up the location
	;; tree until we find one that matches.

	If(WhoSwitchLocale)
	
		Here = Who.GetCurrentLocation()
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

		If(IsInHome && self.ActorHasOutfit(Who,self.KeyOutfitWhenHome))
			OutfitName = self.KeyOutfitWhenHome
		ElseIf(IsInCity && self.ActorHasOutfit(Who,self.KeyOutfitWhenCity))
			OutfitName = self.KeyOutfitWhenCity
		ElseIf(self.ActorHasOutfit(Who,self.KeyOutfitWhenWilderness))
			OutfitName = self.KeyOutfitWhenWilderness
		EndIf

		If(OutfitName != "")
			self.PrintDebug(Who.GetDisplayName() + " found " + OutfitName)
			self.ActorSetCurrentOutfit(Who,OutfitName)		
			Return OutfitName
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

Bool Function IsHomeOutfit(String OutfitName)
{is this the home outfit?}

	Return OutfitName == self.KeyOutfitWhenHome
EndFunction

Bool Function IsCityOutfit(String OutfitName)
{is this the city outfit?}

	Return OutfitName == self.KeyOutfitWhenCity
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

