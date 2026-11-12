# 3.1.13 全面审查

日期：2026-11-11
范围：本轮 5 个功能提交 + 版本收口。基线：3.1.12（build 16）。

## 提交

| 提交 | 内容 |
|---|---|
| `1b7a687` | BackupCenter、VerifiedFileWriter、备份/恢复/事务回收 |
| `2ddad15` | LaunchServices 快速目录、持久化缓存、App Data/Cleaner 零扫描 |
| `c2b216b` | 功能主页、固定 5 项底栏、三语 |
| `1a4ba5a` | ScanCoordinator/Pathleak、App Group 提示、致谢、Respring |
| `58920d3` | MobileGestalt/拨号主题、SQLite/Hex/Plist、逐目标授权与 flags 学习 |
| `5401417` | 文件信息、左滑删除、崩溃日志清理、3.1.13 收口与 IPA |
| `2662cd7` | 拨号键恢复失败处理、Respring 兜底与最终校验和 |

## 验证证据

- Release 无签名构建：**BUILD SUCCEEDED**（3.1.13 build 17，最终构建日志 `/tmp/3106-build19.log`）。
- 策略/单元测试：`bash Tests/run_policy_tests.sh` → **PASS: 76 checks**。
- 本地化：491 个字面 key 在 en / zh-Hans / vi **全部存在**。
- 工程文件：`plutil -lint project.pbxproj` → OK。
- 产物：`dist/3106-3.1.13-unsigned.ipa`，4.2 MB，SHA-256 `00ea0503fc27c0a98d7d6c6e045c275143acc8b739ccb15c4932b4a52aaecd15`。

## 功能矩阵

| 能力 | 状态 |
|---|---|
| LS 数据库直出 + 磁盘缓存 | ✅ 已实现 |
| App Data / Cleaner 零扫描热路径 | ✅ 已实现（缓存命中） |
| 扫描进度/剩余/隐藏/停止/后台 | ✅ 已实现 |
| 扫描前“文件数 + 预计耗时”确认 | ⚠️ 未做；当前直接显示进度 sheet |
| pathleak 回退枚举 | ✅ 已实现 |
| pathleak 增量（startInode 持久化） | ❌ 未做 |
| App Group 启动阻断提示 | ✅ 已实现 |
| 致谢/许可页 | ✅ 已实现 |
| Respring | ✅ 已实现（真机未验证） |
| 文件信息 / 左滑删除 | ✅ 已实现 |
| 结构化 Plist 编辑 | ✅ 根字典 + 嵌套导航 + 叶子编辑/增删 |
| Plist 嵌套容器新增 | ⚠️ 目前只新增空字符串叶子 |
| Hex 查看/覆写 | ✅ 已实现（编辑上限 64 MB） |
| SQLite 只读查看 | ✅ 已实现（表/行/查询/CSV，`dlopen`） |
| MobileGestalt 安全子集 | ✅ 已实现（真机未验证） |
| 拨号键主题 | ✅ 已实现（真机未验证） |
| 补丁逐目标父目录授权 | ✅ 已实现 |
| worse_query 设备级 flags 学习 | ✅ 已实现 |
| 崩溃日志清理 | ✅ 已实现 |
| A–Z 侧栏 | ❌ 未做（SwiftUI 无原生 section index） |
| 应用列表按大小排序 | ❌ 未做（目录阶段无大小） |
| 整包应用备份/恢复 | ❌ 未做 |
| Supervision/Config tweak | ❌ 未移植（高风险，默认不做） |
| 壁纸包 15 个上限 | ❌ 未做（当前安装流程为单包） |

## 代码审查发现（按严重度）

1. **MobileGestalt 键名与写入风险（高）**：键名来自 Erosion，需在 iOS 26.7.1 / 27.2.1 真机逐键验证；只开放安全子集，写入前备份、空 plist 拒绝、回读校验、失败回滚已实现，但未真机验证。
2. **拨号键路径/regCode（中）**：依赖 `Library/Caches/TelephonyUI-*` 与文件名前缀；不同系统/地区可能不同，真机先单键应用 → 恢复。
3. **SQLite `dlopen`（中）**：运行期加载 `/usr/lib/libsqlite3.dylib`；若签名环境禁止，UI 显示错误，不影响其他功能。
4. **Plist 编辑器范围（中）**：根必须是字典；嵌套容器只支持导航与叶子编辑，新增容器项暂未实现类型选择。
5. **Hex 编辑上限（低）**：64 MB 以上只读；覆写前完整加载并走备份，内存峰值约 2 倍文件大小。
6. **扫描确认缺失（低）**：没有开始前的“预计耗时”确认；进度 sheet 可停止。
7. **目录缓存陈旧（低）**：LS 目录可能包含已卸载应用的容器；未做存在性过滤。
8. **iOS 26 差异（中）**：LS 库布局、System Data 可达性、图标可得性需真机验证。
9. **测试缺口（中）**：新增 UI/系统路径功能未进入 macOS harness；仅策略、目录构建、备份/恢复有单测。

## 真机验证清单（发布前必做）

1. iOS 26.7.1 / 27.0.1 / 27.2.1 各一次冷启动：功能页 ≤1s、文件页 ≤1.5s、热切页 ≤300ms。
2. 断网启动：功能页、文件页、清理器不依赖网络。
3. 备份中心：手动备份、删除前备份、补丁前备份、强杀后 journal 恢复。
4. MobileGestalt：只读 → 单键（如 Boot Chime）→ 恢复原始 → Respring；确认无白屏/白苹果。
5. 拨号主题：单键应用 → 电话应用切换外观 → 恢复原始。
6. 文件工具：SQLite 打开 10MB 库、Hex 覆写 1KB、Plist 嵌套编辑、文件信息、左滑删除。
7. 崩溃日志：统计、清理、失败计数。
8. App Group 缺失签名包：启动提示。
9. Respring：iOS 26/27 行为确认。

## 结论

本轮把“加载速度、主页形态、备份体系、扫描控制、文件工具、设备定制、利用层可靠性”全部落到代码并通过构建与 76 项策略/单元测试；**MobileGestalt、拨号主题、SQLite 运行时加载、Respring 仍未真机验证**，发布前必须按上面的清单过一遍。A–Z、应用大小排序、整包备份、Supervision 配置 tweak 明确留待后续。