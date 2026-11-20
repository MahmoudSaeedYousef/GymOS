class PlanModel {
  final String id;
  final String name;
  final String? description;
  final double price;
  final int durationInDays;
  final bool isActive;
  final int? maxSessions;

  const PlanModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.durationInDays,
    this.isActive = true,
    this.maxSessions,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) => PlanModel(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    description: json['description']?.toString(),
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    durationInDays: (json['durationInDays'] as num?)?.toInt() ?? 30,
    isActive: json['isActive'] as bool? ?? true,
    maxSessions: (json['maxSessions'] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'durationInDays': durationInDays,
    'isActive': isActive,
    'maxSessions': maxSessions,
  };

  PlanModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    int? durationInDays,
    bool? isActive,
    int? maxSessions,
  }) {
    return PlanModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      durationInDays: durationInDays ?? this.durationInDays,
      isActive: isActive ?? this.isActive,
      maxSessions: maxSessions ?? this.maxSessions,
    );
  }
}
