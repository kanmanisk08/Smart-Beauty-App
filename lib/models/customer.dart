class Customer {
  final String id;
  final String name;
  final String badge;
  final String memberSince;
  final String phone;
  final String email;
  final String birthday;
  final String skinType;
  final String hairType;
  final String preferredTech;
  int points;
  int reliability;
  int hospitalityRating;
  int cancellations;
  String privateNote;
  final int age;
  
  // Quiz individual responses
  final String skinConcerns;
  final String hairConcerns;
  final String beautyGoal;

  Customer({
    required this.id,
    required this.name,
    required this.badge,
    required this.memberSince,
    required this.phone,
    required this.email,
    required this.birthday,
    required this.skinType,
    required this.hairType,
    required this.preferredTech,
    this.points = 0,
    this.reliability = 100,
    this.hospitalityRating = 100,
    this.cancellations = 0,
    this.privateNote = '',
    this.age = 22,
    this.skinConcerns = 'None',
    this.hairConcerns = 'None',
    this.beautyGoal = 'Routine Grooming',
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      name: json['name'] as String,
      badge: json['badge'] as String? ?? 'Occasional',
      memberSince: json['memberSince'] as String? ?? 'Jul 2026',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      birthday: json['birthday'] as String? ?? '',
      skinType: json['skinType'] as String? ?? 'Normal',
      hairType: json['hairType'] as String? ?? 'Straight',
      preferredTech: json['preferredTech'] as String? ?? 'Selvi',
      points: json['points'] as int? ?? 0,
      reliability: json['reliability'] as int? ?? 100,
      hospitalityRating: json['hospitalityRating'] as int? ?? 100,
      cancellations: json['cancellations'] as int? ?? 0,
      privateNote: json['privateNote'] as String? ?? '',
      age: json['age'] as int? ?? 22,
      skinConcerns: json['skinConcerns'] as String? ?? 'None',
      hairConcerns: json['hairConcerns'] as String? ?? 'None',
      beautyGoal: json['beautyGoal'] as String? ?? 'Routine Grooming',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'badge': badge,
      'memberSince': memberSince,
      'phone': phone,
      'email': email,
      'birthday': birthday,
      'skinType': skinType,
      'hairType': hairType,
      'preferredTech': preferredTech,
      'points': points,
      'reliability': reliability,
      'hospitalityRating': hospitalityRating,
      'cancellations': cancellations,
      'privateNote': privateNote,
      'age': age,
      'skinConcerns': skinConcerns,
      'hairConcerns': hairConcerns,
      'beautyGoal': beautyGoal,
    };
  }
}
