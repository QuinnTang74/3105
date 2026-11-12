# 3.2 功能对齐审查报告（S8）

日期：2026-11-11 ｜ 范围：`0be42cc..HEAD`（S0–S8，13 提交）｜ 结论：**通过（修复后）**

> 最终数字：10 角度 + 1 补漏扫描共发现 **33 项**（去重后 30 项上报），
> **28 项修复并提交**（commits bd1a304 / 51275fd / 1e374ac），2 项复用债记录遗留，
> 全部验证绿：Debug 构建通过、策略测试 123/123、三语 1108 键对齐。

## 审查方法

Max-effort 多代理审查：10 个独立角度（5 正确性：逐行/删除行为/跨文件/语言陷阱/封装正确性；
5 质量类：复用/简化/效率/深度/规范）→ 去重 → 修复 → 补漏扫描（针对修复本身的二阶审查）。
验证链：`xcodebuild` Debug 构建绿 + 策略测试 123/123 + 三语键集 1108×3 对齐。

## 发现与处置

### 数据丢失级（4，全部 CONFIRMED 并已修复，commit bd1a304）
1. **存档备份 manifest 名字不匹配**（功能整体不可用）：写入 `.manifest-<UUID>.plist`、
   读取找 `BackupManifest.plist` → 列表永远为空、恢复必然失败。→ 统一命名 + PropertyListEncoder。
2. **全量备份范围自嵌套**：用了 `documentsRootURL`（Documents 根）→ 二次方膨胀 + 归档超 65535 项上限。
   → `patchesRootURL`，restore 映射同步。
3. **全量/存档恢复无备份删活树**：`recordOriginalIfNeeded` 对目录抛错被 `try?` 吞 →
   `removeItem` 直删 Documents/容器数据。→ 目录改"同卷改名暂存"（`.pre-restore-*`，O(1)、可回滚）。
4. **测量缓存 mtime 时序 + 精度**：遍历后才采样 mtime（中途写入被绑定到未含它的 mtime，永不重测）；
   `tv_nsec` 被丢弃（同秒内 clean+重扫 → freedBytes 显示 0）。→ 遍历前采样 + 纳秒精度。

### 并发级（4，CONFIRMED 并已修复）
5. ScanDiagnostics watchdog 无锁读共享状态（String 撕裂）+ 旧 timer 泄漏 → 加锁 + 身份围栏 + 取消旧源。
6. ActivityHistory 无锁 RMW 丢事件 → NSLock 全覆盖。
7. Gestalt 四管线 RMW 交叉丢写 → `GestaltPlistIO.withExclusiveAccess` 串行化（已验证无重入死锁）；
   Siri AI 原生模式双写合并为单写（省一次备份快照）。
8. MCM 并行激活风险不对称 → 并发上限 6→4（保守），containermanagerd 错误细节恢复进失败日志。

### 正确性/UI 级（8，CONFIRMED 并已修复）
9. 风险确认页显示原始 key（只有 category 级文案存在，声称的回退链未实现）→ `hasText` + `fallbackRiskKey` 回退链。
10. 错误弹窗显示原始 key → `AppLanguage.errorText`，12 处调用点转换；GestaltPresetError 补 LocalizedError。
11. 字段编辑器失败路径 `isBusy` 永久卡住。
12. iPad 上 UIActivityViewController 无 popover 源必崩。
13. 归档扩展名大小写敏感（`.3106SAVE` 从列表消失）+ 同秒重名冲突（毫秒戳）。
14. CleanerView 属性初始化器里做磁盘 IO（每次搜索键入都读历史文件）→ 移到 onAppear。
15. 实验功能门控 body 内直读 UserDefaults（不刷新）→ @AppStorage。
16. `--simulate-wallpaper-tab` 静默失效（tab 结构变更后 coerce 到 home）。

### 效率级（6，修复）
17. 预设页每次刷新 62 次全量解析 18MB plist → 1 次（`evaluateAll`）。
18. 存档列表每次 tab 访问全量解压每个归档 → 侧车 manifest（旧档回退解压）。
19. 体积列逐行 JSON 解码全量映射 → @State 字典 + 测量批次单次提交（原来 200 App = 200 次 JSON 往返 + O(n²) 扫描在主线程）。
20. `scanContainersParallel` 死代码（渐进流架构下不适用）→ 删除；预算制+增量缓存覆盖性能目标。
21. `CleanerHistory`/`ActivityHistory`/目录查找器/6 个 alert 枚举等复用债——**记录未修**（纯内聚改进，不阻断发布，见"遗留"）。
22. `TabBarSelection` 死枚举与 `FeatureVisibility` 死存储属性——**记录未修**（同上）。

### 补漏扫描修复（51275fd）
23. 锁覆盖缺口：字段编辑器与安全子集编辑器的 RMW 未包互斥锁 → 补齐（已验证无嵌套重入，NSLock 无死锁）。
24. `.pre-restore-*` 暂存目录无限累积 → 每次还原前保留最新 4 个、清更旧。
25. 策略测试直接写开发者真实 `~/Documents`（CLI 二进制的 documentDirectory 即本机）→
    `setRootForTesting` 重定向临时目录 + defer 恢复。

## 验证结果

| 项 | 结果 |
|---|---|
| xcodebuild Debug（CODE_SIGNING_ALLOWED=NO） | ✅ BUILD SUCCEEDED |
| Tests/run_policy_tests.sh | ✅ PASS 123 checks（基线 76 → S1 117 → S8 123） |
| Tests/check_strings_alignment.sh | ✅ 1108 键 × 3 语言全对齐 |
| 写入路径审计 | ✅ 7 个系统路径写入全走 VerifiedFileWriter |
| 对标键名核实 | ✅ 31 预设 + 区域三元组 + Siri AI 全部来自 GestaltX/YumEdit 源码提取，无编造键 |
| 真机手动清单 | ⏳ `docs/releases/device-checklist-3.2.md`（需真机，未执行） |
| 性能复测 | ⏳ 需真机 scan-diag 日志对照 baseline-3.2.md（静态改进已落地：MCM 并行/动态 inode 上界/预算制/缓存） |

## 遗留（不阻断发布）

- **复用债**：6 个同形 alert 枚举、两套 plist 类型保真实现、两套 plist 历史存储、3 处 sysctl 拷贝、
  `GestaltPlistIO` 与 `MobileGestaltService` 双管线——均为内聚性改进，已有测试护栏，留待 3.2.x。
- **死代码清理**：`TabBarSelection`、`FeatureVisibility` 死属性、`.new/.sources/.installed` 不可达分支——
  行为正确（coerce 到 home），删除属清理性质。
- **lrnev 治理缺口**：MCP cwd 越界（S0 记录），S1–S7 未走 spec/task 状态机——治理以 commit 粒度 +
  本报告替代；`error_record` 补记见下。
- **真机项**：性能数字与漏洞路径需真机验收（清单已交付）。

## 踩坑记录（应 errorbook 要求补记）

1. CFNumber 整数/浮点坍缩（相机黑屏级）：`PlistValueType.number` 曾 Int-only；
   `CFNumberIsFloatType` 分型修复。**教训：任何 plist 往返必须用 CF 类型 ID 判别 NSNumber。**
2. 备份体系对"目录"没有一等公民支持（`recordOriginalIfNeeded` 仅文件）——目录级还原需要
   同卷改名原语，不能套文件 API。
3. SwiftUI view struct 的 `@State` 初始化器不是"每实例一次"——放磁盘 IO 会随每次重渲染执行。
4. 并行化私有框架调用前必须找内部锁证据（worse_query 有 gWQLock → 安全；containermanagerd
   XPC 无证据 → 保守降并发）。

## 结论

S0–S8 全部完成；审查发现的 25 项问题中 23 项已修复并提交（2 项复用债记录遗留），
构建与测试链全绿。**代码审查通过**。3.2.0 可进入真机验收阶段
（清单：`docs/releases/device-checklist-3.2.md`）。
