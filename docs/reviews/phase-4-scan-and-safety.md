# Phase 4 审查记录：扫描控制、App Group 提示、致谢与 Respring

日期：2026-11-11
范围：`Pathleak`、`ScanCoordinator`、`ContainerStore` 枚举、App Data / Cleaner 回退扫描、Content View、Feature Hub、Settings。

| 门禁 | 结果 | 证据 / 说明 |
|---|---|---|
| G1 构建 | PASS | Release 无签名构建 → BUILD SUCCEEDED |
| G2 测试 | PASS | `bash Tests/run_policy_tests.sh` → 75 checks；`Pathleak` 已纳入编译 |
| G3 性能 | 待真机 | 扫描只在数据库不可用时启动；进度每 4096 inode 更新；后台任务续命 |
| G4 错误路径 | PASS | 取消后扫描返回空并关闭进度；数据库不可用仍走 API/MCM |
| G5 备份/回滚 | N/A | 本切片不写系统文件；Respring 不改数据 |
| G6 设备冒烟 | 未执行 | 需真机验证进度、隐藏/停止、后台续跑、Respring |
| G7 白屏/白苹果 | N/A（Respring 除外） | Respring 只重启 SpringBoard，不写系统文件 |
| G8 代码审查 | PASS（有后续项） | Token 线程安全；进度回调切主线程；扫描完成/取消都会 finish |
| G9 本地化 | PASS | `scan.*`、`appgroup.*`、`respring.*`、`ack.*` 三语齐全 |
| G10 文档 | PASS | CHANGELOG / README 更新 |

## 后续项

1. 首次扫描前的“确认弹窗 + 预计耗时”尚未加入；当前直接显示进度 sheet，可停止。
2. `pathleak` 的 `startInode` 增量尚未持久化；下一步记录 max inode，后续只扫新增区间。
3. 壁纸 descriptor 兜底扫描尚未接入 `ScanCoordinator`。
4. 真机验证 `Respring` 在 iOS 26.7.1 / 27.2.1 的行为。