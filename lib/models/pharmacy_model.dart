class PharmacyModel {
  String? id;
  String name;
  String description;
  String address;
  String contactNumber;
  String email;
  double latitude;
  double longitude;
  String profileImageUrl;
  double rating;
  int reviewCount;
  bool isOpen;
  String openingHours;
  List<String> services;

  PharmacyModel({
    this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.contactNumber,
    required this.email,
    required this.latitude,
    required this.longitude,
    this.profileImageUrl = '',
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isOpen = true,
    this.openingHours = '9:00 AM - 9:00 PM',
    this.services = const [],
  });

  factory PharmacyModel.fromMap(Map<String, dynamic> data, String docId) {
    return PharmacyModel(
      id: docId, // This is fine - assigning String to String?
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      address: data['address'] ?? '',
      contactNumber: data['contactNumber'] ?? '',
      email: data['email'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      profileImageUrl: data['profileImageUrl'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: (data['reviewCount'] ?? 0).toInt(),
      isOpen: data['isOpen'] ?? true,
      openingHours: data['openingHours'] ?? '9:00 AM - 9:00 PM',
      services: List<String>.from(data['services'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'address': address,
      'contactNumber': contactNumber,
      'email': email,
      'latitude': latitude,
      'longitude': longitude,
      'profileImageUrl': profileImageUrl,
      'rating': rating,
      'reviewCount': reviewCount,
      'isOpen': isOpen,
      'openingHours': openingHours,
      'services': services,
    };
  }
}