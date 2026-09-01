# 已经修改的反汇编项目 bug 合集

记录时间：2026-06-18；最近更新：2026-08-25

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

## 29. `AwardScreen::Draw` 金向日葵奖杯位置和缩放

- 原错误：非冒险模式的金向日葵奖杯绘制为坐标 `(330, 80)`、缩放 `0.7`。
- 二进制依据：`AwardScreen::Draw` `0x4068D0` 的金奖杯分支在 `0x406AC7` 读取 `0x679610 = 0.6f` 两次作为横纵缩放，并传入图块 `1`；共用调用段 `0x407590`、`0x4075A5` 分别读取 `0x679778 = 65.0f`、`0x67A070 = 325.0f`。
- 修正：金向日葵奖杯改为坐标 `(325, 65)`、缩放 `0.6`；银奖杯分支保持不变。
- 修改文件：`Lawn/Widget/AwardScreen.cpp`
- 回归校验：`tools/verify_binary_corrections.ps1` 新增源码契约、绘制分支和上述三个固定地址常量校验。
- 修改提交号：`d7c16584b508aaa46e11758c9a1ffa745ca15a61`

## 30. `Challenge::UpdateSlotMachine` 普通三连奖励数量

- 原错误：普通植物三连分支循环 20 次生成可用植物卡包。
- 二进制依据：`Challenge::UpdateSlotMachine@0x423800` 的该分支从 `esi = 0`
  开始，每轮加 `0x3c`，到 `cmp esi, 0xb4` 时退出，恰好执行 3 轮。
- 实际游戏行为：错误源码会掉落 20 个相同卡包；原版只掉落 3 个。
- 修正：该分支循环上限改为 3；阳光三连的 20 次循环保持不变。
- 修改文件：`Lawn/Challenge.cpp`
- 回归校验：`tools/verify_binary_corrections.ps1`
- 修改提交号：`8b8d8a7d332654abea1cedd99c1e91064a043eb1`

## 31. `ZombiePickerInitForWave` 跨波次僵尸计数

- 原错误：整结构 `memset` 同时清除了 `mAllWavesZombieTypeCount`。
- 二进制依据：`ZombiePickerInitForWave@0x4090F0` 只清零偏移 `0x00`—`0x88`；
  完整初始化函数才继续清零从 `0x8c` 开始的跨波次数组。
- 实际游戏行为：错误源码每波都会忘记此前各类僵尸的累计数量，改变随机波次
  的类型限制和构成。
- 修正：只清本波数量、点数和 `mZombieTypeCount`。
- 修改文件：`Lawn/Board.cpp`
- 回归校验：`tools/verify_binary_corrections.ps1`
- 修改提交号：`8b8d8a7d332654abea1cedd99c1e91064a043eb1`

## 32. `LawnApp::IsScaryPotterLevel` 砸罐子无尽上界

- 原错误：模式区间上界写成 `GAMEMODE_SCARY_POTTER_9`。
- 二进制依据：`LawnApp::IsScaryPotterLevel@0x4538F0` 接受枚举区间
  `0x33`—`0x3c`，其中 `0x3c` 是砸罐子无尽。
- 实际游戏行为：错误源码不会把无尽识别为砸罐子关卡，相关初始化、推进、
  奖励和交互会选择错误分支。
- 修正：上界改为 `GAMEMODE_SCARY_POTTER_ENDLESS`。
- 修改文件：`LawnApp.cpp`
- 回归校验：`tools/verify_binary_corrections.ps1`
- 修改提交号：`8b8d8a7d332654abea1cedd99c1e91064a043eb1`

## 33. `Challenge::ShovelAddWallnuts` 行数

- 原错误：遍历内部六行，额外在不可见第六行种 9 株坚果。
- 二进制依据：`Challenge::ShovelAddWallnuts@0x428510` 的内层行循环在
  `cmp esi, 0x5` 后回跳，只处理行号 0—4；列循环处理 0—8。
- 实际游戏行为：错误源码会污染“你能把它挖出来吗？”和隐藏松鼠关的植物
  数量及不可见行状态。
- 修正：行上界改为 `MAX_GRID_SIZE_Y - 1`。
- 修改文件：`Lawn/Challenge.cpp`
- 回归校验：`tools/verify_binary_corrections.ps1`
- 修改提交号：`8b8d8a7d332654abea1cedd99c1e91064a043eb1`

## 34. `Board::NextWaveComing` 打僵尸警报条件

- 原错误：打僵尸模式的最终波判断与通用旗帜波判断用“或”连接。
- 二进制依据：`Board::NextWaveComing@0x413C00` 对打僵尸只检查最终波；只有
  非打僵尸模式才调用 `IsFlagWave`。
- 实际游戏行为：错误源码会在打僵尸的中途旗帜波额外播放最终波警报。
- 修正：恢复“打僵尸 ? 最终波 : 旗帜波”的互斥条件。
- 修改文件：`Lawn/Board.cpp`
- 回归校验：`tools/verify_binary_corrections.ps1`
- 修改提交号：`8b8d8a7d332654abea1cedd99c1e91064a043eb1`

## 35. `ZenGarden::FindOpenZenGardenSpot` 占用格跳过层级

- 原错误：坐标匹配时只 `continue` 内层盆栽遍历，之后仍把占用格加入候选。
- 二进制依据：`ZenGarden::FindOpenZenGardenSpot@0x51D7B0` 命中花园和坐标后
  直接跳到增加 Y 的外层位置；只有遍历完未命中才写入候选。
- 实际游戏行为：新盆栽可能与已有盆栽重叠在同一花园坐标。
- 修正：发现占用时跳到下一个候选格。
- 修改文件：`Lawn/ZenGarden.cpp`
- 回归校验：`tools/verify_binary_corrections.ps1`
- 修改提交号：`8b8d8a7d332654abea1cedd99c1e91064a043eb1`

## 36. `Zombie::UpdateZombieJalapenoHead` 引爆后死亡

- 原错误：辣椒头僵尸完成整行爆炸后没有调用死亡函数。
- 二进制依据：原版在 `Zombie::UpdateZombieJalapenoHead@0x5275C0` 的
  `0x52773E` 调用 `Zombie::DieNoLoot@0x530510` 后才返回。
- 实际游戏行为：错误源码中的僵尸引爆后仍存活并继续更新；原版立即无掉落
  死亡。
- 修正：爆炸分支末尾调用 `DieNoLoot()`，不受社区修复宏影响。
- 修改文件：`Lawn/Zombie.cpp`
- 回归校验：`tools/verify_binary_corrections.ps1`
- 修改提交号：`8b8d8a7d332654abea1cedd99c1e91064a043eb1`

## 37. 砸罐子第 6 关橄榄球与小丑数量

- 原错误：两类僵尸都请求放入 6 个。
- 二进制依据：`Challenge::ScaryPotterPopulate@0x4286F0` 的第 6 关分支分别
  向两次放罐调用传入数量 2 和 1。
- 实际游戏行为：错误请求比原版多 4 个橄榄球和 5 个小丑，并可能耗尽候选格
  导致崩溃。
- 修正：数量改为 2 个橄榄球、1 个小丑。
- 修改文件：`Lawn/Challenge.cpp`
- 回归校验：`tools/verify_binary_corrections.ps1`
- 修改提交号：`8b8d8a7d332654abea1cedd99c1e91064a043eb1`

## 38. 普通水壶工具状态

- 原错误：普通水壶分支写入金水壶状态。
- 二进制依据：`ZenGarden::MouseDownWithFeedingTool@0x51EB70` 的金水壶路径
  写 `0x12`，普通水壶路径在 `0x51EF30` 写 `0x0e`。
- 实际游戏行为：错误源码让普通水壶也按金水壶逻辑浇灌范围内多株植物。
- 修正：普通分支写入 `GRIDITEM_STATE_ZEN_TOOL_WATERING_CAN`。
- 修改文件：`Lawn/ZenGarden.cpp`
- 回归校验：`tools/verify_binary_corrections.ps1`
- 修改提交号：`8b8d8a7d332654abea1cedd99c1e91064a043eb1`

## 39. 砸罐子钱袋散币数量

- 原错误：奖杯和钱袋共用 5 枚金币的 fan-out 分支。
- 二进制依据：`Coin::Collect@0x432060` 对 `COIN_AWARD_MONEY_BAG` 在
  `0x4322EC` 传入数量 2；奖杯分支传入 5。
- 实际游戏行为：每个钱袋比原版多给 3 枚金币，即多 30 金币面值。
- 修正：拆分钱袋分支为 2 枚金币，奖杯保留 5 枚。
- 修改文件：`Lawn/Coin.cpp`
- 回归校验：`tools/verify_binary_corrections.ps1`
- 修改提交号：`8b8d8a7d332654abea1cedd99c1e91064a043eb1`

## 40. 解谜阶段巧克力奖励类型

- 原错误：奖励阶段使用普通 `COIN_CHOCOLATE`。
- 二进制依据：`Challenge::PuzzlePhaseComplete@0x429980` 在可掉巧克力时生成
  枚举 `0x18 = COIN_AWARD_CHOCOLATE`，否则生成钱袋 `0x12`。
- 实际游戏行为：普通巧克力会走错展示、收集和奖励处理流程。
- 修正：使用 `COIN_AWARD_CHOCOLATE`。
- 修改文件：`Lawn/Challenge.cpp`
- 回归校验：`tools/verify_binary_corrections.ps1`
- 修改提交号：`8b8d8a7d332654abea1cedd99c1e91064a043eb1`

## 41. `Board::UpdateZombieSpawning` 旗帜波倒计时条件

- 原错误：只在坚果保龄球或 Last Stand 的旗帜波设置额外倒计时。
- 二进制依据：原版 `@0x413D00` 在 `0x414057` 检查特殊模式标志，标志非零时
  跳过 `ZOMBIE_COUNTDOWN_BEFORE_FLAG`；只有普通模式写入该值。
- 实际游戏行为：普通关旗帜波缺少间隔，两个特殊模式反而获得额外间隔。
- 修正：给“坚果保龄球或 Last Stand”并集加取反。
- 修改文件：`Lawn/Board.cpp`
- 回归校验：`tools/verify_binary_corrections.ps1`
- 修改提交号：`8b8d8a7d332654abea1cedd99c1e91064a043eb1`

## 42. 疯狂戴夫自动选卡的“不推荐”标志

- 原错误：计算 `SeedNotRecommendedToPick` 后没有使用其返回值。
- 二进制依据：`SeedChooserScreen::CrazyDavePickSeeds@0x483F70` 保存该标志，
  并在 `0x48400B` 检查；非零时把对应植物权重设为 0。
- 实际游戏行为：戴夫可能随机选到当前场地或僵尸配置明确不推荐的植物。
- 修正：把 `aRecFlags` 并入禁选条件。
- 修改文件：`Lawn/Widget/SeedChooserScreen.cpp`
- 回归校验：`tools/verify_binary_corrections.ps1`
- 修改提交号：`8b8d8a7d332654abea1cedd99c1e91064a043eb1`

## 43. 左向双发射手发射点镜像公式

- 原错误：使用 `mX + aOffsetX + 27`，没有镜像头部动画偏移。
- 二进制依据：`Plant::Fire@0x466E00` 的 `0x4670D8`—`0x4670E6` 执行
  `mX - aOffsetX + 27`。
- 实际游戏行为：动画帧偏移变化时，豌豆出生点会向错误方向移动并脱离炮口。
- 修正：公式恢复为 `mX - aOffsetX + 27`，不使用仅在特定帧等价的常量近似。
- 修改文件：`Lawn/Plant.cpp`
- 回归校验：`tools/verify_binary_corrections.ps1`
- 修改提交号：`8b8d8a7d332654abea1cedd99c1e91064a043eb1`

## 44. 僵尸水族馆初始卡包

- 原错误：`Board::InitLevel` 缺少僵尸水族馆专用初始化分支。
- 二进制依据：原版 `@0x40A8E0` 在 `0x40B317` 识别模式 `0x17`，依次给第 0、
  1 格设置 `SEED_ZOMBIQUARIUM_SNORKLE` 和 `SEED_ZOMBIQUARIUM_TROPHY`。
- 实际游戏行为：错误源码没有潜水僵尸与奖杯两个专用卡包，关卡无法按官方
  规则游玩。
- 修正：恢复两个卡包及其顺序。
- 修改文件：`Lawn/Board.cpp`
- 回归校验：`tools/verify_binary_corrections.ps1`
- 修改提交号：`8b8d8a7d332654abea1cedd99c1e91064a043eb1`

## 45. 宝石迷阵扭转成消预判轮换关系

- 原错误：2×2 临时棋盘的四格赋值不对应实际顺时针扭转。
- 二进制依据：`BeghouledTwistMoveCausesMatch@0x420190` 形成旧值关系
  `B=A、D=B、C=D、A=C`。
- 实际游戏行为：错误预判会拒绝能成消的扭转或允许不能成消的扭转，并影响
  可行步搜索和提示。
- 修正：按上述 A/B/C/D 关系恢复临时轮换。
- 修改文件：`Lawn/Challenge.cpp`
- 回归校验：`tools/verify_binary_corrections.ps1`
- 修改提交号：`8b8d8a7d332654abea1cedd99c1e91064a043eb1`

## 46. 宝石迷阵拖动主方向

- 原错误：直接比较带符号的 X、Y 位移。
- 二进制依据：`Challenge::BeghouledDragUpdate@0x420760` 先分别取两轴绝对值，
  再比较其大小；符号只用于决定具体方向。
- 实际游戏行为：向左或向上斜拖时可能交换较短轴方向的相邻植物。
- 修正：主轴判断改为 `abs(aDeltaX) > abs(aDeltaY)`。
- 修改文件：`Lawn/Challenge.cpp`
- 回归校验：`tools/verify_binary_corrections.ps1`
- 修改提交号：`8b8d8a7d332654abea1cedd99c1e91064a043eb1`

## 47. 宝石迷阵除坑卡包数量

- 原错误：设置第 5 格除坑卡后没有把 `mNumPackets` 从 4 更新为 5。
- 二进制依据：`Challenge::ZombieAtePlant@0x424590` 在设置第 5 格后于
  `0x424607` 明确写入 `SeedBank::mNumPackets = 5`。
- 实际游戏行为：卡包对象已初始化，但种子栏仍只显示四格，玩家无法正常使用
  除坑卡。
- 修正：设置卡包前同步把数量改为 5。
- 修改文件：`Lawn/Challenge.cpp`
- 回归校验：`tools/verify_binary_corrections.ps1`
- 修改提交号：`8b8d8a7d332654abea1cedd99c1e91064a043eb1`

## 48. I, Zombie 蹦极种子枚举

- 原错误：`Challenge::CanPlantAt` 把传入的种子类型同 `ZOMBIE_BUNGEE` 比较。
- 二进制依据：原版 `@0x425550` 在 `0x4255E1` 比较
  `0x42 = SEED_ZOMBIE_BUNGEE`，不是僵尸类型枚举 `0x14`。
- 实际游戏行为：错误源码不能识别蹦极僵尸卡，从而绕过或错用专有落点限制。
- 修正：比较 `SEED_ZOMBIE_BUNGEE`。
- 修改文件：`Lawn/Challenge.cpp`
- 回归校验：`tools/verify_binary_corrections.ps1`
- 修改提交号：`8b8d8a7d332654abea1cedd99c1e91064a043eb1`

## 49. 僵尸水族馆奖杯教学回退状态

- 原错误：玩家买不起奖杯时从“点击奖杯”状态回退到 `TUTORIAL_OFF`。
- 二进制依据：`Challenge::ZombiquariumUpdate@0x4280A0` 在该分支的
  `0x42846E`—`0x42848F` 写入 `0x14 = TUTORIAL_ZOMBIQUARIUM_BOUGHT_SNORKEL`。
- 实际游戏行为：错误源码会彻底结束教学，玩家不再得到后续奖杯购买引导。
- 修正：资金不足时回退到“已购买潜水僵尸”阶段；较早的潜水僵尸教学关闭
  分支保持 `TUTORIAL_OFF`。
- 修改文件：`Lawn/Challenge.cpp`
- 回归校验：`tools/verify_binary_corrections.ps1`
- 修改提交号：`8b8d8a7d332654abea1cedd99c1e91064a043eb1`

## 50. 宝石迷阵一次性升级卡包停用

- 原错误：购买重复射手、忧郁菇或高坚果升级后仍保持卡包激活。
- 二进制依据：`Challenge::BeghouledPacketClicked@0x427A60` 在三个成功分支
  分别于 `0x427B03`、`0x427B78`、`0x427BF4` 清除激活状态。
- 实际游戏行为：已买完的升级仍可再次点击并可能继续扣除阳光而不产生效果。
- 修正：三个成功购买分支末尾均调用 `SetActivate(false)`。
- 修改文件：`Lawn/Challenge.cpp`
- 回归校验：`tools/verify_binary_corrections.ps1`
- 修改提交号：`8b8d8a7d332654abea1cedd99c1e91064a043eb1`

## 51. 隐藏松鼠关卡等待与移动

- 原错误：等待时间写成 100—400；方向三元式使竖直目标也落入右移分支，且
  没有设置移动计数。
- 二进制依据：`SquirrelStart@0x42BB10` 和 `SquirrelChew@0x42BCB0` 生成
  100—500；`SquirrelFound@0x42BE10` 先区分 X，X 相等再区分 Y，并写计数 50。
- 实际游戏行为：松鼠最长少等待 100cs，竖直移动还可能选错方向或卡住。
- 修正：三处等待上界改为 500，按坐标恢复四向判断，并设置 50cs 移动计数。
- 修改文件：`Lawn/Challenge.cpp`
- 回归校验：`tools/verify_binary_corrections.ps1`
- 修改提交号：`8b8d8a7d332654abea1cedd99c1e91064a043eb1`

## 52. 植物僵尸高坚果头裂纹类型

- 原错误：高坚果头使用 `HELMTYPE_WALLNUT`，耐久虽为 2200 但受伤贴图类型错误。
- 二进制依据：`Zombie::ZombieInitialize` 在 `0x52394D` 对类型 `0x1f` 写入
  `9 = HELMTYPE_TALLNUT`，并独立写入 2200 点耐久。
- 实际游戏行为：两档受伤阶段显示普通坚果裂纹，而非高坚果裂纹。
- 修正：头盔类型改为 `HELMTYPE_TALLNUT`；耐久和初始动画保持不变。
- 修改文件：`Lawn/Zombie.cpp`
- 回归校验：`tools/verify_binary_corrections.ps1`
- 修改提交号：`8b8d8a7d332654abea1cedd99c1e91064a043eb1`

## 53. 疯狂戴夫赠送树肥的商店槽位

- 原错误：3200 号台词分支向硬编码索引 29 写入树肥数量。
- 二进制依据：原版在 `0x43C9DD` 向 `PlayerInfo + 0x230` 写 1005；该偏移对应
  `mPurchases[28] = STORE_ITEM_TREE_FOOD`。
- 实际游戏行为：错误源码没有真正增加树肥库存，却污染相邻商品购买数据。
- 修正：显式索引 `STORE_ITEM_TREE_FOOD`。
- 修改文件：`Lawn/CutScene.cpp`
- 回归校验：`tools/verify_binary_corrections.ps1`
- 修改提交号：`8b8d8a7d332654abea1cedd99c1e91064a043eb1`

## 54. 树肥售罄边界

- 原错误：树肥数量只有大于 10 才判定售罄。
- 二进制依据：`StoreScreen::IsItemSoldOut@0x48A9D0` 在 `0x48AA23` 与 10 比较，
  随后使用 `setge`。
- 实际游戏行为：已有 10 份树肥时仍可再买一份，超过官方上限。
- 修正：条件改为 `>= 10`。
- 修改文件：`Lawn/Widget/StoreScreen.cpp`
- 回归校验：`tools/verify_binary_corrections.ps1`
- 修改提交号：`8b8d8a7d332654abea1cedd99c1e91064a043eb1`

## 55. 新档首次冒险前导关条件

- 原错误：条件写成首次冒险、等级 0 且已有存档。
- 二进制依据：`GameSelector::Update@0x44B2A0` 在 `0x44B357` 检查等级 1，
  并且仅在 `SaveFileExists()` 返回 false 时进入 `GAMEMODE_INTRO`。
- 实际游戏行为：真正的新档不会进入前导关，异常的“等级 0 且已有存档”反而
  会尝试进入。
- 修正：恢复 `mLevel == 1 && !SaveFileExists()`。
- 修改文件：`Lawn/Widget/GameSelector.cpp`
- 回归校验：`tools/verify_binary_corrections.ps1`
- 修改提交号：`8b8d8a7d332654abea1cedd99c1e91064a043eb1`

## 56. `SeedTypeAvailable` 机枪射手条件

- 原错误：把“机枪射手且已购买”同 `HasSeedType` 用“或”连接。
- 二进制依据：1051 在选卡界面内联为二选一：类型 `0x28` 时只检查机枪射手
  购买记录，其他类型才调用 `HasSeedType@0x453B20`。
- 实际游戏行为：通关后 `HasSeedType` 会让未购买的机枪射手也出现在选卡界面。
- 修正：机枪射手只按购买记录判断，其他种子调用 `HasSeedType`。
- 修改文件：`LawnApp.cpp`
- 回归校验：`tools/verify_binary_corrections.ps1`
- 修改提交号：`8b8d8a7d332654abea1cedd99c1e91064a043eb1`

## 57. 智慧树模式铲子显示

- 原错误：`CutScene::ShowShovel` 漏掉智慧树提前返回条件。
- 二进制依据：原版 `@0x43C140` 在 `0x43C1A8` 比较
  `0x32 = GAMEMODE_TREE_OF_WISDOM`，命中后直接返回。
- 实际游戏行为：智慧树界面会显示不应出现的铲子并进入普通铲子交互。
- 修正：把 `GAMEMODE_TREE_OF_WISDOM` 加入排除列表。
- 修改文件：`Lawn/CutScene.cpp`
- 回归校验：`tools/verify_binary_corrections.ps1`
- 修改提交号：`8b8d8a7d332654abea1cedd99c1e91064a043eb1`

## 58. 疯狂戴夫卡槽升级对话的槽数、价格和台词号

- 原错误：显示 `aNumPackets + 1`，把钱包余额当价格，并在第二轮成功后检查
  不存在于该分支的 1533。
- 二进制依据：`CutScene::AdvanceCrazyDaveDialog@0x43C950` 使用
  `aNumPackets + 7`、计算所得价格，并在购买后依次检查 1503 和 1553。
- 实际游戏行为：确认框少显示 6 个槽位、显示错误金额，第二轮购买后还无法
  进入 1560 号台词。
- 修正：分别改为 `+ 7`、`GetMoneyString(aCost)` 和消息号 1553。
- 修改文件：`Lawn/CutScene.cpp`
- 回归校验：`tools/verify_binary_corrections.ps1`
- 修改提交号：`8b8d8a7d332654abea1cedd99c1e91064a043eb1`

## 59. 领取奖励淡出阶段的棋盘按钮

- 原错误：`Board::CanInteractWithBoardButtons` 没有排除棋盘淡出状态。
- 二进制依据：原版 `@0x412490` 于 `0x412509` 比较
  `mBoardFadeOutCounter` 与 0，`jge` 跳到返回 false。
- 实际游戏行为：领取奖励后的结算过渡中仍可打开菜单、商店或切换工具。
- 修正：`mBoardFadeOutCounter >= 0` 时返回 false。
- 修改文件：`Lawn/Board.cpp`
- 回归校验：`tools/verify_binary_corrections.ps1`
- 修改提交号：`8b8d8a7d332654abea1cedd99c1e91064a043eb1`

## 60. Upsell 首句疯狂戴夫台词状态

- 原错误：开始 `mCrazyDaveDialogStart` 后没有同步
  `mCrazyDaveLastTalkIndex`。
- 二进制依据：`CutScene::UpdateUpsell@0x440D20` 调用 `CrazyDaveTalkIndex` 后，
  在 `0x440D79`—`0x440D7C` 把同一编号写入 last-talk 字段。
- 实际游戏行为：每帧都会把首句误认为尚未开始并从头重启，演示无法推进。
- 修正：首次调用后记录 `mCrazyDaveLastTalkIndex = mCrazyDaveDialogStart`。
- 修改文件：`Lawn/CutScene.cpp`
- 回归校验：`tools/verify_binary_corrections.ps1`
- 修改提交号：`8b8d8a7d332654abea1cedd99c1e91064a043eb1`

## 61. `ClearUpsellBoard` 保留疯狂戴夫动画

- 原错误：切换演示棋盘时无条件删除全部 reanimation。
- 二进制依据：原版 `CutScene::ClearUpsellBoard@0x43DA50` 在 `0x43DB64` 比较
  `mReanimationType` 与 `0x61 = REANIM_CRAZY_DAVE`，仅对其他类型调用死亡函数。
- 实际游戏行为：疯狂戴夫本体及眨眼动画被销毁，后续更新可能访问失效对象并
  导致演示崩溃。
- 修正：按原版类型语义保留所有 `REANIM_CRAZY_DAVE`。
- 修改文件：`Lawn/CutScene.cpp`
- 回归校验：`tools/verify_binary_corrections.ps1`
- 修改提交号：`8b8d8a7d332654abea1cedd99c1e91064a043eb1`

## 附：已复核但无需修改的行为

- `Plant::Squish` `0x462b80`：源码中樱桃、辣椒、醒着的毁灭菇/寒冰菇、已就绪土豆雷走 `DoSpecial()`，睡眠植物和普通植物进入压扁状态；与二进制一致。
- `Zombie::SquishAllInSquare` `0x52e920`：源码中车辆碾压同格时只额外排除地刺/地刺王，然后调用 `Plant::Squish()`；与二进制一致。
- `Board::UpdateZombieSpawning` `0x413d00`：W9/W19 红字倒计时归零帧会在清 advice、调用 `NextWaveComing()` 并写 `mZombieCountDown = 1` 后继续落入普通 `mZombieCountDown--` 路径；当前反编译源码与二进制一致，不属于反编译源码错误。
- `Zombie::UpdateZombieDancer` `0x528CA0`：原 D34 记录声称源码在递减
  `mSummonCounter` 后检查 `== 1`，实际从初始提交
  `c663d6e1628ae5a34b2da30dbba162571c021527` 起即为 `== 0`，与 1051 二进制
  一致；该项是文档误报，不需要生产代码修改。
