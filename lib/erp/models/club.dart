class Club {
  final String id;
  final String name;
  final String league;
  final String? country;
  final String? city;
  final String? logoUrl;
  final String status;
  final String? address;
  final String? email;
  final String? phone;
  final String? website;

  Club({
    required this.id,
    required this.name,
    required this.league,
    this.country,
    this.city,
    this.logoUrl,
    required this.status,
    this.address,
    this.email,
    this.phone,
    this.website,
  });

  factory Club.fromJson(Map<String, dynamic> json) {
    return Club(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      league: json['league'] ?? '',
      country: json['country'],
      city: json['city'],
      logoUrl: json['logoUrl'],
      status: json['status'] ?? 'pending',
      address: json['address'],
      email: json['email'],
      phone: json['phone'],
      website: json['website'],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'league': league,
    'country': country,
    'city': city,
    'logoUrl': logoUrl,
    'status': status,
    'address': address,
    'email': email,
    'phone': phone,
    'website': website,
  };
}
