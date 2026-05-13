import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kAppName = 'ASSOC.FORMAT.PERFECT.GEST.COL.';
const String kCompanyName = 'ASSOC.FORMAT.PERFECT.GEST.COL.TERR.FRANC';
const String kSupportEmail = 'support@assoc-format-perfect-gest-col.fr';
const bool kScreenshotMode = bool.fromEnvironment('SCREENSHOT_MODE');

void main() {
  runApp(const OperationsApp());
}

class OperationsApp extends StatelessWidget {
  const OperationsApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF075D82);
    const secondary = Color(0xFFD99A1E);
    const tertiary = Color(0xFF2F7D57);
    const background = Color(0xFFF6F8F7);

    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
          primary: primary,
          secondary: secondary,
          tertiary: tertiary,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: background,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: background,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE0E6E8)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      home: const OperationsShell(),
    );
  }
}

class OpsRecord {
  const OpsRecord({
    required this.id,
    required this.type,
    required this.title,
    required this.owner,
    required this.status,
    required this.priority,
    required this.dueLabel,
    required this.notes,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final String owner;
  final String status;
  final String priority;
  final String dueLabel;
  final String notes;
  final DateTime createdAt;

  OpsRecord copyWith({String? status}) {
    return OpsRecord(
      id: id,
      type: type,
      title: title,
      owner: owner,
      status: status ?? this.status,
      priority: priority,
      dueLabel: dueLabel,
      notes: notes,
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'owner': owner,
      'status': status,
      'priority': priority,
      'dueLabel': dueLabel,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory OpsRecord.fromJson(Map<String, Object?> json) {
    return OpsRecord(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'equipment',
      title: json['title'] as String? ?? '',
      owner: json['owner'] as String? ?? '',
      status: json['status'] as String? ?? 'Ready',
      priority: json['priority'] as String? ?? 'Normal',
      dueLabel: json['dueLabel'] as String? ?? 'Today',
      notes: json['notes'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class OperationsController extends ChangeNotifier {
  static const _storageKey = 'operations_records_v1';

  final List<OpsRecord> _records = [];
  bool _loaded = false;

  bool get loaded => _loaded;
  List<OpsRecord> get records => List.unmodifiable(_records);

  Future<void> load() async {
    _records.clear();
    if (kScreenshotMode) {
      _records.addAll(_sampleRecords);
      _loaded = true;
      notifyListeners();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _records.addAll(
        decoded
            .whereType<Map<String, Object?>>()
            .map(OpsRecord.fromJson)
            .where((record) => record.title.isNotEmpty),
      );
    }
    if (_records.isEmpty) {
      _records.addAll(_starterRecords);
      await _save();
    }
    _loaded = true;
    notifyListeners();
  }

  List<OpsRecord> byType(String type) {
    return _records.where((record) => record.type == type).toList();
  }

  int countByType(String type) {
    return _records.where((record) => record.type == type).length;
  }

  int countByStatus(Iterable<String> statuses) {
    final statusSet = statuses.toSet();
    return _records.where((record) => statusSet.contains(record.status)).length;
  }

  Future<void> addRecord(OpsRecord record) async {
    _records.insert(0, record);
    await _save();
    notifyListeners();
  }

  Future<void> updateStatus(String id, String status) async {
    final index = _records.indexWhere((record) => record.id == id);
    if (index == -1) {
      return;
    }
    _records[index] = _records[index].copyWith(status: status);
    await _save();
    notifyListeners();
  }

  Future<void> clearLocalRecords() async {
    _records.clear();
    if (!kScreenshotMode) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    }
    notifyListeners();
  }

  Future<void> _save() async {
    if (kScreenshotMode) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      _records.map((record) => record.toJson()).toList(),
    );
    await prefs.setString(_storageKey, encoded);
  }
}

class OperationsShell extends StatefulWidget {
  const OperationsShell({super.key});

  @override
  State<OperationsShell> createState() => _OperationsShellState();
}

class _OperationsShellState extends State<OperationsShell> {
  late final OperationsController controller;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    controller = OperationsController();
    controller.load();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (!controller.loaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final body = switch (currentIndex) {
          0 => DashboardPage(
            controller: controller,
            onOpenTab: (index) => setState(() => currentIndex = index),
            onCreateType: _openForm,
          ),
          1 => RecordListPage(
            title: 'Equipment checkout',
            type: 'equipment',
            emptyText: 'No equipment records saved.',
            controller: controller,
            onOpenForm: () => _openForm('equipment'),
          ),
          2 => RecordListPage(
            title: 'Incident reporting',
            type: 'incident',
            emptyText: 'No incidents saved.',
            controller: controller,
            onOpenForm: () => _openForm('incident'),
          ),
          3 => ShiftResourcePage(controller: controller, onOpenForm: _openForm),
          _ => SettingsPage(controller: controller),
        };

        return Scaffold(
          appBar: AppBar(
            title: const Text(kAppName),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Chip(
                  avatar: const Icon(Icons.lock_outline, size: 16),
                  label: const Text('Local'),
                  visualDensity: VisualDensity.compact,
                  side: BorderSide.none,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.tertiaryContainer.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
          body: SafeArea(child: body),
          floatingActionButton: _floatingActionButton(),
          bottomNavigationBar: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: (index) =>
                setState(() => currentIndex = index),
            destinations: const [
              NavigationDestination(
                key: ValueKey('tab_dashboard'),
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Ops',
              ),
              NavigationDestination(
                key: ValueKey('tab_equipment'),
                icon: Icon(Icons.precision_manufacturing_outlined),
                selectedIcon: Icon(Icons.precision_manufacturing),
                label: 'Gear',
              ),
              NavigationDestination(
                key: ValueKey('tab_incidents'),
                icon: Icon(Icons.report_problem_outlined),
                selectedIcon: Icon(Icons.report_problem),
                label: 'Issues',
              ),
              NavigationDestination(
                key: ValueKey('tab_shifts'),
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month),
                label: 'Shifts',
              ),
              NavigationDestination(
                key: ValueKey('tab_settings'),
                icon: Icon(Icons.tune_outlined),
                selectedIcon: Icon(Icons.tune),
                label: 'Local',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget? _floatingActionButton() {
    final type = switch (currentIndex) {
      1 => 'equipment',
      2 => 'incident',
      3 => 'shift',
      _ => null,
    };
    if (type == null) {
      return null;
    }

    return FloatingActionButton.extended(
      key: ValueKey('new_$type'),
      onPressed: () => _openForm(type),
      icon: const Icon(Icons.add),
      label: const Text('New'),
    );
  }

  Future<void> _openForm(String type) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            RecordFormPage(controller: controller, initialType: type),
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    required this.controller,
    required this.onOpenTab,
    required this.onCreateType,
    super.key,
  });

  final OperationsController controller;
  final ValueChanged<int> onOpenTab;
  final ValueChanged<String> onCreateType;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final queue = controller.records.take(4).toList();
    final activeIncidents = controller.countByStatus([
      'New',
      'Assessing',
      'Contained',
    ]);
    final pendingEquipment = controller.countByStatus([
      'Checked out',
      'Reserved',
      'Service hold',
    ]);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF001C33),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kCompanyName,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFFE1F4FF),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Operations control',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Daily equipment movement, incident response, shift coverage, and resource allocation stay in one local workspace.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFC6D8DF),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.35,
          children: [
            MetricCard(
              icon: Icons.precision_manufacturing_outlined,
              label: 'Equipment',
              value: '${controller.countByType('equipment')}',
              accent: scheme.primary,
            ),
            MetricCard(
              icon: Icons.report_problem_outlined,
              label: 'Open issues',
              value: '$activeIncidents',
              accent: const Color(0xFFC4492D),
            ),
            MetricCard(
              icon: Icons.groups_outlined,
              label: 'Shifts',
              value: '${controller.countByType('shift')}',
              accent: scheme.tertiary,
            ),
            MetricCard(
              icon: Icons.inventory_2_outlined,
              label: 'Resources',
              value: '${controller.countByType('resource')}',
              accent: scheme.secondary,
            ),
          ],
        ),
        const SizedBox(height: 16),
        SectionHeader(
          title: 'Priority queue',
          action: TextButton.icon(
            onPressed: () => onOpenTab(2),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Issues'),
          ),
        ),
        const SizedBox(height: 8),
        ...queue.map(
          (record) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: CompactRecordTile(record: record),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => onCreateType('equipment'),
                icon: const Icon(Icons.add_box_outlined),
                label: const Text('Checkout'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => onCreateType('incident'),
                icon: const Icon(Icons.warning_amber_outlined),
                label: const Text('Report'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        ResourceBalanceCard(
          title: 'Equipment readiness',
          value: pendingEquipment == 0 ? 0.92 : 0.68,
          detail: '$pendingEquipment checkout or service item(s) need review',
        ),
        const SizedBox(height: 10),
        ResourceBalanceCard(
          title: 'Shift coverage',
          value: controller.countByStatus(['Needs cover']) == 0 ? 0.86 : 0.61,
          detail: '${controller.countByStatus(['Needs cover'])} gap(s) flagged',
        ),
      ],
    );
  }
}

class RecordListPage extends StatelessWidget {
  const RecordListPage({
    required this.title,
    required this.type,
    required this.emptyText,
    required this.controller,
    required this.onOpenForm,
    super.key,
  });

  final String title;
  final String type;
  final String emptyText;
  final OperationsController controller;
  final VoidCallback onOpenForm;

  @override
  Widget build(BuildContext context) {
    final records = controller.byType(type);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        PageIntro(
          title: title,
          subtitle: _subtitleFor(type),
          icon: _iconFor(type),
        ),
        const SizedBox(height: 12),
        if (records.isEmpty)
          EmptyState(text: emptyText, onPressed: onOpenForm)
        else
          ...records.map(
            (record) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: RecordCard(
                record: record,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => RecordDetailPage(
                      controller: controller,
                      recordId: record.id,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class ShiftResourcePage extends StatelessWidget {
  const ShiftResourcePage({
    required this.controller,
    required this.onOpenForm,
    super.key,
  });

  final OperationsController controller;
  final ValueChanged<String> onOpenForm;

  @override
  Widget build(BuildContext context) {
    final shifts = controller.byType('shift');
    final resources = controller.byType('resource');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        const PageIntro(
          title: 'Shift schedule',
          subtitle: 'Coverage, allocation notes, and supply readiness by team.',
          icon: Icons.calendar_month_outlined,
        ),
        const SizedBox(height: 12),
        SectionHeader(
          title: 'Coverage',
          action: TextButton.icon(
            onPressed: () => onOpenForm('shift'),
            icon: const Icon(Icons.add),
            label: const Text('Shift'),
          ),
        ),
        const SizedBox(height: 8),
        ...shifts.map(
          (record) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: RecordCard(
              record: record,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => RecordDetailPage(
                    controller: controller,
                    recordId: record.id,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SectionHeader(
          title: 'Resource allocation',
          action: TextButton.icon(
            onPressed: () => onOpenForm('resource'),
            icon: const Icon(Icons.add),
            label: const Text('Resource'),
          ),
        ),
        const SizedBox(height: 8),
        ...resources.map(
          (record) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: RecordCard(
              record: record,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => RecordDetailPage(
                    controller: controller,
                    recordId: record.id,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({required this.controller, super.key});

  final OperationsController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        const PageIntro(
          title: 'Local workspace',
          subtitle: 'Records and preferences remain on this Android device.',
          icon: Icons.lock_outline,
        ),
        const SizedBox(height: 12),
        InfoPanel(
          title: 'Organization',
          rows: const [
            ('App', kAppName),
            ('Provider', kCompanyName),
            ('Support', kSupportEmail),
          ],
        ),
        const SizedBox(height: 12),
        InfoPanel(
          title: 'Storage',
          rows: [
            ('Saved records', '${controller.records.length}'),
            ('Accounts', 'Not required'),
            ('Cloud sync', 'Not used'),
          ],
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: controller.records.isEmpty
              ? null
              : () async {
                  await controller.clearLocalRecords();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Local records cleared')),
                    );
                  }
                },
          icon: const Icon(Icons.delete_outline),
          label: const Text('Clear local records'),
        ),
      ],
    );
  }
}

class RecordDetailPage extends StatelessWidget {
  const RecordDetailPage({
    required this.controller,
    required this.recordId,
    super.key,
  });

  final OperationsController controller;
  final String recordId;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final record = controller.records.firstWhere(
          (item) => item.id == recordId,
          orElse: () => controller.records.first,
        );
        final statusOptions = _statusOptionsFor(record.type);

        return Scaffold(
          appBar: AppBar(title: Text(_typeLabel(record.type))),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(
                record.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusChip(label: record.status),
                  PriorityChip(label: record.priority),
                  Chip(
                    avatar: const Icon(Icons.schedule, size: 16),
                    label: Text(record.dueLabel),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              InfoPanel(
                title: 'Ownership',
                rows: [
                  ('Responsible', record.owner),
                  ('Created', _formatDate(record.createdAt)),
                  ('Category', _typeLabel(record.type)),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notes',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(record.notes),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status update',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: statusOptions
                            .map(
                              (status) => ChoiceChip(
                                label: Text(status),
                                selected: record.status == status,
                                onSelected: (_) =>
                                    controller.updateStatus(record.id, status),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class RecordFormPage extends StatefulWidget {
  const RecordFormPage({
    required this.controller,
    required this.initialType,
    super.key,
  });

  final OperationsController controller;
  final String initialType;

  @override
  State<RecordFormPage> createState() => _RecordFormPageState();
}

class _RecordFormPageState extends State<RecordFormPage> {
  late String type;
  late String status;
  String priority = 'Normal';
  final titleController = TextEditingController();
  final ownerController = TextEditingController();
  final dueController = TextEditingController();
  final notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    type = widget.initialType;
    status = _statusOptionsFor(type).first;
    dueController.text = 'Today';
  }

  @override
  void dispose() {
    titleController.dispose();
    ownerController.dispose();
    dueController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('New ${_typeLabel(type)}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          DropdownButtonFormField<String>(
            key: const ValueKey('record_type'),
            initialValue: type,
            decoration: const InputDecoration(labelText: 'Category'),
            items: _recordTypes
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(_typeLabel(item)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                type = value;
                status = _statusOptionsFor(value).first;
              });
            },
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('record_title'),
            controller: titleController,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: _titleLabelFor(type)),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('record_owner'),
            controller: ownerController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Responsible team'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: const ValueKey('record_status'),
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: _statusOptionsFor(type)
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => status = value ?? status),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: const ValueKey('record_priority'),
                  initialValue: priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: _priorities
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => priority = value ?? priority),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('record_due'),
            controller: dueController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Shift, date, or due time',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('record_notes'),
            controller: notesController,
            minLines: 4,
            maxLines: 6,
            decoration: const InputDecoration(labelText: 'Operational notes'),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            key: const ValueKey('save_record'),
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: const Text('Save record'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final title = titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }

    await widget.controller.addRecord(
      OpsRecord(
        id: 'record_${DateTime.now().microsecondsSinceEpoch}',
        type: type,
        title: title,
        owner: ownerController.text.trim().isEmpty
            ? 'Operations desk'
            : ownerController.text.trim(),
        status: status,
        priority: priority,
        dueLabel: dueController.text.trim().isEmpty
            ? 'Today'
            : dueController.text.trim(),
        notes: notesController.text.trim().isEmpty
            ? 'No extra notes recorded.'
            : notesController.text.trim(),
        createdAt: DateTime.now(),
      ),
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

class PageIntro extends StatelessWidget {
  const PageIntro({
    required this.title,
    required this.subtitle,
    required this.icon,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: scheme.primaryContainer,
              foregroundColor: scheme.onPrimaryContainer,
              child: Icon(icon),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: accent),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(label),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RecordCard extends StatelessWidget {
  const RecordCard({required this.record, required this.onTap, super.key});

  final OpsRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_iconFor(record.type), color: _accentFor(record.type)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(record.owner),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusChip(label: record.status),
                  PriorityChip(label: record.priority),
                  Chip(
                    avatar: const Icon(Icons.event_available, size: 16),
                    label: Text(record.dueLabel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CompactRecordTile extends StatelessWidget {
  const CompactRecordTile({required this.record, super.key});

  final OpsRecord record;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(_iconFor(record.type), color: _accentFor(record.type)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '${_typeLabel(record.type)} - ${record.owner}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusChip(label: record.status),
          ],
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = switch (label) {
      'New' ||
      'Needs cover' ||
      'Low stock' ||
      'Service hold' => const Color(0xFFC4492D),
      'Closed' ||
      'Returned' ||
      'Completed' ||
      'Ready' => const Color(0xFF2F7D57),
      'Contained' || 'Covered' || 'Rebalanced' => const Color(0xFF075D82),
      _ => const Color(0xFFD99A1E),
    };

    return Chip(
      label: Text(label),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w700),
      side: BorderSide(color: color.withValues(alpha: 0.35)),
      backgroundColor: color.withValues(alpha: 0.1),
      visualDensity: VisualDensity.compact,
    );
  }
}

class PriorityChip extends StatelessWidget {
  const PriorityChip({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = label == 'Critical'
        ? const Color(0xFFC4492D)
        : label == 'High'
        ? const Color(0xFFD99A1E)
        : const Color(0xFF536067);

    return Chip(
      avatar: Icon(Icons.flag_outlined, size: 16, color: color),
      label: Text(label),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w700),
      side: BorderSide(color: color.withValues(alpha: 0.28)),
      backgroundColor: color.withValues(alpha: 0.08),
      visualDensity: VisualDensity.compact,
    );
  }
}

class ResourceBalanceCard extends StatelessWidget {
  const ResourceBalanceCard({
    required this.title,
    required this.value,
    required this.detail,
    super.key,
  });

  final String title;
  final double value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text('${(value * 100).round()}%'),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: value,
              minHeight: 9,
              borderRadius: BorderRadius.circular(8),
              backgroundColor: scheme.surfaceContainerHighest,
            ),
            const SizedBox(height: 8),
            Text(detail),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, this.action, super.key});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        ?action,
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({required this.text, required this.onPressed, super.key});

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.inbox_outlined, size: 42),
            const SizedBox(height: 8),
            Text(text, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.add),
              label: const Text('Add record'),
            ),
          ],
        ),
      ),
    );
  }
}

class InfoPanel extends StatelessWidget {
  const InfoPanel({required this.title, required this.rows, super.key});

  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            ...rows.map(
              (row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 112,
                      child: Text(
                        row.$1,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Expanded(child: Text(row.$2)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _recordTypes = ['equipment', 'incident', 'shift', 'resource'];
const _priorities = ['Low', 'Normal', 'High', 'Critical'];

String _typeLabel(String type) {
  return switch (type) {
    'equipment' => 'Equipment',
    'incident' => 'Incident',
    'shift' => 'Shift',
    'resource' => 'Resource',
    _ => 'Record',
  };
}

String _subtitleFor(String type) {
  return switch (type) {
    'equipment' =>
      'Checkout ownership, returns, reservations, and service holds.',
    'incident' => 'Field issues, containment progress, and closure status.',
    _ => 'Operational records saved locally.',
  };
}

String _titleLabelFor(String type) {
  return switch (type) {
    'equipment' => 'Equipment or kit name',
    'incident' => 'Incident summary',
    'shift' => 'Shift block',
    'resource' => 'Resource pool',
    _ => 'Title',
  };
}

IconData _iconFor(String type) {
  return switch (type) {
    'equipment' => Icons.precision_manufacturing_outlined,
    'incident' => Icons.report_problem_outlined,
    'shift' => Icons.calendar_month_outlined,
    'resource' => Icons.inventory_2_outlined,
    _ => Icons.assignment_outlined,
  };
}

Color _accentFor(String type) {
  return switch (type) {
    'equipment' => const Color(0xFF075D82),
    'incident' => const Color(0xFFC4492D),
    'shift' => const Color(0xFF2F7D57),
    'resource' => const Color(0xFFD99A1E),
    _ => const Color(0xFF536067),
  };
}

List<String> _statusOptionsFor(String type) {
  return switch (type) {
    'equipment' => ['Checked out', 'Reserved', 'Returned', 'Service hold'],
    'incident' => ['New', 'Assessing', 'Contained', 'Closed'],
    'shift' => ['Scheduled', 'Covered', 'Needs cover', 'Completed'],
    'resource' => ['Allocated', 'Low stock', 'Rebalanced', 'Ready'],
    _ => ['Open', 'Closed'],
  };
}

String _formatDate(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

final _starterRecords = [
  OpsRecord(
    id: 'starter_equipment_1',
    type: 'equipment',
    title: 'Inspection kit A17',
    owner: 'North site team',
    status: 'Reserved',
    priority: 'Normal',
    dueLabel: 'Today 17:00',
    notes: 'Ready for handoff after battery and cable check.',
    createdAt: DateTime(2026, 5, 12, 8, 15),
  ),
  OpsRecord(
    id: 'starter_shift_1',
    type: 'shift',
    title: 'Evening coverage',
    owner: 'Logistics desk',
    status: 'Scheduled',
    priority: 'High',
    dueLabel: '18:00-23:00',
    notes: 'Two coordinators assigned to dispatch and reception.',
    createdAt: DateTime(2026, 5, 12, 9, 30),
  ),
];

final _sampleRecords = [
  OpsRecord(
    id: 'sample_equipment_1',
    type: 'equipment',
    title: 'Tablet checkout batch',
    owner: 'Training room B',
    status: 'Checked out',
    priority: 'High',
    dueLabel: 'Return 16:30',
    notes:
        'Six tablets, chargers, and inventory tags assigned to the session lead.',
    createdAt: DateTime(2026, 5, 12, 7, 45),
  ),
  OpsRecord(
    id: 'sample_incident_1',
    type: 'incident',
    title: 'Loading bay access blocked',
    owner: 'Facilities response',
    status: 'Assessing',
    priority: 'Critical',
    dueLabel: 'Next check 10:15',
    notes:
        'Temporary route posted. Supervisor validating delivery timing impact.',
    createdAt: DateTime(2026, 5, 12, 8, 5),
  ),
  OpsRecord(
    id: 'sample_shift_1',
    type: 'shift',
    title: 'Front desk rotation',
    owner: 'Administration',
    status: 'Covered',
    priority: 'Normal',
    dueLabel: '12:00-18:00',
    notes:
        'Two-person coverage confirmed for visitor intake and phone response.',
    createdAt: DateTime(2026, 5, 12, 8, 20),
  ),
  OpsRecord(
    id: 'sample_resource_1',
    type: 'resource',
    title: 'Projector allocation',
    owner: 'Room 204',
    status: 'Allocated',
    priority: 'Normal',
    dueLabel: 'Until 15:00',
    notes:
        'Paired with HDMI adapters and extension cable from storage shelf 2.',
    createdAt: DateTime(2026, 5, 12, 8, 40),
  ),
  OpsRecord(
    id: 'sample_equipment_2',
    type: 'equipment',
    title: 'Maintenance radio set',
    owner: 'Operations desk',
    status: 'Service hold',
    priority: 'High',
    dueLabel: 'Review 14:00',
    notes: 'One handset has intermittent audio. Keep replacement ready.',
    createdAt: DateTime(2026, 5, 12, 9, 0),
  ),
  OpsRecord(
    id: 'sample_incident_2',
    type: 'incident',
    title: 'Late supplier arrival',
    owner: 'Procurement',
    status: 'Contained',
    priority: 'Normal',
    dueLabel: 'Close 17:00',
    notes: 'Receiving team adjusted unloading order and informed shift lead.',
    createdAt: DateTime(2026, 5, 12, 9, 25),
  ),
  OpsRecord(
    id: 'sample_shift_2',
    type: 'shift',
    title: 'Closing checklist',
    owner: 'Site supervisor',
    status: 'Needs cover',
    priority: 'High',
    dueLabel: '20:00-22:00',
    notes: 'Backup person required for final equipment count and room checks.',
    createdAt: DateTime(2026, 5, 12, 10, 5),
  ),
  OpsRecord(
    id: 'sample_resource_2',
    type: 'resource',
    title: 'Badge printer supplies',
    owner: 'Reception',
    status: 'Low stock',
    priority: 'High',
    dueLabel: 'Restock today',
    notes:
        'Ribbon inventory below threshold before the afternoon visitor block.',
    createdAt: DateTime(2026, 5, 12, 10, 30),
  ),
];
