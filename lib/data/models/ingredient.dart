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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'carbPer100g': carbPer100g,
      'proteinPer100g': proteinPer100g,
      'fatPer100g': fatPer100g,
      'isCooked': isCooked,
      'isCommon': isCommon,
      'remainingAmount': remainingAmount,
      'unit': unit,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      carbPer100g: (map['carbPer100g'] as num).toDouble(),
      proteinPer100g: (map['proteinPer100g'] as num).toDouble(),
      fatPer100g: (map['fatPer100g'] as num).toDouble(),
      isCooked: map['isCooked'] as bool? ?? false,
      isCommon: map['isCommon'] as bool? ?? false,
      remainingAmount: (map['remainingAmount'] as num?)?.toDouble(),
      unit: map['unit'] as String? ?? 'g',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now(),
    );
  }
}
