# 已经修改的反汇编项目 bug 合集

记录时间：2026-06-18；最近更新：2026-07-11

用途：记录本反编译项目中已按 PvZ 1.0.0.1051 原版二进制重新校正的源码错误。后续使用本项目作为 PE / rsvz 行为参考时，遇到这些函数应以本文件和源码中的 `Corrected against PvZ 1.0.0.1051 binary` 注释为准。

原版二进制：`PlantsVsZombies.exe`，Plants vs. Zombies 1.0.0.1051 EN。

## 1. `Zombie::PickRandomSpeed` 普通僵尸速度上限

- 原错误：普通兜底速度范围写成 `RandRangeFloat(0.23f, 0.32f)`。
- 二进制依据：`Zombie::PickRandomSpeed` `0x524a70` 中普通兜底分支在 `0x524b81` 加载 `0x679660 = 0.37f`，在 `0x524b8e` 加载 `0x679670 = 0.23f` 后调用 `RandRangeFloat`。
- 修正：改为 `RandRangeFloat(0.23f, 0.37f)`。
- 修改文件：`Lawn/Zombie.cpp`
- 修改提交号：`039a863a727648424f94165377e14846c5e8f938`

## 2. `Projectile::ProjectileInitialize` 屋顶阴影修正条件

- 原错误：屋顶/月夜场景无条件执行 `mShadowY -= 12.0f`。
- 二进制依据：`Projectile::ProjectileInitialize` `0x46c730` 中 `0x46c805-0x46c833` 先判断屋顶/月夜，再比较 projectile 初始 `x` 与 `480.0f`；只有 `x < 480.0f` 时进入减阴影分支。
- 修正：改为 `mBoard->StageHasRoof() && theX < 480`。
- 修改文件：`Lawn/Projectile.cpp`
- 修改提交号：`039a863a727648424f94165377e14846c5e8f938`

## 3. `Projectile::IsSplashDamage` 火抗短路范围

- 原错误：只要 `mProjectileType` 非 0 且目标 `IsFireResistant()` 就返回非溅射，误覆盖西瓜/冰瓜。
- 二进制依据：`Projectile::IsSplashDamage` `0x46d1f0` 在 `0x46d1f3` 先比较 projectile type 是否为 `0x6`，只有 fireball/fire pea 才进入火抗短路；随后 `0x46d21c-0x46d229` 仍将 `0x3` melon、`0x5` winter melon、`0x6` fireball 判为溅射。
- 修正：火抗短路限定为 `mProjectileType == ProjectileType::PROJECTILE_FIREBALL`。
- 修改文件：`Lawn/Projectile.cpp`
- 修改提交号：`039a863a727648424f94165377e14846c5e8f938`

## 4. `Projectile::FindCollisionTarget` 潜水僵尸高度条件

- 原错误：源码写成潜水僵尸 `mPosZ >= 45.0f` 时跳过命中。
- 二进制依据：`Projectile::FindCollisionTarget` `0x46cd40` 中 `0x46cdc4-0x46cdd2` 比较 `45.0f` 与 projectile `mPosZ`，实际只允许 `mPosZ > 45.0f` 继续碰撞判定。
- 修正：潜水僵尸跳过条件改为 `mPosZ <= 45.0f`。
- 修改文件：`Lawn/Projectile.cpp`
- 修改提交号：`039a863a727648424f94165377e14846c5e8f938`

## 5. `Projectile::FindCollisionTarget` 命中边界

- 原错误：projectile 与僵尸横向重叠条件写成 `GetRectOverlap(...) > 0`，会排除边界相切。
- 二进制依据：`Projectile::FindCollisionTarget` `0x46ce35-0x46ce37` 为 `test eax,eax; jl skip`，即只在 overlap `< 0` 时跳过。
- 修正：命中候选条件改为 `GetRectOverlap(...) >= 0`。
- 修改文件：`Lawn/Projectile.cpp`
- 修改提交号：`039a863a727648424f94165377e14846c5e8f938`

## 6. `Projectile::CheckForCollision` 星星弹上边界

- 原错误：星星弹在 `mPosY < 0.0f` 时销毁。
- 二进制依据：`Projectile::CheckForCollision` `0x46ce80` 的星星弹分支在 `0x46cf88` 加载 `0x67959c = 40.0f`，原版在 `mPosY < 40.0f` 时销毁星星弹。
- 修正：星星弹上边界改为 `mPosY < 40.0f`。
- 修改文件：`Lawn/Projectile.cpp`
- 修改提交号：`039a863a727648424f94165377e14846c5e8f938`

## 7. `Projectile::DoSplashDamage` 非火球溅射总伤害上限

- 原错误：非火球溅射总伤害上限写成 `7 * (original_damage / 3)`。
- 二进制依据：`Projectile::DoSplashDamage` `0x46d390` 中 `0x46d3eb-0x46d40d` 先保留原始伤害，再计算单目标溅射伤害；`0x46d3fa-0x46d403` 用 `lea ecx,[ebp*8]; sub ecx,ebp` 得到 `7 * original_damage`，火球/火豌豆在 `0x46d405-0x46d40b` 改回 `original_damage`。
- 修正：非火球上限改为 `aOriginalDamage * 7`。
- 修改文件：`Lawn/Projectile.cpp`
- 修改提交号：`039a863a727648424f94165377e14846c5e8f938`

## 8. `Plant::UpdateSpikeweed` 地刺王伤害帧

- 原错误：地刺王两段伤害帧写成 `69` 和 `33`。
- 二进制依据：`Plant::UpdateSpikeweed` `0x460370` 中 `0x4603b3` 比较 `0x46`，`0x4603b8` 比较 `0x20`，即倒计时 `70` 和 `32`。
- 修正：地刺王伤害帧改为 `70` 和 `32`。
- 修改文件：`Lawn/Plant.cpp`
- 修改提交号：`039a863a727648424f94165377e14846c5e8f938`

## 9. `Plant::UpdateSquash` 倭瓜预跳倒计时

- 原错误：`STATE_SQUASH_LOOK -> STATE_SQUASH_PRE_LAUNCH` 转换时写成 `mStateCountdown = 30`。
- 二进制依据：`Plant::UpdateSquash` `0x4609d0` 中 `0x460ae7` 写状态 `0x4` 后，`0x460aee c7 46 54 2d 00 00 00` 将倒计时写为 `0x2d`，即 45。
- 修正：倭瓜预跳倒计时改为 `45`。
- 修改文件：`Lawn/Plant.cpp`
- 修改提交号：`999a6152d6043e024ced45facc5aec006aded8f3`

## 10. `Plant::FindStarFruitTarget` 杨桃矿工矩形修正字段

- 原错误：矿工僵尸特殊处理写成 `aZombieRect.mX += 10`。
- 二进制依据：`Plant::FindStarFruitTarget` `0x45f470` 中 `0x45f52a` 检查矿工僵尸后，`0x45f52f add DWORD PTR [esp+0x38],0xa` 修改的是矩形宽度字段；同函数 `0x45f511-0x45f51b` 使用 `[esp+0x30] + [esp+0x38]` 作为 `x + width`。
- 修正：改为 `aZombieRect.mWidth += 10`。
- 修改文件：`Lawn/Plant.cpp`
- 修改提交号：`999a6152d6043e024ced45facc5aec006aded8f3`

## 11. `Zombie::FindZombieTarget` 催眠僵尸攻击啃食目标贴边条件

- 原错误：啃食目标分支写成 `aOverlap > 0`，排除了 overlap 为 0 的贴边情况。
- 二进制依据：`Zombie::FindZombieTarget` `0x52e840` 中 `0x52e8e0 cmp eax,0x14; jge accept` 后，`0x52e8e5 test eax,eax; jl skip`，只在 overlap `< 0` 时跳过啃食分支。
- 修正：改为 `aOverlap >= 20 || (aOverlap >= 0 && aZombie->mIsEating)`。
- 修改文件：`Lawn/Zombie.cpp`
- 修改提交号：`999a6152d6043e024ced45facc5aec006aded8f3`

## 12. `Challenge::GraveDangerSpawnRandomGrave` / `WhackAZombiePlaceGraves` 新增墓碑权重反写

- 原错误：新增墓碑候选格权重写成 `GetTopPlantAt(...) ? 100000 : 1`，即已有植物格高权重、空格低权重。
- 二进制依据：`Challenge::GraveDangerSpawnRandomGrave` `0x4266c0` 在 `0x426796` 对有植物格写 `1`，在 `0x4267a2` 对空格写 `0x186a0`；`Challenge::WhackAZombiePlaceGraves` `0x425da0` 在 `0x425e7d` 对有植物格写 `1`，在 `0x425e89` 对空格写 `0x186a0`。
- 修正：两处均改为 `GetTopPlantAt(...) ? 1 : 100000`。
- 修改文件：`Lawn/Challenge.cpp`
- 修改提交号：`b8f25428fb5a16b2d1a1d3c37c39799c38154e86`

## 13. `Challenge::SpawnZombieWave` 生存夜晚最终波新增墓碑上限

- 原错误：生存夜晚最终波新增墓碑条件写成 `(IsSurvivalNormal(...) && aNumGraves < 8) || aNumGraves < 12`，导致生存简单在墓碑数小于 12 时仍会生成新墓碑。
- 二进制依据：`Challenge::SpawnZombieWave` `0x426850` 中 `0x42696c-0x426977` 对生存简单比较 `aNumGraves < 8`，`0x426979-0x42697c` 对其他生存模式比较 `aNumGraves < 12`，只有小于对应上限才在 `0x42697e-0x42697f` 调用 `GraveDangerSpawnRandomGrave()`。
- 修正：按模式先选择上限，生存简单为 `8`，其他生存模式为 `12`。
- 修改文件：`Lawn/Challenge.cpp`
- 修改提交号：`b8f25428fb5a16b2d1a1d3c37c39799c38154e86`

## 14. `Challenge::UpdateZombieSpawning` 打地鼠分支缺少返回值

- 原错误：打地鼠分支调用 `WhackAZombieSpawning()` 后没有返回值。
- 二进制依据：`Challenge::UpdateZombieSpawning` `0x426580` 在 `0x4265a6-0x4265a7` 调用 `WhackAZombieSpawning` `0x425ff0` 后，`0x4265ac-0x4265ae` 执行 `mov al, 1; ret`。
- 修正：打地鼠分支调用 `WhackAZombieSpawning()` 后 `return true`。
- 修改文件：`Lawn/Challenge.cpp`
- 修改提交号：`b8f25428fb5a16b2d1a1d3c37c39799c38154e86`

## 15. `Board::SpawnZombieWave` 最终波伏兵倒计时常量

- 原错误：最终波且非 continuous challenge 时写成 `mRiseFromGraveCounter = 210`。
- 二进制依据：`Board::SpawnZombieWave` `0x412ee0` 中 `0x413094` 的机器码 `c7 87 74 55 00 00 c8 00 00 00` 向 `Board + 0x5574` 写入 `0xc8`，即 `200`。
- 修正：改为 `mRiseFromGraveCounter = 200`。
- 修改文件：`Lawn/Board.cpp`
- 修改提交号：`b8f25428fb5a16b2d1a1d3c37c39799c38154e86`

## 16. `Board::SpawnZombiesFromGraves` 点数下限判断变量

- 原错误：墓碑起尸扣减点数后写成 `if (aZombieType < 1)`，把应检查的剩余点数误写为僵尸类型。
- 二进制依据：`Board::SpawnZombiesFromGraves` `0x412ce0` 中 `0x412e03` 扣减点数后，`0x412e06-0x412e0d` 比较减法后的剩余点数与 `1`，`0x412e0f-0x412e16` 才把局部剩余点数写回 `1`。
- 修正：改为 `if (aZombiePoints < 1) aZombiePoints = 1;`。
- 修改文件：`Lawn/Board.cpp`
- 修改提交号：`b8f25428fb5a16b2d1a1d3c37c39799c38154e86`

## 17. `Board::PickGraveRisingZombieType` 伪参数

- 原错误：源码签名写成 `PickGraveRisingZombieType(int theZombiePoints)`，调用点也传入 `aZombiePoints`，容易误解为伏兵类型选择会按剩余点数预算过滤。
- 二进制依据：`Board::PickGraveRisingZombieType` `0x40d770` 不读取栈参数或寄存器点数；`SpawnZombiesFromPool` `0x4128f0` 在 `0x412a1a-0x412a23` 仅把 `edx` 设为 board 指针后调用 `0x40d770`，没有传点数；屋顶空降和墓碑起尸调用点同样是无参数 picker 语义。
- 修正：移除 `PickGraveRisingZombieType` 的参数，并同步更新泳池伏兵、屋顶空降和墓碑起尸调用点。调用点保留本地扣点 / clamp 计算，但不再把它表达成 picker 输入。
- 修改文件：`Lawn/Board.h`、`Lawn/Board.cpp`
- 修改提交号：`b8f25428fb5a16b2d1a1d3c37c39799c38154e86`

## 18. `Zombie::StopZombieSound` 舞王 / 伴舞音乐停止条件

- 原错误：源码在找到仍有效的舞王 / 伴舞后设置 `aStopSound = true` 并停止 `FOLEY_DANCER`，条件极性反了。
- 二进制依据：`Zombie::StopZombieSound` `0x530850` 中 `0x5308c5-0x5308d0` 如果找到类型为 `0x8` 或 `0x9` 的有效僵尸，则直接跳到 `0x5308fb`，跳过 `StopFoley`；只有遍历耗尽后才落到 `0x5308eb-0x5308f6` 调用 `StopFoley(FOLEY_DANCER)`。
- 修正：默认需要停止声音，遍历到任一有效舞王 / 伴舞时取消停止。
- 修改文件：`Lawn/Zombie.cpp`
- 修改提交号：`b8f25428fb5a16b2d1a1d3c37c39799c38154e86`

## 19. `Zombie::PickRandomSpeed` 潜水僵尸二次入水速度相位

- 原错误：开头 `0.3f` 固定速度分支写成 `mZombiePhase == PHASE_DOLPHIN_WALKING_IN_POOL`，误把海豚水中行走相位当成该分支条件。
- 二进制依据：`Zombie::PickRandomSpeed` `0x524a70` 中 `0x524a77` 比较 `edx` 与 `0x3b`，匹配后 `0x524a7c` 加载 `0.3f` 写入 `mVelX`；`ConstEnums.h` 中 `0x3b = PHASE_SNORKEL_WALKING_IN_POOL`，`0x37 = PHASE_DOLPHIN_WALKING_IN_POOL`。
- 修正：该分支改为 `mZombiePhase == ZombiePhase::PHASE_SNORKEL_WALKING_IN_POOL`。
- 修改文件：`Lawn/Zombie.cpp`
- 回归校验：`tools/verify_binary_corrections.ps1`
- 修改提交号：`fd3bed59bd57c90fa3fb3717bb7e8bf885564c32`

## 20. `Zombie::ZombieTypeCanGoInPool` 水路合法类型漏气球

- 原错误：水路合法类型列表漏掉 `ZOMBIE_BALLOON`。
- 二进制依据：`Zombie::ZombieTypeCanGoInPool` `0x532060` 中 `0x532073 cmp eax,0x10`、`0x532076 je 0x53209e`，类型 `0x10` 返回 true；`ConstEnums.h` 中 `0x10 = ZOMBIE_BALLOON`。
- 修正：`ZombieTypeCanGoInPool()` 增加 `theZombieType == ZombieType::ZOMBIE_BALLOON`，并把函数地址注释修正为 `0x532060`。
- 修改文件：`Lawn/Zombie.cpp`
- 回归校验：`tools/verify_binary_corrections.ps1`
- 修改提交号：`fd3bed59bd57c90fa3fb3717bb7e8bf885564c32`

## 21. `Plant::FindTargetAndFire` 普通头部射击计数

- 原错误：普通 `anim_shooting` 头部射击分支把 `mShootingCounter` 写成 `33`，比原版提前 2cs。
- 二进制依据：`Plant::FindTargetAndFire` `0x45ef10` 中 `0x45f045` 向 `Plant + 0x90` 写入 `0x23`，即 35；重复射手、裂荚、左射和机枪分支随后再覆盖为 26 或 100。
- 修正：普通头部射击计数改为 `35`，保留各特殊植物的后续覆盖。
- 修改文件：`Lawn/Plant.cpp`
- 回归校验：`tools/verify_binary_corrections.ps1`
- 修改提交号：`fd3bed59bd57c90fa3fb3717bb7e8bf885564c32`

## 22. `Plant::BlowAwayFliers` 错误包含气球下落相位

- 原错误：三叶草直接调用 `Zombie::IsFlying()`；该函数按其通用语义同时包含 `PHASE_BALLOON_FLYING` 和 `PHASE_BALLOON_POPPING`，导致已经破球下落的僵尸也会被吹走。
- 二进制依据：`Plant::BlowAwayFliers` `0x4665b0` 在 `0x4665fe-0x46660b` 接受 `0x49` 并显式排除 `0x4a`，只有 `0x46660d` 才写 `mBlowingAway = 1`。独立的 `Zombie::IsFlying@0x534680` 同时包含两相位，因此不能全局收窄该函数。
- 修正：只在 `mZombiePhase == PHASE_BALLOON_FLYING` 时设置 `mBlowingAway`。
- 修改文件：`Lawn/Plant.cpp`
- 回归校验：`tools/verify_binary_corrections.ps1`
- 修改提交号：`fd3bed59bd57c90fa3fb3717bb7e8bf885564c32`

## 23. `Challenge::IZombiePlaceZombie` 蹦极行列参数混用

- 原错误：蹦极分支先按 `theGridY` 创建僵尸，随后却调用 `SetRow(theGridX)`，把列号写入行号。
- 二进制依据：`Challenge::IZombiePlaceZombie` `0x42a0f0` 中 `0x42a125` 把 col 写入 `mTargetCol`，`0x42a12b` 把 row 写入 `mRow`；位置 y 与 render order 也都使用 row。
- 修正：蹦极分支改为 `SetRow(theGridY)`。
- 修改文件：`Lawn/Challenge.cpp`
- 回归校验：`tools/verify_binary_corrections.ps1`
- 修改提交号：`fd3bed59bd57c90fa3fb3717bb7e8bf885564c32`

## 24. `Board::GetPlantsOnLawn` 模仿者 flying 层类型

- 原错误：函数已将模仿者替换成目标 `aSeedType`，但 flying 层判断又重新使用 `aPlant->mSeedType`，使尚未变身的模仿咖啡豆落入 normal 层。
- 二进制依据：`Board::GetPlantsOnLawn` `0x40d2a0` 在 `0x40d307-0x40d317` 用 `mImitaterType` 覆盖 EDI，随后 `0x40d350` 继续用 EDI 比较 `0x23 = SEED_INSTANT_COFFEE`；没有重新读取实际类型。
- 修正：flying 层判断改为 `Plant::IsFlying(aSeedType)`，与其余分层统一使用有效类型。
- 修改文件：`Lawn/Board.cpp`
- 回归校验：`tools/verify_binary_corrections.ps1`
- 修改提交号：`fd3bed59bd57c90fa3fb3717bb7e8bf885564c32`

## 25. `Plant::UpdateBlover` 倒计时字段

- 原错误：三叶草在非 `STATE_DOINGSPECIAL` 状态下检查 `mStateCountdown == 0`，但等待生效使用的是 `mDoSpecialCountdown`。
- 二进制依据：`Plant::UpdateBlover` `0x460f00` 在 `0x460f44` 比较 `[Plant + 0x50]`；字段布局中 `+0x50 = mDoSpecialCountdown`，`+0x54 = mStateCountdown`。
- 修正：触发条件改为 `mDoSpecialCountdown == 0`。
- 修改文件：`Lawn/Plant.cpp`
- 回归校验：`tools/verify_binary_corrections.ps1`
- 修改提交号：`fd3bed59bd57c90fa3fb3717bb7e8bf885564c32`

## 26. `Zombie::UpdateYuckyFace` 单向换行方向

- 原错误：仅下方可走时写 `row - 1`，仅上方可走时写 `row + 1`；顶行和底行会尝试进入非法行。
- 二进制依据：`Zombie::UpdateYuckyFace` `0x52b6a0` 在 `0x52b826` 生成 `row - 1`，并在仅上方可走的 `0x52b8c7` 写入；`0x52b876` 生成 `row + 1`，并在仅下方可走的 `0x52b8e8` 写入。
- 修正：仅下方可走时使用 `row + 1`，仅上方可走时使用 `row - 1`；双向合法时的随机分支保持不变。
- 修改文件：`Lawn/Zombie.cpp`
- 回归校验：`tools/verify_binary_corrections.ps1`
- 修改提交号：`fd3bed59bd57c90fa3fb3717bb7e8bf885564c32`

## 27. `Challenge::UpdateZombieSpawning` 返回类型

- 原错误：源码声明和定义使用 `int`，但原版只在 AL 中返回真假；把它表达为 32 位返回值会读取未定义的高位。
- 二进制依据：`Challenge::UpdateZombieSpawning` `0x426580` 在 `0x4265ac` 用 `mov al,1` 返回 true，在 `0x426617` 用 `xor al,al` 返回 false；唯一原版调用点 `0x413df5` 使用 `test al,al`。
- 修正：声明和定义的返回类型统一改为 `bool`；现有调用点本来就只用于布尔条件。
- 修改文件：`Lawn/Challenge.h`、`Lawn/Challenge.cpp`
- 回归校验：`tools/verify_binary_corrections.ps1`
- 修改提交号：`fd3bed59bd57c90fa3fb3717bb7e8bf885564c32`

## 28. `Plant::UpdateSquash` 下落曲线枚举

- 原错误：窝瓜 `STATE_SQUASH_FALLING` 分支把 10cs 下落写成 `TodCurves::CURVE_EASE_IN_OUT`；这会让反编译源码中的下落位置明显晚于原版，而上升段才使用该缓入缓出曲线。
- 二进制依据：`Plant::UpdateSquash@0x4609D0` 的上升分支在 `0x460BE2` 向 `TodAnimateCurve@0x511C40` 传 `push 0x4`（`CURVE_EASE_IN_OUT`）；下落分支在 `0x460C6C` 明确传 `push 0x1`（`CURVE_LINEAR`），并于 `0x460C7A` 调用同一函数。
- 修正：下落分支改为 `TodCurves::CURVE_LINEAR`；PE 模拟器原有线性插值无需修改。
- 修改文件：`Lawn/Plant.cpp`
- 回归校验：`tools/verify_binary_corrections.ps1` 新增源码契约及 `0x460C6C push 1` / `0x460C7A call 0x511C40` 固定地址校验。
- 修改提交号：`8214a34ecd7533c5f0872828aca0550beab1eb51`

## 附：已复核但无需修改的行为

- `Plant::Squish` `0x462b80`：源码中樱桃、辣椒、醒着的毁灭菇/寒冰菇、已就绪土豆雷走 `DoSpecial()`，睡眠植物和普通植物进入压扁状态；与二进制一致。
- `Zombie::SquishAllInSquare` `0x52e920`：源码中车辆碾压同格时只额外排除地刺/地刺王，然后调用 `Plant::Squish()`；与二进制一致。
- `Board::UpdateZombieSpawning` `0x413d00`：W9/W19 红字倒计时归零帧会在清 advice、调用 `NextWaveComing()` 并写 `mZombieCountDown = 1` 后继续落入普通 `mZombieCountDown--` 路径；当前反编译源码与二进制一致，不属于反编译源码错误。
