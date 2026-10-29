import 'package:drift/drift.dart';

import '../field_meta.dart' show ReviewStatus;

import 'tables.dart';

export 'tables.dart';

part 'app_database.g.dart';

/// 数据库（表结构见 docs/schema.md）。
/// 迁移从 schemaVersion 1 开始编号，之后只追加迁移，不改旧迁移。
@DriftDatabase(tables: [
  Messages,
  MessageRevisions,
  Attachments,
  AttachmentCopies,
  MessageAttachments,
  ProfileFields,
  Settings,
  HealthSamples,
  HealthAnchors,
  HealthDaily,
  OrganizeRuns,
  OrganizeRunItems,
  ModelCalls,
  Records,
  RecordRevisions,
  RecordSources,
  ModelConfigs,
  ReviewPrompts,
  CorrectionSuggestions,
  ChangeLogs,
  Peers,
  SyncStates,
  AnalysisArtifacts,
  BackupRuns,
  MedicalDocuments,
  LabResults,
  ConsultMessages,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 19;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // v0.2 整理层、健康数据与模型配置（schema §2.5/§2.6/§3/§4.3/§4.4）。
            await m.createTable(healthSamples);
            await m.createTable(healthAnchors);
            await m.createTable(healthDaily);
            await m.createTable(organizeRuns);
            await m.createTable(organizeRunItems);
            await m.createTable(modelCalls);
            await m.createTable(records);
            await m.createTable(recordRevisions);
            await m.createTable(recordSources);
            await m.createTable(modelConfigs);
            await m.createTable(reviewPrompts);
          }
          if (from < 3) {
            // 修正建议提前到 v0.2：手机整理的受保护字段冲突要用（A-25）。
            await m.createTable(correctionSuggestions);
          }
          if (from < 4) {
            // v0.3 同步的变更日志（schema §7.2）。
            await m.createTable(changeLogs);
          }
          if (from < 5) {
            // v0.3 配对设备（schema §7.1）。
            await m.createTable(peers);
          }
          if (from < 6) {
            // v0.3 同步进度（schema §7.3）。
            await m.createTable(syncStates);
          }
          if (from < 7) {
            // v0.3 分析结果（schema §6.1）。
            await m.createTable(analysisArtifacts);
          }
          if (from < 8) {
            // v0.3 备份记录（schema §7.5，Mac 端）。
            await m.createTable(backupRuns);
          }
          if (from < 9) {
            // v0.4 医疗文件（schema §5.1）。
            await m.createTable(medicalDocuments);
          }
          if (from < 10) {
            // v0.4 调用记录加脱敏遮蔽项数（D-24）。
            await _addColumnIfMissing(m, modelCalls, modelCalls.redactedCount);
          }
          if (from < 11) {
            // v0.4 检验项目索引（schema §5.3，派生表，升级后自动重建）。
            await m.createTable(labResults);
          }
          if (from < 12) {
            // v0.4 页筛选的用户覆盖（D-23）。
            await _addColumnIfMissing(
                m, medicalDocuments, medicalDocuments.pageOverrides);
          }
          if (from < 13) {
            // v0.4 主动咨询（D-26）+ 调用记录的发送内容范围描述。
            await m.createTable(consultMessages);
            await _addColumnIfMissing(m, modelCalls, modelCalls.sentSummary);
          }
          if (from < 14) {
            // 调用记录保存实际发送内容（D-16 透明度）。
            await _addColumnIfMissing(m, modelCalls, modelCalls.requestText);
          }
          if (from < 15) {
            // 发送前确认页的行修改持久化（D-28）。
            await _addColumnIfMissing(
                m, medicalDocuments, medicalDocuments.lineEdits);
          }
          if (from < 16) {
            // 检验项目的检查大项（D-36）。索引是派生表，启动时整表重建。
            await _addColumnIfMissing(m, labResults, labResults.panelRaw);
          }
          if (from < 17) {
            // 医疗文件的就诊标题（D-37）。
            await _addColumnIfMissing(
                m, medicalDocuments, medicalDocuments.visitTitle);
          }
          if (from < 18) {
            // 检验索引加 part 并进主键（血压拆成收缩压、舒张压，D-39）。
            // 派生表，删了重建，启动时整表重算。
            await m.deleteTable(labResults.actualTableName);
            await m.createTable(labResults);
          }
          if (from < 19) {
            // 检验索引加标准名（D-49）。派生表，删了重建，启动时整表重算。
            await m.deleteTable(labResults.actualTableName);
            await m.createTable(labResults);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// 迁移必须可重跑：createTable 按当前表定义建表（v9 建 medical_documents
  /// 时已含 v12 才加的列），且 drift 迁移不在事务里，中途失败会留下已执行的
  /// 步骤而 user_version 不变。加列前先查列是否已在（2026-09-29 Mac 从 v8
  /// 升级卡死在 duplicate column）。
  Future<void> _addColumnIfMissing(
      Migrator m, TableInfo table, GeneratedColumn column) async {
    final cols =
        await customSelect('PRAGMA table_info(${table.actualTableName})').get();
    if (cols.any((r) => r.read<String>('name') == column.name)) return;
    await m.addColumn(table, column);
  }
}
