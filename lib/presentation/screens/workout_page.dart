import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/workout_constants.dart';
import '../providers/workout_provider.dart';

class WorkoutPage extends StatefulWidget {
  final DateTime date;
  final String dayType;

  const WorkoutPage({
    super.key,
    required this.date,
    required this.dayType,
  });

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkoutProvider>().initialize(widget.date, widget.dayType);
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dayTypeName = WorkoutConstants.getDayTypeName(widget.dayType);
    final dayColor = Color(WorkoutConstants.DAY_TYPE_COLORS[widget.dayType] ?? 0xFF9E9E9E);

    return Scaffold(
      appBar: AppBar(
        title: Text(dayTypeName),
        centerTitle: true,
        backgroundColor: dayColor.withOpacity(0.2),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: _showPhotoOptions,
            tooltip: '拍照打卡',
          ),
        ],
      ),
      body: Consumer<WorkoutProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(provider.error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.initialize(widget.date, widget.dayType),
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          final record = provider.currentRecord;
          if (record == null) {
            return const Center(child: Text('暂无训练计划'));
          }

          return Column(
            children: [
              _buildHeader(record, dayColor),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: record.exercises.length + 1,
                  itemBuilder: (context, index) {
                    if (index == record.exercises.length) {
                      return _buildNotesSection(provider);
                    }
                    return _buildExerciseCard(record.exercises[index], index, provider, dayColor);
                  },
                ),
              ),
              if (record.photoUrl != null) _buildPhotoPreview(record.photoUrl!),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(record, Color dayColor) {
    final dateFormat = DateFormat('M月d日 E');
    final progress = record.progress;
    final completedCount = record.completedCount;
    final totalCount = record.totalCount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            dayColor.withOpacity(0.3),
            dayColor.withOpacity(0.1),
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateFormat.format(widget.date),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (record.isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text('已完成', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$completedCount / $totalCount',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: dayColor),
                    ),
                    const Text('已完成动作', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(dayColor),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: dayColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(exercise, int index, WorkoutProvider provider, Color dayColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: exercise.isCompleted ? 0 : 2,
      color: exercise.isCompleted ? Colors.green.withOpacity(0.1) : null,
      child: InkWell(
        onTap: () => provider.toggleExercise(index),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: exercise.isCompleted ? Colors.green : Colors.grey[300],
                ),
                child: Icon(
                  exercise.isCompleted ? Icons.check : Icons.fitness_center,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: exercise.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (exercise.sets != null || exercise.reps != null)
                      Text(
                        '${exercise.sets ?? ''}组 × ${exercise.reps ?? ''}次${exercise.weight != null ? ' @ ${exercise.weight}kg' : ''}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    if (exercise.duration != null)
                      Text(
                        '${exercise.duration} 分钟',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
              Checkbox(
                value: exercise.isCompleted,
                onChanged: (_) => provider.toggleExercise(index),
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotesSection(WorkoutProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          '训练笔记',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: '记录今天的训练感受...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[100],
          ),
          onChanged: (value) {
            // Debounce save
          },
          onEditingComplete: () {
            provider.setNotes(_notesController.text);
          },
        ),
      ],
    );
  }

  Widget _buildPhotoPreview(String photoUrl) {
    // 支持 base64 和 URL
    Widget imageWidget;
    if (photoUrl.startsWith('data:image')) {
      final base64Data = photoUrl.split(',').last;
      imageWidget = Image.memory(
        base64Decode(base64Data),
        height: 200,
        fit: BoxFit.cover,
      );
    } else {
      imageWidget = Image.network(
        photoUrl,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 200,
            color: Colors.grey[300],
            child: const Center(child: Icon(Icons.broken_image, size: 48)),
          );
        },
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: imageWidget,
      ),
    );
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '训练打卡',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('拍照打卡'),
              subtitle: const Text('记录今天的训练状态'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('从相册选择'),
              subtitle: const Text('选择已有照片'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _takePhoto() {
    // Web 端暂时用 base64 模拟
    // 实际需要 image_picker + Firebase Storage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Web 端暂不支持拍照，请使用相册选择或粘贴图片 URL')),
    );
  }

  void _pickFromGallery() {
    // Web 端暂时提示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('请在输入框粘贴图片 URL 或使用 Firebase Storage')),
    );
  }
}
