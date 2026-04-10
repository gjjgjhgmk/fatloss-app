import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/supabase/supabase_config.dart';
import '../../data/models/weight_record.dart';
import '../../data/repositories/weight_record_repository.dart';

class WeightRecordPage extends StatefulWidget {
  const WeightRecordPage({super.key});

  @override
  State<WeightRecordPage> createState() => _WeightRecordPageState();
}

class _WeightRecordPageState extends State<WeightRecordPage> {
  static const String _imageBucket = 'image';

  final WeightRecordRepository _repo = WeightRecordRepository();
  String _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  WeightRecord? _morningRecord;
  WeightRecord? _eveningRecord;
  String? _uploadingRecordId;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  void _loadRecords() {
    setState(() {
      _morningRecord = _repo.getMorningWeight(_selectedDate);
      _eveningRecord = _repo.getEveningWeight(_selectedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('体重打卡'),
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
            _buildWeightCard('早上空腹', 'morning', _morningRecord),
            const SizedBox(height: 16),
            _buildWeightCard('晚上睡前', 'evening', _eveningRecord),
            const SizedBox(height: 24),
            _buildHistoryButton(),
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
          Text(
            displayDate,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          TextButton(
            onPressed: _selectDate,
            child: const Text('选择日期'),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightCard(String label, String timeOfDay, WeightRecord? record) {
    final photoUrl = _extractPhotoUrl(record?.notes);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  timeOfDay == 'morning' ? Icons.wb_sunny : Icons.nights_stay,
                  color: timeOfDay == 'morning' ? Colors.orange : Colors.indigo,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (record != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    record.weight.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                  ),
                  const Text(' kg', style: TextStyle(fontSize: 18)),
                ],
              ),
              if (record.recordTime != null)
                Center(
                  child: Text(
                    '记录时间: ${record.recordTime}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              if (photoUrl != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    photoUrl,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 140,
                      color: Colors.grey[300],
                      alignment: Alignment.center,
                      child: const Text('图片加载失败'),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Center(
                child: Wrap(
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => _showEditDialog(timeOfDay, record),
                      child: const Text('修改'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _uploadingRecordId == record.id
                          ? null
                          : () => _uploadBodyPhoto(record),
                      icon: const Icon(Icons.photo_camera, size: 16),
                      label: Text(
                        _uploadingRecordId == record.id ? '上传中...' : '图片打卡',
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => _showAddDialog(timeOfDay),
                  icon: const Icon(Icons.add),
                  label: const Text('添加记录'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryButton() {
    return Center(
      child: TextButton(
        onPressed: _showHistory,
        child: const Text('查看历史记录'),
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
      _loadRecords();
    }
  }

  void _showAddDialog(String timeOfDay) {
    final weightController = TextEditingController();
    final timeController = TextEditingController(
      text: timeOfDay == 'morning'
          ? DateFormat('HH:mm').format(DateTime.now())
          : '22:00',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('记录${timeOfDay == 'morning' ? '早上' : '晚上'}体重'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '体重 (kg)',
                hintText: '例如: 80.5',
              ),
              autofocus: true,
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
              final weight = double.tryParse(weightController.text);
              if (weight != null && weight > 0) {
                final id = '${_selectedDate}_$timeOfDay';
                final record = WeightRecord(
                  id: id,
                  recordDate: _selectedDate,
                  timeOfDay: timeOfDay,
                  weight: weight,
                  recordTime: timeController.text.isNotEmpty ? timeController.text : null,
                );
                await _repo.saveWeightRecord(record);
                Navigator.pop(context);
                _loadRecords();
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(String timeOfDay, WeightRecord record) {
    final weightController = TextEditingController(text: record.weight.toString());
    final timeController = TextEditingController(text: record.recordTime ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改体重记录'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: '体重 (kg)'),
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
              await _repo.deleteWeightRecord(record.id);
              Navigator.pop(context);
              _loadRecords();
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final weight = double.tryParse(weightController.text);
              if (weight != null && weight > 0) {
                final updated = record.copyWith(
                  weight: weight,
                  recordTime: timeController.text.isNotEmpty ? timeController.text : null,
                  updatedAt: DateTime.now(),
                );
                await _repo.saveWeightRecord(updated);
                Navigator.pop(context);
                _loadRecords();
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showHistory() {
    final records = _repo.getAllWeightRecords();
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
                '体重历史记录',
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
                          title: Text('${record.weight.toStringAsFixed(1)} kg'),
                          subtitle: Text('${record.recordDate} ${record.displayTime}'),
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

  String? _extractPhotoUrl(String? notes) {
    if (notes == null || notes.isEmpty) return null;
    final value = notes.trim();
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    return null;
  }

  Future<void> _uploadBodyPhoto(WeightRecord record) async {
    try {
      setState(() {
        _uploadingRecordId = record.id;
      });

      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final path = 'uploads/weight_${record.recordDate}_${record.timeOfDay}_$ts.jpg';

      await SupabaseConfig.client.storage
          .from(_imageBucket)
          .uploadBinary(path, bytes);

      final url = SupabaseConfig.client.storage
          .from(_imageBucket)
          .getPublicUrl(path);

      final updated = record.copyWith(
        notes: url,
        updatedAt: DateTime.now(),
      );
      await _repo.saveWeightRecord(updated);
      _loadRecords();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('体重打卡图片上传成功')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('图片上传失败: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _uploadingRecordId = null;
        });
      }
    }
  }
}
