param(
    [string]$PvzExe = $env:PVZ_1051_EXE,
    [string]$Objdump = $env:OBJDUMP
)

$ErrorActionPreference = "Stop"
$ExpectedSha256 = "F9669AF338964787A3785A7895791297D599295B8BB669B0DB49443F736A1322"

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) {
        throw $Message
    }
}

function Assert-Contains {
    param([string]$Text, [string]$Needle, [string]$Message)
    Assert-True $Text.Contains($Needle) $Message
}

function Assert-Matches {
    param([string]$Text, [string]$Pattern, [string]$Message)
    Assert-True ([regex]::IsMatch(
        $Text,
        $Pattern,
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )) $Message
}

function Get-Snippet {
    param([string]$Text, [string]$Signature, [int]$Length)
    $start = $Text.IndexOf($Signature)
    Assert-True ($start -ge 0) "Missing source signature: $Signature"
    return $Text.Substring($start, [Math]::Min($Length, $Text.Length - $start))
}

function Get-EnumValue {
    param([string]$HeaderText, [string]$EnumName, [string]$MemberName)

    $match = [regex]::Match(
        $HeaderText,
        "enum\s+$([regex]::Escape($EnumName))\s*\{(?<body>.*?)\};",
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )
    Assert-True $match.Success "Missing enum $EnumName"

    $nextValue = 0
    foreach ($rawLine in ($match.Groups["body"].Value -split "`r?`n")) {
        $line = ($rawLine -replace "//.*", "").Trim().TrimEnd(",").Trim()
        if ($line -notmatch "^(?<name>[A-Za-z_][A-Za-z0-9_]*)(\s*=\s*(?<value>-?0x[0-9A-Fa-f]+|-?\d+))?") {
            continue
        }

        $name = $Matches["name"]
        $valueText = $Matches["value"]
        if ([string]::IsNullOrEmpty($valueText)) {
            $currentValue = $nextValue
        }
        elseif ($valueText -match "^-?0x") {
            $sign = if ($valueText.StartsWith("-")) { -1 } else { 1 }
            $digits = $valueText.TrimStart("-").Substring(2)
            $currentValue = $sign * [Convert]::ToInt32($digits, 16)
        }
        else {
            $currentValue = [int]$valueText
        }
        $nextValue = $currentValue + 1

        if ($name -eq $MemberName) {
            return $currentValue
        }
    }

    throw "Missing enum member ${EnumName}::${MemberName}"
}

function Resolve-Application {
    param([string]$Value, [string]$FallbackName)

    if ($Value -and (Test-Path -LiteralPath $Value)) {
        return (Resolve-Path -LiteralPath $Value).Path
    }

    $name = if ($Value) { $Value } else { $FallbackName }
    $command = Get-Command $name -CommandType Application -ErrorAction SilentlyContinue
    Assert-True ($null -ne $command) "Executable not found: $name"
    return $command.Source
}

function Get-Disassembly {
    param([string]$Start, [string]$Stop)

    $dump = & $script:ObjdumpPath -d -Mintel "--start-address=$Start" "--stop-address=$Stop" $script:PvzExePath 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -eq 0) "objdump failed for $Start..$Stop"
    return $dump
}

function Get-HexDump {
    param([string]$Start, [string]$Stop)

    $dump = & $script:ObjdumpPath -s "--start-address=$Start" "--stop-address=$Stop" $script:PvzExePath 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -eq 0) "objdump failed for $Start..$Stop"
    return $dump
}

$RepoRoot = Split-Path -Parent $PSScriptRoot
$PlantSource = Get-Content -LiteralPath (Join-Path $RepoRoot "Lawn\Plant.cpp") -Raw -Encoding Default
$BoardSource = Get-Content -LiteralPath (Join-Path $RepoRoot "Lawn\Board.cpp") -Raw -Encoding Default
$ChallengeSource = Get-Content -LiteralPath (Join-Path $RepoRoot "Lawn\Challenge.cpp") -Raw -Encoding Default
$ChallengeHeader = Get-Content -LiteralPath (Join-Path $RepoRoot "Lawn\Challenge.h") -Raw -Encoding Default
$ZombieSource = Get-Content -LiteralPath (Join-Path $RepoRoot "Lawn\Zombie.cpp") -Raw -Encoding Default
$CoinSource = Get-Content -LiteralPath (Join-Path $RepoRoot "Lawn\Coin.cpp") -Raw -Encoding Default
$CutSceneSource = Get-Content -LiteralPath (Join-Path $RepoRoot "Lawn\CutScene.cpp") -Raw -Encoding Default
$ZenGardenSource = Get-Content -LiteralPath (Join-Path $RepoRoot "Lawn\ZenGarden.cpp") -Raw -Encoding Default
$SeedChooserSource = Get-Content -LiteralPath (Join-Path $RepoRoot "Lawn\Widget\SeedChooserScreen.cpp") -Raw -Encoding Default
$StoreScreenSource = Get-Content -LiteralPath (Join-Path $RepoRoot "Lawn\Widget\StoreScreen.cpp") -Raw -Encoding Default
$GameSelectorSource = Get-Content -LiteralPath (Join-Path $RepoRoot "Lawn\Widget\GameSelector.cpp") -Raw -Encoding Default
$LawnAppSource = Get-Content -LiteralPath (Join-Path $RepoRoot "LawnApp.cpp") -Raw -Encoding Default
$AwardSource = Get-Content -LiteralPath (Join-Path $RepoRoot "Lawn\Widget\AwardScreen.cpp") -Raw -Encoding Default
$ConstEnums = Get-Content -LiteralPath (Join-Path $RepoRoot "ConstEnums.h") -Raw -Encoding Default

$pickSpeed = Get-Snippet $ZombieSource "void Zombie::PickRandomSpeed()" 1000
Assert-Contains $pickSpeed "if (mZombiePhase == ZombiePhase::PHASE_SNORKEL_WALKING_IN_POOL)" `
    "PickRandomSpeed must use the snorkel walking phase for the 0.3f branch"
Assert-True (-not $pickSpeed.Contains("PHASE_DOLPHIN_WALKING_IN_POOL")) `
    "PickRandomSpeed must not use the dolphin walking phase for the 0.3f branch"

$poolTypes = Get-Snippet $ZombieSource "bool Zombie::ZombieTypeCanGoInPool" 1100
Assert-Contains $poolTypes "theZombieType == ZombieType::ZOMBIE_BALLOON" `
    "ZombieTypeCanGoInPool must allow balloon zombies"

$shoot = Get-Snippet $PlantSource "bool Plant::FindTargetAndFire" 6500
Assert-Matches $shoot "mShootingCounter\s*=\s*35;.*mShootingCounter\s*=\s*26;.*mShootingCounter\s*=\s*100;" `
    "FindTargetAndFire must keep the original 35/26/100 shooting counters"

$squash = Get-Snippet $PlantSource "void Plant::UpdateSquash()" 5000
Assert-Contains $squash "mY = TodAnimateCurve(10, 0, mStateCountdown, aDestY - 120, aDestY, TodCurves::CURVE_LINEAR);" `
    "UpdateSquash falling must use the linear curve"

$blow = Get-Snippet $PlantSource "void Plant::BlowAwayFliers" 1700
Assert-Matches $blow "if\s*\(\s*aZombie->mZombiePhase\s*==\s*ZombiePhase::PHASE_BALLOON_FLYING\s*\)\s*\{" `
    "BlowAwayFliers must accept only the balloon flying phase"
Assert-True (-not $blow.Contains("aZombie->IsFlying()")) `
    "BlowAwayFliers must not include the balloon popping phase through IsFlying"
Assert-True (-not $blow.Contains("PHASE_BALLOON_POPPING")) `
    "BlowAwayFliers must not include the balloon popping phase directly"

$isFlying = Get-Snippet $ZombieSource "bool Zombie::IsFlying()" 500
Assert-Matches $isFlying "mZombiePhase\s*==\s*ZombiePhase::PHASE_BALLOON_FLYING\s*\|\|\s*mZombiePhase\s*==\s*ZombiePhase::PHASE_BALLOON_POPPING" `
    "Zombie::IsFlying must retain OR semantics for the flying and popping phases"

$blover = Get-Snippet $PlantSource "void Plant::UpdateBlover()" 1800
Assert-Contains $blover "mState != PlantState::STATE_DOINGSPECIAL && mDoSpecialCountdown == 0" `
    "UpdateBlover must test mDoSpecialCountdown"

$plantsOnLawn = Get-Snippet $BoardSource "void Board::GetPlantsOnLawn" 4500
Assert-Contains $plantsOnLawn "if (Plant::IsFlying(aSeedType))" `
    "GetPlantsOnLawn must classify flying plants by the effective imitater type"

$iZombie = Get-Snippet $ChallengeSource "void Challenge::IZombiePlaceZombie" 1500
Assert-Contains $iZombie "aZombie->SetRow(theGridY);" "IZombie bungee placement must use the requested row"
Assert-True (-not $iZombie.Contains("aZombie->SetRow(theGridX);")) `
    "IZombie bungee placement must not use the requested column as its row"

$yuckyFace = Get-Snippet $ZombieSource "void Zombie::UpdateYuckyFace()" 6500
Assert-Matches $yuckyFace "if\s*\(aCanGoDown && !aCanGoUp\).*?SetRow\(mRow \+ 1\);" `
    "UpdateYuckyFace must move down to row + 1"
Assert-Matches $yuckyFace "else if\s*\(!aCanGoDown && aCanGoUp\).*?SetRow\(mRow - 1\);" `
    "UpdateYuckyFace must move up to row - 1"

Assert-Contains $ChallengeSource "bool Challenge::UpdateZombieSpawning()" `
    "UpdateZombieSpawning definition must return bool"
Assert-Contains $ChallengeHeader "bool                   UpdateZombieSpawning();" `
    "UpdateZombieSpawning declaration must return bool"

$award = Get-Snippet $AwardSource "void AwardScreen::Draw(Graphics* g)" 14000
Assert-Contains $award "TodDrawImageCelCenterScaledF(g, Sexy::IMAGE_SUNFLOWER_TROPHY, 325, 65, 1, 0.6f, 0.6f);" `
    "AwardScreen gold trophy must use the original position and scale"

$slotMachine = Get-Snippet $ChallengeSource "void Challenge::UpdateSlotMachine()" 8500
Assert-Contains $slotMachine "for (int i = 0; i < 3; i++)" `
    "Slot machine plant triples must award three seed packets"

$pickerForWave = Get-Snippet $BoardSource "void ZombiePickerInitForWave" 450
Assert-Contains $pickerForWave "memset(theZombiePicker->mZombieTypeCount, 0, sizeof(theZombiePicker->mZombieTypeCount));" `
    "Per-wave zombie picker initialization must preserve all-wave counts"
Assert-True (-not $pickerForWave.Contains("sizeof(ZombiePicker)")) `
    "Per-wave zombie picker initialization must not clear the whole picker"

$scaryPotter = Get-Snippet $LawnAppSource "bool LawnApp::IsScaryPotterLevel()" 450
Assert-Contains $scaryPotter "GAMEMODE_SCARY_POTTER_ENDLESS" `
    "Scary Potter detection must include endless mode"

$shovelWallnuts = Get-Snippet $ChallengeSource "void Challenge::ShovelAddWallnuts()" 500
Assert-Contains $shovelWallnuts "aRow < MAX_GRID_SIZE_Y - 1" `
    "Shovel challenge must plant wall-nuts in five rows"

$nextWave = Get-Snippet $BoardSource "void Board::NextWaveComing()" 1500
Assert-Contains $nextWave "mApp->IsWhackAZombieLevel() ? (mCurrentWave == mNumWaves - 1) : IsFlagWave(mCurrentWave)" `
    "Whack-a-zombie siren logic must be exclusive from ordinary flag-wave logic"

$openGardenSpot = Get-Snippet $ZenGardenSource "void ZenGarden::FindOpenZenGardenSpot" 1800
Assert-Contains $openGardenSpot "goto nextSpot;" `
    "Occupied Zen Garden cells must be skipped as whole candidates"

$jalapenoHead = Get-Snippet $ZombieSource "void Zombie::UpdateZombieJalapenoHead()" 2600
Assert-Matches $jalapenoHead "#endif\s*DieNoLoot\(\);" `
    "Jalapeno-head zombies must die after exploding"

$potterPopulate = Get-Snippet $ChallengeSource "void Challenge::ScaryPotterPopulate()" 11000
Assert-Contains $potterPopulate "ScaryPotterPlacePot(SCARYPOT_ZOMBIE, ZOMBIE_FOOTBALL, SEED_NONE, 2" `
    "Scary Potter level 6 must contain two football zombies"
Assert-Contains $potterPopulate "ScaryPotterPlacePot(SCARYPOT_ZOMBIE, ZOMBIE_JACK_IN_THE_BOX, SEED_NONE, 1" `
    "Scary Potter level 6 must contain one jack-in-the-box zombie"

$feedingTool = Get-Snippet $ZenGardenSource "void ZenGarden::MouseDownWithFeedingTool" 7500
Assert-Contains $feedingTool "aZenTool->mGridItemState = GridItemState::GRIDITEM_STATE_ZEN_TOOL_WATERING_CAN;" `
    "The ordinary watering can must use the ordinary tool state"

$collectCoin = Get-Snippet $CoinSource "void Coin::Collect()" 10500
Assert-Matches $collectCoin "COIN_AWARD_MONEY_BAG\).*?FanOutCoins\(CoinType::COIN_GOLD, 2\);" `
    "Scary Potter money bags must fan out two gold coins"

$puzzleComplete = Get-Snippet $ChallengeSource "void Challenge::PuzzlePhaseComplete" 2700
Assert-Contains $puzzleComplete "COIN_AWARD_CHOCOLATE : COIN_AWARD_MONEY_BAG" `
    "Puzzle phase rewards must use award chocolate"

$spawning = Get-Snippet $BoardSource "void Board::UpdateZombieSpawning()" 6500
Assert-Contains $spawning "IsFlagWave(mCurrentWave) && !(mApp->IsWallnutBowlingLevel()" `
    "Flag-wave delay must exclude Wall-nut Bowling and Last Stand"

$davePicks = Get-Snippet $SeedChooserSource "void SeedChooserScreen::CrazyDavePickSeeds()" 4300
Assert-Contains $davePicks "if (aRecFlags ||" `
    "Crazy Dave seed selection must reject not-recommended seeds"

$plantFire = Get-Snippet $PlantSource "void Plant::Fire(" 6000
Assert-Contains $plantFire "aOriginX = mX - aOffsetX + 27;" `
    "Leftpeater firing must mirror the animated head offset"

$initLevel = Get-Snippet $BoardSource "void Board::InitLevel()" 10000
Assert-Matches $initLevel "GAMEMODE_CHALLENGE_ZOMBIQUARIUM.*?SEED_ZOMBIQUARIUM_SNORKLE.*?SEED_ZOMBIQUARIUM_TROPHY" `
    "Zombiquarium must initialize snorkel and trophy packets"

$twistMatch = Get-Snippet $ChallengeSource "int Challenge::BeghouledTwistMoveCausesMatch" 1900
Assert-Matches $twistMatch "\[theGridX \+ 1\]\[theGridY\] = aSeed1;.*?\[theGridX \+ 1\]\[theGridY \+ 1\] = aSeed2;.*?\[theGridX\]\[theGridY \+ 1\] = aSeed4;.*?\[theGridX\]\[theGridY\] = aSeed3;" `
    "Beghouled Twist match prediction must rotate the four cells clockwise"

$dragUpdate = Get-Snippet $ChallengeSource "void Challenge::BeghouledDragUpdate" 1900
Assert-Contains $dragUpdate "if (abs(aDeltaX) > abs(aDeltaY))" `
    "Beghouled drag direction must compare absolute axis distances"

$zombieAtePlant = Get-Snippet $ChallengeSource "void Challenge::ZombieAtePlant" 900
Assert-Matches $zombieAtePlant "mNumPackets = 5;.*?SEED_BEGHOULED_BUTTON_CRATER" `
    "Beghouled crater packet unlock must expose the fifth packet"

$canPlantAt = Get-Snippet $ChallengeSource "PlantingReason Challenge::CanPlantAt" 6000
Assert-Contains $canPlantAt "if (theSeedType == SEED_ZOMBIE_BUNGEE)" `
    "I, Zombie bungee placement must compare the seed enum"

$zombiquarium = Get-Snippet $ChallengeSource "void Challenge::ZombiquariumUpdate()" 4200
Assert-Matches $zombiquarium "TUTORIAL_ZOMBIQUARIUM_CLICK_TROPHY.*?mTutorialState = TUTORIAL_ZOMBIQUARIUM_BOUGHT_SNORKEL;" `
    "Unaffordable Zombiquarium trophy clicks must return to the bought-snorkel tutorial state"

$upgradePackets = Get-Snippet $ChallengeSource "void Challenge::BeghouledPacketClicked" 6200
Assert-True (([regex]::Matches($upgradePackets, "theSeedPacket->SetActivate\(false\);")).Count -ge 3) `
    "Each Beghouled plant upgrade must deactivate its packet"

$squirrelStart = Get-Snippet $ChallengeSource "void Challenge::SquirrelStart()" 1500
Assert-Contains $squirrelStart "RandRangeInt(100, 500)" `
    "Squirrel initial waits must range from 100 through 500"
$squirrelChew = Get-Snippet $ChallengeSource "void Challenge::SquirrelChew" 700
Assert-Contains $squirrelChew "RandRangeInt(100, 500)" `
    "Squirrel chewing waits must range from 100 through 500"
$squirrelFound = Get-Snippet $ChallengeSource "void Challenge::SquirrelFound" 3600
Assert-Matches $squirrelFound "aGrid->mX != theSquirrel->mGridX.*?RUNNING_LEFT.*?RUNNING_RIGHT.*?RUNNING_UP.*?RUNNING_DOWN.*?mGridItemCounter = 50;" `
    "Squirrel movement must select all four directions and run for 50 centiseconds"

$tallnutHead = Get-Snippet $ZombieSource "case ZombieType::ZOMBIE_TALLNUT_HEAD" 1300
Assert-Contains $tallnutHead "mHelmType = HelmType::HELMTYPE_TALLNUT;" `
    "Tall-nut-head zombies must use tall-nut damage art"

$advanceDave = Get-Snippet $CutSceneSource "void CutScene::AdvanceCrazyDaveDialog" 9000
Assert-Contains $advanceDave "mPurchases[(int)StoreItem::STORE_ITEM_TREE_FOOD] = PURCHASE_COUNT_OFFSET + 5;" `
    "Tree of Wisdom introduction must grant tree food in the correct store slot"
Assert-Contains $advanceDave "aNumPackets + 7" `
    "Packet-upgrade dialog must display the total slot count"
Assert-Contains $advanceDave "GetMoneyString(aCost)" `
    "Packet-upgrade dialog must display the upgrade price"
Assert-Matches $advanceDave "else if \(aMessageIndex == 1553\).*?CrazyDaveTalkIndex\(1560\);" `
    "The second packet-upgrade purchase must continue from message 1553"

$soldOut = Get-Snippet $StoreScreenSource "bool StoreScreen::IsItemSoldOut" 1500
Assert-Contains $soldOut "mPurchases[STORE_ITEM_TREE_FOOD] - PURCHASE_COUNT_OFFSET >= 10" `
    "Tree food must be sold out at ten units"

$selectorUpdate = Get-Snippet $GameSelectorSource "void GameSelector::Update()" 8500
Assert-Contains $selectorUpdate "mLevel == 1 && !mApp->SaveFileExists()" `
    "Only a new level-one profile without a save must enter the intro"

$seedAvailable = Get-Snippet $LawnAppSource "bool LawnApp::SeedTypeAvailable" 500
Assert-Matches $seedAvailable "SEED_GATLINGPEA \?.*?STORE_ITEM_PLANT_GATLINGPEA\] > 0 : HasSeedType\(theSeedType\)" `
    "Gatling pea availability must depend only on its purchase record"

$showShovel = Get-Snippet $CutSceneSource "void CutScene::ShowShovel()" 1200
Assert-Contains $showShovel "GAMEMODE_TREE_OF_WISDOM" `
    "Tree of Wisdom must suppress the shovel"

$boardButtons = Get-Snippet $BoardSource "bool Board::CanInteractWithBoardButtons()" 1000
Assert-Contains $boardButtons "if (mBoardFadeOutCounter >= 0)" `
    "Board buttons must be disabled during fade-out"

$upsellUpdate = Get-Snippet $CutSceneSource "void CutScene::UpdateUpsell()" 1800
Assert-Matches $upsellUpdate "CrazyDaveTalkIndex\(mCrazyDaveDialogStart\);\s*mCrazyDaveLastTalkIndex = mCrazyDaveDialogStart;" `
    "Upsell must remember the first Crazy Dave message"

$clearUpsell = Get-Snippet $CutSceneSource "void CutScene::ClearUpsellBoard()" 1800
Assert-Matches $clearUpsell "mReanimationType != ReanimationType::REANIM_CRAZY_DAVE.*?ReanimationDie\(\);" `
    "Clearing an upsell board must preserve Crazy Dave reanimations"

$dancerUpdate = Get-Snippet $ZombieSource "void Zombie::UpdateZombieDancer()" 1600
Assert-Matches $dancerUpdate "mSummonCounter--;\s*if \(mSummonCounter == 0\)" `
    "Dancer summon checks must run when the decremented counter reaches zero"

Assert-True ((Get-EnumValue $ConstEnums "ZombiePhase" "PHASE_DOLPHIN_WALKING_IN_POOL") -eq 0x37) `
    "Expected dolphin walking phase 0x37"
Assert-True ((Get-EnumValue $ConstEnums "ZombiePhase" "PHASE_SNORKEL_WALKING_IN_POOL") -eq 0x3b) `
    "Expected snorkel walking phase 0x3b"
Assert-True ((Get-EnumValue $ConstEnums "ZombiePhase" "PHASE_BALLOON_FLYING") -eq 0x49) `
    "Expected balloon flying phase 0x49"
Assert-True ((Get-EnumValue $ConstEnums "ZombiePhase" "PHASE_BALLOON_POPPING") -eq 0x4a) `
    "Expected balloon popping phase 0x4a"
Assert-True ((Get-EnumValue $ConstEnums "ZombieType" "ZOMBIE_BALLOON") -eq 0x10) `
    "Expected balloon zombie type 0x10"

Assert-True (-not [string]::IsNullOrWhiteSpace($PvzExe)) `
    "Pass -PvzExe or set PVZ_1051_EXE to the PvZ 1.0.0.1051 executable"
$script:PvzExePath = (Resolve-Path -LiteralPath $PvzExe).Path
$script:ObjdumpPath = Resolve-Application $Objdump "objdump"
Assert-True ((Get-FileHash -Algorithm SHA256 -LiteralPath $script:PvzExePath).Hash -eq $ExpectedSha256) `
    "PvZ executable SHA-256 does not match version 1.0.0.1051"

$dump = Get-Disassembly "0x524a70" "0x524ab0"
Assert-Matches $dump "524a77:.*cmp\s+edx,0x3b" "PickRandomSpeed binary must compare phase 0x3b"

$dump = Get-Disassembly "0x532060" "0x5320b0"
Assert-Matches $dump "532073:.*cmp\s+eax,0x10" "Pool eligibility binary must include zombie type 0x10"

$dump = Get-Disassembly "0x45f030" "0x45f060"
Assert-Matches $dump "45f045:.*\[esi\+0x90\],0x23" "FindTargetAndFire binary must write shooting counter 35"

$dump = Get-Disassembly "0x460c60" "0x460c90"
Assert-Matches $dump "460c6c:.*push\s+0x1.*460c7a:.*call\s+0x511c40" `
    "UpdateSquash falling binary must pass CURVE_LINEAR to TodAnimateCurve"

$dump = Get-Disassembly "0x4665f0" "0x466620"
Assert-Matches $dump "4665fe:.*cmp\s+eax,0x49" "BlowAwayFliers binary must accept phase 0x49"
Assert-Matches $dump "466608:.*cmp\s+eax,0x4a.*46660b:.*je\s+0x466614" `
    "BlowAwayFliers binary must reject phase 0x4a"
Assert-Matches $dump "46660d:.*\[ebx\+0xb9\],0x1" "BlowAwayFliers binary must set mBlowingAway"

$dump = Get-Disassembly "0x42a110" "0x42a140"
Assert-Matches $dump "42a125:.*\[ebx\+0x80\],edx" "IZombie binary must store target column"
Assert-Matches $dump "42a12b:.*\[ebx\+0x1c\],esi" "IZombie binary must store the requested row"

$dump = Get-Disassembly "0x40d2f8" "0x40d390"
Assert-Matches $dump "40d317:.*mov\s+edi,eax.*40d350:.*cmp\s+edi,0x23" `
    "GetPlantsOnLawn binary must classify by the effective imitater type"

$dump = Get-Disassembly "0x460f30" "0x460f55"
Assert-Matches $dump "460f44:.*\[edi\+0x50\],0x0" "UpdateBlover binary must test mDoSpecialCountdown"

$dump = Get-Disassembly "0x52b810" "0x52b930"
Assert-Matches $dump "52b826:.*\[eax-0x1\].*52b8c7:.*\[edi\+0x1c\],esi" `
    "UpdateYuckyFace binary must use row - 1 for the up-only path"
Assert-Matches $dump "52b876:.*\[eax\+0x1\].*52b8e8:.*\[edi\+0x1c\],edx" `
    "UpdateYuckyFace binary must use row + 1 for the down-only path"

$dump = Get-Disassembly "0x426580" "0x426620"
Assert-Matches $dump "4265ac:.*mov\s+al,0x1" "UpdateZombieSpawning binary must return true in AL"
Assert-Matches $dump "426617:.*xor\s+al,al" "UpdateZombieSpawning binary must return false in AL"

$dump = Get-Disassembly "0x413de0" "0x413e05"
Assert-Matches $dump "413df0:.*call\s+0x426580.*413df5:.*test\s+al,al" `
    "UpdateZombieSpawning caller must consume only AL"

$dump = Get-Disassembly "0x406ac0" "0x406ade"
Assert-Matches $dump "406ac7:.*fld\s+DWORD PTR ds:0x679610.*406ad7:.*push\s+0x1" `
    "AwardScreen binary must use gold trophy cel 1 and scale constant 0x679610"
Assert-Matches (Get-HexDump "0x679610" "0x679614") "679610\s+9a99193f" `
    "AwardScreen gold trophy scale constant must be 0.6f"
Assert-Matches (Get-HexDump "0x679778" "0x67977c") "679778\s+00008242" `
    "AwardScreen gold trophy y constant must be 65.0f"
Assert-Matches (Get-HexDump "0x67a070" "0x67a074") "67a070\s+0080a243" `
    "AwardScreen gold trophy x constant must be 325.0f"

Write-Host "OK: 44 source contracts match PvZ 1.0.0.1051 source and objdump evidence."
