#include <ButtonConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <ComboConstants.au3>
#include "../GWA2/GWA2.au3"
#include "../_SimpleInventory.au3"
GUISetIcon(@ScriptDir & "\feather.ico")
TraySetIcon(@ScriptDir & "\feather.ico")
#NoTrayIcon

#Region Constants
; === Maps ===
Global $SEITUNG_HARBOR = 250 ; Seitungs Harbor
Global $JAYA_BLUFF = 196 ; Jaya Bluff

; === Build ===
Global Const $SkillBarTemplate = "OACjAqiK5OPur53sce2gmNTnJA"

Global $SkillEnergy[8] = [5, 15, 0, 5, 5, 15, 5, 10]
Global $SkillCastTime[8] = [750, 1000, 750, 750, 1000, 1000, 2000, 2000]
#EndRegion Constants

#Region Declarations
Opt("GUIOnEventMode", True)
Global $feathers = 0
Global $bones = 0
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
$USE_EXPERT_ID_KIT = False

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
	$LabelDeaths = GUICtrlCreateLabel("0", 150, 90, 50, 15, $SS_RIGHT)
GUICtrlCreateLabel("Total gold earned:", 10, 110, 90, 15)
	$LabelGolds = GUICtrlCreateLabel("0", 150, 110, 50, 15, $SS_RIGHT)
GUICtrlCreateLabel("Feathers:", 10, 130, 66, 15)
	$LabelFeathers = GUICtrlCreateLabel("0", 150, 130, 50, 15, $SS_RIGHT)
GUICtrlCreateLabel("Feathered Crests:", 10, 150, 105, 15)
	$LabelCrests = GUICtrlCreateLabel("0", 150, 150, 50, 15, $SS_RIGHT)
GUICtrlCreateLabel("Bones:", 10, 170, 105, 15)
	$LabelBones = GUICtrlCreateLabel("0", 150, 170, 50, 15, $SS_RIGHT)

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

	$TOTAL_GOLDS += GetGoldCharacter() - $INITIAL_GOLD
	GUICtrlSetData($LabelGolds, $TOTAL_GOLDS)
	$TOTAL_RUNS += 1
	GUICtrlSetData($LabelRun, $TOTAL_RUNS)

	Farm()

	Out("Returning to Harbor")
	HardLeave()
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

	If CountSlots() < 10 Then Inventory()
	RndSleep(500)
	SetupResign()
	$INITIAL_GOLD = GetGoldCharacter()
EndFunc ;Setup

Func SetupResign()
	Out("Setting up resign")
	GoPortal()
	EnterArea()
	Out("Go back")
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
	MoveTo(17171, 17331)
	RndSleep(200)
	Move(16800, 17500)
	WaitMapLoading($JAYA_BLUFF)
EndFunc ;EnterArea
#EndRegion Setup

Func GUI_EventHandler()
	Switch (@GUI_CtrlId)
		Case $GUI_EVENT_CLOSE
			Exit
		Case $cbxHideGW
			If GUICtrlRead($cbxHideGW) == 1 Then
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
		If GUICtrlRead($CharacterName) == "" Then
			If Not Initialize(ProcessExists("gw.exe")) Then
				MsgBox(0, "Error", "Guild Wars Is not running.")
				Exit
			EndIf
			$gwpid=ProcessExists("gw.exe")
		Else
			If Not Initialize(GUICtrlRead($CharacterName), True, True) Then
				MsgBox(0, "Error", "Can't find a Guild Wars client with that character name.")
				Exit
			EndIf
			$lWinList = ProcessList('gw.exe')
			For $i = 1 To $lWinList[0][0]
				$mGWHwnd = $lWinList[$i][1]
				MemoryOpen($mGWHwnd)
				If StringRegExp(ScanForCharname(), GUICtrlRead($CharacterName)) Then
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
	WaitMapLoading($SEITUNG_HARBOR)
EndFunc ;HardLeave

Func Farm()
	Out("Running to farming route")
	MoveTo(9545, -11478)
	MoveTo(11226, -9199, 100)

	Local $route[41][2] = [ _
		[12020, -6218], _
		[12021, -5815], _
		[10069, -6791], _
		[8678, -6602], _
		[7020, -5578], _
		[5033, -4532], _
		[4202, -1804], _
		[1519, -763], _
		[381, 657], _
		[-499, 1758], _
		[-492, 2537], _
		[-2256, 2418], _
		[-3205, 2418], _
		[-3691, 888], _
		[-2551, -521], _
		[-2458, -1202], _
		[-3988, -2440], _
		[-5791, -3179], _
		[-6375, -3320], _
		[-6915, -2723], _
		[-6475, -3140], _
		[-5503, -3532], _
		[-2205, -3590], _
		[-732, -4359], _
		[-353, -6682], _
		[-2056, -8224], _
		[-4218, -7767], _
		[-6150, -7394], _
		[-7660, -9095], _
		[-8455, -7300], _
		[-8778, -8544], _
		[-10431, -8705], _
		[-13613, -4731], _
		[-14189, -2634], _
		[-13513, -1885], _
		[-10872, -3658], _
		[-12139, -1372], _
		[-12015, 816], _
		[-10676, 3225], _
		[-10009, 3637], _
		[-10465, 5466] _
	]

	For $i = 0 To UBound($route)
		KeepUpBoon()
		If InventoryIsFull() Then ContinueLoop
		If Not AttackMove($route[$i][0], $route[$i][1]) Then
			If GetIsDead() Then
				$Deaths += 1
				GUICtrlSetData($LabelDeaths, $Deaths)
				Return False
			EndIf
		EndIf
	Next
	RndSleep(200)
	Out("Run succesful")
	Return True
EndFunc ;Farm

Func AttackMove($x, $y)
	Local $iBlocked = 0

	Do
		If GetIsDead() Then Return False
		Out("Going to " & $x & " " & $y)
		Do
			Move($x, $y)
			RndSleep(250)
		Until EnemyInRange() Or ReachedDestination($x, $y)

		If EnemyInRange() Then
			Fight()
			Loot()
		EndiF

		If Not GetIsDead() Then WaitRecharge()

		$iBlocked += 1
	Until ReachedDestination($x, $y) Or $iBlocked > 5
	If $iBlocked > 5 Then Return False
	RndSleep(250)
	Return True
EndFunc ;AttackMove

#Region Fight
Func Fight()
	Local $iBlocked = 0
	$target = GetNearestEnemyToAgent()
	ChangeTarget($target)
	RndSleep(150)

	Do
		If GetIsDead() Then Return False
		KeepUpBoon()
		CallTarget($target)
		RndSleep(150)

		Local $lDeadlock = TimerInit()
		Do
			If GetIsDead() Then Return False
			Attack($target)
			KeepUpBoon()
			UseSkills()
			RndSleep(150)
		Until Not TargetIsAlive() Or TimerDiff($lDeadlock) > 10000

		$target = GetNearestEnemyToAgent()
		ChangeTarget($target)
		RndSleep(300)
		$iBlocked += 1
	Until $target == 0 Or Not TargetIsInRange() Or $iBlocked > 5

	RndSleep(250)
	Return True
EndFunc ;Fight

Func UseSkills()
	For $i = 0 To 7
		If Not TargetIsAlive() Then ExitLoop
		Local $skill = GetSkillByID(GetSkillbarSkillID($i, 0))
		$recharge = DllStructGetData(GetSkillBar(), "Recharge" & $i + 1)

		If Not TargetIsSpiritRange() And $i < 6 Then ContinueLoop
		If $recharge == 0 And GetEnergy() >= GetEnergyCostEx($skill) Then
			$useSkill = $i + 1
			UseSkill($useSkill, GetCurrentTarget())
			RndSleep($SkillCastTime[$i] + 500)
		EndIf
	Next
EndFunc ;UseSkill

Func WaitRecharge()
	Out("wait recharge")
	Local $j = 0
	Do 
		For $i = 1 To 5
			If GetSkillbarSkillRecharge($i) Then $j += 1
		Next
		RndSleep(1000)
	Until $j < 3

	Return $j > 2
EndFunc ;WaitRecharge
#EndRegion Fight

Func KeepUpBoon()
	If GetSkillBarSkillRecharge(8) == 0 And DllStructGetData(GetEffect(1230), 'SkillID') <> 1230 and GetEnergy(-2)>=10 Then UseSkill(8, -2)
	RndSleep(250)
	If GetSkillBarSkillRecharge(7) == 0 And DllStructGetData(GetEffect(1229), 'SkillID') <> 1229 and GetEnergy(-2)>=5 Then UseSkill(7, -2)
EndFunc ;KeepUpBoon

Func GoMerchant()
    MoveTo(18887, 16337)
	GoToNPC(GetNearestNPCToCoords(17219, 12378))
EndFunc ;GoMerchant

#Region Loot
Func Loot()
	Out("looting")
	Local $me, $agent, $item
	Local $lBlockedTimer
	Local $lBlockedCount = 0

	For $i = 1 To GetMaxAgents()
		If GetIsDead() Then Return
		If InventoryIsFull() Then ContinueLoop
		$me = GetAgentByID(-2)
		$agent = GetAgentByID($i)
		If Not GetIsMovable($agent) Or Not GetCanPickUp($agent) Then
			ContinueLoop
		EndIf
		$item = GetItemByAgentID($i)

		If CanPickUp($item) Then
			$itemExists = True
			Do
				PickUpItem($item)
				RndSleep(100)
				Do
					Sleep(100)
					$me = GetAgentByID(-2)
				Until DllStructGetData($me, 'MoveX') == 0 And DllStructGetData($me, 'MoveY') == 0
				$lBlockedTimer = TimerInit()
				Do
					Sleep(3)
					$itemExists = IsDllStruct(GetAgentByID($i))
				Until Not $itemExists Or TimerDiff($lBlockedTimer) > Random(5000, 7500, 1)
				If $itemExists Then $lBlockedCount += 1
			Until Not $itemExists Or $lBlockedCount > 5
		EndIf
	Next
EndFunc ;Loot

Func CanPickUp($item)
	Local $ModelID = DllStructGetData($item, 'ModelID')
	Local $ExtraID = DllStructGetData($item, 'ExtraID')
	Local $rarity = GetRarity($item)

	If $rarity == $RARITY_GOLD Then Return True
	If $ModelID == $ITEM_DYES And ($ExtraID == $ITEM_BLACK_DYE Or $ExtraID == $ITEM_WHITE_DYE) Then Return True	;Black and White Dye ; for only B/W

	If $ModelID == $MAT_BONES Then
		$bones += DllStructGetData($item, 'Quantity')
		GUICtrlSetData($LabelBones, $bones)
		Return True ;changed to false because too many bones
	EndIf
	If $ModelID == $MAT_FEATHER Then
		$feathers += DllStructGetData($item, 'Quantity')
		GUICtrlSetData($LabelFeathers, $feathers)
		Return True
	EndIf
	If $ModelID == $ITEM_FEATHERED_CREST Then
		$crests += 1
		GUICtrlSetData($LabelCrests, $crests)
		Return True
	EndIf
	If $ModelID == $ITEM_LOCKPICK Then Return True
	If $ModelID == $DPREMOVAL_FOUR_LEAF_CLOVER Then Return True
	If $ModelID == $GOLD_COINS And GetGoldCharacter() < 99000 Then Return True

	If InArray($ModelID, $ALL_TOMES_ARRAY)			Then Return True
	If InArray($ModelID, $ALL_TROPHIES_ARRAY)		Then Return True
	If InArray($ModelID, $ALL_TITLE_ITEMS)			Then Return True
	If InArray($ModelID, $ALL_MATERIALS_ARRAY)		Then Return True
	If InArray($ModelID, $SPECIAL_DROPS_ARRAY)		Then Return True
	If InArray($ModelID, $ALL_DPREMOVAL_ARRAY)		Then Return True

	Return False
	Return True ;Added to gather everythings
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

#Region FightHelpers
Func ReachedDestination($x, $y)
	$me = GetAgentByID()
	$distance = ComputeDistance(DllStructGetData($me, 'X'), DllStructGetData($me, 'Y'), $x, $y)
	Return $distance < 250
EndFunc ;ReachedDestination
Func EnemyInRange()
	$enemy = GetNearestEnemyToAgent()
	If $enemy == 0 Then Return False

	Return GetDistance($enemy) < 1100
EndFunc ;EnemyInRange
Func TargetIsAlive()
	Return DllStructGetData(GetCurrentTarget(), 'HP') > 0 And DllStructGetData(GetCurrentTarget(), 'Effects') <> 0x0010
EndFunc ;TargetIsAlive
Func TargetIsInRange()
	Return GetDistance(GetCurrentTarget()) < 1000
EndFunc ;TargetIsInRange
Func TargetIsSpiritRange()
	Return GetDistance(GetCurrentTarget()) < 1000
EndFunc ;TargetIsSpiritRange
#EndRegion FightHelpers

#Region Memory
Func ReduceMemory()
	Local $ai_return = DllCall("psapi.dll", "int", "EmptyWorkingSet", "long", -1)
	Return $ai_return[0]
EndFunc ;ReduceMemory
#EndRegion
