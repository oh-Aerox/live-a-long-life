# 安卓端实施计划

本文是安卓端适配的实施依据和进度记录，用法同 plan-v0.1～v0.4：任务完成后在第 5 节勾选，验证证据记入 [platform-matrix.md](platform-matrix.md) 第 3 节与 `evidence/`。

依据：[requirements.md](requirements.md) R-21、R-33；[platform-matrix.md](platform-matrix.md) 第 2 节"安卓首轮验证范围"与小米 12 注意事项；[decisions.md](decisions.md) D-23（安卓 OCR 用 ML Kit）、D-30（内部标识发版前再改）。

## 0. 背景与范围

- iPhone 与 Mac 的 v0.1～v0.4 已在真机验收完成。安卓的目标是 R-21 的"验证可以适配"：**同一套 Dart 代码在安卓上跑通手机端的主要流程**，并在 platform-matrix 里如实记录哪些已验证、哪些待实现。安卓不另做功能，界面沿用 Material 样式（`useCupertino` 在安卓上已返回 false）。
- **验证设备（2026-09-29 首次连接记录）：** 小米 12（型号 2201123C），Android 15（API 35），HyperOS 3.0（OS3.0.3.0.VLCCNXM）。系统内置 Health Connect（`com.android.healthconnect.controller`），装有小米运动健康（`com.mi.health`）。
- **现状摸底：** 安卓工程是 Flutter 模板原样，没有任何权限声明与原生代码。手机端依赖的平台能力中，以下几项目前只有 iOS 实现：
  | 能力 | iOS 现状 | 安卓要做的 |
  |---|---|---|
  | 医疗文字提取 `life.long/medical_text` | PDFKit + Vision（Swift） | PdfRenderer 渲染 + PDF 文字层抽取 + ML Kit 中文识别（Kotlin） |
  | 局域网发现 `life.long/bonjour` | NetService（Swift） | NsdManager 查找（Kotlin）；手机只需 resolve，不广播 |
  | 健康数据 | health 插件 → HealthKit | 同一插件 → Health Connect；类型映射不同（安卓没有 SLEEP_IN_BED，用 SLEEP_SESSION） |
  | 定时提醒 | 本地通知，系统保证重启后仍在 | 需声明开机广播接收器；准时提醒要"闹钟和提醒"权限；小米要自启动与省电白名单 |
  | 导出位置 | 文件 App 可见的 Documents | 应用私有目录用户看不到，改到外部应用目录并如实写明路径 |
  | 覆盖安装 | `scripts/resign-install.sh`（devicectl 原地覆盖） | `adb install -r` 保留数据（`flutter install` 会先卸载清数据，同 iOS 的坑） |
- **Mac 测试数据隔离：** Mac 把手机同步来的数据合进同一份只读副本。安卓是验证机，测试数据不能混进日常在用的 Mac 副本（周报会把测试消息当真）。Mac 增加开发用的"数据档案"开关（`--dart-define=LLAL_PROFILE=android-test` 时数据库、附件、日志放到独立子目录，设备 ID 也随之独立），安卓配对只配到测试档案的 Mac 上。日常用的 Mac 数据不受影响。
- **2026-09-30 联调发现（导出恢复）：** 小米上用 iPhone 的导出恢复后看不到任何数据；iPhone 上复现恢复后病例夹与体检列表为空。原因三条：①导出只带 v0.2 写定的表，v0.4 的医疗文件、分析结果、咨询记录都没带（检验索引也没重建）；②文件管理解压出的文件本应用无权读取（分区存储），Mac 压缩的 zip 不带 UTF-8 标记、目录名乱码；③恢复在读出导出之前就关了数据库，失败后界面空白。修复：导出格式 v3 补表、每张表必须登记导出与否（单测把关）、启动时重建检验索引、安卓可选 zip 由应用自己解压、先读 manifest 再关库。iPhone 用"08:42 导出 + Mac 副本里的医疗文件"合成的找回导出恢复，逐项核对一致；咨询记录只存手机本机，已无法找回。**遗留：** 恢复后手机换了数据代次，Mac 拒收（schema §7.3 完整重建未实现），iPhone 暂时无法同步到 Mac。
- **本期不做：** P-02 通知内回复（安卓本期不做，矩阵已定）；P-52 签名到期提醒（安卓调试安装无到期问题）；Play 商店上架、正式签名；内部标识改名（D-30，发版前统一改）。

## 1. 目标与完成标准

1. **首轮（platform-matrix 第 2 节）：** P-01、P-03、P-04、P-06、P-30～P-33 在小米 12 真机通过，外加 P-51 覆盖安装数据保留。
2. **扩展：** 手机端其余功能在安卓上能用并留下验证记录：模型配置与整理（P-20～P-23）、导出与恢复（P-08）、医疗导入与提取（A-19 安卓场景）、手机空间清理与取回（P-09、P-53）、Health Connect（P-10～P-14，按矩阵要求：确实不可用则记"受阻"并写降级方案）、周报查看（P-41）。
3. 全套单测保持通过；iOS 与 macOS 构建不受影响。

## 2. 技术要点与候选

| 事项 | 方案 | 备注 |
|---|---|---|
| 最低系统版本 | minSdk 26 | health 插件要求；小米 12 出厂即 Android 12，不影响 |
| 通知插件 | coreLibraryDesugaring；声明 ScheduledNotificationReceiver、ScheduledNotificationBootReceiver、RECEIVE_BOOT_COMPLETED、POST_NOTIFICATIONS、SCHEDULE_EXACT_ALARM | 有"闹钟和提醒"权限时用 exactAllowWhileIdle，没有时退回 inexact 并在设置里引导开启 |
| 主 Activity | 改为 FlutterFragmentActivity | health 插件用 registerForActivityResult 申请 Health Connect 权限 |
| OCR | ML Kit `text-recognition-chinese`（**bundled 版**，模型打进 APK） | 国行系统没有 Google 服务，不能用依赖 Play 服务下载模型的 unbundled 版；输出行文字 + 包围框，换算成与 Vision 相同的左上原点归一化坐标 |
| PDF 渲染 | 系统 `android.graphics.pdf.PdfRenderer` | 页数与渲染成 PNG；长边约 2200px，与 iOS 一致 |
| PDF 文字层 | `pdfbox-android`（PDFTextStripper 按页取文本） | 系统 PdfRenderer 的取文字接口要 SDK 扩展 13，不可靠；抽取失败按"没有文字层"处理，退回渲染 + OCR |
| 局域网发现 | NsdManager discover + resolve，读 TXT 里的 `ips` 与解析地址 | 与 iOS 返回格式一致（逗号分隔 host:port），Dart 端排序逻辑复用；超时同 5 秒 |
| 小米后台限制 | 设置页加"后台与提醒"说明页：打开应用详情页（自启动、省电策略"无限制"）、"闹钟和提醒"权限页 | 通过 `life.long/android_settings` channel 打开对应系统页面 |
| 覆盖安装 | `scripts/android-install.sh`：`flutter build apk` + `adb install -r` | 保留数据；A-07 同法验证 |

## 3. 里程碑

- **AN-M0 工程配置与首次构建：** Gradle（minSdk、desugaring）、AndroidManifest 权限与接收器、FlutterFragmentActivity、Health Connect 的 queries 与权限说明入口；`flutter build apk` 通过、真机能启动到首次引导。覆盖安装脚本。
- **AN-M1 Dart 侧平台差异：** 局域网发现在安卓上启用；配对时上报的设备名按平台（不再写死 iPhone）；导出目录与提示文字按平台；HealthKit 试验页只在 iOS 显示；界面里"苹果健康"等 iOS 措辞在安卓上改为平台中立或 Health Connect；Mac 端提示文字去掉"苹果健康"。
- **AN-M2 提醒：** 精确提醒权限检测与退回、开机后重排、小米自启动/省电引导（设置页"后台与提醒"）。
- **AN-M3 局域网发现（Kotlin NsdManager）：** 与 iOS 的 BonjourChannel 同一协议；手机按 Mac 设备 ID 找回新地址。
- **AN-M4 医疗文字提取（Kotlin）：** PdfRenderer + pdfbox-android + ML Kit，四个方法与 iOS 同名同参同返回；坐标约定一致，定位高亮（A-19）直接复用。
- **AN-M5 Health Connect：** 安卓类型映射（SLEEP_SESSION → 在床、各睡眠阶段、步数、体能训练、活动能量）；可用性检测与"未安装/不可用"措辞；读取数据的 30 天历史限制在界面上如实说明。
- **AN-M6 Mac 测试档案：** Mac 端 `LLAL_PROFILE` 数据目录隔离。
- **AN-M7 真机验证：** 先首轮（P-01、P-03、P-04、P-06、P-30～P-33、P-51），再扩展项；证据写入 `evidence/` 与 platform-matrix。需要用户配合的步骤（锁屏等通知、重启手机、扫码配对、导入真实检查单）在执行时逐条说明。

## 4. 风险与注意

- **需要用户在手机上操作的环节：** 首次安装要在手机上允许 USB 安装；通知、相机、Health Connect、闹钟和提醒、自启动都要人手点允许。这些由用户按提示完成，结果如实记录，不替用户假定"已开启"。
- **小米后台清理：** 即使开了精确提醒，被系统杀掉后提醒也可能不响。P-01 的通过标准是"按引导设置后收到提醒，重启手机后仍收到"；只在默认设置下不响的情况单独记录，不算通过也不隐瞒。
- **ML Kit 质量与体积：** bundled 中文模型让 APK 增大约 20MB+；识别质量与 Vision 不同，脱敏第一层依赖坐标，需用真实样本复核遮蔽效果（A-19 安卓场景）。质量不够时仍有 V4-M3 模型识图兜底。
- **Health Connect 口径：** 小米运动健康写入 Health Connect 的数据种类取决于用户是否在该应用里开启同步；读不到时要区分"未授权 / 没有数据源 / 确实没有数据"，措辞沿用 D-11"暂未读取到"。
- **不改 iOS / Mac 行为：** 所有改动按平台分支；每个里程碑后跑全套单测，并构建 iOS 与 macOS。

## 5. 任务清单

| 状态 | 任务 | 备注 |
|---|---|---|
| [x] | AN-M0 工程配置与首次构建 | 2026-09-29 代码完成：minSdk 26、desugaring、FlutterFragmentActivity；manifest 声明网络/组播、通知/开机/精确提醒、相机、Health Connect 只读权限与权限说明入口、通知接收器；release 混淆规则（pdfbox 可选的 JPEG2000 依赖、反射加载的类）。`scripts/android-install.sh`（release arm64 + `adb install -r`）。debug/release APK 构建通过（release 81MB），iOS、macOS 构建不受影响，全套 203 个单测通过。**2026-09-30 真机：** 覆盖安装成功、首次启动进入引导（时区自动识别 Asia/Shanghai），无崩溃。坑：HyperOS 除了开发者选项里的"USB 安装"，每次安装还弹确认框（有倒计时），不点就报 INSTALL_FAILED_USER_RESTRICTED |
| [x] | AN-M1 Dart 侧平台差异 | 2026-09-29：局域网发现在安卓启用；配对上报"安卓手机"；导出放公共"下载/长命百岁/exports"（建不了时退回外部应用目录），导出完成与清理提示按平台写位置（`ExportLocation`）；HealthKit 试验页只在 iOS 显示；Mac 设置页"苹果健康"改"健康数据" |
| [ ] | AN-M2 提醒 | 2026-09-29 代码完成：有"闹钟和提醒"权限时 exactAllowWhileIdle，没有时退回 inexact；设置页"后台与提醒"（仅安卓）列通知、闹钟和提醒、省电策略状态，打开小米自启动管理/应用详情，回到页面刷新并重排提醒。待真机 P-01 |
| [ ] | AN-M3 局域网发现 | 2026-09-29 代码完成：Kotlin NsdManager，读 TXT `ips` + 解析地址（仅 IPv4），返回格式与 iOS 一致。待真机 P-30 |
| [ ] | AN-M4 医疗文字提取 | 2026-09-29 代码完成：PdfRenderer（铺白底、长边 2200px）、pdfbox-android 文字层、ML Kit bundled 中文识别（照片按 EXIF 转正、长边 4000 以内解码，坐标归一化左上原点）。待真机样本 |
| [ ] | AN-M5 Health Connect | 2026-09-29 代码完成：安卓类型表（SLEEP_SESSION 按在床、各阶段、训练、步数、活动能量），另申请距离与总能量供训练摘要；Health Connect 不可用时按未授权处理。待真机 P-10～P-14 |
| [x] | AN-M6 Mac 测试档案 | 2026-09-29：`--dart-define=LLAL_PROFILE=<名>` 时数据库/附件/日志放 `Application Support/profiles/<名>`、备份放 `~/Documents/长命百岁备份-<名>`，窗口右上角显示档案名角标；不传时行为不变 |
| [ ] | AN-M7 真机验证 | |
