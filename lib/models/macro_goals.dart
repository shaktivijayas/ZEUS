class MacroGoals {
  const MacroGoals({required this.protein, required this.carbs, required this.fat});

  final int protein;
  final int carbs;
  final int fat;

  factory MacroGoals.fromMap(Map<String, dynamic> map) {
    return MacroGoals(
      protein: map['protein'] as int,
      carbs: map['carbs'] as int,
      fat: map['fat'] as int,
    );
  }

  Map<String, dynamic> toMap() => {'protein': protein, 'carbs': carbs, 'fat': fat};
}
