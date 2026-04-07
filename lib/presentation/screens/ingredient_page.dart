import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
            icon: const Icon(Icons.add),
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
            const Text('暂无食材，点击右上角添加'),
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
          '每100g: ${ingredient.carbPer100g.toStringAsFixed(0)}c '
          '${ingredient.proteinPer100g.toStringAsFixed(0)}p '
          '${ingredient.fatPer100g.toStringAsFixed(0)}f',
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
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? '编辑食材' : '添加食材'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
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
        ),
      ),
    );
  }
}
