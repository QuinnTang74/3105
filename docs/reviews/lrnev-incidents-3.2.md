# lrnev 补记（errorbook / governance 缺口）

> 状态：lrnev MCP 服务端 cwd 与会话工作目录不一致（`project_status` /
> `error_record` 均报「路径越界：.lrnev/...」），S0 复现、S9 确认。
> 以下 4 条踩坑按 `error_record` 的字段规范落盘于此；MCP 配置修复后
> 可用本文内容回填 errorbook。

## Incident 1 — CFNumber 整数/浮点坍缩（相机黑屏级）

- **symptom**：结构化 Plist 编辑器把 `<real>` 值（相机变焦 1.0/2.0/5.0）写回为
  `<integer>`，编辑保存后系统相机取景黑屏（Erosion 上游真实事故，本项目
  S6 审计发现同型缺陷）。
- **root_cause**：`PlistValueType.number` 保存路径是 `Int(text)` 单一分支；
  NSNumber 的 Boolean/Integer/Real 三态未用 CoreFoundation 类型 ID 判别。
- **fix_action**：number 拆分 integer/real 两态，检测用
  `CFGetTypeID(number) == CFBooleanGetTypeID()` +
  `CFNumberIsFloatType(unsafeBitCast(number, to: CFNumber.self))`；
  新代码统一走 `GestaltValueKind`（8 类型，含 XML 片段嵌套）。
- **verification**：commit ca2d9f0（S6）；真机清单 D 节含 Real 往返用例。
- **tags**：plist, type-fidelity, camera, corefoundation

## Incident 2 — 备份体系对目录无一等公民支持

- **symptom**：全量/存档还原调用 `recordOriginalIfNeeded` 对目录抛
  `targetNotRegularFile`，被 `try?` 静默吞掉，随后 `removeItem` 无备份地
  删除整个活树（审查 CONFIRMED 数据丢失级）。
- **root_cause**：BackupCenter 的快照原语以 `regularFileIdentity` 开头，
  目录从未被建模。
- **fix_action**：目录级还原改"同卷改名暂存"原语（`.pre-restore-*`，
  O(1) 改名、可回滚），每次还原前保留最新 4 个、清更旧。
- **verification**：commit bd1a304 + 51275fd；`pruneRestoreAsides`。
- **tags**：backup, restore, directory, data-loss

## Incident 3 — SwiftUI @State 初始化器做磁盘 IO

- **symptom**：`@State private var cleanerHistory = CleanerHistory.loadEntries()`
  在**每次 view struct init**（包括搜索框每次键入触发的重渲染）都读一次
  plist，清理页输入明显卡顿。
- **root_cause**：把"每实例一次"误解为"每视图生命周期一次"。
- **fix_action**：IO 移到 `onAppear`（`hasLoaded` 门控）。
- **verification**：commit bd1a304。
- **tags**：swiftui, state, io, performance

## Incident 4 — 并行化私有框架调用前必须找内部锁证据

- **symptom**：S3 把 `MCMActivateContainerPath`（containermanagerd XPC）与
  `worse_query_grant` 都并发化了；审查质疑线程安全。
- **root_cause / 判别法**：worse_query.m 内有 `gWQLock`（NSRecursiveLock）
  → 并发安全证据成立，保留并行；containermanagerd 私有框架无任何锁证据
  → 风险不对称（收益几秒 vs 列表静默缺行），并发上限 6→4 保守化并保留
  LS snapshot 回落。
- **fix_action**：`activateContainersParallel` cap=4 + 错误细节随元组返回。
- **verification**：commit 51275fd。
- **tags**：concurrency, private-framework, sandbox-escape, mcm

## 治理缺口声明

S1–S7 未走 spec/task/gate 状态机（原因：本 incident 的 MCP cwd 问题）。
等价审计链：11 个 S 前缀 commit + `docs/reviews/baseline-3.2.md` +
`docs/reviews/parity-review-3.2.md` + 本文件。MCP 配置修复后建议补建
3.2.0 的 spec 骨架（验收标准已内嵌于 parity-review 的发现/处置表）。
