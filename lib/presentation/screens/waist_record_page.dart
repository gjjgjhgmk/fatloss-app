import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/waist_record.dart';
import '../../data/repositories/waist_record_repository.dart';

class WaistRecordPage extends StatefulWidget {
  const WaistRecordPage({super.key});

  @override
  State<WaistRecordPage> createState() => _WaistRecordPageState();
}

class _WaistRecordPageState extends State<WaistRecordPage> {
  final WaistRecordRepository _repo = WaistRecordRepository();
  String _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  WaistRecord? _record;

  @override
  void initState() {
    super.initState();
    _loadRecord();
  }

  void _loadRecord() {
    setState(() {
      _record = _repo.getWaistRecordForDate(_selectedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('腰围记录'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateHeader(),
            const SizedBox(height: 24),
            _buildWaistCard(),
            const SizedBox(height: 24),
            _buildTrendButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader() {
    final date = DateTime.parse(_selectedDate);
    final displayDate = DateFormat('M月d日 E').format(date);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayDate,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Text(
                '早上空腹测量',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
          TextButton(
            onPressed: _selectDate,
            child: const Text('选择日期'),
          ),
        ],
      ),
    );
  }

  Widget _buildWaistCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.straighten, size: 48, color: Colors.blue),
            const SizedBox(height: 16),
            if (_record != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _record!.waist.toStringAsFixed(1),
                    style: const TextStyle(
                        fontSize: 48, fontWeight: FontWeight.bold),
                  ),
                  const Text(' cm', style: TextStyle(fontSize: 18)),
                ],
              ),
              if (_record!.recordTime != null)
                Center(
                  child: Text(
                    '记录时间: ${_record!.recordTime}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _showEditDialog,
                  child: const Text('修改'),
                ),
              ),
            ] else ...[
              const Text(
                '今日尚未记录',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _showAddDialog,
                icon: const Icon(Icons.add),
                label: const Text('添加记录'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrendButton() {
    return Center(
      child: TextButton(
        onPressed: _showTrend,
        child: const Text('查看趋势'),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_selectedDate),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date != null) {
      _selectedDate = DateFormat('yyyy-MM-dd').format(date);
      _loadRecord();
    }
  }

  void _showAddDialog() {
    final waistController = TextEditingController();
    final focusNode = FocusNode();
    final timeController = TextEditingController(
      text: DateFormat('HH:mm').format(DateTime.now()),
    );

    showDialog(
      context: context,
      builder: (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (focusNode.canRequestFocus) {
            focusNode.requestFocus();
          }
        });
        return AlertDialog(
          title: const Text('记录腰围'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: waistController,
                focusNode: focusNode,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: '腰围 (cm)',
                  hintText: '例如: 85.5',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(
                  labelText: '时间 (HH:mm)',
                  hintText: '例如: 08:30',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                final waist = double.tryParse(waistController.text);
                if (waist != null && waist > 0) {
                  final record = WaistRecord(
                    id: _selectedDate,
                    recordDate: _selectedDate,
                    waist: waist,
                    recordTime: timeController.text.isNotEmpty
                        ? timeController.text
                        : null,
                  );
                  await _repo.saveWaistRecord(record);
                  Navigator.pop(context);
                  _loadRecord();
                }
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );

    focusNode.dispose();
  }

  void _showEditDialog() {
    if (_record == null) return;

    final waistController =
        TextEditingController(text: _record!.waist.toString());
    final focusNode = FocusNode();
    final timeController =
        TextEditingController(text: _record!.recordTime ?? '');

    showDialog(
      context: context,
      builder: (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (focusNode.canRequestFocus) {
            focusNode.requestFocus();
          }
        });
        return AlertDialog(
          title: const Text('修改腰围记录'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: waistController,
                focusNode: focusNode,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: '腰围 (cm)'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(labelText: '时间 (HH:mm)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await _repo.deleteWaistRecord(_selectedDate);
                Navigator.pop(context);
                _loadRecord();
              },
              child: const Text('删除', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                final waist = double.tryParse(waistController.text);
                if (waist != null && waist > 0) {
                  final updated = _record!.copyWith(
                    waist: waist,
                    recordTime: timeController.text.isNotEmpty
                        ? timeController.text
                        : null,
                    updatedAt: DateTime.now(),
                  );
                  await _repo.saveWaistRecord(updated);
                  Navigator.pop(context);
                  _loadRecord();
                }
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );

    focusNode.dispose();
  }

  void _showTrend() {
    final records = _repo.getAllWaistRecords();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                '腰围历史记录',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: records.isEmpty
                  ? const Center(child: Text('暂无记录'))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: records.length,
                      itemBuilder: (context, index) {
                        final record = records[index];
                        return ListTile(
                          title: Text('${record.waist.toStringAsFixed(1)} cm'),
                          subtitle: Text(record.recordDate),
                          trailing: record.recordTime != null
                              ? Text(record.recordTime!)
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
