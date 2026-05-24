import 'package:flutter/material.dart';

class Company {
  final String id;
  final String name;
  final String? nameEs;
  final String? nameEn;
  final String abbr;
  final String domain;
  final String? logoUrl;
  final String? logoAbbrUrl;
  final String primaryColorHex;
  final String secondaryColorHex;
  final String? contactEmail;
  final String? contactPhone;
  final String? contactWhatsapp;
  final String? instagramUrl;
  final String? facebookUrl;
  final String? telegramUrl;
  final bool isDemo;
  final bool isActive;
  final bool showCarousel;
  final bool showReferralMenu;
  final bool showOrganicAffiliate;
  // Subscription fields
  final String subscriptionStatus;
  final DateTime? trialEndsAt;
  final DateTime? subscriptionStartsAt;
  final DateTime? subscriptionEndsAt;
  final String billingCycle;
  final double basePrice;
  final double referralDiscount;
  final String? referralCode;
  final String? referredByCompanyId;
  final String? referralEmailEntered;
  final String language;
  final String? contactName;
  final DateTime? suspendedAt;
  final DateTime? graceEndsAt;
  
  // Strategy 2 fields
  final int maxPhotosPerProperty;
  final int maxProperties;
  final int referralBonusPhotos;
  final int referralBonusProperties;
  final String? referredBySalesperson;
  final String acquisitionChannel;

  // Regional settings
  final String currencySymbol;
  final String currencyCode;
  final String areaUnit;
  final String? country;
  final String? state;
  final String? city;
  final String carouselStrategy;
  final String carouselAnimation;
  final double defaultCommissionPct;
  final double defaultManagementPct;
  final double defaultSaleCommissionPct;
  final double defaultAgencySplitPct;
  final double defaultResidentialRentalMonths;
  final double defaultCommercialRentalMonths;
  final double defaultAdminCommissionPct;

  final String taxLabel;
  final double taxPercentage;

  const Company({
    required this.id,
    required this.name,
    this.nameEs,
    this.nameEn,
    required this.abbr,
    required this.domain,
    this.logoUrl,
    this.logoAbbrUrl,
    this.primaryColorHex = '#006837',
    this.secondaryColorHex = '#A64F35',
    this.contactEmail,
    this.contactPhone,
    this.contactWhatsapp,
    this.instagramUrl,
    this.facebookUrl,
    this.telegramUrl,
    this.isDemo = false,
    this.isActive = true,
    this.showCarousel = true,
    this.showReferralMenu = true,
    this.showOrganicAffiliate = true,
    this.subscriptionStatus = 'trial',
    this.trialEndsAt,
    this.subscriptionStartsAt,
    this.subscriptionEndsAt,
    this.billingCycle = 'monthly',
    this.basePrice = 18.00,
    this.referralDiscount = 0.00,
    this.referralCode,
    this.referredByCompanyId,
    this.referralEmailEntered,
    this.language = 'es',
    this.contactName,
    this.suspendedAt,
    this.graceEndsAt,
    this.maxPhotosPerProperty = 10,
    this.maxProperties = 30,
    this.referralBonusPhotos = 0,
    this.referralBonusProperties = 0,
    this.referredBySalesperson,
    this.acquisitionChannel = 'organic',
    this.currencySymbol = r'$',
    this.currencyCode = 'USD',
    this.areaUnit = 'm²',
    this.country,
    this.state,
    this.city,
    this.carouselStrategy = 'manual',
    this.carouselAnimation = 'slide',
    this.defaultCommissionPct = 40.0,
    this.defaultManagementPct = 5.0,
    this.defaultSaleCommissionPct = 5.0,
    this.defaultAgencySplitPct = 50.0,
    this.defaultResidentialRentalMonths = 1.0,
    this.defaultCommercialRentalMonths = 1.0,
    this.defaultAdminCommissionPct = 5.0,
    this.taxLabel = 'IVA',
    this.taxPercentage = 16.0,
  });

  // ─── Helpers de Suscripción ───────────────────────────────────────────
  double get effectivePrice {
    final discountPrice = basePrice - referralDiscount;
    // Si hay descuento acumulado, el piso máximo de descuento es el 25% (Límite: 75% del precio base)
    final lowerBound = basePrice * 0.75;
    
    if (referralDiscount > 0) {
      return discountPrice.clamp(lowerBound, double.infinity);
    }
    return discountPrice.clamp(0.0, double.infinity);
  }
  int get totalAllowedPhotosPerProperty => maxPhotosPerProperty + referralBonusPhotos;
  int get totalAllowedProperties => maxProperties + referralBonusProperties;

  // ─── Helpers de Color ─────────────────────────────────────────────────
  Color get primaryColor => _hexToColor(primaryColorHex);
  Color get secondaryColor => _hexToColor(secondaryColorHex);

  static Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  // ─── Nombre localizado ─────────────────────────────────────────────────
  String localizedName(String languageCode) {
    if (languageCode == 'es' && (nameEs?.isNotEmpty ?? false)) return nameEs!;
    if (languageCode == 'en' && (nameEn?.isNotEmpty ?? false)) return nameEn!;
    return name;
  }

  // ─── Serialization ────────────────────────────────────────────────────
  factory Company.fromJson(Map<String, dynamic> json, {Map<String, int>? globalLimits}) {
    return Company(
      id: json['id'] as String,
      name: json['name'] as String,
      nameEs: json['name_es'] as String?,
      nameEn: json['name_en'] as String?,
      abbr: json['abbr'] as String,
      domain: json['domain'] as String,
      logoUrl: json['logo_url'] as String?,
      logoAbbrUrl: json['logo_abbr_url'] as String?,
      primaryColorHex: json['primary_color'] as String? ?? '#006837',
      secondaryColorHex: json['secondary_color'] as String? ?? '#A64F35',
      contactEmail: json['contact_email'] as String?,
      contactPhone: json['contact_phone'] as String?,
      contactWhatsapp: json['contact_whatsapp'] as String?,
      instagramUrl: json['instagram_url'] as String?,
      facebookUrl: json['facebook_url'] as String?,
      telegramUrl: json['telegram_url'] as String?,
      isDemo: json['is_demo'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      showCarousel: json['show_carousel'] as bool? ?? true,
      showReferralMenu: json['show_referral_menu'] as bool? ?? true,
      showOrganicAffiliate: json['show_organic_affiliate'] as bool? ?? true,
      subscriptionStatus: json['subscription_status'] as String? ?? 'trial',
      trialEndsAt: json['trial_ends_at'] != null ? DateTime.parse(json['trial_ends_at']) : null,
      subscriptionStartsAt: json['subscription_starts_at'] != null ? DateTime.parse(json['subscription_starts_at']) : null,
      subscriptionEndsAt: json['subscription_ends_at'] != null ? DateTime.parse(json['subscription_ends_at']) : null,
      billingCycle: json['billing_cycle'] as String? ?? 'monthly',
      basePrice: (json['base_price'] as num?)?.toDouble() ?? 18.00,
      referralDiscount: (json['referral_discount'] as num?)?.toDouble() ?? 0.00,
      referralCode: json['referral_code'] as String?,
      referredByCompanyId: json['referred_by_company_id'] as String?,
      referralEmailEntered: json['referral_email_entered'] as String?,
      language: json['language'] as String? ?? 'es',
      contactName: json['contact_name'] as String?,
      suspendedAt: json['suspended_at'] != null ? DateTime.parse(json['suspended_at']) : null,
      graceEndsAt: json['grace_ends_at'] != null ? DateTime.parse(json['grace_ends_at']) : null,
      maxPhotosPerProperty: json['max_photos_per_property'] as int? ?? globalLimits?['max_photos_per_property'] ?? 10,
      maxProperties: json['max_properties'] as int? ?? globalLimits?['max_properties'] ?? 20,
      referralBonusPhotos: json['referral_bonus_photos'] as int? ?? 0,
      referralBonusProperties: json['referral_bonus_properties'] as int? ?? 0,
      referredBySalesperson: json['referred_by_salesperson'] as String?,
      acquisitionChannel: json['acquisition_channel'] as String? ?? 'organic',
      currencySymbol: json['currency_symbol'] as String? ?? r'$',
      currencyCode: json['currency_code'] as String? ?? 'USD',
      areaUnit: json['area_unit'] as String? ?? 'm²',
      country: json['country'] as String?,
      state: json['state'] as String?,
      city: json['city'] as String?,
      carouselStrategy: json['carousel_strategy'] as String? ?? 'manual',
      carouselAnimation: json['carousel_animation'] as String? ?? 'slide',
      defaultCommissionPct: (json['default_commission_pct'] as num?)?.toDouble() ?? 40.0,
      defaultManagementPct: (json['default_management_pct'] as num?)?.toDouble() ?? 5.0,
      defaultSaleCommissionPct: (json['default_sale_commission_pct'] as num?)?.toDouble() ?? 5.0,
      defaultAgencySplitPct: (json['default_agency_split_pct'] as num?)?.toDouble() ?? 50.0,
      defaultResidentialRentalMonths: (json['default_residential_rental_months'] as num?)?.toDouble() ?? 1.0,
      defaultCommercialRentalMonths: (json['default_commercial_rental_months'] as num?)?.toDouble() ?? 1.0,
      defaultAdminCommissionPct: (json['default_admin_commission_pct'] as num?)?.toDouble() ?? 5.0,
      taxLabel: json['tax_label'] as String? ?? 'IVA',
      taxPercentage: (json['tax_percentage'] as num?)?.toDouble() ?? 16.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'name_es': nameEs,
      'name_en': nameEn,
      'abbr': abbr,
      'domain': domain,
      'logo_url': logoUrl,
      'logo_abbr_url': logoAbbrUrl,
      'primary_color': primaryColorHex,
      'secondary_color': secondaryColorHex,
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
      'contact_whatsapp': contactWhatsapp,
      'instagram_url': instagramUrl,
      'facebook_url': facebookUrl,
      'telegram_url': telegramUrl,
      'is_demo': isDemo,
      'is_active': isActive,
      'show_carousel': showCarousel,
      'show_referral_menu': showReferralMenu,
      'show_organic_affiliate': showOrganicAffiliate,
      'subscription_status': subscriptionStatus,
      'trial_ends_at': trialEndsAt?.toIso8601String(),
      'subscription_starts_at': subscriptionStartsAt?.toIso8601String(),
      'subscription_ends_at': subscriptionEndsAt?.toIso8601String(),
      'billing_cycle': billingCycle,
      'base_price': basePrice,
      'referral_discount': referralDiscount,
      'referral_code': referralCode,
      'referred_by_company_id': referredByCompanyId,
      'referral_email_entered': referralEmailEntered,
      'language': language,
      'contact_name': contactName,
      'suspended_at': suspendedAt?.toIso8601String(),
      'grace_ends_at': graceEndsAt?.toIso8601String(),
      'max_photos_per_property': maxPhotosPerProperty,
      'max_properties': maxProperties,
      'referral_bonus_photos': referralBonusPhotos,
      'referral_bonus_properties': referralBonusProperties,
      'referred_by_salesperson': referredBySalesperson,
      'acquisition_channel': acquisitionChannel,
      'currency_symbol': currencySymbol,
      'currency_code': currencyCode,
      'area_unit': areaUnit,
      'country': country,
      'state': state,
      'city': city,
      'carousel_strategy': carouselStrategy,
      'carousel_animation': carouselAnimation,
      'default_commission_pct': defaultCommissionPct,
      'default_management_pct': defaultManagementPct,
      'default_sale_commission_pct': defaultSaleCommissionPct,
      'default_agency_split_pct': defaultAgencySplitPct,
      'default_residential_rental_months': defaultResidentialRentalMonths,
      'default_commercial_rental_months': defaultCommercialRentalMonths,
      'default_admin_commission_pct': defaultAdminCommissionPct,
      'tax_label': taxLabel,
      'tax_percentage': taxPercentage,
    };
  }

  // ─── Empresa vacía (fallback local antes de cargar de BD) ─────────────
  static const Company empty = Company(
    id: '',
    name: 'Alveo',
    nameEs: 'Alveo',
    nameEn: 'Alveo',
    abbr: 'demo',
    domain: 'alveo-demo.web.app',
    logoUrl: null,
    logoAbbrUrl: null,
    primaryColorHex: '#006837',
    secondaryColorHex: '#A64F35',
    isDemo: true,
    showCarousel: true,
    showReferralMenu: true,
    showOrganicAffiliate: true,
    carouselStrategy: 'manual',
    carouselAnimation: 'slide',
    defaultManagementPct: 5.0,
    defaultSaleCommissionPct: 5.0,
    defaultAgencySplitPct: 50.0,
    defaultResidentialRentalMonths: 1.0,
    defaultCommercialRentalMonths: 1.0,
    defaultAdminCommissionPct: 5.0,
    taxLabel: 'IVA',
    taxPercentage: 16.0,
  );

  Company copyWith({
    String? id,
    String? name,
    String? nameEs,
    String? nameEn,
    String? abbr,
    String? domain,
    String? logoUrl,
    String? logoAbbrUrl,
    String? primaryColorHex,
    String? secondaryColorHex,
    String? contactEmail,
    String? contactPhone,
    String? contactWhatsapp,
    String? instagramUrl,
    String? facebookUrl,
    String? telegramUrl,
    bool? isDemo,
    bool? isActive,
    bool? showCarousel,
    bool? showReferralMenu,
    bool? showOrganicAffiliate,
    String? subscriptionStatus,
    DateTime? trialEndsAt,
    DateTime? subscriptionStartsAt,
    DateTime? subscriptionEndsAt,
    String? billingCycle,
    double? basePrice,
    double? referralDiscount,
    String? referralCode,
    String? referredByCompanyId,
    String? referralEmailEntered,
    String? language,
    String? contactName,
    DateTime? suspendedAt,
    DateTime? graceEndsAt,
    int? maxPhotosPerProperty,
    int? maxProperties,
    int? referralBonusPhotos,
    int? referralBonusProperties,
    String? referredBySalesperson,
    String? acquisitionChannel,
    String? currencySymbol,
    String? currencyCode,
    String? areaUnit,
    String? country,
    String? state,
    String? city,
    String? carouselStrategy,
    String? carouselAnimation,
    double? defaultCommissionPct,
    double? defaultManagementPct,
    double? defaultSaleCommissionPct,
    double? defaultAgencySplitPct,
    double? defaultResidentialRentalMonths,
    double? defaultCommercialRentalMonths,
    double? defaultAdminCommissionPct,
    String? taxLabel,
    double? taxPercentage,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      nameEs: nameEs ?? this.nameEs,
      nameEn: nameEn ?? this.nameEn,
      abbr: abbr ?? this.abbr,
      domain: domain ?? this.domain,
      logoUrl: logoUrl ?? this.logoUrl,
      logoAbbrUrl: logoAbbrUrl ?? this.logoAbbrUrl,
      primaryColorHex: primaryColorHex ?? this.primaryColorHex,
      secondaryColorHex: secondaryColorHex ?? this.secondaryColorHex,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      contactWhatsapp: contactWhatsapp ?? this.contactWhatsapp,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      facebookUrl: facebookUrl ?? this.facebookUrl,
      telegramUrl: telegramUrl ?? this.telegramUrl,
      isDemo: isDemo ?? this.isDemo,
      isActive: isActive ?? this.isActive,
      showCarousel: showCarousel ?? this.showCarousel,
      showReferralMenu: showReferralMenu ?? this.showReferralMenu,
      showOrganicAffiliate: showOrganicAffiliate ?? this.showOrganicAffiliate,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      trialEndsAt: trialEndsAt ?? this.trialEndsAt,
      subscriptionStartsAt: subscriptionStartsAt ?? this.subscriptionStartsAt,
      subscriptionEndsAt: subscriptionEndsAt ?? this.subscriptionEndsAt,
      billingCycle: billingCycle ?? this.billingCycle,
      basePrice: basePrice ?? this.basePrice,
      referralDiscount: referralDiscount ?? this.referralDiscount,
      referralCode: referralCode ?? this.referralCode,
      referredByCompanyId: referredByCompanyId ?? this.referredByCompanyId,
      referralEmailEntered: referralEmailEntered ?? this.referralEmailEntered,
      language: language ?? this.language,
      contactName: contactName ?? this.contactName,
      suspendedAt: suspendedAt ?? this.suspendedAt,
      graceEndsAt: graceEndsAt ?? this.graceEndsAt,
      maxPhotosPerProperty: maxPhotosPerProperty ?? this.maxPhotosPerProperty,
      maxProperties: maxProperties ?? this.maxProperties,
      referralBonusPhotos: referralBonusPhotos ?? this.referralBonusPhotos,
      referralBonusProperties: referralBonusProperties ?? this.referralBonusProperties,
      referredBySalesperson: referredBySalesperson ?? this.referredBySalesperson,
      acquisitionChannel: acquisitionChannel ?? this.acquisitionChannel,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      currencyCode: currencyCode ?? this.currencyCode,
      areaUnit: areaUnit ?? this.areaUnit,
      country: country ?? this.country,
      state: state ?? this.state,
      city: city ?? this.city,
      carouselStrategy: carouselStrategy ?? this.carouselStrategy,
      carouselAnimation: carouselAnimation ?? this.carouselAnimation,
      defaultCommissionPct: defaultCommissionPct ?? this.defaultCommissionPct,
      defaultManagementPct: defaultManagementPct ?? this.defaultManagementPct,
      defaultSaleCommissionPct: defaultSaleCommissionPct ?? this.defaultSaleCommissionPct,
      defaultAgencySplitPct: defaultAgencySplitPct ?? this.defaultAgencySplitPct,
      defaultResidentialRentalMonths: defaultResidentialRentalMonths ?? this.defaultResidentialRentalMonths,
      defaultCommercialRentalMonths: defaultCommercialRentalMonths ?? this.defaultCommercialRentalMonths,
      defaultAdminCommissionPct: defaultAdminCommissionPct ?? this.defaultAdminCommissionPct,
      taxLabel: taxLabel ?? this.taxLabel,
      taxPercentage: taxPercentage ?? this.taxPercentage,
    );
  }
}
