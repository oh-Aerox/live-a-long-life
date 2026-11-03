# 开发说明

面向参与开发的贡献者：工程怎么组织、遵守哪些约定、用了哪些依赖、各平台有哪些技术要点和已知的坑。构建与运行步骤见根目录 [README.md](../README.md#构建与运行)，数据结构见 [schema.md](schema.md)，设计决策见 [decisions.md](decisions.md)，安卓端的实施要点见 [plan-android.md](plan-android.md)。

## 1. 工程结构

- Flutter 工程在 `app/` 子目录（项目根目录名含空格，不适合直接做工程目录），工程名 `live_a_long_life`。iPhone、安卓、Mac、Windows 共用一套 Dart 代码。
- `app/lib/data/`：drift 表定义（`db/tables.dart`）、数据库与迁移（`db/app_database.dart`）、各实体仓库（`repositories/`）、TimeValue / field_meta / 变更日志等数据层模型。
- `app/lib/services/`：整理、回顾、健康数据、模型客户端、医疗提取（文字识别、页筛选、脱敏、结构化）、导出恢复、备份（电脑端 `backup_service.dart`，手机 iCloud `cloud_vault.dart` / `cloud_backup_service.dart`）、分析、咨询；同步相关在 `services/sync/`。
- `app/lib/ui/`：页面。手机与电脑共用的页面用 `readOnly` 开关区分（见 §2 写入者分工）。
- `app/lib/main.dart` 按平台分流：Mac / Windows 走电脑端入口（只读副本 + 同步接收），不初始化手机专属插件（health、image_picker、本地通知、扫码等）；新增手机专属插件时同样不要在电脑端入口里初始化。
- `app/lib/app_services.dart`：应用级服务的组装处（数据库、仓库、各服务）。
- `app/ios/`、`app/macos/`：Apple 平台工程，原生 channel（文字识别、Bonjour、菜单栏）在 `Runner/AppDelegate.swift` 与 `Runner/MainFlutterWindow.swift`。
- `app/android/`、`app/windows/`：安卓与 Windows 工程，原生 channel 分别在 `android/app/src/main/kotlin/...` 与 `windows/runner/`。
- `app/test/`：单元测试与组件测试，按 `data/`、`services/`、`ui/` 分目录。
- `scripts/`：iPhone 一键重签安装、安卓覆盖安装、Windows 打包、人体图抠图脚本。

## 2. 工程约定

**数据结构与迁移**
- 改数据结构先改 [schema.md](schema.md)，再改代码。
- drift 迁移从 schemaVersion 1 开始编号，只追加新迁移，不改旧迁移。迁移必须可重跑：`createTable` 按当前表定义建表（可能已含后续版本才加的列），drift 迁移又不在事务里、中途失败会留下已执行的步骤，所以加列一律走 `_addColumnIfMissing`，否则会卡在 duplicate column。
- 修改表定义后重新生成代码：`dart run build_runner build --force-jit --delete-conflicting-outputs`（`--force-jit` 的原因见 §5）。
- **数据库里不存沙盒绝对路径。** iOS 覆盖安装会更换应用容器路径，附件的 `local_path` 只存文件名，运行时再拼当前目录（见 `AttachmentRepository`）。今后任何落库的文件引用都只存相对名。
- 数据库和附件放在 Application Support 下（附件在 `files/`，按 SHA-256 命名），覆盖安装后保留，不出现在用户可见的文档目录里。导出放在用户可见的位置，按平台不同（见 `export_location.dart`）。

**写入与同步**
- 手机是唯一编辑者（D-12）。Mac 端只写副本表、分析结果和备份记录；复用手机页面时打开 `readOnly`，隐藏一切写操作。
- 手机上同步范围内的每条写路径，都要在同一事务里追加变更日志（`lib/data/change_log.dart`，schema §7.2）。**漏埋的写路径等于永远同步不到**，新写路径的代码评审必查。新增需要同步的表时，同时更新 Mac 端回灌白名单（`sync_server.dart`）、schema §7.4 同步范围和变更日志的存量回填表清单。
- 变更日志只捕获埋点之后的写入。任何"只记增量"的机制上线时，都要考虑存量数据的一次性回填（现有实现见 `ChangeLog` 的 backfill）。
- 派生数据（文字识别 sidecar 缓存、`lab_results` 检验项目索引）不算事实，可整表重算，不入变更日志、不同步、不备份。

**模型相关**
- 发给模型的提示词都是代码常量，统一登记在 [prompts.md](prompts.md)；改提示词必须同步更新该文档。
- 模型输出解析要容错但不编造：缺字段丢弃该条并记入错误，不猜默认值；解析整体失败时一条记录都不写；编造的来源、行号、目标记录一律拒绝。
- 模型提取的内容一律 `unreviewed`，用户确认或修改后才作为事实参与分析（D-04）。这是安全网，UI 上不能为省点击绕过。
- 每次模型调用（包括失败的）都写 `model_calls`，记录发送内容与发送范围（D-16）。
- 只配置本地模型且不可达时，不得退回云端；数据边界检查在发送前做。

**运行日志**
- 用 `AppLog`（`lib/services/app_log.dart`）：调试构建从 debug 级起、发布构建从 info 级起；同时写控制台、Application Support/logs/app.log（1MB 滚动）和内存缓冲（应用内"查看日志"页）。
- 调用方负责不把 API key、Authorization 头等机密传进日志。

**测试**
- 平台插件都包在可替换的接口后（如 `HealthPort`），单测用假实现。
- 同步、配对、取回原件用回环网络端到端测试；模型客户端用本地假 HTTP 服务器测试。
- 提交前 `flutter analyze` 零问题、`flutter test` 全绿。

**平台验证**
- [platform-matrix.md](platform-matrix.md) 的状态只凭实际验证结果更新。
- 改动启动流程、原生代码或签名配置后，要用**不挂调试器**的方式启动验证（主屏幕点开，或 `xcrun devicectl device process launch`），原因见 §5 的 UIScene。

## 3. 主要依赖

以 `app/pubspec.yaml` 为准。

| 包 | 用途 | 说明 |
|---|---|---|
| drift、drift_flutter（dev：drift_dev、build_runner） | SQLite 数据库与迁移 | 类型安全、自带迁移，数据层跨平台复用 |
| path_provider、path | 应用目录与路径拼接 | |
| uuid | 实体 ID | 客户端生成，配合 `client_msg_id` 做幂等写入（D-10） |
| crypto | SHA-256 | 附件流式计算哈希，大文件不整块读入内存；密钥指纹 |
| cryptography | AES-256-GCM、PBKDF2 | 同步通道加密、Mac 端加密备份 |
| image_picker | 拍照、相册多选 | |
| file_picker | 导入 PDF 等文件 | |
| open_filex | 用系统预览打开附件 | 附件按哈希命名、没有后缀，系统认不出类型；先复制一份带原文件名和后缀的临时副本再交给系统 |
| flutter_local_notifications、timezone、flutter_timezone | 每日回顾提醒 | 启动时按设置重排提醒 |
| health | iOS 读 HealthKit，安卓读 Health Connect | 限制见 §4.1 |
| flutter_secure_storage | API key、同步密钥、备份密钥 | 数据库、导出、备份里只存引用名；macOS 配置见 §4.2 |
| qr_flutter | 电脑端显示配对二维码 | |
| mobile_scanner | 手机扫码配对 | |
| package_info_plus | 设置页显示版本 | |
| archive | 从 zip 恢复导出 | 安卓上可以直接选别的设备导出后压缩成的 zip |

以下能力**刻意没有引第三方包**，自己实现：

- **模型客户端**（`model_client.dart`）：只用 `dart:io`，支持两种协议——`openai_compatible`（OpenAI、DeepSeek、Kimi、智谱 GLM、Ollama、自定义兼容服务）与 `anthropic`，含多模态图片输入。不引 LLM SDK，避免依赖漂移。
- **文字识别与 PDF**：原生 channel，Apple 平台用 PDFKit + Vision，安卓用 ML Kit。
- **局域网发现**：原生 channel（Apple 平台 NetService、安卓 NsdManager、Windows DNS-SD）。
- **菜单栏 / 系统托盘**：原生 channel。
- **指标趋势图**：自绘折线图（参考范围色带、未核对空心点）。
- **Markdown 显示**：自写 `MarkdownText`，周报与咨询共用。
- **识图前裁剪**：应用内框选页 `MedicalCropPage`，裁剪图只在内存生成，不落库。

## 4. 平台技术要点

### 4.1 iPhone

- **部署目标 iOS 15.0**：Xcode 27 不再接受模板默认的 13.0（`ios/Podfile` 与工程设置一致）。
- **UIScene 生命周期**：Info.plist 声明 `UIApplicationSceneManifest`（`FlutterSceneDelegate`），插件注册放在 `AppDelegate.didInitializeImplicitFlutterEngine`。不要回退成旧的 AppDelegate 生命周期（原因见 §5）。
- **权限文案**：相册、相机、HealthKit 读取、本地网络都在 Info.plist 写明用途；`NSBonjourServices` 声明 `_llal-sync._tcp`。
- **本地网络明文 HTTP**：ATS 只放开 `NSAllowsLocalNetworking`（局域网里的 Ollama 等自建服务），公网仍要求 HTTPS。
- **HealthKit**：`Runner.entitlements` 开 HealthKit capability，只读不写（D-11）。health 插件不支持 `HKAnchoredObjectQuery`，拿不到锚点和"已删除样本"，所以：
  - 增量同步按时间窗重读（上次同步往前多读 2 天），按样本 UUID 幂等去重；
  - 苹果健康里删除的样本暂时无法同步删除，缺席也不判定为删除；`health_anchors` 表为将来的原生实现保留；
  - 活动能量没有统计查询，按来源优先级（Watch > iPhone > 其他）取单一来源求和；
  - 睡眠合并是纯函数（`sleep_merge.dart`），按 D-11 规则，便于单测。
- **签名到期读取**：设置页从 `embedded.mobileprovision` 读到期日，到期前在应用内提醒（D-19）。

### 4.2 Mac

- **部署目标 macOS 12.0**：Xcode 27 要求。`macos/Podfile` 的 `post_install` 把低于 12.0 的 Pod 统一抬高。
- **关闭 App Sandbox**：本机自用、不上架，需要局域网收发（同步服务）和直接写 `~/Documents`（备份）。entitlements 里关沙盒并开 `network.server` / `network.client`。
- **钥匙串**：数据保护钥匙串需要 keychain-access-groups entitlement，免费 / 本机签名下报 `-34018`。`KeyStore` 在 macOS 上用传统钥匙串（`usesDataProtectionKeychain: false`）。
- **Bonjour 广播**：Info.plist 必须同时声明 `NSLocalNetworkUsageDescription` 和 `NSBonjourServices`，否则不会真正广播。
- **菜单栏常驻**：关窗只隐藏，同步服务照常运行（`MainFlutterWindow.swift` 的 MenuBarChannel）。

### 4.3 原生 channel

| channel | 作用 | 实现位置 |
|---|---|---|
| `life.long/medical_text` | PDF 文字层探测与逐页抽取、扫描页渲染、OCR（文字 + 坐标，坐标转为左上原点） | iOS / macOS 同构实现（PDFKit + Vision，zh-Hans / en）；安卓 `MedicalTextChannel.kt`（ML Kit） |
| `life.long/bonjour` | 电脑广播同步服务、手机按设备 ID 找回地址 | iOS / macOS `BonjourChannel`（NetService）；安卓 `BonjourChannel.kt`；Windows `bonjour_channel.cpp`（只广播） |
| `life.long/menu_bar` | Mac 菜单栏 / Windows 托盘的同步状态 | `MainFlutterWindow.swift`；`windows/runner/tray_channel.cpp` |
| `life.long/android_settings` | 安卓后台与提醒设置入口 | `AndroidSettingsChannel.kt` |
| `life.long/cloud_folder` | iCloud 备份：选文件夹并保存书签、凭书签访问、经 NSFileCoordinator 下载 / 写入 / 改名 / 删除、查询是否已上传、切后台时申请后台时间（D-51） | iOS `AppDelegate.swift` 的 CloudFolderChannel |

Dart 侧调用原生 channel 时，要处理 `MissingPluginException`（测试环境和不支持的平台没有原生侧）。

### 4.4 同步通道

- 传输：本机 HTTP（`dart:io`）+ 应用层 AES-256-GCM，不用自签 TLS（Dart 侧生成、固定 X.509 证书链复杂度高，安全收益没有差别）。
- 配对：二维码只出现在用户自己的电脑屏幕上，作为带外安全信道直接携带 32 字节对称密钥。之后所有消息 AES-GCM 加密，AAD 绑定发送方设备 ID 与时间戳；时间戳窗口 ±5 分钟加 nonce 缓存挡重放。`peers.cert_fingerprint` 存密钥的 SHA-256 指纹，密钥本体在系统安全存储。详见 D-13。
- 电脑端同步服务从固定端口 47856 起，被占用则顺延。
- 推送：按 `change_seq` 逐条发送、逐条确认，连续游标推进，断点续传；附件先报哈希，对方缺才传，校验后确认（schema §7.2–§7.4）。电脑端回灌只接受白名单内的表，回灌不产生本机变更日志。
- 局域网发现：电脑广播服务名 `llal-<设备 ID>`、类型 `_llal-sync._tcp`。电脑每块网卡各广播一份，手机可能只解析到数据线那条链路，所以 TXT 记录里写上电脑的局域网地址；手机端候选地址里局域网地址优先，`169.254` 链路本地放最后，试连通过才更新记录。广播名被冒用也连不上，连接仍要过配对密钥。

### 4.5 备份

- 备份密码经 PBKDF2-HMAC-SHA256（20 万次）派生密钥，存系统安全存储；数据快照与附件逐个 AES-256-GCM 加密。
- 生成时先写临时目录，逐项解密校验通过才转正式名并标为可用；缺原件列入缺件清单，不当作业务删除。详见 D-15、schema §7.5。
- 加密函数在 `backup_crypto.dart`，电脑端备份和手机 iCloud 备份共用。
- **手机 iCloud 备份不用 iCloud 能力**：免费签名开不了 iCloud 容器，改用系统文件选择器选 iCloud 云盘文件夹 + 书签（D-51），Info.plist 和 entitlements 都不用改。iCloud 里没下载的文件可能显示成 `.<文件名>.icloud` 占位文件，列目录时按已有处理，读之前先经原生通道协调下载。格式和流程的单测用本地目录代替（`test/services/cloud_backup_test.dart`）；真实的 iCloud 上传、下载只能在真机上验证。

### 4.6 安卓与 Windows

安卓端的技术要点与注意事项见 [plan-android.md](plan-android.md)，各平台的验证状态见 [platform-matrix.md](platform-matrix.md)。

## 5. 已知的坑与注意事项

- **UIScene 闪退只在不挂调试器时出现。** 用 Xcode 27 SDK 构建的应用在 iOS 27 上必须采用 UIScene 生命周期，否则从主屏幕正常启动时被系统 SIGTRAP 终止；用 `flutter run` 挂调试器启动时 trap 被吞掉，完全看不出问题。所以改动启动相关代码后，一定要从主屏幕点开验证。
- **build_runner 要加 `--force-jit`。** sqlite3 3.x 的 native hook 与 build_runner 的 AOT 编译冲突，不加时报错信息含糊。
- **安装失败或启动空白先 `flutter clean`。** sqlite3、objective_c 等 native-assets 原生库由 hooks 产出，构建缓存残留时会漏打包（装上后空白）或停留在 ad-hoc 签名（设备拒装）。hooks 缓存在 `.dart_tool`，只删 `build/ios` 不够。
- **不要用 `flutter install` 装到 iPhone**：它会先卸载应用，数据全丢。用 `scripts/resign-install.sh`，它用 `devicectl` 原地覆盖安装。
- **免费签名 7 天过期。** 只重新构建不会延后到期日，因为 Xcode 会复用本机缓存里没过期的描述文件；脚本先把本应用的缓存描述文件挪开，再指定已连接的设备构建一次让 Xcode 重新申请（免费账号必须指定设备才能生成）。重签安装后，首次用 `devicectl` 远程启动会被拒、手机提示"未验证"，手动打开一次即可恢复；HealthKit 授权也可能被重置，首次启动重新弹授权属正常。
- **签名信息放在本机配置里。** team ID、bundle ID 和默认安装设备写在 `app/Signing.xcconfig`（照 `app/Signing.example.xcconfig` 复制，不进 git）。iOS 工程通过 `ios/Flutter/Debug.xcconfig`、`Release.xcconfig`，Mac 工程通过 `macos/Runner/Configs/AppInfo.xcconfig` 读取它，`scripts/resign-install.sh` 也从这里取值；工程文件里不写死任何个人签名信息。Mac 端只取 bundle ID，仍用本机临时签名，换签名身份会读不到钥匙串里已存的内容。免费账号的 App ID 数量有限，开发期间保持同一个 team 和 bundle ID。
- **OpenAI 兼容服务（尤其中转站）不能假设标准。** 地址可能缺 `/v1`，错误可能是顶层 `{code, message}`，返回可能不是严格 JSON。解析要容错，错误信息要带响应片段，日志里要能看到实际返回。
- **Mac 钥匙串 `-34018`**、**Bonjour 不广播**：见 §4.2。
- **附件"已保存"必须在落盘并校验 SHA-256 之后才显示**；多图和大 PDF 的复制校验异步执行，界面显示进度。
- **脱敏范围是定死的**（姓名、证件号、门诊卡号，D-24）：医师姓名、医院名、流水号不在删除范围，不要擅自扩大，也不要漏掉三层规则中的任何一层（锚点标签取邻值、身份证校验位正则、已知姓名全文替换）。规则漏网的兜底是"发送前预览 + 裁剪提示 + 用户核对"，不是承诺零泄漏。
- **原件清理是删除性操作**：严格按 schema §8 的状态执行；正在导入、提取、传输的文件必须跳过；确认文件真正删除后才更新副本状态和已释放空间。
- **医疗报告版式差异大**：页筛选的锚点词表、脱敏规则和结构化提示词，要用不同医院的真实样本调；对应单测用固定样本集，改规则后先跑测试。
