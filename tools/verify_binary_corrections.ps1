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

$RepoRoot = Split-Path -Parent $PSScriptRoot
$PlantSource = Get-Content -LiteralPath (Join-Path $RepoRoot "Lawn\Plant.cpp") -Raw -Encoding Default
$BoardSource = Get-Content -LiteralPath (Join-Path $RepoRoot "Lawn\Board.cpp") -Raw -Encoding Default
$ChallengeSource = Get-Content -LiteralPath (Join-Path $RepoRoot "Lawn\Challenge.cpp") -Raw -Encoding Default
$ChallengeHeader = Get-Content -LiteralPath (Join-Path $RepoRoot "Lawn\Challenge.h") -Raw -Encoding Default
$ZombieSource = Get-Content -LiteralPath (Join-Path $RepoRoot "Lawn\Zombie.cpp") -Raw -Encoding Default
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

Write-Host "OK: 9 source corrections match PvZ 1.0.0.1051 source contracts and objdump."
