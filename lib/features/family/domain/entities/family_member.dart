class FamilyMember {
  final String id;
  final String name;
  final String relationship;
  final double monthlyIncome;

  const FamilyMember({
    required this.id,
    required this.name,
    required this.relationship,
    required this.monthlyIncome,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'relationship': relationship,
    'monthlyIncome': monthlyIncome,
  };

  factory FamilyMember.fromMap(Map<String, dynamic> map) => FamilyMember(
    id: map['id'] as String,
    name: map['name'] as String,
    relationship: map['relationship'] as String,
    monthlyIncome: (map['monthlyIncome'] as num).toDouble(),
  );
}
