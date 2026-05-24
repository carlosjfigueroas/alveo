class UserProfile {
  final String id;
  final String fullName;
  final String role;
  final String? companyId;
  final String? slug;
  final String? bio;
  final String? profilePhotoUrl;
  final String? whatsappNumber;
  final String? contactEmail;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.role,
    this.companyId,
    this.slug,
    this.bio,
    this.profilePhotoUrl,
    this.whatsappNumber,
    this.contactEmail,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? '',
      role: json['role'] ?? 'agent',
      companyId: json['company_id'],
      slug: json['slug'],
      bio: json['bio'],
      profilePhotoUrl: json['profile_photo_url'],
      whatsappNumber: json['whatsapp_number'],
      contactEmail: json['contact_email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'role': role,
      'company_id': companyId,
      'slug': slug,
      'bio': bio,
      'profile_photo_url': profilePhotoUrl,
      'whatsapp_number': whatsappNumber,
      'contact_email': contactEmail,
    };
  }
}
