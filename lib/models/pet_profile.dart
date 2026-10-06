/// A pet saved on the user's account (server: `user.pets[]`).
class PetProfile {
  final String id;
  final String name;
  final String type;
  final String breed;
  final String age;
  final String weight;

  const PetProfile({
    required this.id,
    required this.name,
    required this.type,
    this.breed = '',
    this.age = '',
    this.weight = '',
  });

  factory PetProfile.fromJson(Map<String, dynamic> json) {
    return PetProfile(
      id: (json['id'] ?? '').toString(),
      name: json['name'] ?? '',
      type: json['type'] ?? 'Other',
      breed: json['breed'] ?? '',
      age: json['age'] ?? '',
      weight: json['weight'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'breed': breed,
    'age': age,
    'weight': weight,
  };

  /// Body for create/update requests (the server owns `id`).
  Map<String, dynamic> toRequest() => {
    'name': name,
    'type': type,
    'breed': breed,
    'age': age,
    'weight': weight,
  };

  /// "Dog · Golden Retriever · 3 yrs" — skips empty parts.
  String get subtitle =>
      [type, breed, age].where((s) => s.trim().isNotEmpty).join(' · ');

  String get initial => name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
}
