#include-once
#include "GWA2_Headers.au3"
#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <ComboConstants.au3>
#include <ScrollBarsConstants.au3>
#include <GWA2.au3>
#include <farmingroute.au3>
#include <GuiEdit.au3>
#include "SimpleInventory.au3"
#NoTrayIcon

#Region Constants
; === Maps ===
Global $SEITUNG_HARBOR = 250 ; Seitungs Harbor
Global $JAYA_BLUFF = 196 ; Jaya Bluff

; === Build ===
Global Const $SkillBarTemplate = "OACjAqiK5OQzH318bWOPbNTnJA"

; === Materials and usefull Items ===
Global Const $ITEM_ID_FEATHER = 933
Global Const $ITEM_ID_FEATHERED_CREST = 835
Global Const $ITEM_ID_BONES = 921
Global Const $ITEM_ID_DUST = 929
Global Const $ITEM_ID_DIESSA = 24353
Global Const $ITEM_ID_RIN = 24354
Global Const $ITEM_ID_LOCKPICKS = 22751
#EndRegion Constants

#Region Declarations
Opt("GUIOnEventMode", True)
Global $feathers = 0
Global $bones = 0
Global $dusts = 0
Global $crests = 0
Global $deaths = 0
Global $BOT_RUNNING = False
Global $BOT_INITIALIZED = False

Global $INITIAL_GOLD = -1
Global $TOTAL_GOLDS = 0
Global $TOTAL_RUNS = 0

Global $Rendering = True
Global $MAX_HP
Global $gwpid = -1

#Region Gui
GUICreate("Feather Farm", 210, 290, 100, 100)

GUICtrlCreateGroup("Character name:", 5, 5, 200, 45)
$CharacterName = GUICtrlCreateCombo("", 10, 20, 120, 20, BitOR($CBS_DROPDOWN, $CBS_AUTOHSCROLL))
	GUICtrlSetData(-1, GetLoggedCharNames())
$cbxHideGW = GUICtrlCreateCheckbox("Render", 145, 20, 50, 20)
	GUICtrlSetOnEvent($cbxHideGW, "GUI_EventHandler")

GUICtrlCreateGroup("Information", 5, 50, 200, 150)
GUICtrlCreateLabel("Total runs:", 10, 70, 54, 15)
	$LabelRun = GUICtrlCreateLabel("0", 150, 70, 50, 15, $SS_RIGHT)
GUICtrlCreateLabel("Number of Deaths", 10, 90, 90, 15)
	$LabelDeaths = GUICtrlCreateLabel("0000", 150, 90, 50, 15, $SS_RIGHT)
GUICtrlCreateLabel("Total gold earned:", 10, 110, 90, 15)
	$LabelGolds = GUICtrlCreateLabel("0", 150, 110, 50, 15, $SS_RIGHT)
GUICtrlCreateLabel("Feathers:", 10, 130, 66, 15)
	$LabelFeathers = GUICtrlCreateLabel("0", 150, 130, 50, 15, $SS_RIGHT)
GUICtrlCreateLabel("Feathered Crests:", 10, 150, 105, 15)
	$LabelCrests = GUICtrlCreateLabel("0", 150, 150, 50, 15, $SS_RIGHT)

GUICtrlCreateGroup("Status:", 5, 200, 200, 40)
	$LabelStatus = GUICtrlCreateLabel("Ready to begin", 10, 215, 180, 20, $SS_CENTER)

$StartButton = GUICtrlCreateButton("Start", 15, 250, 170, 25)

Opt("GUIOnEventMode", 1)
GUISetOnEvent($GUI_EVENT_CLOSE, "_exit")
GUICtrlSetOnEvent($StartButton, "Init")
GUISetState(@SW_SHOW)
#EndRegion Gui

#Region Loops
Out("Ready")
While Not $BOT_RUNNING
   Sleep(500)
WEnd

AdlibRegister("VerifyConnection", 5000)
Setup()
While 1
	If Not $BOT_RUNNING Then
	   AdlibUnRegister("VerifyConnection")
	   Out("Bot is paused.")
	   GUICtrlSetState($StartButton, $GUI_ENABLE)
	   GUICtrlSetData($StartButton, "Start")
		While Not $BOT_RUNNING
			Sleep(500)
		WEnd
	   AdlibRegister("VerifyConnection", 5000)
	EndIf
	MainLoop()
WEnd
#EndRegion Loops

Func MainLoop()
	If GetMapID() == $SEITUNG_HARBOR Then EnterArea()
	
	$INITIAL_GOLD = GetGoldCharacter()
	$TOTAL_GOLDS += GetGoldCharacter() - $INITIAL_GOLD
	GUICtrlSetData($LabelGolds, $TOTAL_GOLDS)
	$TOTAL_RUNS += 1
	GUICtrlSetData($LabelRun, $TOTAL_RUNS)
	
	Farm()

	Out("Returning to Harbor")
	Resign()
	RndSleep(4000)
	ReturnToOutpost()
	WaitMapLoading($SEITUNG_HARBOR)
	If InventoryIsFull() Then 
		Inventory()
		GoPortal()
	EndIf
EndFunc ;MainLoop

#Region Setup
Func Setup()
	Out("Travelling to Harbor.")
	If GetMapID() <> $SEITUNG_HARBOR Then TravelTo($SEITUNG_HARBOR)

	Out("Loading skillbar.")
	LoadSkillTemplate($SkillBarTemplate)
	SwitchMode(False)

	RndSleep(500)
	SetupResign()
EndFunc ;Setup

Func SetupResign()
	Out("Setting up resign.")
	GoPortal()
	EnterArea()
	Move(10767, -13273)
	RndSleep(2500)
	WaitMapLoading($SEITUNG_HARBOR)
	RndSleep(500)
	Return True
EndFunc ;SetupResign

Func GoPortal()
	Out("Going portal")
	;from merchant to area
	MoveTo(17002, 12778)
	RndSleep(200)
	MoveTo(18012, 13664)
	RndSleep(200)
	MoveTo(18859, 13224)
	RndSleep(200)
	MoveTo(19088, 13416)
	RndSleep(200)
	MoveTo(18288, 14884)
	RndSleep(200)
	MoveTo(18783, 16107)
	RndSleep(200)
EndFunc ;GoPortal

Func EnterArea()
	Out("Enter area")
	Do
		MoveTo(17171, 17331)
		RndSleep(200)
		MoveTo(16800, 17500)
		WaitMapLoading()
	Until GetMapID() == $JAYA_BLUFF
EndFunc ;EnterArea
#EndRegion Setup

Func GUI_EventHandler()
	Switch (@GUI_CtrlId)
		Case $GUI_EVENT_CLOSE
			Exit
		Case $cbxHideGW
			If GUICtrlRead($cbxHideGW) = 1 Then
				DisableRendering()
				AdlibRegister("reduceMemory", 20000)
				WinSetState(GetWindowHandle(), "", @SW_HIDE)
			Else
				EnableRendering()
				AdlibUnRegister("reduceMemory")
				WinSetState(GetWindowHandle(), "", @SW_SHOW)
			EndIf
	EndSwitch
EndFunc ;GUI_EventHandler

Func Init()
	$BOT_RUNNING = Not $BOT_RUNNING
	If $BOT_RUNNING Then
		GUICtrlSetData($StartButton, "Initializing...")
		GUICtrlSetState($StartButton, $GUI_DISABLE)
		GUICtrlSetState($CharacterName, $GUI_DISABLE)
		If GUICtrlRead($CharacterName) = "" Then
			If Initialize(ProcessExists("gw.exe")) = False Then
				MsgBox(0, "Error", "Guild Wars Is not running.")
				Exit
			EndIf
			$gwpid=ProcessExists("gw.exe")
		Else
			If Initialize(GUICtrlRead($CharacterName), True, True) = False Then
				MsgBox(0, "Error", "Can't find a Guild Wars client with that character name.")
				Exit
			EndIf
			$lWinList = ProcessList('gw.exe')
			For $i = 1 To $lWinList[0][0]
				$mGWHwnd = $lWinList[$i][1]
				MemoryOpen($mGWHwnd)
				If StringRegExp(ScanForCharname(), GUICtrlRead($CharacterName)) = 1 Then
					$gwpid = $mGWHwnd
					ExitLoop
				EndIf
			Next
		EndIf
		GUICtrlSetState($StartButton, $GUI_ENABLE)
		GUICtrlSetData($StartButton, "Pause")
		$me = GetAgentByID(-2)
		$MAX_HP = DllStructGetData($me, 'MaxHP')
	Else
		GUICtrlSetData($StartButton, "BOT WILL HALT AFTER THIS RUN")
		GUICtrlSetState($StartButton, $GUI_DISABLE)
	EndIf
EndFunc

Func HardLeave()
	Resign()
	RndSleep(4000)
	ReturnToOutpost()
	WaitMapLoading()
EndFunc ;HardLeave

Func MoveAndUseSkills($aX, $aY)
	Local $lBlocked = 0
	Local $me
	Local $lastHP = 0

	Out("Moving on Farming-Route!")
	;Out("Moving to "&string($aX)&", "&string($aY))
	Move($aX, $aY)
	Do
		Sleep(40)

		If GetIsDead() Then RndSleep(10000)

		$me = GetAgentByID(-2)
		If DllStructGetData($me, 'HP') < $lastHP Then
			if Nuke()==0 Then return 0
			Move($aX, $aY, 100)
			;Out("Moving to "&string($aX)&", "&string($aY))
			Out("Moving on Farming-Route!")
		EndIf
		KeepUpBoon()
		$lastHP = DllStructGetData($me, 'HP')
		If GetIsMoving($me) = False Then
			$lBlocked += 1
			Move($aX, $aY, 100)
		EndIf

	Until ComputeDistance(DllStructGetData($me, 'X'), DllStructGetData($me, 'Y'), $aX, $aY) < 110 Or $lBlocked > 8

	Return 1
EndFunc ;MoveAndUseSkills

Func Farm()
	Out("Calculating waypoints...")
	Local $route = CreateFarmingRoute()
	Out("Running to farming route")
	MoveTo(9545,-11478)
	MoveTo(11226,-9199,100)
	Local $i = 0
	While $i < UBound($route, 1)
		KeepUpBoon()
		If Not MoveAndUseSkills($route[$i][0], $route[$i][1]) Then
			If GetIsDead() Then
				$Deaths += 1
				GUICtrlSetData($LabelDeaths, $Deaths)
				while GetIsDead()
					RndSleep(3000)
				WEnd
				Local $p = (1 - DllStructGetData(GetAgentByID(-2),'MaxHP') / $MAX_HP) * 100
				If (1 - DllStructGetData(GetAgentByID(-2),'MaxHP') / $MAX_HP) * 100 > 40 Then
					Out("Too much DP... Restarting")
					HardLeave()
					Return False
				EndIf
				$i = 0
				Local $x = DllStructGetData(GetAgentByID(-2),'X'),$y = DllStructGetData(GetAgentByID(-2),'Y')
				For $j = 1 To UBound($route) - 1
					if Dist($x, $y, $route[$i][0], $route[$i][1]) > Dist($x, $y, $route[$j][0], $route[$j][1]) Then $i = $j
				Next
			EndIf
			Return False
		EndIf
		$i += 1
	WEnd
	RndSleep(200)
	Out("Run succesful")
	Return True
EndFunc ;Farm

Func Dist($x1, $y1, $x2, $y2)
	$x1 = ($x1-$x2)*($x1-$x2)
	$y1 = ($y1-$y2)*($y1-$y2)
	Return Sqrt($x1+$y2)
EndFunc ;Dist

Func Nuke()
	Out("Kill them all")
	$deadlock = 0
	$target = GetNearestEnemyToAgent(-2)
	Local $me = GetAgentByID(-2)
	Local $e = 0, $shouldmove = False
	Do
		if GetIsDead() Then
			;HardLeave()
			Out("Found ourself dead")
			return 0
		EndIf
		RndSleep(50)
		$deadlock += 100
		$e = GetEnergy($me)
		if GetSkillBarSkillRecharge(3) = 0 and DllStructGetData($me, 'HP') < 1/2 Then
			UseSkillEx(3, -2)
		Else
			KeepUpBoon()
			If GetSkillBarSkillRecharge(6) = 0 Then
				If $e >= 15 Then UseSkillEx(6, -2)
			ElseIf GetSkillBarSkillRecharge(5) = 0 Then
				If $e >= 5 Then UseSkillEx(5, -2)
			ElseIf GetSkillBarSkillRecharge(4) = 0 Then
				If $e >= 5 Then UseSkillEx(4, -2)
			ElseIf GetSkillBarSkillRecharge(3) = 0 Then
				UseSkillEx(3, -2)
			ElseIf GetSkillBarSkillRecharge(2) = 0 Then
				If $e >= 15 Then UseSkillEx(2, -2)
			ElseIf GetSkillBarSkillRecharge(1) = 0 Then
				If $e >= 5 Then UseSkillEx(1, -2)
			Else
				Attack($target)
			EndIf
		EndIf
		$target = GetNearestEnemyToAgent(-2)
		ChangeTarget($target)
	Until DllStructGetData($target, 'HP') = 0 Or GetNumberOfFoesInRangeOfAgent1(-2, 1012) = 0 Or $deadlock > 6000 Or GetDistance($target, -2) > 1150
	Sleep(3000)

	Out("Picking up items")
	PickUpLoot()
	Out("Waiting for CD")
	Local $lastHP = DllStructGetData($me, 'HP')
	Do
		if GetIsDead() Then
			Out("Found ourself dead")
			return 0
		EndIf
		If DllStructGetData($me, 'HP') < $lastHP Then
			if Nuke()==0 Then return 0
		EndIf
		KeepUpBoon()
		$lastHP = DllStructGetData($me, 'HP')
		Sleep(Random(1000,2000))
		$i=0
		If GetSkillBarSkillRecharge(3) == 0 Then
			$i = $i + 1
		EndIf
		If GetSkillBarSkillRecharge(4) == 0 Then
			$i = $i + 1
		EndIf
		If GetSkillBarSkillRecharge(5) == 0 Then
			$i = $i + 1
		EndIf
		If GetSkillBarSkillRecharge(6) == 0 Then
			$i = $i + 1
		EndIf
	Until $i > 2
	return 1
EndFunc ;Nuke

Func MoveAway($start,$target)
	$xdiff = DllStructGetData($start,"X")-DllStructGetData($target,"X")
	$ydiff = DllStructGetData($start,"Y")-DllStructGetData($target,"Y")
	MoveTo(DllStructGetData($start,"X")+Random()*$xdiff,DllStructGetData($start,"Y")+Random()*$ydiff)
EndFunc ;MoveAway

Func KeepUpBoon()
	If GetSkillBarSkillRecharge(8) == 0 And DllStructGetData(GetEffect(1230), 'SkillID') <> 1230 and GetEnergy(-2)>=10 Then UseSkillEx(8, -2)
	RndSleep(250)
	If GetSkillBarSkillRecharge(7) == 0 And DllStructGetData(GetEffect(1229), 'SkillID') <> 1229 and GetEnergy(-2)>=5 Then UseSkillEx(7, -2)
EndFunc ;KeepUpBoon

Func GoMerchant()
	MoveTo(16821,9924,100)
	RndSleep(600)
	MoveTo(16568,11932,100)
	RndSleep(600)
	MoveTo(17219,12378)
	RndSleep(600)
	GoToNPC(GetNearestNPCToCoords(17219,12378))
EndFunc ;GoMerchant

#Region Loot
Func PickUpLoot()
	Local $me
	Local $lBlockedTimer
	Local $lBlockedCount = 0
	Local $JAYA_BLUFFtemExists = True
	For $i = 1 To GetMaxAgents()
		$lAgent = GetAgentByID($i)
		if CountSlots()=0 Then Return False
		If Not GetIsMovable($lAgent) Then ContinueLoop
		If Not GetCanPickUp($lAgent) Then ContinueLoop
		$JAYA_BLUFFtem = GetItemByAgentID($i)
		If CanPickup($JAYA_BLUFFtem) Then
			Do
				If GetDistance($JAYA_BLUFFtem) > 150 Then Move(DllStructGetData($JAYA_BLUFFtem, 'X'), DllStructGetData($JAYA_BLUFFtem, 'Y'))
				PickUpItem($JAYA_BLUFFtem)
				Sleep(GetPing())
				Do
					If GetIsDead() Then Return False
					Sleep(100)
					$me = GetAgentByID(-2)
				Until DllStructGetData($me, 'MoveX') == 0 And DllStructGetData($me, 'MoveY') == 0
				$lBlockedTimer = TimerInit()
				Do
					If GetIsDead() Then Return False
					Sleep(3)
					$JAYA_BLUFFtemExists = IsDllStruct(GetAgentByID($i))
				Until Not $JAYA_BLUFFtemExists Or TimerDiff($lBlockedTimer) > Random(5000, 7500, 1)
				If $JAYA_BLUFFtemExists Then $lBlockedCount += 1
			Until Not $JAYA_BLUFFtemExists Or $lBlockedCount > 5
		EndIf
	Next
EndFunc ;PickUpLoot

Func CanPickUp($item)
	Local $ModelID = DllStructGetData($item, 'ModelID')
	Local $ExtraID = DllStructGetData($item, 'ExtraID')
	Local $rarity = GetRarity($item)

	If $ModelID == $ITEM_DYES And ($ExtraID == $ITEM_BLACK_DYE Or $ExtraID == $ITEM_WHITE_DYE) Then Return True	;Black and White Dye ; for only B/W
	If $rarity == $RARITY_GOLD Then
		$TOTAL_GOLDS += 1
		GUICtrlSetData($COUNT_GOLDS, $TOTAL_GOLDS)
		Return True
	EndIf
	If $ModelID == $ITEM_ID_BONES Then
		$bones += DllStructGetData($item, 'Quantity')
		GUICtrlSetData($COUNT_BONES, $bones)
		Return True ;changed to false because too many bones
	EndIf
	If $ModelID == $ITEM_ID_DUST Then
		$dusts += DllStructGetData($item, 'Quantity')
		GUICtrlSetData($COUNT_DUSTS, $dusts)
		Return True
	EndIf
	If $ModelID == $ITEM_ID_FEATHER Then
		$feathers += DllStructGetData($item, 'Quantity')
		GUICtrlSetData($COUNT_FEATHERS, $feathers)
		Return True
	EndIf
	If $ModelID == $ITEM_ID_DIESSA Then Return True
	If $ModelID == $ITEM_ID_RIN Then Return True
	If $ModelID == $ITEM_ID_LOCKPICKS Then Return True
	If $ModelID == 22191 Then Return True ; Clover
	If $ModelID == $GOLD_COINS And GetGoldCharacter() < 99000 Then Return True

	Return True ;Added to gather everything
	Return False
EndFunc ;CanPickUp
#EndRegion Loot

#Region Helpers
Func Out($text)
	GUICtrlSetData($LabelStatus, $text)
EndFunc ;Out

Func VerifyConnection()
    If GetMapLoading() == 2 Then Disconnected()
EndFunc ;VerifyConneciton

Func _exit()
	If GUICtrlRead($Rendering) == $GUI_CHECKED Then
		EnableRendering()
		WinSetState($HWND, "", @SW_SHOW)
		Sleep(500)
	EndIf
	Exit
EndFunc ;_exit
#EndRegion Helpers

;=================================================================================================
; Function:            GetNearestItemToAgent($aAgent)
; Description:        Get nearest item lying on floor around $aAgent ($aAgent = -2 ourself), necessary to work with PickUpItems Func
; Parameter(s):        $aAgent: ID of Agent
; Requirement(s):    GW must be running and Memory must have been scanned for pointers (see Initialize())
; Return Value(s):    On Success - Returns ID of nearest item
;                    @extended  - distance to item
; Author(s):        GWCA team, recoded by ddarek
;=================================================================================================
Func GetNumberOfFoesInRangeOfAgent1($aAgent = -2, $fMaxDistance = 1012)
	Local $lDistance, $lCount = 0

	If IsDllStruct($aAgent) = 0 Then $aAgent = GetAgentByID($aAgent)
	For $i = 1 To GetMaxAgents()
		$lAgentToCompare = GetAgentByID($i)
		If GetIsDead($lAgentToCompare) <> 0 Then ContinueLoop
		If DllStructGetData($lAgentToCompare, 'Allegiance') = 0x3 Or DllStructGetData($lAgentToCompare, 'Type') = 0xDB Then
			$lDistance = GetDistance($lAgentToCompare, $aAgent)
			If $lDistance < $fMaxDistance Then
				$lCount += 1
			EndIf
		EndIf
	Next

	Return $lCount
EndFunc   ;==>GetNumberOfFoesInRangeOfAgent

#Region Memory
Func ReduceMemory()
	Local $ai_return = DllCall("psapi.dll", "int", "EmptyWorkingSet", "long", -1)
	Return $ai_return[0]
EndFunc ;ReduceMemory
#EndRegion
