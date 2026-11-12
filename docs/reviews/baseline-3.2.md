# 3.2 对齐开发基线（S0）

日期：2026-11-11 ｜ 分支：3106 ｜ 起点 commit：0be42cc（3.1.13 stable）

## 测试基线
- `Tests/run_policy_tests.sh`：PASS 76 policy checks（全绿）

## 性能基线
性能数字需真机采集（扫描/测量依赖 containermanagerd XPC 与沙盒扩展，模拟器不可复现）。
本基线先记录**架构级瓶颈点**，S3 优化后用 `scan-diag-latest.log` 在真机上量化对比：

| 瓶颈 | 位置 | 现状 | S3 目标 |
|---|---|---|---|
| MCM 逐 bundleID 串行激活 | `ContainerStore.installedAppsFromMCM` / `installedAppsFromMHACandidates` | 每容器一次 XPC 往返，串行 | concurrentPerform 并发 6 |
| 容器体积串行全量遍历 | `LimitedCleanerService.measure()` | 每容器 FileManager.enumerator 全量 | 预算制 12000 项/0.25s + deferred + 增量缓存 |
| lsd 容器目录串行探测 | `LaunchServicesStore.launchServicesStoreCandidates` | 多守护进程容器目录逐个 inspectDirectory | 并行探测 |
| pathleak 全区间爆破 | `Pathleak.list()` | inode 1..2,000,000 固定区间 | stat() 动态最大 inode 基线收窄 |
| 图标逐行 onAppear | `BrowserAppIcon` | 慢滚动闪烁 | 批量异步+通知刷新 |

## 对标差距清单
见计划文件（已批准）：清理安全纵深/预算制/增量缓存/UI、APP 序卡片、MCM 并行、Gestalt 全量预设+字段编辑器+区域+Siri AI、Supervised、存档备份、备份一级 tab（自动/手动/全量/点击恢复+History）、风险说明体系。

## lrnev 状态
MCP 服务端 cwd 不在项目根（`project_status` 报路径越界），治理以 git commit 粒度 + 本目录文档替代；每阶段一 commit，commit message 前缀 S0–S9。
