#include-once
#Region About
#cs
	This is a simple inventory management without a GUI
	The bot will Store the items you want
	Identify whatever is left on your inventory
	Sell what he needs to

	Everything is easily configurable
	You can add more configuration very easily if you know what you're doing

	Configuration:
	  - set $BAGS_TO_USE to the number of bafs you'll be using. The bot will not touch the others
	  - edit CanStore() function to decide what items to keep in your chest
	  - edit CanSell()  function to decide what items to sell to the merchant
	Note that Identify() will identify everything in your inventory, you can edit it to filter which items to ident
	Constants are defined at the bottom of this file
#ce
#EndRegion About

Global $BAGS_TO_USE = 4
Global Const $THIRD_DIALOG = 0x7F

#Region Inventory
Func Inventory()
	Out("Going to merchant")
	GoMerchant()

	Out("Storing")
	Store()
	Out("Identifying")
	Identify()
	Out("Salvaging")
	Salvage()
	Out("Selling")
	Sell()

	RndSleep(1000)
	If GetGoldCharacter() > 80000 Then
		Out("Storing 80K")
		DepositGold(80000)
	EndIf
EndFunc

;Counts open slots in your Imventory
Func CountSlots()
	Local $bag, $count = 0

	For $i = 1 To $BAGS_TO_USE
		$bag = GetBag($i)
		$count += DllStructGetData($bag, 'Slots') - DllStructGetData($bag, 'ItemsCount')
	Next

	Return $count
EndFunc ;CountSlots

Func InventoryIsFull()
	Return CountSlots() < 2
EndFunc ;InventoryIsFull
#EndRegion Inventory

#Region Store
Func Store()
	Local $item, $bag

	For $i = 1 To $BAGS_TO_USE
		$bag = Getbag($i)

		For $j = 1 To DllStructGetData($bag, 'Slots')
			$item = GetItemBySlot($i, $j)
			If DllStructGetData($item, "Id") == 0 Then ContinueLoop
			If CanStore($item) Then
				StoreItem($item) ;hasSleep
				RndSleep(250)
			EndIf
		Next
	Next
EndFunc ;Store
Func CanStore($item)
	Local $ModelID = DllStructGetData($item, "ModelId")
	Local $rarity = GetRarity($item)
	Local $requirement = GetItemReq($item)

	If $rarity == $RARITY_GOLD		  Then Return False
	If $rarity == $RARITY_BLUE		  Then Return False
	If $rarity == $RARITY_PURPLE		Then Return False

	If $ModelID == $ITEM_LOCKPICK		   		    Then Return True
	If $ModelID == $ITEM_DYES 						Then Return False ;Dyes
	If $ModelID == 946 								Then Return False ;Planks
	If $ModelID == 955 								Then Return False ;Granite
	If $ModelID == $ITEM_ID_BONES 					Then Return True ;Bones
	If $ModelID == 953 								Then Return False ;Scales
	If $ModelID == $ITEM_ID_FEATHERED_CREST 		Then Return True
	If InArray($ModelID, $SPECIAL_DROPS)            Then Return False
	If InArray($ModelID, $ALL_TOMES_ARRAY)		    Then Return True ;Tomes
	If InArray($ModelID, $ALL_MATERIALS_ARRAY)		Then Return True ;Materials
	If InArray($ModelID, $STACKABLE_TROPHIES_ARRAY)	Then Return True ;Trophies
	If InArray($ModelID, $ALL_TITLE_ITEMS)			Then Return False ;Party, Alcohol, Sweet
	If InArray($ModelID, $ALL_SCROLLS_ARRAY)		Then Return False ;Scrolls
	If InArray($ModelID, $GENERAL_ITEMS_ARRAY)		Then Return False ;Lockpicks, Kits
	If InArray($ModelID, $WEAPON_MOD_ARRAY)			Then Return False ;Weapon mods

	; TODO: do not pickup those
	If InArray($ModelID, $MAP_PIECE_ARRAY)			Then Return False
	If $rarity == $RARITY_WHITE 					Then Return False

	Return False
EndFunc ;CanStore
Func StoreItem($item)
	Local $slot
	
	If InArray(DllStructGetData($item, 'Type'), $UNSTACKABLES) Then Return StoreInEmptySlot($item)

	For $i = 8 To 16
		$slot = FindItemInStorage($i, $item)
		If $slot <> 0 Then ExitLoop
	Next
	If $slot == 0 Then Return StoreInEmptySlot($item)

	MoveItem($item, getBag($i), $slot)
	RndSleep(500)
	Return True
EndFunc ;StoreItem
Func FindItemInStorage($bagIndex, $item)
	Local $slot, $inSlot
	Local $ModelID = DllStructGetData($item, 'ModelID')
	Local $ExtraID = DllStructGetData($item, 'ExtraID')

	For $slot = 1 To DllStructGetData(GetBag($bagIndex), 'Slots')
		$inSlot = GetItemBySlot($bagIndex, $slot)
		If DllStructGetData($inSlot, 'ModelID') == $ModelID And DllStructGetData($inSlot, 'ExtraID') == $ExtraID And DllStructGetData($inSlot, 'Quantity') < 250 Then
			SetExtended($slot)
			Return $slot
		EndIf
	Next

	Return 0
EndFunc ;FindItemInStorage
Func StoreInEmptySlot($item)
	Local $inSlot, $slot

	For $bagIndex = 8 To 16
		For $slot = 1 To DllStructGetData(GetBag($bagIndex), 'Slots')
			$inSlot = GetItemBySlot($bagIndex, $slot)
			If DllStructGetData($inSlot, 'ID') == 0 Then
				SetExtended($slot)
				MoveItem($item, getBag($bagIndex), $slot)
				Return True
			EndIf
		Next
	Next

	Return 0
EndFunc ;StoreInEmptySlot
#EndRegion Store

#Region Identification
Func Identify()
	Local $item, $bag
	
	For $i = 1 To $BAGS_TO_USE
		$bag = GetBag($i)
		
		If Not RetrieveIdentificationKit(False) Then Return
		For $j = 1 To DllStructGetData($bag, "slots")
			$item = GetItemBySlot($i, $j)
			If DllStructGetData($item, "Id") == 0 Then ContinueLoop
			IdentifyItem($item) ;hasSleep
		Next
	Next
EndFunc ;Identify
Func RetrieveIdentificationKit($expert = True)
	If FindIdentificationKit() = 0 Then
		If GetGoldCharacter() < 500 And GetGoldStorage() > 499 Then
			WithdrawGold(500)
			RndSleep(500)
		EndIf
		Local $J = 0
		Do
			$expert ? BuySuperiorIdentificationKit() : BuyIdentificationKit()
			RndSleep(500)
			$J = $J + 1
		Until FindIdentificationKit() <> 0 Or $J = 3
		If $J = 3 Then Return False
		RndSleep(500)
	EndIf
 EndFunc ;RetrieveIdentificationKit
#EndRegion Identification

#Region Salvage
Func Salvage()
	Local $item, $bag

	For $i = 1 To $BAGS_TO_USE
		$bag = Getbag($i)
		
		If Not RetrieveSalvageKit() Then Return
        For $j = 1 To DllStructGetData($bag, 'Slots')
			$item = GetItemBySlot($i, $j)
			If CanSalvage($item) Then
				StartSalvage($item, True) ;noSleep
				RndSleep(1000)
                SalvageMaterials()
                RndSleep(750)
			EndIf
		Next
	Next
EndFunc ;Salvage
Func CanSalvage($item)
	Local $ModelID = DllStructGetData($item, "ModelId")
	Local $rarity = GetRarity($item)
	Local $requirement = GetItemReq($item)

	If DllStructGetData($item, 'Quantity') > 0 Then Return False
	If $rarity == $RARITY_GOLD			Then Return False
	If $rarity == $RARITY_BLUE			Then Return False
	If $rarity == $RARITY_PURPLE		Then Return False

	If $ModelID == $ITEM_DYES 						Then Return False ;Dyes
    If InArray($ModelID, $SPECIAL_DROPS)            Then Return False ;ToT bags
	If InArray($ModelID, $ALL_TOMES_ARRAY)		    Then Return False ;Tomes
	If InArray($ModelID, $ALL_MATERIALS_ARRAY)		Then Return False ;Materials
	If InArray($ModelID, $STACKABLE_TROPHIES_ARRAY)	Then Return False ;Trophies
	If InArray($ModelID, $ALL_TITLE_ITEMS)			Then Return False ;Party, Alcohol, Sweet
	If InArray($ModelID, $ALL_SCROLLS_ARRAY)		Then Return False ;Scrolls
	If InArray($ModelID, $GENERAL_ITEMS_ARRAY)		Then Return False ;Lockpicks, Kits
	If InArray($ModelID, $WEAPON_MOD_ARRAY)			Then Return False ;Weapon mods

	; TODO: do not pickup those
	If InArray($ModelID, $MAP_PIECE_ARRAY)			Then Return False
	If $rarity == $RARITY_WHITE 					Then Return True

	Return False
EndFunc ;CanSalvage
Func RetrieveSalvageKit()
	If FindExpertSalvageKit() Then Return True

	If GetGoldCharacter() < 500 And GetGoldStorage() > 499 Then
		WithdrawGold(500)
		RndSleep(500)
	EndIf
	Local $j = 0
	Do
		BuyExpertSalvageKit()
		RndSleep(500)
		$j = $j + 1
	Until FindExpertSalvageKit() <> 0 Or $j = 3
	If $j = 3 Then Return False
	RndSleep(500)
	Return True
EndFunc ;RetrieveSalvageKit
#EndRegion


#Region Sell
Func Sell()
	Local $item, $bag

	For $i = 1 To $BAGS_TO_USE
		$bag = Getbag($i)

		For $j = 1 To DllStructGetData($bag, 'Slots')
			$item = GetItemBySlot($i, $j)
			If DllStructGetData($item, "Id") == 0 Then ContinueLoop
			If CanSell($item) Then 
				SellItem($item) ;noSleep
				RndSleep(250)
			EndIf
		Next
	Next
EndFunc ;Sell
Func CanSell($item)
	Local $ModelID = DllStructGetData($item, "ModelId")
	Local $rarity = GetRarity($item)
	Local $requirement = GetItemReq($item)

	If $rarity == $RARITY_GOLD		  	Then Return True
	If $rarity == $RARITY_BLUE		  	Then Return True
	If $rarity == $RARITY_PURPLE		Then Return True

	If $ModelID == $ITEM_DYES Then
		;Uncomment for Only black and white dyes
		Local $ExtraID = DllStructGetData($item, "ExtraId")
		Return $ExtraID <> $ITEM_BLACK_DYE And $ExtraID <> $ITEM_WHITE_DYE
		Return False
	EndIf ;Dies

	If $ModelID == 946 Then Return True ;Planks
	If $ModelID == 949 Then Return True ;Steel ingots
	If $ModelID == 955 Then Return True ;Granite
	If $ModelID == 954 Then Return True ;Chitine
	If $ModelID == 925 Then Return True ;Cloth
	If $ModelID == 940 Then Return True ;Tanned
	If $ModelID == 953 Then Return True ;Scales
	If $ModelID == $ITEM_ID_BONES Then Return False ;Bones
	If $ModelID == $ITEM_ID_FEATHERED_CREST Then Return False
    If InArray($ModelID, $SPECIAL_DROPS)            Then Return False
	If InArray($ModelID, $ALL_TOMES_ARRAY)		  	Then Return False ;Tomes
	If InArray($ModelID, $ALL_MATERIALS_ARRAY)		Then Return False ;Materials
	If InArray($ModelID, $STACKABLE_TROPHIES_ARRAY)	Then Return False ;Trophies
	If InArray($ModelID, $ALL_TITLE_ITEMS)			Then Return False ;Party, Alcohol, Sweet
	If InArray($ModelID, $ALL_SCROLLS_ARRAY)		Then Return True ;Scrolls
	If InArray($ModelID, $GENERAL_ITEMS_ARRAY)		Then Return False ;Lockpicks, Kits
	If InArray($ModelID, $WEAPON_MOD_ARRAY)			Then Return False ;Weapon mods

	; TODO: do not pickup those
	If InArray($ModelID, $MAP_PIECE_ARRAY)			Then Return True
	If $rarity == $RARITY_WHITE 					Then Return True

	Return True
EndFunc ;CanSell
#EndRegion Sell

#Region Helpers
Func InArray($modelId, $array)
	For $p = 0 To (UBound($array) -1)
		If $modelId == $array[$p] Then Return True
	Next
	Return False
EndFunc
#EndRegion Helpers

#Region Global Items
	Global Const $GOLD_COINS = 2511

	Global Const $RARITY_GOLD = 2624
	Global Const $RARITY_PURPLE = 2626
	Global Const $RARITY_BLUE = 2623
	Global Const $RARITY_WHITE = 2621

	;~ All Weapon mods
	Global $WEAPON_MOD_ARRAY[25] = [893, 894, 895, 896, 897, 905, 906, 907, 908, 909, 6323, 6331, 15540, 15541, 15542, 15543, 15544, 15551, 15552, 15553, 15554, 15555, 17059, 19122, 19123]

	;~ General Items
	Global $GENERAL_ITEMS_ARRAY[6] = [2989, 2991, 2992, 5899, 5900, 22751]
	Global Const $ITEM_SALVAGE_KIT = 2992
	Global Const $ITEM_SUP_SALVAGE_KIT = 5900
	Global Const $ITEM_EXP_SALVAGE_KIT = 2991
	Global Const $ITEM_IDENT_KIT = 2989
	Global Const $ITEM_SUP_IDENT_KIT = 5899
	Global Const $ITEM_LOCKPICK = 22751

	;~ Dyes
	Global Const $ITEM_DYES = 146
	Global Const $ITEM_BLACK_DYE = 10
	Global Const $ITEM_WHITE_DYE = 12

	;~ Tonics
	Global $TONIC_PARTY_ARRAY[23] = [4730, 15837, 21490, 22192, 30624, 30626, 30628, 30630, 30632, 30634, 30636, 30638, 30640, 30642, 30646, 30648, 31020, 31141, 31142, 31144, 31172, 37771, 37772]

	;~ Special Drops
	Global $SPECIAL_DROPS[7] = [556, 18345, 21491, 37765, 21833, 28433, 28434]
	#cs
		CC_Shard = 556
		Flame_of_Balthazar = 2514
		Golden_Flame_of_Balthazar = 22188
		Celestial_Sigil = 2571
		Wintersday_Gift = 21491
		Wayfarer_Mark = 37765
	Global Const $ITEM_ID_TOTS = 28434
	Global Const $ITEM_ID_VICTORY_TOKEN = 18345
	Global Const $ITEM_ID_LUNAR_TOKEN = 21833
	Global Const $ITEM_ID_LUNAR_TOKENS = 28433
	#ce

	;~ Map pieces
	Global $MAP_PIECE_ARRAY[4] = [24629, 24630, 24631, 24632]

	;~ Materials
	Global $ALL_MATERIALS_ARRAY[36] = [921, 922, 923, 925, 926, 927, 928, 929, 930, 931, 932, 933, 934, 935, 936, 937, 938, 939, 940, 941, 942, 943, 944, 945, 946, 948, 949, 950, 951, 952, 953, 954, 955, 956, 6532, 6533]
	Global $COMMON_MATERIALS_ARRAY[11] = [921, 925, 929, 933, 934, 940, 946, 948, 953, 954, 955]
	Global $RARE_MATERIALS_ARRAY[25] = [922, 923, 926, 927, 928, 930, 931, 932, 935, 936, 937, 938, 939, 941, 942, 943, 944, 945, 949, 950, 951, 952, 956, 6532, 6533]
	#cs
		Lumps of Charcoal 922
		Monstrous Claws 923
		Bolt of Linen 926
		Bolt of Damask 927
		Bolt of Silk 928
		Glob of Ectoplasm 930
		Monstrous Eye 931
		Monstrous Fangs 932
		Diamonds 935
		Onyx Gemstones 936
		Rubies 937
		Sapphires 938
		Tempered Glass Vial 939
		Fur Square 941
		Leather Squares 942
		Elonian Leather Square 943
		Vial of Ink 944
		Obsidian Shard 945
		Steel of Ignot 949
		Deldrimor Steel Ingot 950
		Rolls of Parchment 951
		Rolls of Vellum 952
		Spiritwood Planks 956
		Amber Chunk 6532
		Jadeite Shard 6533
	#ce

	;~ Title Items (Alcohol, Party, Sweets)
	Global $ITEMS_ALCOHOL[19] = [910, 2513, 5585, 6049, 6366, 6367, 6375, 15477, 19171, 19172, 19173, 22190, 24593, 28435, 30855, 31145, 31146, 35124, 36682]
	Global $ITEMS_SWEETS_TOWN[10] = [15528, 15479, 19170, 21492, 21812, 22644, 30208, 31150, 35125, 36681]
	Global $ITEMS_SWEETS_PVE[13] = [17060, 17061, 17062, 22269, 22752, 28431, 28432, 28436, 29431, 31151, 31152, 31153, 35121]
	Global $ITEMS_PARTY[7] = [6368, 6369, 6376, 21809, 21810, 21813, 36683]
	Global $ITEMS_DP_REMOVAL[8] = [6370, 19039, 21488, 21489, 22191, 26784, 28433, 35127]
	#cs
		Global Const $ITEM_ID_GOLDEN_EGGS = 22752
		Global Const $ITEM_ID_BUNNIES = 22644
		Global Const $ITEM_ID_PIE = 28436
		Global Const $ITEM_ID_CIDER = 28435
		Global Const $ITEM_ID_POPPERS = 21810
		Global Const $ITEM_ID_ROCKETS = 21809
		Global Const $ITEM_ID_CUPCAKES = 22269
		Global Const $ITEM_ID_SPARKLER = 21813
		Global Const $ITEM_ID_HONEYCOMB = 26784
		Global Const $ITEM_ID_HUNTERS_ALE = 910
		Global Const $ITEM_ID_GROG = 30855
		Global Const $ITEM_ID_CLOVER = 22191
		Global Const $ITEM_ID_KRYTAN_BRANDY = 35124
		Global Const $ITEM_ID_BLUE_DRINK = 21812
	#ce

	Global $ALL_TITLE_ITEMS[49]=[910, 2513, 5585, 6049, 6366, 6367, 6375, 15477, 19171, 19172, 19173, 22190, 24593, 28435, 30855, 31145, 31146, 35124, 36682, 15528, 15479, 19170, 21492, 21812, 22644, 30208, 31150, 35125, 36681, 17060, 17061, 17062, 22269, 22752, 28431, 28432, 28436, 29431, 31151, 31152, 31153, 35121, 6368, 6369, 6376, 21809, 21810, 21813, 36683]

	;~ Special Drops (Trophies)
	Global $STACKABLE_TROPHIES_ARRAY[5] = [27047, 27052, 27033, 24353, 24354]
	Global Const $ITEM_GLACIAL_STONES = 27047
	Global Const $ITEM_SUPERIOR_CHARR_CARVING = 27052
	Global Const $ITEM_DESTROYER_CORE = 27033
	Global Const $ITEM_DIESSA_CHALICE = 24353
	Global COnst $ITEM_RIN_RELIC = 24354

	;~ Tomes
	Global $ALL_TOMES_ARRAY[20] = [21786, 21787, 21788, 21789, 21790, 21791, 21792, 21793, 21794, 21795, 21796, 21797, 21798, 21799, 21800, 21801, 21802, 21803, 21804, 21805]
	Global $ELITE_TOME_ARRAY[10] = [21786, 21787, 21788, 21789, 21790, 21791, 21792, 21793, 21794, 21795]
	Global $REGULAR_TOME_ARRAY[10] = [21796, 21797, 21798, 21799, 21800, 21801, 21802, 21803, 21804, 21805]

	;~ Scrolls
	Global $ALL_SCROLLS_ARRAY[11] = [5853, 5975, 5976, 3256, 3746, 5594, 5595, 5611, 21233, 22279, 22280]
#EndRegion Global Items

#Region Item Types
Global $ITEM_TYPE_SALVAGE = 0
Global $ITEM_TYPE_LEADHAND = 1
Global $ITEM_TYPE_AXE = 2
Global $ITEM_TYPE_BAG = 3
Global $ITEM_TYPE_FEET = 4
Global $ITEM_TYPE_BOW = 5
Global $ITEM_TYPE_BUNDLE = 6
Global $ITEM_TYPE_CHEST = 7
Global $ITEM_TYPE_RUNE = 8
Global $ITEM_TYPE_CONSUMABLE = 9
Global $ITEM_TYPE_DYE = 10
Global $ITEM_TYPE_MATERIAL = 11
Global $ITEM_TYPE_FOCUS = 12
Global $ITEM_TYPE_ARMS = 13
Global $ITEM_TYPE_SIGIL = 14
Global $ITEM_TYPE_HAMMER = 15
Global $ITEM_TYPE_HEAD = 16
Global $ITEM_TYPE_SALVAGEITEM = 17
Global $ITEM_TYPE_KEY = 18
Global $ITEM_TYPE_LEGS = 19
Global $ITEM_TYPE_COINS = 20
Global $ITEM_TYPE_QUESTITEM = 21
Global $ITEM_TYPE_WAND = 22
Global $ITEM_TYPE_SHIELD = 24
Global $ITEM_TYPE_STAFF = 26
Global $ITEM_TYPE_SWORD = 27
Global $ITEM_TYPE_KIT = 29
Global $ITEM_TYPE_TROPHY = 30
Global $ITEM_TYPE_SCROLL = 31
Global $ITEM_TYPE_DAGGERS = 32
Global $ITEM_TYPE_PRESENT = 33
Global $ITEM_TYPE_MINIPET = 34
Global $ITEM_TYPE_SCYTHE = 35
Global $ITEM_TYPE_SPEAR = 36
Global $ITEM_TYPE_HANDBOOK = 43
Global $ITEM_TYPE_COSTUMEBODY = 44
Global $ITEM_TYPE_COSTUMEHEAD = 45

Global $UNSTACKABLES[23] = [$ITEM_TYPE_LEADHAND, $ITEM_TYPE_AXE, $ITEM_TYPE_BAG, $ITEM_TYPE_FEET, $ITEM_TYPE_BOW, $ITEM_TYPE_RUNE, $ITEM_TYPE_FOCUS, $ITEM_TYPE_ARMS, $ITEM_TYPE_SIGIL, $ITEM_TYPE_HAMMER, $ITEM_TYPE_HEAD, $ITEM_TYPE_SALVAGEITEM, $ITEM_TYPE_LEGS, $ITEM_TYPE_WAND, $ITEM_TYPE_SHIELD, $ITEM_TYPE_STAFF, $ITEM_TYPE_SWORD, $ITEM_TYPE_KIT, $ITEM_TYPE_DAGGERS, $ITEM_TYPE_MINIPET, $ITEM_TYPE_SCYTHE, $ITEM_TYPE_SPEAR, $ITEM_TYPE_HANDBOOK]
#EndRegion Item Types
