import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/ingredient.dart';
import '../../data/repositories/ingredient_repository.dart';

class IngredientPage extends StatefulWidget {
  const IngredientPage({super.key});

  @override
  State<IngredientPage> createState() => _IngredientPageState();
}

class _IngredientPageState extends State<IngredientPage> {
  final IngredientRepository _repo = IngredientRepository();
  final _uuid = const Uuid();

  List<Ingredient> _ingredients = [];
  String _searchKeyword = '';
  String _selectedCategory = 'all';
  bool _isFetchingBarcode = false;

  @override
  void initState() {
    super.initState();
    _loadIngredients();
  }

  void _loadIngredients() {
    setState(() {
      if (_searchKeyword.isNotEmpty) {
        _ingredients = _repo.searchIngredients(_searchKeyword);
      } else if (_selectedCategory != 'all') {
        _ingredients = _repo.getIngredientsByCategory(_selectedCategory);
      } else {
        _ingredients = _repo.getAllIngredients();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('食材库管理'),
        actions: [
          IconButton(
            icon: _isFetchingBarcode
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.qr_code_scanner),
            tooltip: '扫码添加',
            onPressed: _isFetchingBarcode ? null : _scanBarcodeAndAddIngredient,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '手动添加',
            onPressed: _showAddDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategoryFilter(),
          Expanded(child: _buildIngredientList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          hintText: '搜索食材',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          suffixIcon: _searchKeyword.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchKeyword = '';
                    _loadIngredients();
                  },
                )
              : null,
        ),
        onChanged: (value) {
          _searchKeyword = value;
          _loadIngredients();
        },
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SingleChildScrollView(
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
          _loadIngredients();
        },
      ),
    );
  }

  Widget _buildIngredientList() {
    if (_ingredients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('暂无食材，点右上角添加'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _showAddDialog,
              child: const Text('添加食材'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _ingredients.length,
      itemBuilder: (context, index) {
        final ingredient = _ingredients[index];
        return _buildIngredientCard(ingredient);
      },
    );
  }

  Widget _buildIngredientCard(Ingredient ingredient) {
    final categoryName = ingredient.category == 'carb'
        ? '碳水类'
        : ingredient.category == 'protein'
            ? '蛋白质类'
            : '脂肪类';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Row(
          children: [
            Text(ingredient.name),
            if (ingredient.isCommon)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('常用', style: TextStyle(fontSize: 10)),
              ),
          ],
        ),
        subtitle: Text(
          '每100g: ${ingredient.carbPer100g.toStringAsFixed(1)}c '
          '${ingredient.proteinPer100g.toStringAsFixed(1)}p '
          '${ingredient.fatPer100g.toStringAsFixed(1)}f',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ingredient.category == 'carb'
                    ? Colors.orange[50]
                    : ingredient.category == 'protein'
                        ? Colors.red[50]
                        : Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(categoryName, style: const TextStyle(fontSize: 12)),
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showEditDialog(ingredient),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog() {
    _showIngredientDialog(null);
  }

  void _showEditDialog(Ingredient ingredient) {
    _showIngredientDialog(ingredient);
  }

  void _showIngredientDialog(Ingredient? ingredient) {
    final isEdit = ingredient != null;
    final focusNode = FocusNode();
    final nameController = TextEditingController(text: ingredient?.name ?? '');
    final carbController = TextEditingController(
      text: ingredient?.carbPer100g.toString() ?? '',
    );
    final proteinController = TextEditingController(
      text: ingredient?.proteinPer100g.toString() ?? '',
    );
    final fatController = TextEditingController(
      text: ingredient?.fatPer100g.toString() ?? '',
    );
    String category = ingredient?.category ?? 'carb';
    bool isCommon = ingredient?.isCommon ?? false;
    bool isCooked = ingredient?.isCooked ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (focusNode.canRequestFocus) {
              focusNode.requestFocus();
            }
          });
          return AlertDialog(
            title: Text(isEdit ? '编辑食材' : '添加食材'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    focusNode: focusNode,
                    decoration: const InputDecoration(labelText: '食材名称'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(labelText: '类别'),
                    items: const [
                      DropdownMenuItem(value: 'carb', child: Text('碳水类')),
                      DropdownMenuItem(value: 'protein', child: Text('蛋白质类')),
                      DropdownMenuItem(value: 'fat', child: Text('脂肪类')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        category = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: carbController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '碳水 (g/100g)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: proteinController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '蛋白质 (g/100g)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: fatController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '脂肪 (g/100g)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: isCommon,
                        onChanged: (value) {
                          setDialogState(() {
                            isCommon = value!;
                          });
                        },
                      ),
                      const Text('常用食材'),
                    ],
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: isCooked,
                        onChanged: (value) {
                          setDialogState(() {
                            isCooked = value!;
                          });
                        },
                      ),
                      const Text('熟食'),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final carb = double.tryParse(carbController.text) ?? 0;
                  final protein = double.tryParse(proteinController.text) ?? 0;
                  final fat = double.tryParse(fatController.text) ?? 0;

                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('请输入食材名称')),
                    );
                    return;
                  }

                  final newIngredient = Ingredient(
                    id: ingredient?.id ?? _uuid.v4(),
                    name: name,
                    category: category,
                    carbPer100g: carb,
                    proteinPer100g: protein,
                    fatPer100g: fat,
                    isCommon: isCommon,
                    isCooked: isCooked,
                  );

                  if (isEdit) {
                    await _repo.updateIngredient(newIngredient);
                  } else {
                    await _repo.insertIngredient(newIngredient);
                  }

                  Navigator.pop(context);
                  _loadIngredients();
                },
                child: Text(isEdit ? '保存' : '添加'),
              ),
            ],
          );
        },
      ),
    );
    focusNode.dispose();
  }

  Future<void> _scanBarcodeAndAddIngredient() async {
    setState(() {
      _isFetchingBarcode = true;
    });

    try {
      final barcode = await _scanBarcodeWithCamera();
      if (barcode == null || barcode.isEmpty) {
        // 用户取消扫码
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('正在查询: $barcode'),
          duration: const Duration(seconds: 1),
        ),
      );

      final food = await _fetchFoodFromOpenFoodFacts(barcode);
      if (food == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('未查询到该条码对应食品，请尝试手动添加'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      final ingredient = Ingredient(
        id: 'barcode_$barcode',
        name: food.productName,
        category: _inferCategory(
          carb: food.carbPer100g,
          protein: food.proteinPer100g,
          fat: food.fatPer100g,
        ),
        carbPer100g: food.carbPer100g,
        proteinPer100g: food.proteinPer100g,
        fatPer100g: food.fatPer100g,
        isCommon: true,
      );

      await _repo.insertIngredient(ingredient);
      _loadIngredients();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已扫码添加: ${ingredient.name}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      String errorMessage = '扫码添加失败';
      if (e.toString().contains('超时')) {
        errorMessage = '网络超时，请检查网络后重试';
      } else if (e.toString().contains('network')) {
        errorMessage = '网络错误，请检查网络连接';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), duration: const Duration(seconds: 3)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingBarcode = false;
        });
      }
    }
  }

  Future<String?> _scanBarcodeWithCamera() async {
    final controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );

    String? scannedCode;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          child: SizedBox(
            width: 420,
            height: 520,
            child: Stack(
              children: [
                MobileScanner(
                  controller: controller,
                  onDetect: (capture) {
                    if (scannedCode != null) return;
                    final code = capture.barcodes.first.rawValue;
                    if (code == null || code.trim().isEmpty) return;
                    scannedCode = code.trim();
                    Navigator.of(dialogContext).pop();
                  },
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                    ),
                  ),
                ),
                Center(
                  child: IgnorePointer(
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    await controller.dispose();
    return scannedCode;
  }

  Future<_OpenFoodFactsProduct?> _fetchFoodFromOpenFoodFacts(
    String barcode,
  ) async {
    try {
      final uri = Uri.parse(
        'https://world.openfoodfacts.org/api/v0/product/$barcode.json',
      );

      // 设置10秒超时，避免请求无限等待
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('网络请求超时，请检查网络连接');
        },
      );

      if (response.statusCode != 200) {
        print('[OpenFoodFacts] HTTP错误: ${response.statusCode}');
        return null;
      }

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) {
        print('[OpenFoodFacts] 响应格式错误: $body');
        return null;
      }

      final status = body['status'];
      if (status is! num || status.toInt() != 1) {
        final statusVerbose = body['status_verbose'] ?? 'unknown';
        print('[OpenFoodFacts] 产品未找到: $statusVerbose (barcode: $barcode)');
        return null;
      }

      final product = body['product'];
      if (product is! Map) {
        print('[OpenFoodFacts] 产品数据格式错误');
        return null;
      }
      final productMap = Map<String, dynamic>.from(product);

      final nutrimentsRaw = productMap['nutriments'];
      final nutriments = nutrimentsRaw is Map
          ? Map<String, dynamic>.from(nutrimentsRaw)
          : <String, dynamic>{};

      // 尝试多种语言的产品名称，优先中文
      final productName = (productMap['product_name_zh'] as String?)?.trim() ??
          (productMap['product_name_en'] as String?)?.trim() ??
          (productMap['product_name'] as String?)?.trim() ??
          (productMap['product_name_fr'] as String?)?.trim() ??
          '';
      if (productName.isEmpty) {
        print('[OpenFoodFacts] 产品名称为空');
        return null;
      }

      return _OpenFoodFactsProduct(
        productName: productName,
        carbPer100g: _toDouble(nutriments['carbohydrates_100g']) ?? 0,
        proteinPer100g: _toDouble(nutriments['proteins_100g']) ?? 0,
        fatPer100g: _toDouble(nutriments['fat_100g']) ?? 0,
      );
    } catch (e) {
      print('[OpenFoodFacts] 请求异常: $e');
      // 重新抛出以便上层处理
      rethrow;
    }
  }

  String _inferCategory({
    required double carb,
    required double protein,
    required double fat,
  }) {
    if (protein >= carb && protein >= fat) return 'protein';
    if (fat >= carb && fat >= protein) return 'fat';
    return 'carb';
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class _OpenFoodFactsProduct {
  final String productName;
  final double carbPer100g;
  final double proteinPer100g;
  final double fatPer100g;

  const _OpenFoodFactsProduct({
    required this.productName,
    required this.carbPer100g,
    required this.proteinPer100g,
    required this.fatPer100g,
  });
}
