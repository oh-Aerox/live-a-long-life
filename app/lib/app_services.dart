import 'dart:io';

import 'package:drift/native.dart';
import 'package:path/path.dart' as p;

import 'data/app_context.dart';
import 'data/data_profile.dart';
import 'data/db/app_database.dart';
import 'data/repositories/attachment_repository.dart';
import 'data/repositories/medical_document_repository.dart';
import 'data/repositories/message_repository.dart';
import 'data/repositories/model_config_repository.dart';
import 'data/repositories/health_repository.dart';
import 'data/repositories/organize_repository.dart';
import 'data/repositories/profile_repository.dart';
import 'data/repositories/peer_repository.dart';
import 'data/repositories/record_repository.dart';
import 'data/repositories/review_prompt_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'services/sync/lan_discovery.dart';
import 'services/medical_duplicate.dart';
import 'services/analysis_service.dart';
import 'services/backup_service.dart';
import 'services/consult_service.dart';
import 'services/consult_tools.dart';
import 'services/health_live.dart';
import 'services/health_service.dart';
import 'services/key_store.dart';
import 'services/medical_extraction_service.dart';
import 'services/medical_space_service.dart';
import 'services/organize_service.dart';
import 'services/review_service.dart';
import 'services/suggestion_service.dart';
import 'services/sync/sync_service.dart';
import 'services/text_extraction.dart';

/// 应用级服务：数据库与各仓库。
/// 数据库和附件都放 Application Support 下（docs/plan-v0.1.md §2），
/// 覆盖安装后保留（A-07），不出现在用户可见的文档目录里。
class AppServices {
  AppServices._({
    required this.db,
    required this.ctx,
    required this.messages,
    required this.attachments,
    required this.profile,
    required this.settings,
    required this.modelConfigs,
    required this.organize,
    required this.records,
    required this.health,
    required this.keyStore,
    required this.filesDir,
  }) {
    organizeService = OrganizeService(
      db: db,
      messages: messages,
      records: records,
      runs: organize,
      modelConfigs: modelConfigs,
      keyStore: keyStore,
    );
    peerRepo = PeerRepository(db);
    syncService = SyncService(
      deviceId: ctx.deviceId,
      db: db,
      peers: peerRepo,
      keyStore: keyStore,
      filesDir: filesDir,
      // 手机按 Mac 设备 ID 在局域网找回新地址（V4-M5 mDNS）。
      discover: Platform.isIOS || Platform.isAndroid
          ? const LanDiscovery().resolve
          : null,
    );
    analysisService = AnalysisService(
      db: db,
      modelConfigs: modelConfigs,
      organize: organize,
      keyStore: keyStore,
      deviceId: ctx.deviceId,
    );
    suggestionService = SuggestionService(
      db: db,
      records: records,
      deviceId: ctx.deviceId,
    );
    backupService = BackupService(db: db, filesDir: filesDir);
    textExtraction = TextExtractionService(
      extractor: PlatformTextExtractor(),
      cacheDir: Directory(p.join(filesDir.parent.path, 'extract_cache')),
    );
    consult = ConsultService(
      db: db,
      records: records,
      profile: profile,
      organize: organize,
      modelConfigs: modelConfigs,
      keyStore: keyStore,
      tools: ConsultTools(
        db: db,
        records: records,
        documents: medicalDocuments,
        // healthService 在 main 里按平台创建，查询时才取。
        deviceData: (date) => healthService.dayData(date),
        // 实时读取只在 iPhone 上有，随设置里的健康数据开关（D-44）。
        live: Platform.isIOS ? HealthLiveReader(HealthKitLiveSource()) : null,
        liveEnabled: () async =>
            await settings.get('healthkit_sync_enabled') as bool? ?? false,
      ),
    );
    medicalExtraction = MedicalExtractionService(
      attachments: attachments,
      documents: medicalDocuments,
      records: records,
      organize: organize,
      modelConfigs: modelConfigs,
      keyStore: keyStore,
      extraction: textExtraction,
      profile: profile,
    );
    medicalDuplicates = MedicalDuplicateService(
      attachments: attachments,
      documents: medicalDocuments,
      extraction: textExtraction,
    );
    medicalSpace = MedicalSpaceService(
      db: db,
      attachments: attachments,
      documents: medicalDocuments,
      sync: syncService,
      extraction: textExtraction,
    );
  }

  final AppDatabase db;
  final AppContext ctx;
  final MessageRepository messages;
  final AttachmentRepository attachments;
  final ProfileRepository profile;
  final SettingsRepository settings;
  final ModelConfigRepository modelConfigs;
  final OrganizeRepository organize;
  final RecordRepository records;
  final KeyStore keyStore;
  final Directory filesDir;
  late final File dbFile;
  late final OrganizeService organizeService;
  late final PeerRepository peerRepo;
  late final SyncService syncService;
  late final AnalysisService analysisService;
  late final SuggestionService suggestionService;
  late final BackupService backupService;
  late final TextExtractionService textExtraction;
  late final MedicalExtractionService medicalExtraction;
  late final MedicalDuplicateService medicalDuplicates;
  late final ConsultService consult;
  late final MedicalSpaceService medicalSpace;

  final HealthRepository health;
  late final ReviewPromptRepository reviewPrompts =
      ReviewPromptRepository(db, ctx);
  late final MedicalDocumentRepository medicalDocuments =
      MedicalDocumentRepository(db, ctx);

  /// 依赖启动时检测的时区，在 main 里赋值。
  late final HealthService healthService;
  late final ReviewService reviewService;

  static Future<AppServices> init() async {
    final support = await DataProfile.supportDir();
    final dbFile = File(p.join(support.path, 'db', 'app.sqlite'));
    await dbFile.parent.create(recursive: true);
    final filesDir = Directory(p.join(support.path, 'files'));

    final db = AppDatabase(NativeDatabase.createInBackground(dbFile));
    final settings = SettingsRepository(db);
    final ctx = await AppContext.load(settings);
    return AppServices._(
      db: db,
      ctx: ctx,
      messages: MessageRepository(db, ctx),
      attachments: AttachmentRepository(db, ctx, filesDir: filesDir),
      profile: ProfileRepository(db, ctx),
      settings: settings,
      modelConfigs: ModelConfigRepository(db, ctx),
      organize: OrganizeRepository(db, ctx),
      records: RecordRepository(db, ctx),
      health: HealthRepository(db, ctx),
      keyStore: KeyStore(),
      filesDir: filesDir,
    )..dbFile = dbFile;
  }

  /// 资料库里是否已有内容（恢复前判断，A-29）。
  Future<bool> hasExistingData() async {
    final msgs = await (db.select(db.messages)..limit(1)).get();
    if (msgs.isNotEmpty) return true;
    final fields = await (db.select(db.profileFields)..limit(1)).get();
    return fields.isNotEmpty;
  }
}
