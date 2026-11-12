# Phase 2 审查记录：LaunchServices 快速目录

日期：2026-11-11
范围：`ContainerCatalogBuilder` / `ContainerCatalogCache`、`ContainerStore` 找库与目录接口、`AppDataBrowserView`、`CleanerView`。

| 门禁 | 结果 | 证据 / 说明 |
|---|---|---|
| G1 构建 | PASS | `xcodebuild -scheme 3106 -configuration Release -sdk iphoneos CODE_SIGNING_ALLOWED=NO` → BUILD SUCCEEDED |
| G2 测试 | PASS | `bash Tests/run_policy_tests.sh` → PASS: 75 policy checks（新增目录构建/去重/缓存签名测试） |
| G3 性能 | 待真机 | 热路径只读紧凑缓存；缓存读取不拿后台构建锁；首次运行目录发现与 API/MCM 并行，不再串行叠加 |
| G4 错误路径 | PASS | 数据库缺失/解析失败/缓存签名不符均回退到原 API/MCM/文件系统路径，并记录日志 |
| G5 备份/回滚 | 不受影响 | 本切片只读目录来源；写入仍走 `BackupCenter` / `VerifiedFileWriter` |
| G6 设备冒烟 | 未执行 | 需在 iOS 26.7.1 / 27.0.1 / 27.2.1 验证 App Data 与清理器 |
| G7 白屏/白苹果 | N/A | 不修改系统文件 |
| G8 代码审查 | PASS（有后续项） | 已审锁顺序、active candidate、避免重复找库；热路径不阻塞主线程 |
| G9 本地化 | N/A | 无新增用户文案 |
| G10 文档 | PASS | CHANGELOG / README 增加快速目录说明 |

## 后续项

1. 真机读日志：`browser: catalog cache load/built ... elapsed=...` 与 `browser: app data ready ... elapsed=...`，确认热启动首屏 ≤ 300ms、冷启动首屏 ≤ 1.5s。
2. 目录中可能残留已卸载应用的容器；后续在后台做一次轻量存在性过滤（不影响首屏）。
3. 图标/版本仍由 API/MCM 后台补全；后续增加磁盘图标缓存，避免每次冷启动重复取图标。
4. Internal Daemons / System Data 仍需按需扫描，下一步接 `ScanCoordinator` 与 `pathleak`。