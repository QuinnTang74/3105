# Phase 5 审查记录：设备定制、文件工具与利用层加固

日期：2026-11-11
范围：`MobileGestaltService/Editor`、`KeypadThemeService/View`、`SQLiteViewerView`、`HexViewerView`、`PlistEditorView`、`PatchTransaction`、`worse_query.m`。

| 门禁 | 结果 | 证据 / 说明 |
|---|---|---|
| G1 构建 | PASS | Release 无签名构建 → BUILD SUCCEEDED |
| G2 测试 | PASS | 策略测试 75 项；新增文件工具与 MG 服务未纳入 macOS harness（依赖 UIKit/系统路径） |
| G3 性能 | 待真机 | 编辑器按需打开；SQLite 复制数据库后查询；Hex 按页显示；MG/Keypad 只读加载 |
| G4 错误路径 | PASS | MG/Keypad/编辑器均有错误枚举与 UI 提示；SQLite 打开/查询失败可见 |
| G5 备份/回滚 | PASS（逻辑） | MG、Keypad、Plist、Hex 写前均走 `VerifiedFileWriter` / `BackupCenter`；MG/Keypad 提供恢复原始 |
| G6 设备冒烟 | 未执行 | 需真机验证 MG 写入/恢复、拨号键路径、SQLite dlopen、Plist 嵌套编辑 |
| G7 白屏/白苹果 | **未验证（高风险）** | MG 只开放安全子集，写入前备份、失败回滚、空 plist 拒绝；仍需真机分阶段验证 |
| G8 代码审查 | PASS（有后续项） | 已审授权顺序、备份先于写入、Plist 序列化校验、SQLite 只读连接 |
| G9 本地化 | PASS | `gestalt.*`、`keypad.*`、`sqlite.*`、`hex.*`、`plist.*` 三语齐全 |
| G10 文档 | PASS | CHANGELOG / README 更新 |

## 后续项

1. **真机优先**：MG 先在只读模式确认键结构，再单键写入 → 恢复；Keypad 先单键应用 → 恢复。
2. MG 键名需在 iOS 26.7.1 / 27.2.1 上复核；不同系统版本的 `CacheExtra` 可能缺键。
3. SQLite 使用 `dlopen` 运行库，需确认 App Store 签名/越权环境下可加载。
4. Plist 编辑器当前支持根字典、字典/数组导航、叶子编辑与增删；嵌套容器新增暂只创建空字符串。
5. Hex 编辑上限 64 MB；大文件只读浏览。
6. A–Z 侧栏、应用排序、崩溃日志清理、壁纸包数量上限仍未完成。