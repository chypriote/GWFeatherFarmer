#include-once
#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <ComboConstants.au3>
#include <ScrollBarsConstants.au3>
#include "../GWA2.au3"
#include <farmingroute.au3>
#include <GuiEdit.au3>
#include "../SimpleInventory.au3"
#NoTrayIcon

#Region Constants
; === Maps ===
Global $SEITUNG_HARBOR = 250 ; Seitungs Harbor
Global $JAYA_BLUFF = 196 ; Jaya Bluff

; === Build ===
Global Const $SkillBarTemplate = "OACjAqiK5OPur53sce2gmNTnJA"

Global $SkillEnergy[8] = [5, 15, 0, 5, 5, 15, 5, 10]
Global $SkillCastTime[8] = [750, 1000, 750, 750, 1000, 1000, 2000, 2000]

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
    Do
        MoveTo(17171, 17331)
        RndSleep(200)
        MoveTo(16800, 17500)
        WaitMapLoading()
    Until GetMapID() == $JAYA_BLUFF
    RndSleep(1000)
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
    WaitMapLoading()
EndFunc ;HardLeave

Func Dist($x1, $y1, $x2, $y2)
    $x1 = ($x1-$x2)*($x1-$x2)
    $y1 = ($y1-$y2)*($y1-$y2)
    Return Sqrt($x1+$y2)
EndFunc ;Dist

Func Farm()
    Out("Start farming")
    Local $route = CreateFarmingRoute()
    Out("Running to farming route")
    MoveTo(9545,-11478)
    MoveTo(11226,-9199,100)
    Local $i = 0
    While $i < UBound($route, 1)
        KeepUpBoon()
        If Not AttackMove($route[$i][0], $route[$i][1]) Then
            If GetIsDead() Then
                $Deaths += 1
                GUICtrlSetData($LabelDeaths, $Deaths)
                While GetIsDead()
                    RndSleep(3000)
                WEnd

                If TooMuchDp() Then
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
        EndIf
        $i += 1
    WEnd
    RndSleep(200)
    Out("Run succesful")
    Return True
EndFunc ;Farm

Func TooMuchDp()
    Local $p = (1 - DllStructGetData(GetAgentByID(-2),'MaxHP') / $MAX_HP) * 100
    Return (1 - DllStructGetData(GetAgentByID(-2),'MaxHP') / $MAX_HP) * 100 > 40
EndFunc

Func AttackMove($x, $y)
    Local $iBlocked = 0
    Out("Hunting " & $x & " " & $y)

    Do
        If GetIsDead() Then Return False
        Do
            Move($x, $y)
            RndSleep(250)
        Until EnemyInRange() Or ReachedDestination($x, $y)

        If EnemyInRange() Then
            Fight()
            Loot()
        EndiF

        WaitRecharge()

        $iBlocked += 1
    Until ReachedDestination($x, $y) Or $iBlocked > 20
    If $iBlocked > 20 Then Return False
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
    Until $target == 0 Or Not TargetIsInRange() Or $iBlocked > 20
    RndSleep(250)
    Return True
EndFunc ;Fight

Func UseSkills()
    For $i = 0 To 7
        If Not TargetIsAlive() Then ExitLoop
        $recharge = DllStructGetData(GetSkillBar(), "Recharge" & $i + 1)

        If Not TargetIsSpiritRange() And $i < 6 Then ContinueLoop
        If $recharge == 0 And GetEnergy() >= $SkillEnergy[$i] Then
            Out("Using skill " & $i)
            $useSkill = $i + 1
            UseSkill($useSkill, GetCurrentTarget())
            RndSleep($SkillCastTime[$i] + 500)
        EndIf
    Next
EndFunc ;UseSkill

Func WaitRecharge()
    Local $j = 0
    For $i = 1 To 5
        If GetSkillbarSkillRecharge($i) Then $j += 1
    Next
    Return $j > 2
EndFunc ;WaitRecharge
#EndRegion Fight

Func KeepUpBoon()
    If GetSkillBarSkillRecharge(8) == 0 And DllStructGetData(GetEffect(1230), 'SkillID') <> 1230 and GetEnergy(-2)>=10 Then UseSkill(8, -2)
    RndSleep(250)
    If GetSkillBarSkillRecharge(7) == 0 And DllStructGetData(GetEffect(1229), 'SkillID') <> 1229 and GetEnergy(-2)>=5 Then UseSkill(7, -2)
EndFunc ;KeepUpBoon

Func GoMerchant()
    GoToNPC(GetNearestNPCToCoords(17219, 12378))
EndFunc ;GoMerchant

#Region Loot
Func Loot()
    Local $agent, $agentID, $deadlock
    Out("Looting")

    If GetIsDead() Then Return False
    If InventoryIsFull() Then Return False ;full inventory dont try to pick up

    For $agentID = 1 To GetMaxAgents()
        $agent = GetAgentByID($agentID)
        If Not GetIsMovable($agent) Or Not GetCanPickUp($agent) Or InventoryIsFull() Then ContinueLoop
        $item = GetItemByAgentID($agentID)

        If Not CanPickUp($item) Then ContinueLoop
        PickUpItem($item)
        Out("Picking up " & $agentID)

        $deadlock = TimerInit()
        While IsDllStruct(GetAgentByID($agentID))
            Sleep(100)
            If TimerDiff($deadlock) > 11000 Then ExitLoop
        WEnd
    Next
EndFunc ;Loot

Func CanPickUp($item)
    Local $ModelID = DllStructGetData($item, 'ModelID')
    Local $ExtraID = DllStructGetData($item, 'ExtraID')
    Local $rarity = GetRarity($item)

    If $ModelID == $ITEM_DYES And ($ExtraID == $ITEM_BLACK_DYE Or $ExtraID == $ITEM_WHITE_DYE) Then Return True	;Black and White Dye ; for only B/W
    If $rarity == $RARITY_GOLD Then Return True
    If $ModelID == $ITEM_ID_BONES Then
        $bones += DllStructGetData($item, 'Quantity')
        GUICtrlSetData($LabelBones, $bones)
        Return True ;changed to false because too many bones
    EndIf
    If $ModelID == $ITEM_ID_FEATHER Then
        $feathers += DllStructGetData($item, 'Quantity')
        GUICtrlSetData($LabelFeathers, $feathers)
        Return True
    EndIf
    If $ModelID == $ITEM_ID_FEATHERED_CREST Then
        $crests += 1
        GUICtrlSetData($LabelCrests, $crests)
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

#Region FightHelpers
Func ReachedDestination($x, $y)
    $me = GetAgentByID()
    $distance = ComputeDistance(DllStructGetData($me, 'X'), DllStructGetData($me, 'Y'), $x, $y)
    Return $distance < 250
EndFunc ;ReachedDestination
Func EnemyInRange()
    $enemy = GetNearestEnemyToAgent()
    If $enemy == 0 Then Return False

    Return GetDistance($enemy) < 1200
EndFunc ;EnemyInRange
Func TargetIsAlive()
    Return DllStructGetData(GetCurrentTarget(), 'HP') > 0 And DllStructGetData(GetCurrentTarget(), 'Effects') <> 0x0010
EndFunc ;TargetIsAlive
Func TargetIsInRange()
    Return GetDistance(GetCurrentTarget()) < 1200
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
