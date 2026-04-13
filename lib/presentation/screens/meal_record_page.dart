import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/supabase/supabase_config.dart';
import '../../core/utils/nutrition_calculator.dart';
import '../../data/models/daily_meal_record.dart';
import '../../data/models/ingredient.dart';
import '../../data/models/meal_item_record.dart';
import '../../data/repositories/daily_record_repository.dart';
import '../providers/diet_provider.dart';

class MealRecordPage extends StatefulWidget {
  final int mealOrder;

  const MealRecordPage({super.key, required this.mealOrder});

  @override
  State<MealRecordPage> createState() => _MealRecordPageState();
}

class _MealRecordPageState extends State<MealRecordPage> {
  static const String _imageBucket = 'image';

  final List<_SelectedItem> _selectedItems = [];
  final _searchController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _dailyRecordRepo = DailyRecordRepository();
  String _selectedCategory = 'all';
  String? _photoUrl;
  Uint8List? _photoPreviewBytes;
  bool _isUploadingPhoto = false;
  final _uuid = const Uuid();
  bool _isDataLoaded = false;

  @override
  void dispose() {
    _searchController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// 加载已保存的食材与元数据
  void _loadExistingMealData(DailyMealRecord meal) {
    if (_isDataLoaded) return;
    _isDataLoaded = true;

    _photoUrl = meal.photoUrl;
    _notesController.text = meal.notes ?? '';

    final existingItems = _dailyRecordRepo.getMealItems(meal.id);
    if (existingItems.isNotEmpty) {
      setState(() {
        for (final item in existingItems) {
          final per100Factor = item.amount <= 0 ? 1 : item.amount / 100;
          final ingredient = Ingredient(
            id: item.ingredientId ?? '',
            name: item.ingredientName,
            category: 'carb',
            carbPer100g: item.carb / per100Factor,
            proteinPer100g: item.protein / per100Factor,
            fatPer100g: item.fat / per100Factor,
          );
          _selectedItems.add(_SelectedItem(
            ingredient: ingredient,
            amount: item.amount,
            nutrition: NutritionData(
              carb: item.carb,
              protein: item.protein,
              fat: item.fat,
            ),
            itemId: item.id, // 保留 itemId 用于删除
          ));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('第${widget.mealOrder}餐记录'),
        actions: [
          IconButton(
            icon: Icon(_photoUrl != null ? Icons.photo : Icons.photo_camera),
            onPressed: _takePhoto,
            tooltip: '拍照打卡',
          ),
        ],
      ),
      bottomNavigationBar: Consumer<DietProvider>(
        builder: (context, provider, child) {
          final meal = provider.getMealRecord(widget.mealOrder);
          if (meal == null) return const SizedBox.shrink();
          return _buildBottomActionBar(provider);
        },
      ),
      body: Consumer<DietProvider>(
        builder: (context, provider, child) {
          final meal = provider.getMealRecord(widget.mealOrder);
          if (meal == null) {
            return const Center(child: Text('餐次信息不存在'));
          }

          // 加载已保存的食材记录
          _loadExistingMealData(meal);

          return Column(
            children: [
              // 餐次信息
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMealInfo(
                        '预设碳水', '${meal.plannedCarb.toStringAsFixed(0)}g'),
                    _buildMealInfo(
                        '预设蛋白', '${meal.plannedProtein.toStringAsFixed(0)}g'),
                    _buildMealInfo(
                        '预设脂肪', '${meal.plannedFat.toStringAsFixed(0)}g'),
                  ],
                ),
              ),

              _buildPhotoCheckinArea(),

              // 已选食材（限制高度，可滚动）
              if (_selectedItems.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '已选食材',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${_selectedItems.length}项',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _selectedItems.length,
                          itemBuilder: (context, index) =>
                              _buildSelectedItem(_selectedItems[index]),
                        ),
                      ),
                    ],
                  ),
                ),

              // 实时营养素计算
              _buildNutritionPreview(),

              // 食材搜索和选择（占据剩余空间）
              Expanded(
                child: _buildIngredientSelector(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMealInfo(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSelectedItem(_SelectedItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(item.ingredient.name),
        subtitle: Text('${item.amount.toStringAsFixed(0)}g'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${item.nutrition.carb.toStringAsFixed(0)}c '
                '${item.nutrition.protein.toStringAsFixed(0)}p '
                '${item.nutrition.fat.toStringAsFixed(0)}f'),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setState(() {
                  _selectedItems.remove(item);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionPreview() {
    NutritionData total = const NutritionData(carb: 0, protein: 0, fat: 0);
    for (final item in _selectedItems) {
      total = total + item.nutrition;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNutritionChip('碳水', total.carb, Colors.orange),
          _buildNutritionChip('蛋白质', total.protein, Colors.red),
          _buildNutritionChip('脂肪', total.fat, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildPhotoCheckinArea() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.photo_camera, size: 18),
                  SizedBox(width: 6),
                  Text(
                    '图片打卡',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _isUploadingPhoto ? null : _takePhoto,
                icon: const Icon(Icons.upload, size: 16),
                label: Text(_photoUrl == null ? '上传图片' : '重新上传'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_photoUrl == null)
            const Text(
              '未上传图片，可用于记录当天餐饮状态。',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          if (_photoUrl != null)
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: _photoPreviewBytes != null
                      ? MemoryImage(_photoPreviewBytes!)
                      : NetworkImage(_photoUrl!) as ImageProvider,
                  fit: BoxFit.cover,
                ),
              ),
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _photoUrl = null;
                      _photoPreviewBytes = null;
                    });
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNutritionChip(String label, double value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '${value.toStringAsFixed(0)}g',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientSelector(DietProvider provider) {
    return Column(
      children: [
        // 搜索框
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '搜索食材',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        provider.searchIngredients('');
                      },
                    )
                  : null,
            ),
            onChanged: (value) => provider.searchIngredients(value),
          ),
        ),

        // 类别筛选
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildCategoryChip('全部', 'all'),
              _buildCategoryChip('碳水类', 'carb'),
              _buildCategoryChip('蛋白质类', 'protein'),
              _buildCategoryChip('脂肪类', 'fat'),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // 食材列表
        Expanded(
          child: provider.filteredIngredients.isEmpty
              ? const Center(child: Text('暂无食材，请先添加'))
              : ListView.builder(
                  itemCount: provider.filteredIngredients.length,
                  itemBuilder: (context, index) {
                    final ingredient = provider.filteredIngredients[index];
                    return ListTile(
                      title: Text(ingredient.name),
                      subtitle: Text(
                        '每100g: ${ingredient.carbPer100g.toStringAsFixed(0)}c '
                        '${ingredient.proteinPer100g.toStringAsFixed(0)}p '
                        '${ingredient.fatPer100g.toStringAsFixed(0)}f',
                      ),
                      trailing: const Icon(Icons.add_circle_outline),
                      onTap: () => _showAddIngredientDialog(
                          context, provider, ingredient),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String label, String category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
          });
          context.read<DietProvider>().filterByCategory(category);
        },
      ),
    );
  }

  void _showAddIngredientDialog(
    BuildContext context,
    DietProvider provider,
    Ingredient ingredient,
  ) {
    final focusNode = FocusNode();
    _amountController.text = '';

    showDialog(
      context: context,
      builder: (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (focusNode.canRequestFocus) {
            focusNode.requestFocus();
          }
        });
        return AlertDialog(
          title: Text('添加 ${ingredient.name}'),
          content: TextField(
            controller: _amountController,
            focusNode: focusNode,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '克数 (g)',
              hintText: '例如: 100',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(_amountController.text);
                if (amount != null && amount > 0) {
                  final nutrition =
                      provider.calculateIngredientNutrition(ingredient, amount);
                  setState(() {
                    _selectedItems.add(_SelectedItem(
                      ingredient: ingredient,
                      amount: amount,
                      nutrition: nutrition,
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('添加'),
            ),
          ],
        );
      },
    );
    focusNode.dispose();
  }

  Future<void> _takePhoto() async {
    final provider = context.read<DietProvider>();
    final meal = provider.getMealRecord(widget.mealOrder);
    if (meal == null) return;

    try {
      setState(() {
        _isUploadingPhoto = true;
      });

      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = 'uploads/${meal.recordDate}_$timestamp.jpg';

      await SupabaseConfig.client.storage
          .from(_imageBucket)
          .uploadBinary(filePath, bytes);

      final publicUrl = SupabaseConfig.client.storage
          .from(_imageBucket)
          .getPublicUrl(filePath);
      setState(() {
        _photoUrl = publicUrl;
        _photoPreviewBytes = bytes;
      });

      await _saveMealMeta(provider, meal.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('图片上传并关联记录成功')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('图片上传失败: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
      }
    }
  }

  Widget _buildSaveButton(DietProvider provider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isDataLoaded ? () => _saveMeal(provider) : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text('保存记录', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildBottomActionBar(DietProvider provider) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: '添加备注',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 8),
            _buildSaveButton(provider),
          ],
        ),
      ),
    );
  }

  Future<void> _saveMeal(DietProvider provider) async {
    final meal = provider.getMealRecord(widget.mealOrder);
    if (meal == null) return;

    final allItems = _selectedItems
        .map((item) => MealItemRecord(
              id: _uuid.v4(),
              dailyMealRecordId: meal.id,
              ingredientId:
                  item.ingredient.id.isNotEmpty ? item.ingredient.id : null,
              ingredientName: item.ingredient.name,
              amount: item.amount,
              carb: item.nutrition.carb,
              protein: item.nutrition.protein,
              fat: item.nutrition.fat,
              isManualInput: false,
            ))
        .toList();

    await _dailyRecordRepo.replaceMealItems(meal.id, allItems);
    await provider.loadDailyStatus();
    await _saveMealMeta(provider, meal.id);

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('记录保存成功')),
    );
  }

  Future<void> _saveMealMeta(DietProvider provider, String mealId) async {
    final latestMeal = _dailyRecordRepo.getMealRecordById(mealId) ??
        provider.getMealRecord(widget.mealOrder);
    if (latestMeal == null) return;

    final targetPhoto =
        (_photoUrl?.trim().isEmpty ?? true) ? null : _photoUrl!.trim();
    final noteText = _notesController.text.trim();
    final targetNotes = noteText.isEmpty ? null : noteText;

    if (latestMeal.photoUrl == targetPhoto && latestMeal.notes == targetNotes) {
      return;
    }

    final updatedMeal = latestMeal.copyWith(
      photoUrl: targetPhoto,
      notes: targetNotes,
      updatedAt: DateTime.now(),
    );
    await _dailyRecordRepo.updateMealActual(updatedMeal);
    await provider.loadDailyStatus();
  }
}

class _SelectedItem {
  final Ingredient ingredient;
  final double amount;
  final NutritionData nutrition;
  final String? itemId; // 如果有值，说明是已保存的记录

  _SelectedItem({
    required this.ingredient,
    required this.amount,
    required this.nutrition,
    this.itemId,
  });
}
