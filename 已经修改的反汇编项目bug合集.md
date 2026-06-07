# 已经修改的反汇编项目 bug 合集

记录时间：2026-06-07

用途：记录本反编译项目中已按 PvZ 1.0.0.1051 原版二进制重新校正的源码错误。后续使用本项目作为 PE / rsvz 行为参考时，遇到这些函数应以本文件和源码中的 `Corrected against PvZ 1.0.0.1051 binary` 注释为准。

原版二进制路径：`C:\Users\123\Desktop\Plants_Vs_Zombies_V1.0.0\Plants_Vs_Zombies_V1.0.0.1051_EN\PlantsVsZombies.exe`

## 1. `Zombie::PickRandomSpeed` 普通僵尸速度上限

- 原错误：普通兜底速度范围写成 `RandRangeFloat(0.23f, 0.32f)`。
- 二进制依据：`Zombie::PickRandomSpeed` `0x524a70` 中普通兜底分支在 `0x524b81` 加载 `0x679660 = 0.37f`，在 `0x524b8e` 加载 `0x679670 = 0.23f` 后调用 `RandRangeFloat`。
- 修正：改为 `RandRangeFloat(0.23f, 0.37f)`。
- 修改文件：`Lawn/Zombie.cpp`

## 2. `Projectile::ProjectileInitialize` 屋顶阴影修正条件

- 原错误：屋顶/月夜场景无条件执行 `mShadowY -= 12.0f`。
- 二进制依据：`Projectile::ProjectileInitialize` `0x46c730` 中 `0x46c805-0x46c833` 先判断屋顶/月夜，再比较 projectile 初始 `x` 与 `480.0f`；只有 `x < 480.0f` 时进入减阴影分支。
- 修正：改为 `mBoard->StageHasRoof() && theX < 480`。
- 修改文件：`Lawn/Projectile.cpp`

## 3. `Projectile::IsSplashDamage` 火抗短路范围

- 原错误：只要 `mProjectileType` 非 0 且目标 `IsFireResistant()` 就返回非溅射，误覆盖西瓜/冰瓜。
- 二进制依据：`Projectile::IsSplashDamage` `0x46d1f0` 在 `0x46d1f3` 先比较 projectile type 是否为 `0x6`，只有 fireball/fire pea 才进入火抗短路；随后 `0x46d21c-0x46d229` 仍将 `0x3` melon、`0x5` winter melon、`0x6` fireball 判为溅射。
- 修正：火抗短路限定为 `mProjectileType == ProjectileType::PROJECTILE_FIREBALL`。
- 修改文件：`Lawn/Projectile.cpp`

## 4. `Projectile::FindCollisionTarget` 潜水僵尸高度条件

- 原错误：源码写成潜水僵尸 `mPosZ >= 45.0f` 时跳过命中。
- 二进制依据：`Projectile::FindCollisionTarget` `0x46cd40` 中 `0x46cdc4-0x46cdd2` 比较 `45.0f` 与 projectile `mPosZ`，实际只允许 `mPosZ > 45.0f` 继续碰撞判定。
- 修正：潜水僵尸跳过条件改为 `mPosZ <= 45.0f`。
- 修改文件：`Lawn/Projectile.cpp`

## 5. `Projectile::FindCollisionTarget` 命中边界

- 原错误：projectile 与僵尸横向重叠条件写成 `GetRectOverlap(...) > 0`，会排除边界相切。
- 二进制依据：`Projectile::FindCollisionTarget` `0x46ce35-0x46ce37` 为 `test eax,eax; jl skip`，即只在 overlap `< 0` 时跳过。
- 修正：命中候选条件改为 `GetRectOverlap(...) >= 0`。
- 修改文件：`Lawn/Projectile.cpp`

## 6. `Projectile::CheckForCollision` 星星弹上边界

- 原错误：星星弹在 `mPosY < 0.0f` 时销毁。
- 二进制依据：`Projectile::CheckForCollision` `0x46ce80` 的星星弹分支在 `0x46cf88` 加载 `0x67959c = 40.0f`，原版在 `mPosY < 40.0f` 时销毁星星弹。
- 修正：星星弹上边界改为 `mPosY < 40.0f`。
- 修改文件：`Lawn/Projectile.cpp`

## 7. `Projectile::DoSplashDamage` 非火球溅射总伤害上限

- 原错误：非火球溅射总伤害上限写成 `7 * (original_damage / 3)`。
- 二进制依据：`Projectile::DoSplashDamage` `0x46d390` 中 `0x46d3eb-0x46d40d` 先保留原始伤害，再计算单目标溅射伤害；`0x46d3fa-0x46d403` 用 `lea ecx,[ebp*8]; sub ecx,ebp` 得到 `7 * original_damage`，火球/火豌豆在 `0x46d405-0x46d40b` 改回 `original_damage`。
- 修正：非火球上限改为 `aOriginalDamage * 7`。
- 修改文件：`Lawn/Projectile.cpp`

## 8. `Plant::UpdateSpikeweed` 地刺王伤害帧

- 原错误：地刺王两段伤害帧写成 `69` 和 `33`。
- 二进制依据：`Plant::UpdateSpikeweed` `0x460370` 中 `0x4603b3` 比较 `0x46`，`0x4603b8` 比较 `0x20`，即倒计时 `70` 和 `32`。
- 修正：地刺王伤害帧改为 `70` 和 `32`。
- 修改文件：`Lawn/Plant.cpp`

## 附：已复核但无需修改的行为

- `Plant::Squish` `0x462b80`：源码中樱桃、辣椒、醒着的毁灭菇/寒冰菇、已就绪土豆雷走 `DoSpecial()`，睡眠植物和普通植物进入压扁状态；与二进制一致。
- `Zombie::SquishAllInSquare` `0x52e920`：源码中车辆碾压同格时只额外排除地刺/地刺王，然后调用 `Plant::Squish()`；与二进制一致。
