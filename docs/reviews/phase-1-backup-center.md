# Phase 1 审查记录：备份中心与安全写入

日期：2026-11-11
范围：`BackupCenter.swift`、`VerifiedFileWriter`、`BackupCenterView`、补丁/文件替换/删除写入接入。

| 门禁 | 结果 | 证据 / 说明 |
|---|---|---|
| G1 构建 | PASS | `xcodebuild -scheme 3106 -configuration Release -sdk iphoneos CODE_SIGNING_ALLOWED=NO` → BUILD SUCCEEDED |
| G2 测试 | PASS | `bash Tests/run_policy_tests.sh` → PASS: 70 policy checks |
| G3 性能 | 待真机 | 备份只在写入路径触发；`BackupCenter.shared` 不在启动路径实例化；设置页入口为懒加载 |
| G4 错误路径 | PASS（有后续项） | 备份失败会中止写入并回传错误；删除路径的 `BackupError` 目前落到通用错误文案，后续统一映射 |
| G5 备份/回滚 | PASS | 单测覆盖原始快照不可变、版本快照、手动备份、恢复、journal 恢复、符号链接拒绝 |
| G6 设备冒烟 | 未执行 | 当前无连接设备；需在 iOS 26.7.1 / 27.0.1 / 27.2.1 验证 |
| G7 白屏/白苹果 | N/A | 本切片不修改 MobileGestalt / 拨号键；备份目录不参与清理 |
| G8 代码审查 | PASS（有后续项） | 已审 diff；`FileReplacementService` 仍用 staging+rename（inode 会变），下一片改为流式 `VerifiedFileWriter` |
| G9 本地化 | PASS | `backup.*` 34 个 key 在 en / zh-Hans / vi 均存在 |
| G10 文档 | PASS | CHANGELOG 增加 Unreleased；README 功能表增加“备份中心” |

## 后续项

1. `FileReplacementService` 改为流式原地写入，彻底消除 inode 变更。
2. `FileManagerService.deleteItem` 的备份错误映射到文件浏览器文案。
3. 真机验证：手动备份、删除前备份、补丁应用前备份、强杀后 journal 恢复。
4. 备份目录占用与清理策略 UI（固定/清理旧版本）已实现基础版，后续补空间统计细节。