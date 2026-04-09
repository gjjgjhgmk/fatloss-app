import 'package:hive/hive.dart';

part 'ingredient.g.dart';

@HiveType(typeId: 2)
class Ingredient extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String category; // carb, protein, fat

  @HiveField(3)
  final double carbPer100g;

  @HiveField(4)
  final double proteinPer100g;

  @HiveField(5)
  final double fatPer100g;

  @HiveField(6)
  final bool isCooked;

  @HiveField(7)
  final bool isCommon;

  @HiveField(8)
  final double? remainingAmount;

  @HiveField(9)
  final String unit;

  @HiveField(10)
  final DateTime createdAt;

  @HiveField(11)
  final DateTime updatedAt;

  Ingredient({
    required this.id,
    required this.name,
    required this.category,
    required this.carbPer100g,
    required this.proteinPer100g,
    required this.fatPer100g,
    this.isCooked = false,
    this.isCommon = false,
    this.remainingAmount,
    this.unit = 'g',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Ingredient copyWith({
    String? id,
    String? name,
    String? category,
    double? carbPer100g,
    double? proteinPer100g,
    double? fatPer100g,
    bool? isCooked,
    bool? isCommon,
    double? remainingAmount,
    String? unit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Ingredient(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      carbPer100g: carbPer100g ?? this.carbPer100g,
      proteinPer100g: proteinPer100g ?? this.proteinPer100g,
      fatPer100g: fatPer100g ?? this.fatPer100g,
      isCooked: isCooked ?? this.isCooked,
      isCommon: isCommon ?? this.isCommon,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      unit: unit ?? this.unit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap({bool includeRemainingAmount = true}) {
    final Map<String, dynamic> map = {
      'id': id,
      'name': name,
      'category': category,
      'carb_per_100g': carbPer100g,
      'protein_per_100g': proteinPer100g,
      'fat_per_100g': fatPer100g,
      'is_cooked': isCooked,
      'is_common': isCommon,
      'unit': unit,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };

    // 兼容线上旧表结构：只有在需要时才同步库存字段。
    if (includeRemainingAmount) {
      map['remaining_amount'] = remainingAmount;
    }

    return map;
  }

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      carbPer100g: (map['carb_per_100g'] as num).toDouble(),
      proteinPer100g: (map['protein_per_100g'] as num).toDouble(),
      fatPer100g: (map['fat_per_100g'] as num).toDouble(),
      isCooked: map['is_cooked'] == true || map['is_cooked'] == 1,
      isCommon: map['is_common'] == true || map['is_common'] == 1,
      remainingAmount: (map['remaining_amount'] as num?)?.toDouble(),
      unit: map['unit'] as String? ?? 'g',
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : DateTime.now(),
    );
  }
}
