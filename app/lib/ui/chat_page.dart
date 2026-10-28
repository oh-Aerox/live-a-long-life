import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;

import '../app_services.dart';
import '../data/db/app_database.dart';
import '../data/ids.dart';
import '../services/notification_service.dart';
import '../services/signing_info.dart';
import 'adaptive.dart';
import 'body_map_page.dart';
import 'consult_page.dart';
import 'day_view_page.dart';
import 'health_records_page.dart';
import 'record_detail_page.dart';
import 'settings_page.dart';

/// 对话页（product-spec §5）。
/// 消息按 seq 排列、按天分组；发送即保存并显示"已保存"；
/// 照片和文件不在这里添加，从病例夹/体检入口导入（仍写入消息流），
/// 对话流照常显示已有的附件消息。
class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.services,
    required this.tz,
    required this.notifications,
  });

  final AppServices services;

  /// 当前 IANA 时区名，启动时检测。
  final String tz;

  final NotificationService notifications;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _ids = const IdGenerator();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  AppServices get _s => widget.services;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    await _s.messages.send(
      clientMsgId: _ids.newId(),
      role: MessageRole.user,
      kind: MessageKind.text,
      text: text,
      sentTz: widget.tz,
    );
    await _resetIdleTimer();
  }

  Future<void> _sendDoneMarker() async {
    await _s.messages.send(
      clientMsgId: _ids.newId(),
      role: MessageRole.user,
      kind: MessageKind.doneMarker,
      sentTz: widget.tz,
      organizeState: OrganizeState.notApplicable,
    );
    // "记好了"触发整理批次（D-05）。
    await _s.organizeService.enqueue(OrganizeTrigger.doneMarker);
  }

  @override
  void initState() {
    super.initState();
    _loadBadge();
  }

  /// 健康档案（D-27 医疗入口）：回来后刷新底栏角标。
  Future<void> _openHealthRecords() async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => HealthRecordsPage(services: _s)));
    await _loadBadge();
  }

  /// 底栏"健康档案"的角标：待处理的修正建议数（原来只在设置里，没有提示）。
  int _pendingSuggestions = 0;

  Future<void> _loadBadge() async {
    final n = (await _s.suggestionService.pending()).length;
    if (mounted && n != _pendingSuggestions) {
      setState(() => _pendingSuggestions = n);
    }
  }

  /// 每次录入后重置"短暂无输入预整理"计时（R-08）。
  Future<void> _resetIdleTimer() async {
    final sec =
        await _s.settings.get('idle_preorganize_sec') as int? ?? 180;
    _s.organizeService.noteUserActivity(Duration(seconds: sec));
  }

  // ---- 显示 ----

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: useCupertino(context)
          ? CupertinoColors.systemBackground.resolveFrom(context)
          : null,
      appBar: adaptiveAppBar(context, title: const Text('长命百岁')),
      body: Column(
        children: [
          _SigningExpiryBanner(),
          Expanded(
            // 首页没有可返回的列表页，侧滑收不起输入法：点对话区域
            // 或上下滑动对话即收起，底栏随之出现。
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: StreamBuilder<List<Message>>(
                stream: _s.messages.watchThread(),
                builder: (context, snapshot) {
                  final messages = snapshot.data ?? const <Message>[];
                  if (messages.isEmpty) {
                    return const Center(
                      child: Text('想到什么，随手记下来',
                          style: TextStyle(color: Colors.grey)),
                    );
                  }
                  return _buildList(messages);
                },
              ),
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  /// 底栏入口：按日查看、健康档案、咨询、设置（原在顶栏，移到输入框下面）。
  List<NavAction> _navActions() => [
        NavAction(
          icon: Icons.calendar_today_outlined,
          cupertinoIcon: CupertinoIcons.calendar,
          tooltip: '按日查看',
          color: const Color(0xFF5B9BF0),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DayViewPage(services: _s)),
          ),
        ),
        NavAction(
          icon: Icons.medical_information_outlined,
          cupertinoIcon: CupertinoIcons.folder,
          tooltip: '健康档案',
          color: const Color(0xFF3FB984),
          badge: _pendingSuggestions,
          onPressed: _openHealthRecords,
        ),
        NavAction(
          icon: Icons.psychology_alt_outlined,
          cupertinoIcon: CupertinoIcons.chat_bubble_2,
          tooltip: '咨询',
          color: const Color(0xFFF0A93B),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ConsultPage(services: _s)),
          ),
        ),
        NavAction(
          icon: Icons.settings_outlined,
          cupertinoIcon: CupertinoIcons.gear,
          tooltip: '设置',
          color: const Color(0xFF9A86E8),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => SettingsPage(
                      services: _s, notifications: widget.notifications)),
            );
            await _loadBadge();
          },
        ),
      ];

  Widget _buildList(List<Message> messages) {
    // 组装为（日期头 + 消息）的条目列表，倒序显示（最新在底部）。
    final items = <Widget>[];
    String? lastDate;
    String? lastUserMessageId;
    for (final m in messages) {
      if (m.role == MessageRole.user) lastUserMessageId = m.id;
    }
    for (final m in messages) {
      final local = DateTime.fromMillisecondsSinceEpoch(m.sentAt, isUtc: true)
          .toLocal();
      final dateLabel = local.year == DateTime.now().year
          ? '${local.month}月${local.day}日'
          : '${local.year}年${local.month}月${local.day}日';
      if (dateLabel != lastDate) {
        lastDate = dateLabel;
        items.add(Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(dateLabel,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ));
      }
      items.add(_buildMessage(m));
      if (m.id == lastUserMessageId) {
        items.add(Padding(
          padding: EdgeInsets.only(
              top: 2,
              bottom: 4,
              right: m.role == MessageRole.user ? 12 : 0),
          child: const Align(
            alignment: Alignment.centerRight,
            child: Text('✓ 已保存',
                style: TextStyle(color: Colors.green, fontSize: 12)),
          ),
        ));
      }
    }
    final reversed = items.reversed.toList();
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: reversed.length,
      itemBuilder: (context, index) => reversed[index],
    );
  }

  Widget _buildMessage(Message m) {
    if (m.kind == MessageKind.doneMarker) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Text('— 记好了 —',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
        ),
      );
    }
    final isUser = m.role == MessageRole.user;
    final Widget content;
    if (m.kind == MessageKind.attachments) {
      content = _AttachmentTiles(services: _s, messageId: m.id);
    } else {
      final textStyle = TextStyle(color: isUser ? Colors.white : null);
      content = m.revisionNo > 0
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(m.body ?? '', style: textStyle),
                Text('已编辑',
                    style: TextStyle(
                        fontSize: 10,
                        color: (isUser ? Colors.white : Colors.grey)
                            .withValues(alpha: 0.7))),
              ],
            )
          : Text(m.body ?? '', style: textStyle);
    }
    final cupertino = useCupertino(context);
    final bubble = Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      constraints:
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
      decoration: BoxDecoration(
        color: isUser
            ? Theme.of(context).colorScheme.primary
            : cupertino
                ? CupertinoColors.systemGrey5.resolveFrom(context)
                : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(cupertino ? 18 : 14),
      ),
      child: content,
    );
    // 整理状态（A-10：无模型或失败时消息显示"待整理"）。
    final stateLabel = switch (m.organizeState) {
      OrganizeState.pending || OrganizeState.needsReorganize => '待整理',
      OrganizeState.needsManual => '整理遇到冲突，需手动处理',
      _ => null,
    };
    final withState = !isUser || stateLabel == null
        ? bubble
        : Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              bubble,
              Padding(
                padding: const EdgeInsets.only(right: 14, bottom: 2),
                child: Text(stateLabel,
                    style: TextStyle(
                        fontSize: 10,
                        color: m.organizeState == OrganizeState.needsManual
                            ? Colors.orange
                            : Colors.grey)),
              ),
            ],
          );
    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: GestureDetector(
            onLongPress: () => _showMessageMenu(m), child: withState),
      );
    }
    // "已记到 X月X日"等提示：点开对应记录（A-23 歧义核对入口）。
    final recordId = _noticeRecordId(m);
    if (recordId != null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    RecordDetailPage(services: _s, recordId: recordId)),
          ),
          child: withState,
        ),
      );
    }
    // 回顾提问：带"跳过"（跳过的问题当天不再出现，A-32）。
    final promptRowId = _reviewPromptRowId(m);
    if (promptRowId != null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            withState,
            _ReviewPromptSkip(services: _s, promptRowId: promptRowId),
          ],
        ),
      );
    }
    return Align(alignment: Alignment.centerLeft, child: withState);
  }

  String? _reviewPromptRowId(Message m) {
    if (m.kind != MessageKind.appPrompt || m.promptMeta == null) return null;
    try {
      final meta = jsonDecode(m.promptMeta!) as Map;
      if (meta['kind'] != 'review_prompt') return null;
      return meta['prompt_row_id'] as String?;
    } catch (_) {
      return null;
    }
  }

  String? _noticeRecordId(Message m) {
    if (m.kind != MessageKind.appNotice || m.promptMeta == null) return null;
    try {
      final meta = jsonDecode(m.promptMeta!) as Map;
      return meta['record_id'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ---- 消息纠错（A-06 与误发移除）----

  Future<void> _showMessageMenu(Message m) async {
    // 先收起输入法，否则菜单被键盘遮挡。
    FocusManager.instance.primaryFocus?.unfocus();
    final canEdit = m.kind == MessageKind.text;
    final action = await showActionSheet<String>(context, actions: [
      if (canEdit)
        const SheetAction(
            value: 'edit', label: '编辑', icon: Icons.edit_outlined),
      if (canEdit && m.revisionNo > 0)
        const SheetAction(
            value: 'history', label: '查看原文', icon: Icons.history),
      const SheetAction(
          value: 'delete',
          label: '删除（误发）',
          icon: Icons.delete_outline,
          isDestructiveAction: true),
    ]);
    if (action == null || !mounted) return;
    switch (action) {
      case 'edit':
        await _editMessage(m);
      case 'history':
        await _showHistory(m);
      case 'delete':
        await _confirmDelete(m);
    }
  }

  Future<void> _editMessage(Message m) async {
    final values = await showFieldsDialog(context, title: '编辑消息', fields: [
      DialogField(initial: m.body ?? '', maxLines: 5, minLines: 1),
    ]);
    final newText = values?.single.trim();
    if (newText == null || newText.isEmpty || newText == m.body) return;
    await _s.messages.edit(m.id, newText);
  }

  Future<void> _showHistory(Message m) async {
    final revisions = await _s.messages.revisionsOf(m.id);
    if (!mounted) return;
    await showAdaptiveDialog<void>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: const Text('修改历史'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final r in revisions) ...[
                Text(
                  r.revisionNo == 0 ? '原文' : '第 ${r.revisionNo} 次修改前',
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(r.textBefore),
                ),
              ],
              const Text('当前',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text(m.body ?? ''),
            ],
          ),
        ),
        actions: [
          DialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(Message m) async {
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: const Text('删除这条消息？'),
        content: const Text('消息会从对话流移除。这是给误发准备的，'
            '写错内容用"编辑"更合适。'),
        actions: [
          DialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          DialogAction(
            onPressed: () => Navigator.pop(context, true),
            isDestructiveAction: true,
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _s.messages.markDeleted(m.id);
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            useCupertino(context)
                ? _buildCupertinoInputRow()
                : _buildMaterialInputRow(),
            // 打字时收起底栏，给对话留出空间。
            if (MediaQuery.viewInsetsOf(context).bottom == 0)
              _BottomNavRow(
                actions: _navActions(),
                center: _BodyMapButton(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => BodyMapPage(services: _s)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialInputRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: _textController,
            minLines: 1,
            maxLines: 5,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              hintText: '说点什么…',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            ),
          ),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _textController,
          builder: (context, value, _) =>
              value.text.trim().isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.arrow_upward),
                      tooltip: '发送',
                      onPressed: _sendText,
                    )
                  : TextButton(
                      onPressed: _sendDoneMarker,
                      child: const Text('记好了'),
                    ),
        ),
      ],
    );
  }

  /// iOS 输入栏：圆角输入框，发送是实心上箭头，空输入时显示"记好了"。
  Widget _buildCupertinoInputRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: CupertinoTextField(
            controller: _textController,
            minLines: 1,
            maxLines: 5,
            textInputAction: TextInputAction.newline,
            placeholder: '说点什么…',
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              border: Border.all(
                  color: CupertinoColors.systemGrey4.resolveFrom(context)),
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _textController,
          builder: (context, value, _) => value.text.trim().isNotEmpty
              ? CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  minimumSize: const Size(36, 36),
                  onPressed: _sendText,
                  child: const Icon(CupertinoIcons.arrow_up_circle_fill,
                      size: 32),
                )
              : CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: const Size(36, 36),
                  onPressed: _sendDoneMarker,
                  child: const Text('记好了'),
                ),
        ),
      ],
    );
  }
}

/// 输入框下面的一排入口：彩色图标下面带名称，等分；[center] 插在正中间。
class _BottomNavRow extends StatelessWidget {
  const _BottomNavRow({required this.actions, this.center});

  final List<NavAction> actions;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    final cupertino = useCupertino(context);
    final fallback = cupertino
        ? CupertinoColors.secondaryLabel.resolveFrom(context)
        : Theme.of(context).colorScheme.onSurfaceVariant;
    final items = <Widget>[
      for (final a in actions)
        _NavItem(
          label: a.tooltip,
          onTap: a.onPressed,
          icon: Badge(
            isLabelVisible: a.badge > 0,
            label: Text(a.badge > 99 ? '99+' : '${a.badge}'),
            backgroundColor: Colors.orange,
            child: Icon(cupertino ? a.cupertinoIcon : a.icon,
                size: 24, color: a.color ?? fallback),
          ),
        ),
    ];
    final c = center;
    if (c != null) items.insert(items.length ~/ 2, c);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [for (final item in items) Expanded(child: item)],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.onTap,
    required this.icon,
  });

  final String label;
  final VoidCallback? onTap;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    final cupertino = useCupertino(context);
    final labelColor = cupertino
        ? CupertinoColors.secondaryLabel.resolveFrom(context)
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: Semantics(
        label: label,
        button: true,
        excludeSemantics: true,
        child: InkResponse(
          onTap: onTap,
          radius: 28,
          // iOS 点按没有水波纹。
          splashFactory: cupertino ? NoSplash.splashFactory : null,
          highlightShape: BoxShape.rectangle,
          highlightColor: cupertino ? Colors.transparent : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 28, child: Center(child: icon)),
                const SizedBox(height: 2),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: labelColor)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 底栏正中的人体图入口：渐变彩色，配色取人体图里器官的蓝、绿、黄。
class _BodyMapButton extends StatelessWidget {
  const _BodyMapButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _NavItem(
      label: '人体图',
      onTap: onTap,
      icon: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF5B9BF0), Color(0xFF4CC38A), Color(0xFFF2B33D)],
        ).createShader(bounds),
        child: const Icon(Icons.accessibility_new, size: 28),
      ),
    );
  }
}

/// 签名剩两天以内时在对话页顶部提示（D-19、P-52）。
class _SigningExpiryBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DateTime?>(
      future: SigningInfo.provisioningExpiry(),
      builder: (context, snapshot) {
        final expiry = snapshot.data;
        if (expiry == null) return const SizedBox.shrink();
        final days = expiry.difference(DateTime.now()).inDays;
        if (days > 2) return const SizedBox.shrink();
        final text = days < 0
            ? '应用签名已过期，请尽快连接 Mac 重签'
            : days == 0
                ? '应用签名今天到期，请连接 Mac 重签，先导出一次数据'
                : '应用签名 $days 天后到期，记得连接 Mac 重签';
        return Container(
          width: double.infinity,
          color: Colors.orange.withValues(alpha: 0.15),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(text,
              style: const TextStyle(fontSize: 13, color: Colors.orange)),
        );
      },
    );
  }
}

/// 一条附件消息里的缩略图或文件卡片，按 position 排列（A-01）。
class _AttachmentTiles extends StatelessWidget {
  const _AttachmentTiles({required this.services, required this.messageId});

  final AppServices services;
  final String messageId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<(MessageAttachment, Attachment)>>(
      future: services.attachments.attachmentsOf(messageId),
      builder: (context, snapshot) {
        final rows = snapshot.data;
        if (rows == null) {
          return const SizedBox(
              width: 60,
              height: 60,
              child: Center(child: CircularProgressIndicator.adaptive(strokeWidth: 2)));
        }
        return Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [for (final (_, a) in rows) _tile(context, a)],
        );
      },
    );
  }

  Widget _tile(BuildContext context, Attachment a) {
    if (a.mimeType.startsWith('image/')) {
      return FutureBuilder<String?>(
        future: services.attachments.localPathOf(a.id),
        builder: (context, snapshot) {
          final path = snapshot.data;
          return GestureDetector(
            onTap: path == null
                ? null
                : () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => _ImageViewerPage(path: path),
                    )),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: path != null
                  ? Image.file(File(path),
                      width: 84, height: 84, fit: BoxFit.cover)
                  : Container(
                      width: 84,
                      height: 84,
                      color: Colors.black12,
                      child: const Icon(Icons.image_not_supported_outlined)),
            ),
          );
        },
      );
    }
    return GestureDetector(
      onTap: () => _openFile(context, a),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf_outlined, size: 18),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Text(
                a.originalFilename ?? 'PDF',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 用系统预览打开文件（PDF 等）。副本不在本机时提示，不静默失败。
  ///
  /// 附件按 SHA-256 命名、无后缀，系统预览认不出类型，所以先在临时目录
  /// 以原始文件名（带后缀）建一份预览副本再打开；预览标题也因此是原名。
  Future<void> _openFile(BuildContext context, Attachment a) async {
    final messenger = ScaffoldMessenger.of(context);
    final path = await services.attachments.localPathOf(a.id);
    if (path == null || !await File(path).exists()) {
      messenger.showSnackBar(
          const SnackBar(content: Text('文件不在本机，无法打开')));
      return;
    }
    final name = _previewName(a);
    final preview =
        File(p.join(Directory.systemTemp.path, 'preview', a.sha256, name));
    if (!await preview.exists()) {
      await preview.parent.create(recursive: true);
      await File(path).copy(preview.path);
    }
    final result = await OpenFilex.open(preview.path);
    if (result.type != ResultType.done) {
      messenger.showSnackBar(SnackBar(content: Text('打开失败：${result.message}')));
    }
  }

  String _previewName(Attachment a) {
    final original = a.originalFilename;
    if (original != null && p.extension(original).isNotEmpty) return original;
    final ext = switch (a.mimeType) {
      'application/pdf' => '.pdf',
      'image/jpeg' => '.jpg',
      'image/png' => '.png',
      'image/heic' => '.heic',
      'image/gif' => '.gif',
      _ => '',
    };
    return (original ?? '文件') + ext;
  }
}

/// 全屏图片查看：可缩放、拖动，点一下返回。
class _ImageViewerPage extends StatelessWidget {
  const _ImageViewerPage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: SizedBox.expand(
          child: InteractiveViewer(
            maxScale: 6,
            child: Center(child: Image.file(File(path))),
          ),
        ),
      ),
    );
  }
}

/// 回顾提问下的"跳过"：跳过后当天不再问这个缺口（A-32）。
class _ReviewPromptSkip extends StatefulWidget {
  const _ReviewPromptSkip({required this.services, required this.promptRowId});

  final AppServices services;
  final String promptRowId;

  @override
  State<_ReviewPromptSkip> createState() => _ReviewPromptSkipState();
}

class _ReviewPromptSkipState extends State<_ReviewPromptSkip> {
  ReviewOutcome? _outcome;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    widget.services.reviewPrompts.byId(widget.promptRowId).then((row) {
      if (mounted) {
        setState(() {
          _outcome = row?.outcome;
          _loaded = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();
    if (_outcome == ReviewOutcome.skipped) {
      return const Padding(
        padding: EdgeInsets.only(left: 16, bottom: 4),
        child: Text('已跳过', style: TextStyle(fontSize: 11, color: Colors.grey)),
      );
    }
    if (_outcome != null) return const SizedBox.shrink();
    Future<void> skip() async {
      await widget.services.reviewPrompts
          .markOutcome(widget.promptRowId, ReviewOutcome.skipped);
      if (mounted) setState(() => _outcome = ReviewOutcome.skipped);
    }

    if (useCupertino(context)) {
      return Padding(
        padding: const EdgeInsets.only(left: 8),
        child: CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          minimumSize: Size.zero,
          onPressed: skip,
          child: const Text('跳过', style: TextStyle(fontSize: 13)),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: TextButton(
        style: TextButton.styleFrom(
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2)),
        onPressed: skip,
        child: const Text('跳过', style: TextStyle(fontSize: 12)),
      ),
    );
  }
}
