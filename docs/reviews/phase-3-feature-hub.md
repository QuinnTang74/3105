# Phase 3 审查记录：功能主页与固定底栏

日期：2026-11-11
范围：`FeatureHubView`、`ContentView`、`AppTabNavigationState`、`SettingsView`、三语本地化。

| 门禁 | 结果 | 证据 / 说明 |
|---|---|---|
| G1 构建 | PASS | `xcodebuild -scheme 3106 -configuration Release -sdk iphoneos CODE_SIGNING_ALLOWED=NO` → BUILD SUCCEEDED |
| G2 测试 | PASS | `bash Tests/run_policy_tests.sh` → PASS: 75 policy checks |
| G3 性能 | PASS（本地页） | 功能页只读本地状态，不发起网络请求；不加载仓库 feed |
| G4 错误路径 | PASS | App Group 缺失时在状态区显示橙色警告与签名说明 |
| G5 备份/回滚 | N/A | 本切片不涉及写入 |
| G6 设备冒烟 | 未执行 | 需真机确认 5 个 tab、功能页导航与返回行为 |
| G7 白屏/白苹果 | N/A | 不改系统文件 |
| G8 代码审查 | PASS（有后续项） | `visibleSections` 固定；旧 tab 选择由 `reconcileSelection` 回落到功能页；设置页移除无效开关 |
| G9 本地化 | PASS | 主页/卡片/状态共 30 个 key，在 en / zh-Hans / vi 均存在 |
| G10 文档 | PASS | CHANGELOG / README 更新 |

## 后续项

1. 真机确认：底部只有 功能 / 文件 / 搜索 / 清理 / 壁纸；从功能页跳转后返回仍落在功能页。
2. 旧版本存储的 tab 选择（new/sources/installed）升级后应自动回落到功能页。
3. MobileGestalt 编辑器、拨号键主题实现后，在“设备定制”区补卡片。
4. 功能页卡片状态摘要（补丁数、备份时间）可在后续迭代补充。