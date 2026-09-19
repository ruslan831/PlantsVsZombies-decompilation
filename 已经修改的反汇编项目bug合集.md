Collection of Fixed Bugs in the Decompilation Project
Record Date: 2026-06-18; Last Updated: 2026-08-25

Purpose: To document errors in the source code of this decompilation project that have been corrected to match the original PvZ 1.0.0.1051 binary. When using this project as a reference for PE/rsvz behavior in the future, if these functions are encountered, the information in this file and the "Corrected against PvZ 1.0.0.1051 binary" comments within the source code should be considered the authoritative source.

Original Binary: PlantsVsZombies.exe, Plants vs. Zombies 1.0.0.1051 EN.

1. Zombie::PickRandomSpeed ​​– Maximum speed for regular zombies
Original Error: The speed range for regular zombies was incorrectly written as `RandRangeFloat(0.23f, 0.32f)`.
Binary Evidence: In `Zombie::PickRandomSpeed` (0x524a70), the branch for regular zombies loads `0x679660` (0.37f) at 0x524b81 and `0x679670` (0.23f) at 0x524b8e before calling `RandRangeFloat`.
Correction: Changed to `RandRangeFloat(0.23f, 0.37f)`.
Modified File: `Lawn/Zombie.cpp`
Commit Hash: `039a863a727648424f94165377e14846c5e8f938`
2. Projectile::ProjectileInitialize – Condition for roof shadow adjustment
Original Error: `mShadowY -= 12.0f` was executed unconditionally for Roof and Night (Moonlight) levels.
Binary Evidence: In `Projectile::ProjectileInitialize` (0x46c730), the code at 0x46c805–0x46c833 first checks for Roof/Night levels and then compares the projectile's initial x-coordinate against 480.0f; the branch that subtracts from the shadow position is entered only when x < 480.0f. Fix: Changed to `mBoard->StageHasRoof() && theX < 480`.
File modified: `Lawn/Projectile.cpp`
Commit hash: `039a863a727648424f94165377e14846c5e8f938`
3. `Projectile::IsSplashDamage`: Fire-resistance short-circuit scope
Original error: It returned "non-splash" whenever `mProjectileType` was non-zero and the target was `IsFireResistant()`, incorrectly overriding the logic for Watermelons/Winter Melons.
Binary evidence: In `Projectile::IsSplashDamage` (0x46d1f0), the code at 0x46d1f3 first compares the projectile type against 0x6; only fireballs/fire peas enter the fire-resistance short-circuit logic. Subsequently, the code at 0x46d21c–0x46d229 still classifies type 0x3 (Melon), 0x5 (Winter Melon), and 0x6 (Fireball) as splash damage.
Fix: Restricted the fire-resistance short-circuit to `mProjectileType == ProjectileType::PROJECTILE_FIREBALL`.
File modified: `Lawn/Projectile.cpp`
Commit hash: `039a863a727648424f94165377e14846c5e8f938`
4. `Projectile::FindCollisionTarget`: Height condition for submerged zombies
Original error: The source code skipped hit detection when a submerged zombie's `mPosZ` was `>= 45.0f`.
Binary evidence: In `Projectile::FindCollisionTarget` (0x46cd40), the instructions at 0x46cdc4–0x46cdd2 compare 45.0f with the projectile's `mPosZ`; in reality, collision detection only proceeds if `mPosZ > 45.0f`.
Fix: Changed the skip condition for submerged zombies to `mPosZ <= 45.0f`. File modified: Lawn/Projectile.cpp
Commit hash: 039a863a727648424f94165377e14846c5e8f938
5. Projectile::FindCollisionTarget: Collision boundary
Original error: The condition for horizontal overlap between the projectile and the zombie was written as `GetRectOverlap(...) > 0`, which excluded cases where the boundaries were merely touching (tangent).
Binary evidence: In `Projectile::FindCollisionTarget`, the instructions at 0x46ce35–0x46ce37 are `test eax, eax; jl skip`, meaning the skip occurs only when overlap < 0.
Correction: Changed the collision candidate condition to `GetRectOverlap(...) >= 0`.
File modified: Lawn/Projectile.cpp
Commit hash: 039a863a727648424f94165377e14846c5e8f938
6. Projectile::CheckForCollision: Star projectile upper boundary
Original error: Star projectiles were destroyed when `mPosY < 0.0f`.
Binary evidence: In `Projectile::CheckForCollision`, the star projectile branch at 0x46ce80 loads the value at 0x67959c (40.0f) at 0x46cf88; the original game destroys the star projectile when `mPosY < 40.0f`.
Correction: Changed the star projectile upper boundary to `mPosY < 40.0f`.
File modified: Lawn/Projectile.cpp
Commit hash: 039a863a727648424f94165377e14846c5e8f938
7. Projectile::DoSplashDamage: Maximum total splash damage for non-fireball projectiles
Original error: The maximum total splash damage for non-fireball projectiles was written as `7 * (original_damage / 3)`. Binary evidence: In `Projectile::DoSplashDamage` (0x46d390), the code at 0x46d3eb–0x46d40d preserves the original damage before calculating single-target splash damage; the sequence `lea ecx,[ebp*8]; sub ecx,ebp` at 0x46d3fa–0x46d403 yields `7 * original_damage`, while the code at 0x46d405–0x46d40b reverts this to `original_damage` for fireballs/fire peas.
Correction: Changed the cap for non-fireball projectiles to `aOriginalDamage * 7`.
File modified: `Lawn/Projectile.cpp`
Commit hash: `039a863a727648424f94165377e14846c5e8f938`
8. `Plant::UpdateSpikeweed`: Spikerock damage frames
Original error: The two damage frames for Spikerock were incorrectly set to 69 and 33.
Binary evidence: In `Plant::UpdateSpikeweed` (0x460370), the instructions at 0x46d3b3 and 0x46d3b8 compare values ​​against `0x46` (70) and `0x20` (32), respectively.
Correction: Changed Spikerock damage frames to 70 and 32.
File modified: `Lawn/Plant.cpp`
Commit hash: `039a863a727648424f94165377e14846c5e8f938`
9. `Plant::UpdateSquash`: Squash pre-jump countdown
Original error: During the transition from `STATE_SQUASH_LOOK` to `STATE_SQUASH_PRE_LAUNCH`, `mStateCountdown` was set to 30. Binary evidence: In `Plant::UpdateSquash` (0x4609d0), after the state 0x4 is written at 0x460ae7, the instruction at 0x460aee (`c7 46 54 2d 00 00 00`) sets the countdown timer to 0x2d (decimal 45).
Fix: Changed the Squash's pre-jump countdown timer to 45.
File modified: `Lawn/Plant.cpp`
Commit hash: `999a6152d6043e024ced45facc5aec006aded8f3`
10. `Plant::FindStarFruitTarget`: Correction of the rectangle field for Starfruit targeting Miner Zombies
Original error: The special handling for Miner Zombies was written as `aZombieRect.mX += 10`.
Binary evidence: In `Plant::FindStarFruitTarget` (0x45f470), after checking for Miner Zombies at 0x45f52a, the instruction at 0x45f52f (`add DWORD PTR [esp+0x38],0xa`) modifies the rectangle's width field; within the same function, the instructions at 0x45f511–0x45f51b use `[esp+0x30] + [esp+0x38]` to represent `x + width`.
Fix: Changed to `aZombieRect.mWidth += 10`.
File modified: `Lawn/Plant.cpp`
Commit hash: `999a6152d6043e024ced45facc5aec006aded8f3`
11. `Zombie::FindZombieTarget`: Condition for edge-aligned contact when a Hypnotized Zombie targets an object to eat
Original error: The branch for the eating target was written as `aOverlap > 0`, which excluded cases where the overlap was 0 (edge-aligned contact).
Binary evidence: In `Zombie::FindZombieTarget` (0x52e840), after the sequence `cmp eax,0x14; jge accept` at 0x45f52a, the instructions `test eax,eax; jl skip` at 0x52e8e5 ensure the eating branch is skipped only when the overlap is less than 0. Fix: Changed to `aOverlap >= 20 || (aOverlap >= 0 && aZombie->mIsEating)`.
File modified: Lawn/Zombie.cpp
Commit hash: 999a6152d6043e024ced45facc5aec006aded8f3
12. Challenge::GraveDangerSpawnRandomGrave / WhackAZombiePlaceGraves: Reversed weight logic for spawning new graves
Original error: The weight for candidate tiles for new graves was set as `GetTopPlantAt(...) ? 100000 : 1`, meaning tiles with existing plants had high weight and empty tiles had low weight.
Binary evidence: In `Challenge::GraveDangerSpawnRandomGrave` (0x4266c0), 1 is written for tiles with plants at 0x426796, and 0x186a0 is written for empty tiles at 0x4267a2; in `Challenge::WhackAZombiePlaceGraves` (0x425da0), 1 is written for tiles with plants at 0x425e7d, and 0x186a0 is written for empty tiles at 0x425e89.
Fix: Changed both instances to `GetTopPlantAt(...) ? 1 : 100000`.
File modified: Lawn/Challenge.cpp
Commit hash: b8f25428fb5a16b2d1a1d3c37c39799c38154e86
13. Challenge::SpawnZombieWave: Grave spawn limit for the final wave of Survival: Night
Original error: The condition for spawning new graves during the final wave of Survival: Night was written as `(IsSurvivalNormal(...) && aNumGraves < 8) || aNumGraves < 12`, causing new graves to spawn in Survival: Normal mode even when the grave count was already below 12. Binary evidence: In `Challenge::SpawnZombieWave` (0x426850), the code at 0x42696c–0x426977 compares `aNumGraves < 8` for "Survival: Easy," while 0x426979–0x42697c compares `aNumGraves < 12` for other Survival modes; `GraveDangerSpawnRandomGrave()` is called at 0x42697e–0x42697f only if the count is below the respective limit.
Fix: Select the limit based on the mode (8 for "Survival: Easy," 12 for other Survival modes).
File modified: `Lawn/Challenge.cpp`
Commit hash: `b8f25428fb5a16b2d1a1d3c37c39799c38154e86`
15. Board::SpawnZombieWave: Constant for the final wave ambush countdown
Original error: For the final wave (when not a continuous challenge), it was set as `mRiseFromGraveCounter = 210`.
Binary evidence: In `Board::SpawnZombieWave` (0x412ee0), the machine code at 0x413094 (`c7 87 74 55 00 00 c8 00 00 00`) writes `0xc8` (i.e., 200) to `Board + 0x5574`.
Correction: Changed to `mRiseFromGraveCounter = 200`.
File modified: `Lawn/Board.cpp`
Commit hash: `b8f25428fb5a16b2d1a1d3c37c39799c38154e86`
16. Board::SpawnZombiesFromGraves: Variable for the lower-bound check on points
Original error: After deducting points for spawning a zombie from a grave, the code checked `if (aZombieType < 1)`, mistakenly checking the zombie type instead of the remaining points.
Binary evidence: In `Board::SpawnZombiesFromGraves` (0x412ce0), after the point deduction at 0x412e03, the instructions at 0x412e06–0x412e0d compare the remaining points against 1, and the local remaining points are updated at 0x412e0f–0x412e16.
Correction: Changed to `if (aZombiePoints < 1) aZombiePoints = 1;`. Modified files: Lawn/Board.cpp
Commit hash: b8f25428fb5a16b2d1a1d3c37c39799c38154e86
17. Board::PickGraveRisingZombieType: Spurious parameter
Original error: The source code signature was defined as `PickGraveRisingZombieType(int theZombiePoints)`, and the call sites passed `aZombiePoints`, creating the misleading impression that the ambush zombie type selection was filtered based on a remaining point budget.
Binary evidence: `Board::PickGraveRisingZombieType` (at 0x40d770) does not read point values ​​from the stack or registers; `SpawnZombiesFromPool` (at 0x4128f0) calls `0x40d770` after setting `edx` to the board pointer (at 0x412a1a–0x412a23) without passing a point value; call sites for Roof airdrops and grave-rising zombies also follow the semantics of a parameterless picker.
Correction: Removed the parameter from `PickGraveRisingZombieType` and updated the call sites for pool ambushes, Roof airdrops, and grave-rising zombies accordingly. Call sites retain the local point deduction/clamping logic but no longer express it as an input to the picker.
Modified files: Lawn/Board.h, Lawn/Board.cpp
Commit hash: b8f25428fb5a16b2d1a1d3c37c39799c38154e86
18. Zombie::StopZombieSound: Music stop condition for Dancing Zombie / Backup Dancer
Original error: The source code set `aStopSound = true` and stopped `FOLEY_DANCER` upon finding a Dancing Zombie or Backup Dancer that was still active; the condition logic was inverted. Binary evidence: In `Zombie::StopZombieSound` (0x530850), the code at 0x5308c5–0x5308d0 jumps directly to 0x5308fb—skipping `StopFoley`—if a valid zombie of type 0x8 or 0x9 is found; execution only proceeds to 0x5308eb–0x5308f6 to call `StopFoley(FOLEY_DANCER)` after the iteration completes without finding such a zombie.
Fix: Default to stopping the sound, but cancel the stop if the iteration encounters either a valid Disco Zombie or Backup Dancer.
Modified file: `Lawn/Zombie.cpp`
Commit hash: `b8f25428fb5a16b2d1a1d3c37c39799c38154e86`
19. `Zombie::PickRandomSpeed`: Speed ​​phase for Dolphin Rider Zombie re-entering the water.
Original error: The branch for the fixed speed of 0.3f at the beginning was written as `mZombiePhase == PHASE_DOLPHIN_WALKING_IN_POOL`, mistakenly using the "Dolphin walking in pool" phase as the condition for this branch.
Binary evidence: In `Zombie::PickRandomSpeed` (0x524a70), the instruction at 0x524a77 compares `edx` with `0x3b`; upon a match, the instruction at 0x524a7c loads `0.3f` and writes it to `mVelX`. In `ConstEnums.h`, `0x3b` corresponds to `PHASE_SNORKEL_WALKING_IN_POOL`, while `0x37` corresponds to `PHASE_DOLPHIN_WALKING_IN_POOL`.
Fix: Change the branch condition to `mZombiePhase == ZombiePhase::PHASE_SNORKEL_WALKING_IN_POOL`. Modified file: Lawn/Zombie.cpp
Regression check: tools/verify_binary_corrections.ps1
Commit hash: fd3bed59bd57c90fa3fb3717bb7e8bf885564c32
20. Zombie::ZombieTypeCanGoInPool: Balloon Zombie missing from valid pool types
Original error: The list of valid types for the pool omitted ZOMBIE_BALLOON.
Binary evidence: In Zombie::ZombieTypeCanGoInPool (0x532060), instructions at 0x532073 (`cmp eax, 0x10`) and 0x532076 (`je 0x53209e`) indicate that type 0x10 returns `true`; in ConstEnums.h, 0x10 corresponds to ZOMBIE_BALLOON.
Fix: Added `theZombieType == ZombieType::ZOMBIE_BALLOON` to `ZombieTypeCanGoInPool()` and corrected the function address comment to 0x532060.
Modified file: Lawn/Zombie.cpp
Regression check: tools/verify_binary_corrections.ps1
Commit hash: fd3bed59bd57c90fa3fb3717bb7e8bf885564c32
21. Plant::FindTargetAndFire: Head-shot counter for standard shots
Original error: The standard `anim_shooting` head-shot branch set `mShootingCounter` to 33, which is 2 centiseconds (cs) earlier than the original version.
Binary evidence: In Plant::FindTargetAndFire (0x45ef10), the instruction at 0x45f045 writes 0x23 (decimal 35) to `Plant + 0x90`; branches for Repeater, Split Pea, Left-shooter, and Gatling Pea subsequently overwrite this value with 26 or 100.
Fix: Changed the standard head-shot counter to 35 while preserving the subsequent overrides for specific plants. Modified file: Lawn/Plant.cpp
Regression check: tools/verify_binary_corrections.ps1
Commit hash: fd3bed59bd57c90fa3fb3717bb7e8bf885564c32
22. Plant::BlowAwayFliers incorrectly includes the balloon-popped falling phase
Original error: The Blover plant directly called `Zombie::IsFlying()`; based on its general semantics, this function includes both `PHASE_BALLOON_FLYING` and `PHASE_BALLOON_POPPING`, causing zombies that had already popped their balloons and were falling to be blown away as well.
Binary evidence: In `Plant::BlowAwayFliers` (0x4665b0), the code at 0x4665fe–0x46660b accepts `0x49` and explicitly excludes `0x4a`, with `mBlowingAway = 1` being set only at 0x46660d. Since the standalone `Zombie::IsFlying` function (at 0x534680) encompasses both phases, the function itself cannot be globally narrowed.
Correction: Set `mBlowingAway` only when `mZombiePhase == PHASE_BALLOON_FLYING`.
Modified file: Lawn/Plant.cpp
Regression check: tools/verify_binary_corrections.ps1
Commit hash: fd3bed59bd57c90fa3fb3717bb7e8bf885564c32
23. Challenge::IZombiePlaceZombie mixes up Bungee Zombie row and column parameters
Original error: In the Bungee Zombie branch, the zombie was initially created based on `theGridY`, but `SetRow(theGridX)` was subsequently called, writing the column index into the row index field.
Binary evidence: In `Challenge::IZombiePlaceZombie` (0x42a0f0), the instruction at 0x42a125 writes `col` to `mTargetCol`, and 0x42a12b writes `row` to `mRow`; the Y-position and render order also utilize the `row` value.
Correction: Changed the Bungee Zombie branch to call `SetRow(theGridY)`. Modified file: Lawn/Challenge.cpp
Regression check: tools/verify_binary_corrections.ps1
Commit hash: fd3bed59bd57c90fa3fb3717bb7e8bf885564c32
24. Board::GetPlantsOnLawn: Imitater "flying" layer type
Original error: The function had already replaced the Imitater with the target `aSeedType`, but the check for the "flying" layer reverted to using `aPlant->mSeedType`, causing an untransformed Imitater Coffee Bean to be placed in the "normal" layer.
Binary evidence: In `Board::GetPlantsOnLawn` (0x40d2a0), the code overwrites the EDI register with `mImitaterType` at 0x40d307–0x40d317, then proceeds to compare EDI against `0x23` (SEED_INSTANT_COFFEE) at 0x40d350, without re-reading the actual type.
Fix: Changed the "flying" layer check to use `Plant::IsFlying(aSeedType)`, ensuring consistency with the other layering logic by using the effective type.
Modified file: Lawn/Board.cpp
Regression check: tools/verify_binary_corrections.ps1
Commit hash: fd3bed59bd57c90fa3fb3717bb7e8bf885564c32
25. Plant::UpdateBlover: Countdown field
Original error: The Blover checked `mStateCountdown == 0` when not in `STATE_DOINGSPECIAL`, but the logic for waiting for activation relied on `mDoSpecialCountdown`.
Binary evidence: In `Plant::UpdateBlover` (0x460f00), the code compares `[Plant + 0x50]` at 0x460f44; in the field layout, `+0x50` corresponds to `mDoSpecialCountdown`, while `+0x54` corresponds to `mStateCountdown`.
Fix: Changed the trigger condition to `mDoSpecialCountdown == 0`. Modified file: Lawn/Plant.cpp
Regression check: tools/verify_binary_corrections.ps1
Commit hash: fd3bed59bd57c90fa3fb3717bb7e8bf885564c32
26. Zombie::UpdateYuckyFace: Unidirectional lane-switching direction
Original error: Wrote `row - 1` when only the path below was available, and `row + 1` when only the path above was available; this caused attempts to access invalid rows from the top and bottom rows.
Binary evidence: In `Zombie::UpdateYuckyFace` (0x52b6a0), `row - 1` is generated at 0x52b826 and written at 0x52b8c7 (where only the path above is available); `row + 1` is generated at 0x52b876 and written at 0x52b8e8 (where only the path below is available).
Correction: Use `row + 1` when only the path below is available, and `row - 1` when only the path above is available; the random branching logic for when both directions are valid remains unchanged.
Modified file: Lawn/Zombie.cpp
Regression check: tools/verify_binary_corrections.ps1
Commit hash: fd3bed59bd57c90fa3fb3717bb7e8bf885564c32
27. Challenge::UpdateZombieSpawning: Return type
Original error: The source code declaration and definition used `int`, but the original game only returned a boolean value (true/false) in the AL register; treating it as a 32-bit return value resulted in reading undefined high-order bits.
Binary evidence: In `Challenge::UpdateZombieSpawning` (0x426580), a `mov` instruction is used at 0x4265ac.
29. AwardScreen::Draw: Golden Sunflower trophy position and scale
Original error: For non-Adventure modes, the Golden Sunflower trophy was drawn at coordinates (330, 80) with a scale of 0.7. Binary evidence: In `AwardScreen::Draw` (0x4068D0), the gold trophy branch reads `0x679610 = 0.6f` twice at `0x406AC7` for horizontal and vertical scaling and passes it to sprite 1; shared call segments at `0x407590` and `0x4075A5` read `0x679778 = 65.0f` and `0x67A070 = 325.0f`, respectively.
Correction: Changed the gold sunflower trophy to coordinates (325, 65) with a scale of 0.6; the silver trophy branch remains unchanged.
Modified file: `Lawn/Widget/AwardScreen.cpp`
Regression check: Added checks for the source code contract, drawing branch, and the three fixed-address constants mentioned above to `tools/verify_binary_corrections.ps1`.
Commit hash: `d7c16584b508aaa46e11758c9a1ffa745ca15a61`
30. `Challenge::UpdateSlotMachine`: Quantity of rewards for a standard three-of-a-kind match
Original error: The branch for a standard plant three-of-a-kind match looped 20 times to generate available plant card packs.
Binary evidence: The relevant branch in `Challenge::UpdateSlotMachine` (0x423800) starts with `esi = 0`, adds `0x3c` per iteration, and exits upon `cmp esi, 0xb4`, resulting in exactly 3 iterations.
Actual game behavior: The erroneous source code would drop 20 identical card packs, whereas the original version drops only 3.
Correction: Changed the loop limit for this branch to 3; the 20-iteration loop for the sun three-of-a-kind match remains unchanged. Modified file: Lawn/Challenge.cpp
Regression check: tools/verify_binary_corrections.ps1
Commit hash: 8b8d8a7d332654abea1cedd99c1e91064a043eb1
31. ZombiePickerInitForWave: Cross-wave zombie counting
Original error: A `memset` on the entire structure inadvertently cleared `mAllWavesZombieTypeCount` as well.
Binary evidence: `ZombiePickerInitForWave@0x4090F0` only zeroes out offsets 0x00–0x88; the full initialization function is responsible for clearing the cross-wave array starting at 0x8c.
Actual game behavior: The erroneous source code forgot the cumulative counts of various zombie types from previous waves, altering the type restrictions and composition of random waves.
Correction: Clear only the current wave's counts, points, and `mZombieTypeCount`.
Modified file: Lawn/Board.cpp
Regression check: tools/verify_binary_corrections.ps1
Commit hash: 8b8d8a7d332654abea1cedd99c1e91064a043eb1
32. LawnApp::IsScaryPotterLevel: Upper bound for Vasebreaker Endless
Original error: The upper bound of the mode range was set to `GAMEMODE_SCARY_POTTER_9`.
Binary evidence: `LawnApp::IsScaryPotterLevel@0x4538F0` accepts the enum range 0x33–0x3c, where 0x3c corresponds to Vasebreaker Endless.
Actual game behavior: The erroneous source code failed to recognize Endless mode as a Vasebreaker level, causing related initialization, progression, rewards, and interactions to follow the wrong code path.
Correction: Changed the upper bound to `GAMEMODE_SCARY_POTTER_ENDLESS`. Modified file: LawnApp.cpp
Regression check: tools/verify_binary_corrections.ps1
Commit hash: 8b8d8a7d332654abea1cedd99c1e91064a043eb1
33. Challenge::ShovelAddWallnuts line count
Original error: Iterated through the internal six rows, planting 9 Wall-nuts in the invisible sixth row.
Binary evidence: The inner row loop in Challenge::ShovelAddWallnuts@0x428510 jumps back after `cmp esi, 0x5`, processing only row indices 0–4; the column loop processes 0–8.
Actual game behavior: The erroneous source code corrupted plant counts and the state of the invisible row for the "Can You Dig It?" and hidden squirrel levels.
Fix: Changed the row upper bound to `MAX_GRID_SIZE_Y - 1`.
Modified file: Lawn/Challenge.cpp
Regression check: tools/verify_binary_corrections.ps1
Commit hash: 8b8d8a7d332654abea1cedd99c1e91064a043eb1
34. Board::NextWaveComing "Next Wave" alert condition
Original error: The check for the final wave in "Whack-a-Zombie" mode was combined with the check for standard flag waves using a logical OR.
Binary evidence: Board::NextWaveComing@0x413C00 checks only for the final wave in "Whack-a-Zombie" mode; `IsFlagWave` is called only in non-"Whack-a-Zombie" modes.
Actual game behavior: The erroneous source code triggered the final wave alert during intermediate flag waves in "Whack-a-Zombie" mode.
Fix: Restored the mutually exclusive condition: "Whack-a-Zombie ? final wave : flag wave". Modified file: Lawn/Board.cpp
Regression check: tools/verify_binary_corrections.ps1
Commit hash: 8b8d8a7d332654abea1cedd99c1e91064a043eb1
35. ZenGarden::FindOpenZenGardenSpot: Skip logic for occupied grid slots
Original error: When coordinates matched an occupied slot, the code only `continue`d the inner loop (iterating through potted plants) but still added the occupied slot to the list of candidates.
Binary evidence: In `ZenGarden::FindOpenZenGardenSpot@0x51D7B0`, upon matching a garden and coordinate, the code jumps directly to the outer loop position (incrementing Y); a slot is only added to candidates if the iteration completes without a match.
Actual game behavior: A new potted plant could overlap with an existing one at the same garden coordinate.
Fix: Skip to the next candidate slot when an occupied slot is detected.
Modified file: Lawn/ZenGarden.cpp
Regression check: tools/verify_binary_corrections.ps1
Commit hash: 8b8d8a7d332654abea1cedd99c1e91064a043eb1
36. Zombie::UpdateZombieJalapenoHead: Death after detonation
Original error: The Jalapeno-head zombie did not call the death function after completing the full-row explosion.
Binary evidence: In the original game, `Zombie::UpdateZombieJalapenoHead@0x5275C0` calls `Zombie::DieNoLoot@0x530510` at address `0x52773E` before returning.
Actual game behavior: Zombies in the erroneous source code remained alive and continued updating after detonation; in the original game, they died immediately without dropping loot.
Fix: Call `DieNoLoot()` at the end of the explosion logic branch; this call is not affected by community fix macros. Modified file: Lawn/Zombie.cpp
Regression check: tools/verify_binary_corrections.ps1
Commit hash: 8b8d8a7d332654abea1cedd99c1e91064a043eb1
37. Number of Football Zombies and Jack-in-the-Box Zombies in Vasebreaker Level 6
Original error: Both zombie types were requested to be spawned in quantities of 6.
Binary evidence: The Level 6 branch of `Challenge::ScaryPotterPopulate@0x4286F0` passes quantities of 2 and 1, respectively, to the two calls for placing vases.
Actual game behavior: The erroneous code requested 4 more Football Zombies and 5 more Jack-in-the-Box Zombies than the original version, potentially exhausting available grid slots and causing a crash.
Correction: Changed quantities to 2 Football Zombies and 1 Jack-in-the-Box Zombie.
Modified file: Lawn/Challenge.cpp
Regression check: tools/verify_binary_corrections.ps1
Commit hash: 8b8d8a7d332654abea1cedd99c1e91064a043eb1
38. State of the standard watering can tool
Original error: The standard watering can branch wrote the state for the Golden Watering Can.
Binary evidence: The Golden Watering Can path in `ZenGarden::MouseDownWithFeedingTool@0x51EB70` writes `0x12`, while the standard watering can path at `0x51EF30` writes `0x0e`.
Actual game behavior: The erroneous source code caused the standard watering can to follow the Golden Watering Can logic, watering multiple plants within range.
Correction: The standard branch now writes `GRIDITEM_STATE_ZEN_TOOL_WATERING_CAN`. Modified file: Lawn/ZenGarden.cpp
Regression check: tools/verify_binary_corrections.ps1
Commit hash: 8b8d8a7d332654abea1cedd99c1e91064a043eb1
39. Number of coins in Vasebreaker money bags
Original error: Trophies and money bags shared a code path (fan-out branch) that specified 5 gold coins.
Binary evidence: `Coin::Collect@0x432060` passes a quantity of 2 for `COIN_AWARD_MONEY_BAG` at `0x4322EC`, whereas the trophy branch passes 5.
Actual game behavior: Each money bag yielded 3 more gold coins than the original version (an extra 30 in coin value).
Correction: Split the branch so money bags yield 2 gold coins, while trophies retain the 5-coin count.
Modified file: Lawn/Coin.cpp
Regression check: tools/verify_binary_corrections.ps1
Commit hash: 8b8d8a7d332654abea1cedd99c1e91064a043eb1
40. Chocolate reward type in Puzzle stages
Original error: The reward phase used the standard `COIN_CHOCOLATE`.
Binary evidence: `Challenge::PuzzlePhaseComplete@0x429980` generates enum `0x18` (`COIN_AWARD_CHOCOLATE`) when chocolate is dropped, or a money bag (`0x12`) otherwise.
Actual game behavior: Standard chocolate triggered incorrect display, collection, and reward processing logic.
Correction: Use `COIN_AWARD_CHOCOLATE`. Modified file: Lawn/Challenge.cpp
Regression check: tools/verify_binary_corrections.ps1
Commit hash: 8b8d8a7d332654abea1cedd99c1e91064a043eb1
41. Board::UpdateZombieSpawning: Flag wave countdown condition
Original error: Extra countdown for flag waves was set only for "Wall-nut Bowling" or "Last Stand".
Binary evidence: In the original code at 0x413D00, the special mode flag is checked at 0x414057; if the flag is non-zero, `ZOMBIE_COUNTDOWN_BEFORE_FLAG` is skipped; the value is written only in normal mode.
Actual game behavior: Flag waves in normal levels lacked the interval, whereas the two special modes received an extra interval.
Fix: Apply logical NOT to the "Wall-nut Bowling or Last Stand" condition.
File modified: Lawn/Board.cpp
Regression check: tools/verify_binary_corrections.ps1
Commit hash: 8b8d8a7d332654abea1cedd99c1e91064a043eb1
42. "Not recommended" flag for Crazy Dave's automatic seed selection
Original error: The return value of `SeedNotRecommendedToPick` was not used after calculation.
Binary evidence: `SeedChooserScreen::CrazyDavePickSeeds` at 0x483F70 saves the flag and checks it at 0x48400B; if non-zero, the corresponding plant's weight is set to 0.
Actual game behavior: Dave might randomly select a plant that is explicitly not recommended for the current field or zombie configuration.
Fix: Incorporate `aRecFlags` into the exclusion criteria.
File modified: Lawn/Widget/SeedChooserScreen.cpp
Regression check: tools/verify_binary_corrections.ps1
Commit hash: 8b8d8a7d332654abea1cedd99c1e91064a043eb1
43. Firing point mirroring formula for left-facing Repeater
Original error: Used `mX + aOffsetX + 27` without mirroring the head animation offset.
Binary evidence: `Plant::Fire` at 0x466E00 executes `mX - aOffsetX + 27` at addresses 0x4670D8–0x4670E6. Actual game behavior: When the animation frame offset changes, the pea spawn point shifts in the wrong direction and detaches from the muzzle.
Fix: Reverted the formula to `mX - aOffsetX + 27`, eliminating the use of a constant approximation that was valid only for specific frames.
Modified file: `Lawn/Plant.cpp`
Regression check: `tools/verify_binary_corrections.ps1`
Commit hash: `8b8d8a7d332654abea1cedd99c1e91064a043eb1`
44. Zombiquarium initial seed packet set
Original error: `Board::InitLevel` lacked the specific initialization branch for Zombiquarium.
Binary evidence: The original game (at `0x40A8E0`) identifies mode `0x17` at `0x40B317` and assigns `SEED_ZOMBIQUARIUM_SNORKLE` and `SEED_ZOMBIQUARIUM_TROPHY` to slots 0 and 1, respectively.
Actual game behavior: The erroneous source code lacked the two specific seed packets (Snorkel Zombie and Trophy), preventing the level from being played according to official rules.
Fix: Restored the two seed packets and their correct order.
Modified file: `Lawn/Board.cpp`
Regression check: `tools/verify_binary_corrections.ps1`
Commit hash: `8b8d8a7d332654abea1cedd99c1e91064a043eb1`
45. Beghouled Twist prediction rotation logic
Original error: The assignment of values ​​to the four cells of the 2×2 temporary board did not correspond to the actual clockwise twist.
Binary evidence: `BeghouledTwistMoveCausesMatch` (at `0x420190`) establishes the relationship: B=A, D=B, C=D, A=C.
Actual game behavior: Incorrect predictions would reject twists that result in a match or allow twists that do not, affecting the search for valid moves and the hint system.
Fix: Restored the temporary rotation logic based on the A/B/C/D relationship mentioned above. Modified file: Lawn/Challenge.cpp
Regression check: tools/verify_binary_corrections.ps1
Commit hash: 8b8d8a7d332654abea1cedd99c1e91064a043eb1
46. Beghouled drag primary direction
Original error: Directly compared signed X and Y displacements.
Binary evidence: Challenge::BeghouledDragUpdate@0x420760 takes the absolute values ​​of both axes before comparing their magnitudes; the sign is used only to determine the specific direction.
Actual game behavior: Dragging diagonally left or up could swap adjacent plants along the shorter axis.
Correction: Changed primary axis determination to `abs(aDeltaX) > abs(aDeltaY)`.
Modified file: Lawn/Challenge.cpp
Regression check: tools/verify_binary_corrections.ps1
Commit hash: 8b8d8a7d332654abea1cedd99c1e91064a043eb1
47. Beghouled Crater-Removing Card slot count
Original error: Failed to update `mNumPackets` from 4 to 5 after setting the Crater-Removing Card in the 5th slot.
Binary evidence: Challenge::ZombieAtePlant@0x424590 explicitly writes `SeedBank::mNumPackets = 5` at 0x424607 after setting the 5th slot.
Actual game behavior: The card packet object was initialized, but the seed bank still displayed only four slots, preventing the player from using the Crater-Removing Card.
Correction: Synchronized the count to 5 before setting the card packet. Modified file: Lawn/Challenge.cpp
Regression check: tools/verify_binary_corrections.ps1
Commit hash: 8b8d8a7d332654abea1cedd99c1e91064a043eb1
48. "I, Zombie" Bungee Zombie seed enumeration
Original error: `Challenge::CanPlantAt` compared the passed seed type against `ZOMBIE_BUNGEE`.
Binary evidence: The original game at `0x425550` compares against `0x42` (`SEED_ZOMBIE_BUNGEE`) at `0x4255E1`, not the zombie type enum `0x14`.
Actual game behavior: The incorrect source code failed to recognize the Bungee Zombie card, thereby bypassing or misapplying specific placement restrictions.
Correction: Compare against `SEED_ZOMBIE_BUNGEE`.
Modified file: Lawn/Challenge.cpp
Regression check: tools/verify_binary_corrections.ps1
Commit hash: 8b8d8a7d332654abea1cedd99c1e91064a043eb1
49. Zombiquarium trophy tutorial fallback state
Original error: When the player could not afford the trophy, the state reverted from "Click Trophy" to `TUTORIAL_OFF`.
Binary evidence: `Challenge::ZombiquariumUpdate@0x4280A0` writes `0x14` (`TUTORIAL_ZOMBIQUARIUM_BOUGHT_SNORKEL`) at `0x42846E`–`0x42848F` for this branch.
Actual game behavior: The incorrect source code completely terminated the tutorial, so the player no longer received guidance on purchasing subsequent trophies.
Correction: Revert to the "Snorkel Zombie Purchased" stage when funds are insufficient; the earlier branch for closing the Snorkel Zombie tutorial remains `TUTORIAL_OFF`. Modified file: Lawn/Challenge.cpp
Regression check: tools/verify_binary_corrections.ps1
Commit hash: 8b8d8a7d332654abea1cedd99c1e91064a043eb1
50. Beghouled upgrade card pack deactivation
Original error: The card pack remained active after purchasing upgrades for the Repeater, Gloom-shroom, or Tall-nut.
Binary basis: `Challenge::BeghouledPacketClicked@0x427A60` clears the active state at the end of three success branches (at 0x427B03, 0x427B78, and 0x427BF4, respectively).
Actual game behavior: Upgrades that had already been purchased could still be clicked, potentially deducting sun without producing any effect.
Fix: Call `SetActivate(false)` at the end of all three successful purchase branches.
Modified file: Lawn/Challenge.cpp
Regression check: tools/verify_binary_corrections.ps1
Commit hash: 8b8d8a7d332654abea1cedd99c1e91064a043eb1
51. Hidden squirrel level: waiting and movement
Original error: Wait time was coded as 100–400; the directional logic caused vertical targets to fall into the "move right" branch, and the movement counter was not set.
Binary basis: `SquirrelStart@0x42BB10` and `SquirrelChew@0x42BCB0` generate a range of 100–500; `SquirrelFound@0x42BE10` distinguishes X first, then Y if X is equal, and sets a counter of 50.
Actual game behavior: Squirrels waited up to 100cs less than intended; vertical movement could select the wrong direction or get stuck.
Fix: Change the upper bound of the wait time to 500 in all three locations, restore four-way directional logic based on coordinates, and set the movement counter to 50cs. Modified file: Lawn/Challenge.cpp
Regression check: tools/verify_binary_corrections.ps1
Commit hash: 8b8d8a7d332654abea1cedd99c1e91064a043eb1
52. Tall-nut head crack type for Tall-nut Zombie
Original error: The Tall-nut head used `HELMTYPE_WALLNUT`; while the durability was 2200, the damage sprite type was incorrect.
Binary evidence: In `Zombie::ZombieInitialize`, the value 9 (`HELMTYPE_TALLNUT`) was written for type `0x1f` at `0x52394D`, and the durability was independently set to 2200.
Actual game behavior: The two damage stages displayed cracks typical of the standard Wall-nut rather than the Tall-nut.
Correction: Changed the helmet type to `HELMTYPE_TALLNUT`; durability and initial animation remain unchanged.
Modified file: Lawn/Zombie.cpp
Regression check: tools/verify_binary_corrections.ps1
Commit hash: 8b8d8a7d332654abea1cedd99c1e91064a043eb1
53. Shop slot for Tree Food gifted by Crazy Dave
Original error: Dialogue branch 3200 wrote the Tree Food quantity to hardcoded index 29.
Binary evidence: The original version wrote 1005 to `PlayerInfo + 0x230` at `0x43C9DD`; this offset corresponds to `mPurchases[28] = STORE_ITEM_TREE_FOOD`.
Actual game behavior: The erroneous source code failed to actually increase the Tree Food inventory but corrupted the purchase data for adjacent items.
Correction: Explicitly used the index `STORE_ITEM_TREE_FOOD`. Modified file: Lawn/CutScene.cpp
Regression check: tools/verify_binary_corrections.ps1
Commit hash: 8b8d8a7d332654abea1cedd99c1e91064a043eb1
54. Tree Food "Sold Out" boundary
Original error: Tree Food was considered sold out only if the quantity exceeded 10.
Binary evidence: `StoreScreen::IsItemSoldOut@0x48A9D0` compares the value against 10 at `0x48AA23` and subsequently uses `setge`.
Actual game behavior: One could purchase an additional unit of Tree Food even when already possessing 10, exceeding the official limit.
Correction: Changed the condition to `>= 10`.
Modified file: Lawn/Widget/StoreScreen.cpp
Regression check: tools/verify_binary_corrections.ps1
Commit hash: 8b8d8a7d332654abea1cedd99c1e91064a043eb1
55. Condition for the introductory level in a new save
Original error: The condition was set for "first-time Adventure mode," "Level 0," and "save file exists."
Binary evidence: `GameSelector::Update@0x44B2A0` checks for Level 1 at `0x44B357` and enters `GAMEMODE_INTRO` only when `SaveFileExists()` returns `false`.
Actual game behavior: A genuine new save would not enter the introductory level, whereas an anomalous state of "Level 0 with an existing save file" would attempt to enter it.
Correction: Reverted to `mLevel == 1 && !SaveFileExists()`.
Modified file: Lawn/Widget/GameSelector.cpp
Regression check: tools/verify_binary_corrections.ps1
Commit hash: 8b8d8a7d332654abea1cedd99c1e91064a043eb1
56. `SeedTypeAvailable` condition for Gatling Pea
Original error: Connected "Gatling Pea and purchased" with `HasSeedType` using a logical OR. Binary basis: 1051; on the card selection screen, this is linked as a choice between two options: Class.56. SeedTypeAvailable condition for Gatling Pea
Original error: Combined the "Gatling Pea and purchased" check with `HasSeedType` using a logical OR.
Binary evidence: At address 0x1051, the logic in the seed selection screen is branched: for type 0x28, it checks only the Gatling Pea purchase record; for other types, it calls `HasSeedType` (@0x453B20).
Actual game behavior: After beating the game, `HasSeedType` caused the unpurchased Gatling Pea to appear in the seed selection screen.
Fix: Gatling Pea is determined solely by the purchase record; other seeds call `HasSeedType`.
File modified: LawnApp.cpp
Regression check: tools/verify_binary_corrections.ps1
Commit hash: 8b8d8a7d332654abea1cedd99c1e91064a043eb1
57. Shovel display in Tree of Wisdom mode
Original error: `CutScene::ShowShovel` missed the early-return condition for the Tree of Wisdom mode.
Binary evidence: The original code @0x43C140 compares the value against 0x32 (`GAMEMODE_TREE_OF_WISDOM`) at 0x43C1A8 and returns immediately upon a match.
Actual game behavior: The Tree of Wisdom screen displayed a shovel that shouldn't be there and allowed standard shovel interaction.
Fix: Added `GAMEMODE_TREE_OF_WISDOM` to the exclusion list.
File modified: Lawn/CutScene.cpp
Regression check: tools/verify_binary_corrections.ps1
Commit hash: 8b8d8a7d332654abea1cedd99c1e91064a043eb1
58. Slot count, price, and dialogue ID for Crazy Dave's seed slot upgrade dialog
Original error: Displayed `aNumPackets + 1`, treated the wallet balance as the price, and checked for ID 1533 (which does not exist in this branch) after the second round succeeded. Binary basis: `CutScene::AdvanceCrazyDaveDialog@0x43C950` used `aNumPackets + 7` and a calculated price, and checked IDs 1503 and 1553 sequentially after purchase.
Actual game behavior: The confirmation dialog displayed 6 fewer slots and an incorrect amount; furthermore, it failed to advance to dialogue ID 1560 after the second purchase.
Fix: Changed to `+ 7`, `GetMoneyString(aCost)`, and message ID 1553, respectively.
Modified file: `Lawn/CutScene.cpp`
Regression check: `tools/verify_binary_corrections.ps1`
Commit hash: `8b8d8a7d332654abea1cedd99c1e91064a043eb1`
59. Board buttons during the reward collection fade-out phase
Original error: `Board::CanInteractWithBoardButtons` did not exclude the board fade-out state.
Binary basis: Original version @`0x412490` compared `mBoardFadeOutCounter` with 0 at `0x412509`, with a `jge` jump returning `false`.
Actual game behavior: The menu or shop could still be opened, or tools switched, during the transition following reward collection.
Fix: Return `false` when `mBoardFadeOutCounter >= 0`.
Modified file: `Lawn/Board.cpp`
Regression check: `tools/verify_binary_corrections.ps1`
Commit hash: `8b8d8a7d332654abea1cedd99c1e91064a043eb1`
60. Upsell: State of the initial Crazy Dave dialogue line
Original error: `mCrazyDaveLastTalkIndex` was not synchronized after initiating `mCrazyDaveDialogStart`.
Binary basis: `CutScene::UpdateUpsell@0x440D20` called `CrazyDaveTalkIndex`, then wrote the same ID to the `last-talk` field at `0x440D79`–`0x440D7C`.
Actual game behavior: Every frame, the initial line was mistakenly identified as not yet started and restarted from the beginning, preventing the demonstration from progressing. Fix: Record `mCrazyDaveLastTalkIndex = mCrazyDaveDialogStart` after the initial call.
Modified file: `Lawn/CutScene.cpp`
Regression check: `tools/verify_binary_corrections.ps1`
Commit hash: `8b8d8a7d332654abea1cedd99c1e91064a043eb1`
61. `ClearUpsellBoard`: Preserve Crazy Dave animations.
Original error: Unconditionally deleted all reanimations when switching demo boards.
Binary evidence: The original `CutScene::ClearUpsellBoard@0x43DA50` compares `mReanimationType` with `0x61` (`REANIM_CRAZY_DAVE`) at `0x43DB64`, calling the death function only for other types.
Actual game behavior: Crazy Dave's body and blinking animations were destroyed; subsequent updates might access invalid objects, causing the demo to crash.
Fix: Preserve all `REANIM_CRAZY_DAVE` instances based on original type semantics.
Modified file: `Lawn/CutScene.cpp`
Regression check: `tools/verify_binary_corrections.ps1`
Commit hash: `8b8d8a7d332654abea1cedd99c1e91064a043eb1`
Note: Behaviors reviewed but requiring no modification
`Plant::Squish` (0x462b80): In the source code, Cherry Bomb, Jalapeno, awake Doom-shroom/Ice-shroom, and armed Potato Mine execute `DoSpecial()`, while sleeping plants and ordinary plants enter the squished state; consistent with the binary.
`Zombie::SquishAllInSquare` (0x52e920): In the source code, when a vehicle crushes a tile, it only excludes Spikeweed/Spikerock from the additional check before calling `Plant::Squish()`; consistent with the binary. Board::UpdateZombieSpawning (0x413d00): At the frame where the red countdown timer reaches zero, execution proceeds to the standard `mZombieCountDown--` path after clearing advice, calling `NextWaveComing()`, and setting `mZombieCountDown = 1`. The current decompiled source code matches the binary; this is not a decompilation error.
Zombie::UpdateZombieDancer (0x528CA0): Previous D34 records claimed the source code checked for `== 1` after decrementing `mSummonCounter`, but the code has actually checked for `== 0` since the initial commit (c663d6e1628ae5a34b2da30dbba162571c021527), matching the 1051 binary. This entry is a documentation error and requires no changes to the production code.
