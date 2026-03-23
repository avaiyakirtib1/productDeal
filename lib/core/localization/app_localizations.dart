import 'package:flutter/material.dart';

import '../constants/app_languages.dart';
import 'ar_file.dart';
import 'de_file.dart';
import 'en_file.dart';
import 'hi_file.dart';
import 'ru_file.dart';
import 'tr_file.dart';
import 'uk_file.dart';
import 'ur_file.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': EnglishFile.englishTranslations,
    'de': GermanFile.germanTranslations,
    'tr': TurkishFile.turkishTranslations,
    'ar': ArabicFile.arabicTranslations,
    'ur': UrduFile.urduTranslations,
    'hi': HindiFile.hindiTranslations,
    'ru': RussianFile.russianTranslations,
    'uk': UkrainianFile.ukrainianTranslations,
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }

  /// Translate a key and replace positional args like {0}, {1}, ...
  String translateWithArgs(String key, List<String> args) {
    var text = translate(key);
    for (var i = 0; i < args.length; i++) {
      text = text.replaceAll('{$i}', args[i]);
    }
    return text;
  }

  // Getters for easier access
  String get options => translate('options');
  String get account => translate('account');
  String get myOrders => translate('myOrders');
  String get myOrdersSubtitle => translate('myOrdersSubtitle');
  String get statistics => translate('statistics');
  String get statisticsSubtitle => translate('statisticsSubtitle');
  String get profile => translate('profile');
  String get profileSubtitle => translate('profileSubtitle');
  String get management => translate('management');
  String get manageCategories => translate('manageCategories');
  String get manageCategoriesSubtitle => translate('manageCategoriesSubtitle');
  String get createNewProductSubtitle => translate('createNewProductSubtitle');
  String get createNewDealSubtitle => translate('createNewDealSubtitle');
  String get viewOrdersSubtitle => translate('viewOrdersSubtitle');
  String get inactiveMembersViewSubtitle =>
      translate('inactiveMembersViewSubtitle');
  String get manageBannersSubtitle => translate('manageBannersSubtitle');
  String get myBannersSubtitle => translate('myBannersSubtitle');
  String get unableToLoadOptions => translate('unableToLoadOptions');
  String get loggingOut => translate('loggingOut');
  String get manageUsers => translate('manageUsers');
  String get manageUsersSubtitle => translate('manageUsersSubtitle');
  String get analytics => translate('analytics');
  String get analyticsSubtitle => translate('analyticsSubtitle');
  String get information => translate('information');
  String get faq => translate('faq');
  String get faqSubtitle => translate('faqSubtitle');
  String get aboutUs => translate('aboutUs');
  String get aboutUsSubtitle => translate('aboutUsSubtitle');
  String get helpSupport => translate('helpSupport');
  String get helpSupportSubtitle => translate('helpSupportSubtitle');
  String get accountActions => translate('accountActions');
  String get deleteAccount => translate('deleteAccount');
  String get deleteAccountSubtitle => translate('deleteAccountSubtitle');
  String get logout => translate('logout');
  String get logoutSubtitle => translate('logoutSubtitle');
  String get confirmLogout => translate('confirmLogout');
  String get confirmLogoutMessage => translate('confirmLogoutMessage');
  String get cancel => translate('cancel');
  String get loginAgain => translate('loginAgain');
  String get language => translate('language');
  String get languageSubtitle => translate('languageSubtitle');
  String get selectYourLanguage => translate('selectYourLanguage');
  String get selectYourLanguageSubtitle =>
      translate('selectYourLanguageSubtitle');
  String get continueButton => translate('continueButton');
  String get notificationSettings => translate('notificationSettings');
  String get notificationSettingsSubtitle =>
      translate('notificationSettingsSubtitle');
  String get notificationChannels => translate('notificationChannels');
  String get pushNotifications => translate('pushNotifications');
  String get pushNotificationsSubtitle =>
      translate('pushNotificationsSubtitle');
  String get emailNotifications => translate('emailNotifications');
  String get emailNotificationsSubtitle =>
      translate('emailNotificationsSubtitle');
  String get notificationModules => translate('notificationModules');
  String get notificationSettingsSaved =>
      translate('notificationSettingsSaved');
  String get notificationModuleProducts =>
      translate('notificationModuleProducts');
  String get notificationModuleProductOrders =>
      translate('notificationModuleProductOrders');
  String get notificationModuleDeals => translate('notificationModuleDeals');
  String get notificationModuleDealOrders =>
      translate('notificationModuleDealOrders');
  String get notificationModuleBanners =>
      translate('notificationModuleBanners');
  String get notificationModuleAdmin => translate('notificationModuleAdmin');
  String get notificationModuleEngagement =>
      translate('notificationModuleEngagement');
  String get notificationModulePayment =>
      translate('notificationModulePayment');
  String get push => translate('push');
  String get currency => translate('currency');
  String get currencySubtitle => translate('currencySubtitle');
  String get systemDefault => translate('systemDefault');
  String get syncFxRates => translate('syncFxRates');
  String get syncFxRatesSubtitle => translate('syncFxRatesSubtitle');
  String get syncFxRatesSuccess => translate('syncFxRatesSuccess');
  String get syncFxRatesFailed => translate('syncFxRatesFailed');
  String get changingLanguage => translate('changingLanguage');
  String get languageChangeFailed => translate('languageChangeFailed');
  String get failedToChangeLanguage => translate('failedToChangeLanguage');
  String get english => translate('english');
  String get german => translate('german');
  String get sourceLanguageLabel => translate('sourceLanguageLabel');
  String get sourceLanguageHint => translate('sourceLanguageHint');
  String get sessionExpired => translate('sessionExpired');
  String get sessionExpiredMessage => translate('sessionExpiredMessage');
  String get comingSoon => translate('comingSoon');
  String get welcomeToProductDeal => translate('welcomeToProductDeal');
  String get trustedMarketplace => translate('trustedMarketplace');
  String get ourMission => translate('ourMission');
  String get ourMissionContent => translate('ourMissionContent');
  String get whatWeOffer => translate('whatWeOffer');
  String get whatWeOfferContent => translate('whatWeOfferContent');
  String get forWholesalers => translate('forWholesalers');
  String get frequentlyAskedQuestions => translate('frequentlyAskedQuestions');
  String get commonQuestions => translate('commonQuestions');
  String get advertiseWithUs => translate('advertiseWithUs');
  String get nearbyWholesalers => translate('nearbyWholesalers');
  String get activeShopsSuffix => translate('activeShopsSuffix');
  String get location => translate('location');
  String get allWholesalers => translate('allWholesalers');
  String get noWholesalersFound => translate('noWholesalersFound');
  String get errorLoadingWholesalers => translate('errorLoadingWholesalers');
  String get boostYourSales => translate('boostYourSales');
  String get promoteYourProducts => translate('promoteYourProducts');
  String get verifiedPartners => translate('verifiedPartners');
  String get verifiedPartnersDescription =>
      translate('verifiedPartnersDescription');
  String get couldNotLoadWholesalers => translate('couldNotLoadWholesalers');
  String get noWholesalersNearYou => translate('noWholesalersNearYou');
  String get orderId => translate('orderId');
  String get status => translate('status');
  String get payment => translate('payment');
  String get paymentStatus => translate('paymentStatus');
  String get placedOn => translate('placedOn');
  String get orderItems => translate('orderItems');
  String get createShipment => translate('createShipment');
  String get shippingAddress => translate('shippingAddress');
  String get notes => translate('notes');
  String get orderNotes => translate('orderNotes');
  String get orderDetails => translate('orderDetails');
  String get unableToLoadOrder => translate('unableToLoadOrder');
  String get unableToLoadProduct => translate('unableToLoadProduct');
  String get unableToLoadWholesaler => translate('unableToLoadWholesaler');
  String get retry => translate('retry');
  String get updateOrderStatus => translate('updateOrderStatus');
  String get subtotal => translate('subtotal');
  String get shipping => translate('shipping');
  String get shippingWithFreeThreshold =>
      translate('shippingWithFreeThreshold');
  String get freeShippingForThreshold => translate('freeShippingForThreshold');
  String get shippingBaseOnly => translate('shippingBaseOnly');
  String get shippingWithPerUnit => translate('shippingWithPerUnit');
  String get total => translate('total');
  String get reasonOptional => translate('reasonOptional');
  String get notesOptional => translate('notesOptional');
  String get update => translate('update');
  String get sku => translate('sku');
  String get skuNA => translate('skuN/A');
  String get trackingAvailable => translate('trackingAvailable');
  String get shipped => translate('shipped');
  String get shipments => translate('shipments');
  String get shipmentId => translate('shipmentId');
  String get trackingLabel => translate('trackingLabel');
  String get track => translate('track');
  String get couldNotOpenTrackingUrl => translate('couldNotOpenTrackingUrl');
  String get carrierLabel => translate('carrierLabel');
  String get estDelivery => translate('estDelivery');
  String get shippedAt => translate('shippedAt');
  String get deliveredAt => translate('deliveredAt');
  String get each => translate('each');
  String get unit => translate('unit');
  String get updateItemStatus => translate('updateItemStatus');
  String get orderStatusUpdated => translate('orderStatusUpdated');
  String get itemStatusUpdated => translate('itemStatusUpdated');
  String get failedToUpdateStatus => translate('failedToUpdateStatus');
  String get viewAll => translate('viewAll');
  String get noActiveDeals => translate('noActiveDeals');
  String get perUnitLabel => translate('perUnitLabel');
  String get inStock => translate('inStock');
  String get similarProducts => translate('similarProducts');
  String get noActiveDealsForProduct => translate('noActiveDealsForProduct');
  String get activeDealsForProduct => translate('activeDealsForProduct');
  String get moreFromWholesaler => translate('moreFromWholesaler');
  String get dealsFromWholesaler => translate('dealsFromWholesaler');
  String get productsFromWholesaler => translate('productsFromWholesaler');
  String get searchProductsFromWholesaler =>
      translate('searchProductsFromWholesaler');
  String get onlyKioskCanPurchase => translate('onlyKioskCanPurchase');
  String get canOnlyReviewFromDelivered =>
      translate('canOnlyReviewFromDelivered');
  String get alreadyReviewedThisProduct =>
      translate('alreadyReviewedThisProduct');
  String get selectOrderToReview => translate('selectOrderToReview');
  String get orderN => translate('orderN');
  String get viewDeals => translate('viewDeals');
  String get locationInfoNotAvailable => translate('locationInfoNotAvailable');
  String get kfProductDealTagline => translate('kfProductDealTagline');
  String get errorSearchingProducts => translate('errorSearchingProducts');
  String get productsSection => translate('productsSection');
  String get myDealOrders => translate('myDealOrders');
  String get noDealOrdersYet => translate('noDealOrdersYet');
  String get browseDealsPlaceFirstOrder =>
      translate('browseDealsPlaceFirstOrder');
  String get statusLabel => translate('statusLabel');
  String get noProductsFoundForWholesaler =>
      translate('noProductsFoundForWholesaler');
  String get noApprovedWholesalersAvailable =>
      translate('noApprovedWholesalersAvailable');
  String get searchByNameBusinessEmail =>
      translate('searchByNameBusinessEmail');
  String get selectWholesaler => translate('selectWholesaler');
  String get pageNOfM => translate('pageNOfM');
  String get priceLabel => translate('priceLabel');
  String get pleaseSelectImageOrVideo =>
      translate('pleaseSelectImageOrVideo');
  String get onlyWholesalersCreateStories =>
      translate('onlyWholesalersCreateStories');
  String get storyCreatedSuccessfully =>
      translate('storyCreatedSuccessfully');
  String get uploadingMedia => translate('uploadingMedia');
  String get creatingStory => translate('creatingStory');
  String get storyMedia => translate('storyMedia');
  String get videoSelected => translate('videoSelected');
  String get storiesCountSuffix => translate('storiesCountSuffix');
  String get create => translate('create');
  String get viewAllProducts => translate('viewAllProducts');
  String get addToCart => translate('addToCart');
  String get buyNow => translate('buyNow');
  String get category => translate('category');
  String get bannerRequestComingSoon => translate('bannerRequestComingSoon');
  String get forRetailers => translate('forRetailers');
  String get forRetailersContent => translate('forRetailersContent');
  String get forWholesalersContent => translate('forWholesalersContent');
  String get faqQuestion1 => translate('faqQuestion1');
  String get faqAnswer1 => translate('faqAnswer1');
  String get faqQuestion2 => translate('faqQuestion2');
  String get faqAnswer2 => translate('faqAnswer2');
  String get faqQuestion3 => translate('faqQuestion3');
  String get faqAnswer3 => translate('faqAnswer3');
  String get faqQuestion4 => translate('faqQuestion4');
  String get faqAnswer4 => translate('faqAnswer4');
  String get faqQuestion5 => translate('faqQuestion5');
  String get faqAnswer5 => translate('faqAnswer5');
  String get faqQuestion6 => translate('faqQuestion6');
  String get faqAnswer6 => translate('faqAnswer6');
  String get faqQuestion7 => translate('faqQuestion7');
  String get faqAnswer7 => translate('faqAnswer7');
  String get faqQuestion8 => translate('faqQuestion8');
  String get faqAnswer8 => translate('faqAnswer8');

  // My Orders Screen
  String get noOrdersYet => translate('noOrdersYet');
  String get noOrdersYetMessage => translate('noOrdersYetMessage');
  String get unableToLoadOrders => translate('unableToLoadOrders');

  // Cart Screen
  String get yourCart => translate('yourCart');
  String get emptyCart => translate('emptyCart');
  String get emptyCartMessage => translate('emptyCartMessage');
  String get addProductsToSeeThemHere => translate('addProductsToSeeThemHere');
  String get placeOrderCashOnDelivery => translate('placeOrderCashOnDelivery');
  String get cashOnDelivery => translate('cashOnDelivery');
  String get payWithCard => translate('payWithCard');
  String get placeOrderPayNow => translate('placeOrderPayNow');
  String get paymentAfterOrderConfirmed => translate('paymentAfterOrderConfirmed');
  String get paymentNotAvailable => translate('paymentNotAvailable');
  String get paymentCancelled => translate('paymentCancelled');
  String get dealSucceededPayNow => translate('dealSucceededPayNow');
  String get totalToPay => translate('totalToPay');
  String get payByInvoice => translate('payByInvoice');
  String get payByCard => translate('payByCard');
  String get invoiceInstructionsSent => translate('invoiceInstructionsSent');
  String get reportPayment => translate('reportPayment');
  String get buyerReportedPayment => translate('buyerReportedPayment');
  String get reportedAt => translate('reportedAt');
  String get reportPaymentSubtitle => translate('reportPaymentSubtitle');
  String get reportPaymentSuccess => translate('reportPaymentSuccess');
  String get referenceNumber => translate('referenceNumber');
  String get transactionId => translate('transactionId');
  String get bankName => translate('bankName');
  String get paymentDetailsNotes => translate('paymentDetailsNotes');
  String get paymentInstructionsBankOnly => translate('paymentInstructionsBankOnly');
  String get markAsPaid => translate('markAsPaid');
  String get paymentNotesOptional => translate('paymentNotesOptional');
  String get myDealStats => translate('myDealStats');
  String get dealsJoined => translate('dealsJoined');
  String get totalOrderedQuantity => translate('totalOrderedQuantity');
  String get totalOrders => translate('totalOrders');
  String get placeOrder => translate('placeOrder');
  String get fxDisclaimer => translate('fxDisclaimer');
  String get paymentMethodCash => translate('paymentMethodCash');
  String get paymentMethodCashDesc => translate('paymentMethodCashDesc');
  String get paymentMethodInvoice => translate('paymentMethodInvoice');
  String get paymentMethodInvoiceDesc => translate('paymentMethodInvoiceDesc');
  String get paymentMethodBankTransfer => translate('paymentMethodBankTransfer');
  String get paymentMethodBankTransferDesc => translate('paymentMethodBankTransferDesc');
  String get sendPaymentInstructions => translate('sendPaymentInstructions');
  String get paymentMode => translate('paymentMode');
  String get paymentModeSubtitle => translate('paymentModeSubtitle');
  String get paymentModeSubtitleMulti => translate('paymentModeSubtitleMulti');
  String get paymentSettings => translate('paymentSettings');
  String get paymentSettingsSubtitle => translate('paymentSettingsSubtitle');
  String get placingOrder => translate('placingOrder');
  String get orderPlacedSuccessfully => translate('orderPlacedSuccessfully');
  String get failedToPlaceOrder => translate('failedToPlaceOrder');
  String get onlyKioskCanOrder => translate('onlyKioskCanOrder');
  String get admins => translate('admins');
  String get subAdmins => translate('subAdmins');
  String get wholesalers => translate('wholesalers');
  String get canOnlyViewProducts => translate('canOnlyViewProducts');

  // Register Screen
  String get register => translate('register');
  String get createAccount => translate('createAccount');
  String get fullName => translate('fullName');
  String get email => translate('email');
  String get phone => translate('phone');
  String get password => translate('password');
  String get confirmPassword => translate('confirmPassword');
  String get businessName => translate('businessName');
  String get country => translate('country');
  String get city => translate('city');
  String get address => translate('address');
  String get getLocation => translate('getLocation');
  String get selectRole => translate('selectRole');
  String get alreadyHaveAccount => translate('alreadyHaveAccount');
  String get login => translate('login');
  String get registrationReceived => translate('registrationReceived');
  String get createAccountTitle => translate('createAccountTitle');
  String get createAccountSubtitle => translate('createAccountSubtitle');
  String get accountType => translate('accountType');
  String get fullNameRequired => translate('fullNameRequired');
  String get fullNameMinLength => translate('fullNameMinLength');
  String get workEmail => translate('workEmail');
  String get emailRequired => translate('emailRequired');
  String get provideValidEmail => translate('provideValidEmail');
  String get phoneNumberOptional => translate('phoneNumberOptional');
  String get enterValidPhoneNumber => translate('enterValidPhoneNumber');
  String get kioskShopNameOptional => translate('kioskShopNameOptional');
  String get kioskShopRole => translate('kioskShopRole');
  String get companyName => translate('companyName');
  String get streetAddress => translate('streetAddress');
  String get addressWillBeGeocoded => translate('addressWillBeGeocoded');
  String get addressSearchHint => translate('addressSearchHint');
  String get placesLookupFailed => translate('placesLookupFailed');
  String get placesNoAddressResults => translate('placesNoAddressResults');
  String get placesAddressSearchConfigError =>
      translate('placesAddressSearchConfigError');
  String get placesAddressSearchRequestFailed =>
      translate('placesAddressSearchRequestFailed');
  String get latitudeOptional => translate('latitudeOptional');
  String get longitudeOptional => translate('longitudeOptional');
  String get locating => translate('locating');
  String get useCurrentLocation => translate('useCurrentLocation');
  String get enableLocationServices => translate('enableLocationServices');
  String get unableToFetchLocation => translate('unableToFetchLocation');
  String get createPassword => translate('createPassword');
  String get minimum8CharactersRequired =>
      translate('minimum8CharactersRequired');
  String get confirmPasswordLabel => translate('confirmPasswordLabel');
  String get weVerifyEveryBusiness => translate('weVerifyEveryBusiness');
  String get submitForReview => translate('submitForReview');
  String get mustAcceptAllLegalDocuments =>
      translate('mustAcceptAllLegalDocuments');
  String get mustAcceptTermsAndPrivacy => translate('mustAcceptTermsAndPrivacy');
  String get legalComplianceTitle => translate('legalComplianceTitle');
  String get scrollToAcceptTerms => translate('scrollToAcceptTerms');
  String get termsAndConditionsFullText =>
      translate('termsAndConditionsFullText');
  String get scrollToBottom => translate('scrollToBottom');
  String get acceptTermsLabel => translate('acceptTermsLabel');
  String get termsScrollHint => translate('termsScrollHint');
  String get acceptPrivacyLabel => translate('acceptPrivacyLabel');
  String get privacySummaryText => translate('privacySummaryText');
  String get alreadyVerifiedSignIn => translate('alreadyVerifiedSignIn');

  // Profile Screen
  String get editProfile => translate('editProfile');
  String get save => translate('save');
  String get done => translate('done');
  String get saving => translate('saving');
  String get profileUpdated => translate('profileUpdated');
  String get failedToUpdateProfile => translate('failedToUpdateProfile');
  String get profileImageUpdated => translate('profileImageUpdated');
  String get failedToUploadImage => translate('failedToUploadImage');
  String get tagline => translate('tagline');
  String get locations => translate('locations');
  String get addLocation => translate('addLocation');
  String get editLocation => translate('editLocation');
  String get deleteLocation => translate('deleteLocation');
  String get latitude => translate('latitude');
  String get longitude => translate('longitude');
  String get nameIsRequired => translate('nameIsRequired');
  String get businessNameOptional => translate('businessNameOptional');
  String get phoneOptional => translate('phoneOptional');
  String get addresses => translate('addresses');
  String get addAddress => translate('addAddress');
  String get noAddressesAdded => translate('noAddressesAdded');
  String get addYourFirstAddress => translate('addYourFirstAddress');
  String get editAddress => translate('editAddress');
  String get removeAddress => translate('removeAddress');
  String get saveChanges => translate('saveChanges');
  String get createStory => translate('createStory');
  String get editAddressTitle => translate('editAddressTitle');
  String get addAddressTitle => translate('addAddressTitle');
  String get labelExample => translate('labelExample');
  String get streetAreaOptional => translate('streetAreaOptional');
  String get countryOptional => translate('countryOptional');
  String get cityOptional => translate('cityOptional');
  String get locatingEllipsis => translate('locatingEllipsis');
  String get enableLocationPermissions =>
      translate('enableLocationPermissions');
  String get unableToFetchLocationShort =>
      translate('unableToFetchLocationShort');
  String get pleaseEnterValidLatLng => translate('pleaseEnterValidLatLng');
  String get add => translate('add');

  // Deal List Screen
  String get deals => translate('deals');
  String get activeDeals => translate('activeDeals');
  String get noDealsFound => translate('noDealsFound');
  String get unableToLoadDeals => translate('unableToLoadDeals');
  String get noDealsAvailable => translate('noDealsAvailable');
  String get checkBackLaterForNewDeals =>
      translate('checkBackLaterForNewDeals');
  String get filterDeals => translate('filterDeals');
  String get all => translate('all');
  String get progress => translate('progress');
  String get dealClosed => translate('dealClosed');
  String get ordered => translate('ordered');
  String get order => translate('order');
  String get orderLabel => translate('orderLabel');
  String get orders => translate('orders');
  String get dealOrder => translate('dealOrder');
  String get productOrder => translate('productOrder');
  String get bid => translate('bid');
  String get itemPlusMore => translate('itemPlusMore');
  String get endingSoon => translate('endingSoon');
  String get ends => translate('ends');
  String get variant => translate('variant');
  String get min => translate('min');
  String get max => translate('max');
  String get perUnit => translate('perUnit');
  String get off => translate('off');
  String get filter => translate('filter');
  String get error => translate('error');
  String get errorWithDetail => translate('errorWithDetail');
  String get type => translate('type');
  String get close => translate('close');
  String get navigationError => translate('navigationError');
  String get noProductsAvailable => translate('noProductsAvailable');
  String get addedToCart => translate('addedToCart');
  String get reviewed => translate('reviewed');
  String get maximum5ImagesAllowed => translate('maximum5ImagesAllowed');
  String get failedToPickImage => translate('failedToPickImage');
  String get failedToUploadImages => translate('failedToUploadImages');
  String get pleaseSelectRating => translate('pleaseSelectRating');
  String get uploadImages => translate('uploadImages');
  String get uploadFailed => translate('uploadFailed');
  String get productUpdatedSuccessfully =>
      translate('productUpdatedSuccessfully');
  String get productCreatedSuccessfully =>
      translate('productCreatedSuccessfully');
  String get kilogram => translate('kilogram');
  String get gram => translate('gram');
  String get liter => translate('liter');
  String get milliliter => translate('milliliter');
  String get piece => translate('piece');
  String get box => translate('box');
  String get pack => translate('pack');
  String get pending => translate('pending');
  String get approved => translate('approved');
  String get rejected => translate('rejected');
  String get draft => translate('draft');
  String get useVariants => translate('useVariants');
  String get addVariant => translate('addVariant');
  String get addAttribute => translate('addAttribute');
  String get featuredProduct => translate('featuredProduct');
  String get default_ => translate('default');
  String get updateProduct => translate('updateProduct');
  String get createProduct => translate('createProduct');
  String get selectCategory => translate('selectCategory');
  String get selectCategories => translate('selectCategories');
  String get select => translate('select');
  String get contactUsOnWhatsApp => translate('contactUsOnWhatsApp');
  String get helloNeedAssistance => translate('helloNeedAssistance');
  String get myDetails => translate('myDetails');
  String get nameLabel => translate('nameLabel');
  String get phoneLabel => translate('phoneLabel');
  String get emailLabel => translate('emailLabel');
  String get businessLabel => translate('businessLabel');
  String get howCanYouHelpMe => translate('howCanYouHelpMe');
  String get importFromCsv => translate('importFromCsv');
  String get addProduct => translate('addProduct');
  String get remove => translate('remove');
  String get viewWholesaler => translate('viewWholesaler');
  String get cart => translate('cart');
  String get quantity => translate('quantity');
  String get unitPrice => translate('unitPrice');
  String get totalAmount => translate('totalAmount');
  String get buyer => translate('buyer');
  String get trackingNumber => translate('trackingNumber');
  String get carrier => translate('carrier');
  String get trackingUrl => translate('trackingUrl');
  String get confirmed => translate('confirmed');
  String get delivered => translate('delivered');
  String get minOrder => translate('minOrder');
  String get target => translate('target');
  String get units => translate('units');
  String get submitDeletionRequest => translate('submitDeletionRequest');
  String get confirmActionPermanent => translate('confirmActionPermanent');
  String get requestSubmitted => translate('requestSubmitted');
  String get deletionRequestSubmittedMessage =>
      translate('deletionRequestSubmittedMessage');
  String get ok => translate('ok');
  String get failedToSubmitDeletionRequest =>
      translate('failedToSubmitDeletionRequest');
  String get requestAccountDeletion => translate('requestAccountDeletion');
  String get sorryToSeeYouGo => translate('sorryToSeeYouGo');
  String get emailAddress => translate('emailAddress');
  String get enterRegisteredEmail => translate('enterRegisteredEmail');
  String get emailAddressRequired => translate('emailAddressRequired');
  String get pleaseEnterValidEmail => translate('pleaseEnterValidEmail');
  String get invalidEmail => translate('invalidEmail');
  String get reasonForDeletionOptional =>
      translate('reasonForDeletionOptional');
  String get helpUsImproveLeaving => translate('helpUsImproveLeaving');
  String get understandActionPermanent =>
      translate('understandActionPermanent');
  String get hours => translate('hours');
  String get youHaveAlreadyReviewed => translate('youHaveAlreadyReviewed');
  String get reviewUpdatedSuccessfully =>
      translate('reviewUpdatedSuccessfully');
  String get reviewSubmittedSuccessfully =>
      translate('reviewSubmittedSuccessfully');
  String get pickImage => translate('pickImage');
  String get pickVideo => translate('pickVideo');
  String get expiresAt => translate('expiresAt');
  String get change => translate('change');
  String get upload => translate('upload');
  String get invalidImageUrl => translate('invalidImageUrl');
  String get createNewBanner => translate('createNewBanner');
  String get bannerTitle => translate('bannerTitle');
  String get enterBannerTitle => translate('enterBannerTitle');
  String get bannerImage => translate('bannerImage');
  String get webBannerImage => translate('webBannerImage');
  String get webBannerImageHint => translate('webBannerImageHint');
  String get mobileBannerImage => translate('mobileBannerImage');
  String get mobileBannerImageHint => translate('mobileBannerImageHint');
  String get mobilePreview => translate('mobilePreview');
  String get preview => translate('preview');
  String get previewMobile => translate('previewMobile');
  String get previewWillAppearHere => translate('previewWillAppearHere');
  String get pasteImageUrlHere => translate('pasteImageUrlHere');
  String get pleaseEnterImageUrlOrSwitch =>
      translate('pleaseEnterImageUrlOrSwitch');
  String get pleaseTapChooseImage => translate('pleaseTapChooseImage');
  String get tapToUploadWebImage => translate('tapToUploadWebImage');
  String get tapToUploadMobileImage => translate('tapToUploadMobileImage');
  String get chooseImage => translate('chooseImage');
  String get replaceImage => translate('replaceImage');
  String get required => translate('required');
  String get bannerRequestSubmitted => translate('bannerRequestSubmitted');
  String get failedToSubmitRequest => translate('failedToSubmitRequest');
  String get dealCreatedSuccessfully => translate('dealCreatedSuccessfully');
  String get pleaseSelectWholesalerFirst =>
      translate('pleaseSelectWholesalerFirst');
  String get auction => translate('auction');
  String get priceDrop => translate('priceDrop');
  String get limitedStock => translate('limitedStock');
  String get scheduled => translate('scheduled');
  String get live => translate('live');
  String get highlightedDeal => translate('highlightedDeal');
  String get createDeal => translate('createDeal');
  String get errors => translate('errors');
  String get templateSavedSuccessfully =>
      translate('templateSavedSuccessfully');
  String get templateDownloadCancelled =>
      translate('templateDownloadCancelled');
  String get errorGeneratingTemplate => translate('errorGeneratingTemplate');
  String get selectProduct => translate('selectProduct');
  String get selectDeal => translate('selectDeal');
  String get price => translate('price');
  String get dealPrice => translate('dealPrice');
  String get hello => translate('hello');
  String get unableToOpenWhatsApp => translate('unableToOpenWhatsApp');
  String get createYourFirstDeal => translate('createYourFirstDeal');
  String get addYourFirstProduct => translate('addYourFirstProduct');
  String get changeProductStatus => translate('changeProductStatus');
  String get updatingStatus => translate('updatingStatus');
  String get statusUpdatedToPending => translate('statusUpdatedToPending');
  String get statusUpdatedToApproved => translate('statusUpdatedToApproved');
  String get statusUpdatedToRejected => translate('statusUpdatedToRejected');
  String get productDeletedSuccessfully =>
      translate('productDeletedSuccessfully');
  String get storiesFromVerifiedWholesalers =>
      translate('storiesFromVerifiedWholesalers');
  String get submitRequest => translate('submitRequest');
  String get reviewProcess => translate('reviewProcess');
  String get accountDeleted => translate('accountDeleted');
  String get pendingOrders => translate('pendingOrders');
  String get viewOrders => translate('viewOrders');
  String get myBanners => translate('myBanners');
  String get cropImage => translate('cropImage');
  String get orderPlaced => translate('orderPlaced');
  String get packed => translate('packed');
  String get emailSupport => translate('emailSupport');
  String get getHelpViaEmail => translate('getHelpViaEmail');
  String get phoneSupport => translate('phoneSupport');
  String get callUsDuringBusinessHours =>
      translate('callUsDuringBusinessHours');
  String get liveChat => translate('liveChat');
  String get businessEmail => translate('businessEmail');
  String get signIn => translate('signIn');
  String get outOfStock => translate('outOfStock');
  String get onlyLeft => translate('onlyLeft');
  String get left => translate('left');
  String get timeRemainingDay => translate('timeRemainingDay');
  String get timeRemainingDays => translate('timeRemainingDays');
  String get timeRemainingHour => translate('timeRemainingHour');
  String get timeRemainingHours => translate('timeRemainingHours');
  String get timeRemainingMinute => translate('timeRemainingMinute');
  String get timeRemainingMinutes => translate('timeRemainingMinutes');
  String get minutes => translate('minutes');
  String get seconds => translate('seconds');
  String get twentyFourHours => translate('twentyFourHours');
  String get twelveHours => translate('twelveHours');
  String get sixHours => translate('sixHours');
  String get welcomeBack => translate('welcomeBack');
  String get signInToReach => translate('signInToReach');
  String get forgotPassword => translate('forgotPassword');
  String get createKioskOrWholesalerAccount =>
      translate('createKioskOrWholesalerAccount');
  String get accountSubmittedForApproval =>
      translate('accountSubmittedForApproval');
  String get dashboardWillUnlock => translate('dashboardWillUnlock');
  String get unableToLoadDashboard => translate('unableToLoadDashboard');
  String get chatWithUs => translate('chatWithUs');
  String get post => translate('post');
  String get selectImageOrVideoForStory =>
      translate('selectImageOrVideoForStory');
  String get editDeal => translate('editDeal');
  String get closeDeal => translate('closeDeal');
  String get closeDealConfirmMessage => translate('closeDealConfirmMessage');
  String get closeDealGoalReached => translate('closeDealGoalReached');
  String get closeDealGoalReachedHint => translate('closeDealGoalReachedHint');
  String get openTrackingLink => translate('openTrackingLink');
  String get statusTimeline => translate('statusTimeline');
  String get unknown => translate('unknown');
  String get pleaseLoginToPlaceOrder => translate('pleaseLoginToPlaceOrder');
  String get canOnlyViewDeals => translate('canOnlyViewDeals');

  String get chatWithSupportTeam => translate('chatWithSupportTeam');
  String get commonIssues => translate('commonIssues');
  String get orderNotShowingUp => translate('orderNotShowingUp');
  String get orderNotShowingUpSolution =>
      translate('orderNotShowingUpSolution');
  String get locationNotUpdating => translate('locationNotUpdating');
  String get locationNotUpdatingSolution =>
      translate('locationNotUpdatingSolution');
  String get dealProgressNotUpdating => translate('dealProgressNotUpdating');
  String get dealProgressNotUpdatingSolution =>
      translate('dealProgressNotUpdatingSolution');
  String get dealProgress => translate('dealProgress');
  String get unableToLoadProgress => translate('unableToLoadProgress');
  String get noOrdersPlacedYet => translate('noOrdersPlacedYet');
  String get orderPlacedSuffix => translate('orderPlacedSuffix');
  String get ordersPlacedSuffix => translate('ordersPlacedSuffix');
  String get closed => translate('closed');
  String get liveChatComingSoon => translate('liveChatComingSoon');
  String get needHelpContactSupport => translate('needHelpContactSupport');
  String get contactSupportAt => translate('contactSupportAt');
  String get whatHappensNext => translate('whatHappensNext');
  String get submitRequestDescription => translate('submitRequestDescription');
  String get reviewProcessDescription => translate('reviewProcessDescription');
  String get accountDeletedDescription =>
      translate('accountDeletedDescription');
  String get ourTeamReviewsYourRequest =>
      translate('ourTeamReviewsYourRequest');
  String get reviewDetails => translate('reviewDetails');
  String get reviewDetailsDescription => translate('reviewDetailsDescription');
  String get yourAccountIsPermanentlyRemoved =>
      translate('yourAccountIsPermanentlyRemoved');
  String get finalStep => translate('finalStep');
  String get finalStepDescription => translate('finalStepDescription');
  String get importantInformation => translate('importantInformation');
  String get accountDeletionIsPermanent =>
      translate('accountDeletionIsPermanent');
  String get allDataWillBeRemoved => translate('allDataWillBeRemoved');
  String get pendingOrdersMustBeCompleted =>
      translate('pendingOrdersMustBeCompleted');
  String get youllReceiveEmailConfirmation =>
      translate('youllReceiveEmailConfirmation');

  // Common validation
  String get passwordTooShort => translate('passwordTooShort');
  String get passwordsDoNotMatch => translate('passwordsDoNotMatch');
  String get getInTouch => translate('getInTouch');
  String get wereHereToHelp => translate('wereHereToHelp');
  String get spotlight => translate('spotlight');
  // Story Carousel
  String get beTheFirstStory => translate('beTheFirstStory');
  String get storiesWillAppearHere => translate('storiesWillAppearHere');
  String get updates => translate('updates');
  String get story => translate('story');
  String get shareWithCustomers => translate('shareWithCustomers');
  String get expires => translate('expires');

  String get spotlightWholesalersEmpty =>
      translate('spotlightWholesalersEmpty');

  String get selectVariant => translate('selectVariant');
  String get productsWillAppearHere => translate('productsWillAppearHere');
  String get noProductsFound => translate('noProductsFound');
  String get youveReachedEnd => translate('youveReachedEnd');
  String get errorLoadingProducts => translate('errorLoadingProducts');
  String get featuredCatalog => translate('featuredCatalog');
  String get kmAway => translate('kmAway');

  // Product Management (New)
  String get editProduct => translate('editProduct');
  String get validationError => translate('validationError');
  String get checkAllFields => translate('checkAllFields');
  String get globalAttributes => translate('globalAttributes');
  String get globalAttributesDescription =>
      translate('globalAttributesDescription');
  String get attributeName => translate('attributeName');
  String get attributeNameHint => translate('attributeNameHint');
  String get imageUrl => translate('imageUrl');
  String get productImages => translate('productImages');
  String get firstImagePrimary => translate('firstImagePrimary');
  String get addImageUrl => translate('addImageUrl');
  String get pasteImageUrlHint => translate('pasteImageUrlHint');
  String get costPrice => translate('costPrice');
  String get stock => translate('stock');
  String get stockRequired => translate('stockRequired');
  String get stockNegative => translate('stockNegative');
  String get priceRequired => translate('priceRequired');
  String get pricePositive => translate('pricePositive');
  String get variants => translate('variants');
  String get wholesaler => translate('wholesaler');
  String get description => translate('description');
  String get productTitle => translate('productTitle');
  String get productTitleRequired => translate('productTitleRequired');
  String get titleMinLength => translate('titleMinLength');
  String get pleaseSelectCategory => translate('pleaseSelectCategory');
  String get tapToSelectCategory => translate('tapToSelectCategory');
  String get pleaseSelectWholesaler => translate('pleaseSelectWholesaler');
  String get tapToSelectWholesaler => translate('tapToSelectWholesaler');
  String get yourAccount => translate('yourAccount');
  String get currentUser => translate('currentUser');
  String get unknownCategory => translate('unknownCategory');
  String get variantSkuRequired => translate('variantSkuRequired');
  String get addAtLeastOneVariant => translate('addAtLeastOneVariant');
  String get dealTitle => translate('dealTitle');
  String get pleaseEnterDealTitle => translate('pleaseEnterDealTitle');
  String get dealType => translate('dealType');
  String get startDate => translate('startDate');
  String get endDate => translate('endDate');
  String get pleaseEnterDealPrice => translate('pleaseEnterDealPrice');
  String get originalPrice => translate('originalPrice');
  String get targetQuantity => translate('targetQuantity');
  String get pleaseEnterTargetQuantity =>
      translate('pleaseEnterTargetQuantity');
  String get targetQuantityMin => translate('targetQuantityMin');
  String get minOrderQty => translate('minOrderQty');
  String get pleaseEnterMinOrderQty => translate('pleaseEnterMinOrderQty');
  String get minOrderQtyMin => translate('minOrderQtyMin');
  String get maxOrderQuantityOptional => translate('maxOrderQuantityOptional');
  String get endDateMustBeAfterStartDate =>
      translate('endDateMustBeAfterStartDate');
  String get tapToSelectProduct => translate('tapToSelectProduct');
  String get unknownProduct => translate('unknownProduct');
  String get noVariantsMessage => translate('noVariantsMessage');
  String get selectVariantHelper => translate('selectVariantHelper');
  String get unableToLoadVariantsMessage =>
      translate('unableToLoadVariantsMessage');
  String get product => translate('product');
  String get pleaseSelectProduct => translate('pleaseSelectProduct');
  String get failedToCreateDeal => translate('failedToCreateDeal');
  String get dealNotification24hLabel => translate('dealNotification24hLabel');
  String get dealNotification24hHint => translate('dealNotification24hHint');
  String get dealNotification7dLabel => translate('dealNotification7dLabel');
  String get dealNotification7dHint => translate('dealNotification7dHint');
  String get notificationTemplatePlaceholdersError =>
      translate('notificationTemplatePlaceholdersError');
  String get invalidDateTimeFormat => translate('invalidDateTimeFormat');
  String get accessDenied => translate('accessDenied');
  String get managersSectionOnly => translate('managersSectionOnly');
  String get admin => translate('admin');
  String get role => translate('role');
  String get created => translate('created');
  String get subAdmin => translate('subAdmin');
  String get dashboard => translate('dashboard');
  String get allProducts => translate('allProducts');
  String get myProducts => translate('myProducts');
  String get allDeals => translate('allDeals');
  String get myDeals => translate('myDeals');
  String get manageDeals => translate('manageDeals');
  String get totalRevenue => translate('totalRevenue');
  String get myRevenue => translate('myRevenue');
  String get revenueDetail => translate('revenueDetail');
  String get myRevenueDetail => translate('myRevenueDetail');
  String get howCalculated => translate('howCalculated');
  String get productOrdersRevenue => translate('productOrdersRevenue');
  String get dealOrdersRevenue => translate('dealOrdersRevenue');
  String get totalGrossRevenue => translate('totalGrossRevenue');
  String platformCut(String percent) =>
      translate('platformCut').replaceAll('{percent}', percent);
  String get platformCutDescription => translate('platformCutDescription');
  String get revenueFromDeliveredOrders =>
      translate('revenueFromDeliveredOrders');
  String get revenueDetailAdminInfo => translate('revenueDetailAdminInfo');
  String get revenueDetailOwnerInfo => translate('revenueDetailOwnerInfo');
  String get revenueOrdersList => translate('revenueOrdersList');
  String get noRevenueOrdersYet => translate('noRevenueOrdersYet');
  String get errorLoading => translate('errorLoading');
  String get activeShops => translate('activeShops');
  String get activeMembers => translate('activeMembers');
  String get inactiveMembers => translate('inactiveMembers');
  String get activeShopsSubtitle => translate('activeShopsSubtitle');
  String get activeMembersSubtitle => translate('activeMembersSubtitle');
  String get inactiveMembersSubtitle => translate('inactiveMembersSubtitle');
  String get lastOrder => translate('lastOrder');
  String get lastActive => translate('lastActive');
  String get lastLogin => translate('lastLogin');
  String get joined => translate('joined');
  String get selectToNotify => translate('selectToNotify');
  String get deselect => translate('deselect');
  String get recipients => translate('recipients');
  String get notificationSent => translate('notificationSent');
  String get notifyDealParticipantsTitle =>
      translate('notifyDealParticipantsTitle');
  String get notifyDealParticipantsAudienceWarning =>
      translate('notifyDealParticipantsAudienceWarning');
  String get notifyDealParticipantsSendUpdateTooltip =>
      translate('notifyDealParticipantsSendUpdateTooltip');
  String get notifyDealParticipantsSending =>
      translate('notifyDealParticipantsSending');
  String get notifyDealParticipantsNoParticipantsError =>
      translate('notifyDealParticipantsNoParticipantsError');
  String get notifyDealParticipantsFailedToSend =>
      translate('notifyDealParticipantsFailedToSend');
  String get noInactiveMembers => translate('noInactiveMembers');
  String get selectAll => translate('selectAll');
  String get sendNotification => translate('sendNotification');
  String get title => translate('title');
  String get body => translate('body');
  String get send => translate('send');
  String get generateWithAI => translate('generateWithAI');
  String get generateNotificationPrompt =>
      translate('generateNotificationPrompt');
  String get weMissYou => translate('weMissYou');
  String get reEngagementDefaultBody => translate('reEngagementDefaultBody');
  String get notificationRemindHint => translate('notificationRemindHint');
  String get searchByNameEmail => translate('searchByNameEmail');
  String get generate => translate('generate');
  String get page => translate('page');
  String get never => translate('never');
  String get quickActions => translate('quickActions');
  String get recentOrders => translate('recentOrders');
  String get noRecentOrders => translate('noRecentOrders');
  String get items => translate('items');
  String get analyticsComingSoon => translate('analyticsComingSoon');
  String get importCsv => translate('importCsv');
  String get importProductsFromCsv => translate('importProductsFromCsv');
  String get importProducts => translate('importProducts');
  String get importing => translate('importing');
  String get downloadCsvTemplate => translate('downloadCsvTemplate');
  String get getSampleCsvWithColumns => translate('getSampleCsvWithColumns');
  String get selectCsvFile => translate('selectCsvFile');
  String get chooseFile => translate('chooseFile');
  String get tapToSelectWholesalerForImport =>
      translate('tapToSelectWholesalerForImport');
  String get importComplete => translate('importComplete');
  String get inserted => translate('inserted');
  String get updated => translate('updated');
  String get skipped => translate('skipped');
  String get fileLabel => translate('fileLabel');
  String get wholesalerRequired => translate('wholesalerRequired');
  String get wholesalerLabel => translate('wholesalerLabel');
  String get csvPreviewRows => translate('csvPreviewRows');
  String get multipleRowsSameProductVariant =>
      translate('multipleRowsSameProductVariant');
  String get errorsCount => translate('errorsCount');
  String get andMoreErrors => translate('andMoreErrors');
  String get failedToReadFileBytes => translate('failedToReadFileBytes');
  String get failedToGetFilePath => translate('failedToGetFilePath');
  String get errorPickingFile => translate('errorPickingFile');
  String get csvFileEmpty => translate('csvFileEmpty');
  String get errorParsingCsv => translate('errorParsingCsv');
  String get searchProductsHint => translate('searchProductsHint');
  String get noProductsYet => translate('noProductsYet');
  String get addFirstProduct => translate('addFirstProduct');
  String get loadingMoreProducts => translate('loadingMoreProducts');
  String get reachedEnd => translate('reachedEnd');
  String get deleteProduct => translate('deleteProduct');
  String get deletingProduct => translate('deletingProduct');
  String get deleteProductConfirmGeneric =>
      translate('deleteProductConfirmGeneric');
  String get edit => translate('edit');
  String get changeStatus => translate('changeStatus');
  String get delete => translate('delete');
  String get allOrders => translate('allOrders');
  String get pendingConfirmation => translate('pendingConfirmation');
  String get packing => translate('packing');
  String get dispatched => translate('dispatched');
  String get outForDelivery => translate('outForDelivery');
  String get viewDetails => translate('viewDetails');
  String get changeOrderStatus => translate('changeOrderStatus');
  String get orderStatusUpdatedSuccessfully =>
      translate('orderStatusUpdatedSuccessfully');
  String get noDealsYet => translate('noDealsYet');
  String get cancelled => translate('cancelled');
  String get ordersCountSuffix => translate('ordersCountSuffix');
  String get manageBanners => translate('manageBanners');
  String get noBannersFound => translate('noBannersFound');
  String get targetId => translate('targetId');
  String get url => translate('url');
  String get deleteBanner => translate('deleteBanner');
  String get deleteBannerConfirm => translate('deleteBannerConfirm');
  String get bannerDeleted => translate('bannerDeleted');
  String get bannerUpdated => translate('bannerUpdated');
  String get bannerEditSubmittedForApproval =>
      translate('bannerEditSubmittedForApproval');
  String get bannerDetails => translate('bannerDetails');
  String get bannerNotFound => translate('bannerNotFound');
  String get views => translate('views');
  String get clicks => translate('clicks');
  String get failedToDeleteBanner => translate('failedToDeleteBanner');
  String get viewProduct => translate('viewProduct');
  String get viewDeal => translate('viewDeal');
  String get openLink => translate('openLink');
  String get discoverGreatDealsNearby => translate('discoverGreatDealsNearby');
  String get stayTunedForOffers => translate('stayTunedForOffers');

  // Categories
  String get noCategoriesFound => translate('noCategoriesFound');
  String get noCategoriesAvailable => translate('noCategoriesAvailable');
  String get allCategories => translate('allCategories');
  String get searchCategories => translate('searchCategories');
  String get noCategoriesMatchSearch => translate('noCategoriesMatchSearch');
  String get categoriesWillAppearHere => translate('categoriesWillAppearHere');
  String get tryDifferentSearchTerm => translate('tryDifferentSearchTerm');
  String get errorLoadingCategories => translate('errorLoadingCategories');
  String get unableToLoadCategory => translate('unableToLoadCategory');
  String get productsCount => translate('productsCount');
  String get productsCountSuffix => translate('productsCountSuffix');
  String get categoryName => translate('categoryName');
  String get categoryDescription => translate('categoryDescription');
  String get categoryImageUrl => translate('categoryImageUrl');
  String get createCategory => translate('createCategory');
  String get editCategory => translate('editCategory');
  String get deleteCategory => translate('deleteCategory');
  String get deleteCategoryConfirm => translate('deleteCategoryConfirm');
  String get categoryCreatedSuccessfully =>
      translate('categoryCreatedSuccessfully');
  String get enterCategoryDescriptionToGenerate =>
      translate('enterCategoryDescriptionToGenerate');
  String get categoryDescriptionHint => translate('categoryDescriptionHint');
  String get contentGeneratedSuccessfullyEnglish =>
      translate('contentGeneratedSuccessfullyEnglish');
  String get generationFailedWithError =>
      translate('generationFailedWithError');
  String get categoryUpdatedSuccessfully =>
      translate('categoryUpdatedSuccessfully');
  String get categoryDeletedSuccessfully =>
      translate('categoryDeletedSuccessfully');
  String get categoryCreationImportMessage =>
      translate('categoryCreationImportMessage');
  String get pleaseEnterCategoryName => translate('pleaseEnterCategoryName');

  // Account Approval / Waiting Screen
  String get accountApproval => translate('accountApproval');
  String get accountApproved => translate('accountApproved');
  String get redirecting => translate('redirecting');
  String get pendingReview => translate('pendingReview');
  String get needMoreInfo => translate('needMoreInfo');
  String get wholesalerVerificationMessage =>
      translate('wholesalerVerificationMessage');
  String get buyerVerificationMessage => translate('buyerVerificationMessage');
  String get generalVerificationMessage =>
      translate('generalVerificationMessage');
  String get adminNote => translate('adminNote');
  String get uploadVerificationDocument =>
      translate('uploadVerificationDocument');
  String get acceptedDocumentTypes => translate('acceptedDocumentTypes');
  String get wholesalerDocumentTypes => translate('wholesalerDocumentTypes');
  String get buyerDocumentTypes => translate('buyerDocumentTypes');
  String get generalDocumentTypes => translate('generalDocumentTypes');
  String get selectedDocuments => translate('selectedDocuments');
  String get addDocuments => translate('addDocuments');
  String get documentRemoved => translate('documentRemoved');
  String get uploading => translate('uploading');
  String get uploaded => translate('uploaded');
  String get selectFirst => translate('selectFirst');
  String get documentsUploadedSuccessfully =>
      translate('documentsUploadedSuccessfully');
  String get documentUploadedSuccessfully =>
      translate('documentUploadedSuccessfully');
  String get failedToPickDocuments => translate('failedToPickDocuments');
  String get pleaseSelectAtLeastOneDocument =>
      translate('pleaseSelectAtLeastOneDocument');
  String get passport => translate('passport');
  String get passportDescription => translate('passportDescription');
  String get passportAlternative => translate('passportAlternative');
  String get gewerbeschein => translate('gewerbeschein');
  String get idCard => translate('idCard');
  String get taxId => translate('taxId');
  String get companyRegistration => translate('companyRegistration');
  String get document => translate('document');
  String get gewerbescheinDescription =>
      translate('gewerbescheinDescription');
  String get gewerbescheinAlternative =>
      translate('gewerbescheinAlternative');
  String get businessLicense => translate('businessLicense');
  String get businessLicenseDescription =>
      translate('businessLicenseDescription');
  String get businessLicenseAlternative =>
      translate('businessLicenseAlternative');
  String get selectDocument => translate('selectDocument');
  String get changeDocument => translate('changeDocument');
  String get sendByEmail => translate('sendByEmail');
  String get emailOptionDescription => translate('emailOptionDescription');
  String get openEmailToAdmin => translate('openEmailToAdmin');
  String get emailDraftOpened => translate('emailDraftOpened');
  String get couldNotOpenEmailApp => translate('couldNotOpenEmailApp');
  String get manually => translate('manually');
  String get failedToOpenEmail => translate('failedToOpenEmail');
  String get loadingAccountStatus => translate('loadingAccountStatus');
  String get errorLoadingStatus => translate('errorLoadingStatus');
  String get pleaseReviewAndResubmit => translate('pleaseReviewAndResubmit');
  String get useDifferentAccount => translate('useDifferentAccount');
  String get useDifferentAccountConfirm =>
      translate('useDifferentAccountConfirm');

  // Navigation / Route Errors
  String get noStoryDataProvided => translate('noStoryDataProvided');
  String get missingWholesalerId => translate('missingWholesalerId');
  String get missingProductId => translate('missingProductId');
  String get missingCategorySlug => translate('missingCategorySlug');
  String get missingDealId => translate('missingDealId');
  String get missingOrderId => translate('missingOrderId');
  String get featuredProducts => translate('featuredProducts');

  // Order Update / Quantity Change
  String get orderUpdate => translate('orderUpdate');
  String get viewMyOrders => translate('viewMyOrders');
  String get goToHome => translate('goToHome');
  String get quantityChangeAccepted => translate('quantityChangeAccepted');
  String get quantityChangeDeclined => translate('quantityChangeDeclined');
  String get somethingWentWrong => translate('somethingWentWrong');
  String get orderUpdatedMessage => translate('orderUpdatedMessage');
  String get orderRevertedMessage => translate('orderRevertedMessage');
  String get pleaseTryAgainLater => translate('pleaseTryAgainLater');

  // Deal Detail / Errors
  String get unableToLoadDeal => translate('unableToLoadDeal');
  String get regularPrice => translate('regularPrice');
  String get stockLabel => translate('stockLabel');
  String get dealEnded => translate('dealEnded');
  String get dealNotStarted => translate('dealNotStarted');
  String get adminWholesalerManageHint => translate('adminWholesalerManageHint');
  String get adminDealOnlyOwnerCanBid => translate('adminDealOnlyOwnerCanBid');
  String get kioskOnlyPlaceOrders => translate('kioskOnlyPlaceOrders');
  String get managementView => translate('managementView');
  String get ordering => translate('ordering');
  String get failedToLoadDealData => translate('failedToLoadDealData');
  String get dealClosedSuccess => translate('dealClosedSuccess');
  String get failedToCloseDeal => translate('failedToCloseDeal');
  String get onlyAdminCanAddBidsOnAdminDeals =>
      translate('onlyAdminCanAddBidsOnAdminDeals');

  // Product Search / Detail
  String get searchProducts => translate('searchProducts');
  String get youCanOnlyReviewFromDeliveredOrders =>
      translate('youCanOnlyReviewFromDeliveredOrders');
  String get allImages => translate('allImages');
  String get contentGeneratedSuccessfully =>
      translate('contentGeneratedSuccessfully');
  String get generationFailed => translate('generationFailed');
  String get userIdRequired => translate('userIdRequired');

  // Admin Banner
  String get adminBannerManagement => translate('adminBannerManagement');
  String get requests => translate('requests');
  String get active => translate('active');
  String get noBannersFoundShort => translate('noBannersFoundShort');
  String get failedToUpdateBanner => translate('failedToUpdateBanner');
  String get bannerSubmittedSuccessfully =>
      translate('bannerSubmittedSuccessfully');
  String get failedToCreateBanner => translate('failedToCreateBanner');
  String get failedToSubmitBannerRequest =>
      translate('failedToSubmitBannerRequest');

  // User Management
  String get administratorsOnlySection =>
      translate('administratorsOnlySection');
  String get allRoles => translate('allRoles');
  String get allStatuses => translate('allStatuses');
  String get suspended => translate('suspended');
  String get noUsersFound => translate('noUsersFound');
  String get pageOf => translate('pageOf');
  String get ofLabel => translate('ofLabel');
  String get documentN => translate('documentN');
  String get noDocumentsAvailable => translate('noDocumentsAvailable');
  String get userUpdatedSuccessfully => translate('userUpdatedSuccessfully');
  String get userCreatedSuccessfully => translate('userCreatedSuccessfully');
  String get userDeletedSuccessfully => translate('userDeletedSuccessfully');
  String get deleteUser => translate('deleteUser');
  String get deleteUserConfirm => translate('deleteUserConfirm');
  String get verificationDocuments => translate('verificationDocuments');
  String get noVerificationDocumentsYet =>
      translate('noVerificationDocumentsYet');
  String get rejectionReason => translate('rejectionReason');
  String get createUser => translate('createUser');
  String get editUser => translate('editUser');
  String get updateUser => translate('updateUser');
  String get roleRequired => translate('roleRequired');
  String get statusRequired => translate('statusRequired');
  String get newPasswordLeaveEmpty => translate('newPasswordLeaveEmpty');
  String get passwordRequired => translate('passwordRequired');
  String get passwordMinLength => translate('passwordMinLength');
  String get needInfo => translate('needInfo');
  String get business => translate('business');
  String get searchByNameEmailPhone => translate('searchByNameEmailPhone');
  String get daysAgo => translate('daysAgo');
  String get activeDaysLast14 => translate('activeDaysLast14');
  String get docsCount => translate('docsCount');
  String get noPassportDocuments => translate('noPassportDocuments');
  String get noGewerbescheinDocuments =>
      translate('noGewerbescheinDocuments');
  String get noBusinessLicenseDocuments =>
      translate('noBusinessLicenseDocuments');
  String get openInBrowser => translate('openInBrowser');
  String get pdfDocument => translate('pdfDocument');
  String get kiosk => translate('kiosk');

  // Order Management
  String get errorLoadingOrders => translate('errorLoadingOrders');
  String get errorLoadingDeals => translate('errorLoadingDeals');
  String get orderManagement => translate('orderManagement');
  String get orderCountSuffix => translate('orderCountSuffix');
  String get confirmOrder => translate('confirmOrder');
  String get confirmOrderMessage => translate('confirmOrderMessage');
  String get confirm => translate('confirm');
  String get markAsDelivered => translate('markAsDelivered');
  String get markDelivered => translate('markDelivered');
  String get cancelOrder => translate('cancelOrder');
  String get cancelOrderConfirm => translate('cancelOrderConfirm');
  String get no => translate('no');
  String get reduceQuantity => translate('reduceQuantity');
  String get orderConfirmedSuccess => translate('orderConfirmedSuccess');
  String get orderMarkedDelivered => translate('orderMarkedDelivered');
  String get failedToConfirmOrder => translate('failedToConfirmOrder');
  String get failedToMarkDelivered => translate('failedToMarkDelivered');
  String get orderCancelled => translate('orderCancelled');
  String get failedToCancelOrder => translate('failedToCancelOrder');
  String get orderMarkedPaid => translate('orderMarkedPaid');
  String get failedToMarkOrderPaid => translate('failedToMarkOrderPaid');
  String get quantityUpdatedSuccess => translate('quantityUpdatedSuccess');
  String get failedToUpdateQuantity => translate('failedToUpdateQuantity');
  String get deliveryNotesOptional => translate('deliveryNotesOptional');
  String get newQuantity => translate('newQuantity');
  String get reduceQuantityHint => translate('reduceQuantityHint');
  String get quantityUpdatedTo => translate('quantityUpdatedTo');

  // Deal Order Form
  String get enterQuantity => translate('enterQuantity');
  String get pleaseEnterQuantity => translate('pleaseEnterQuantity');
  String get invalidQuantity => translate('invalidQuantity');
  String get minimumOrderIs => translate('minimumOrderIs');
  String get maximumOrderIs => translate('maximumOrderIs');
  String get addSpecialInstructions => translate('addSpecialInstructions');
  String get minQuantityLabel => translate('minQuantityLabel');
  String get selectedLabel => translate('selectedLabel');
  String get maxQuantityLabel => translate('maxQuantityLabel');

  // Shipment
  String get pleaseSelectCarrier => translate('pleaseSelectCarrier');
  String get pleaseEnterCarrierNameForOther =>
      translate('pleaseEnterCarrierNameForOther');
  String get shipmentCreatedSuccess => translate('shipmentCreatedSuccess');
  String get shipmentCreatedAndOrderShipped =>
      translate('shipmentCreatedAndOrderShipped');
  String get failedToCreateShipment => translate('failedToCreateShipment');

  // Stories
  String get failedToPickMedia => translate('failedToPickMedia');
  String get onlyWholesalersCanCreateStories =>
      translate('onlyWholesalersCanCreateStories');
  String get storyCreatedSuccess => translate('storyCreatedSuccess');
  String get failedToCreateStory => translate('failedToCreateStory');

  // Payment
  String get paymentCompletedSuccess => translate('paymentCompletedSuccess');
  String get paymentFailed => translate('paymentFailed');

  // Notifications
  String get notifications => translate('notifications');
  String get markAllAsRead => translate('markAllAsRead');
  String get deleteAll => translate('deleteAll');
  String get filterNotifications => translate('filterNotifications');
  String get unread => translate('unread');
  String get read => translate('read');
  String get deleteAllNotificationsConfirm =>
      translate('deleteAllNotificationsConfirm');
  String get deleteAllNotificationsMessage =>
      translate('deleteAllNotificationsMessage');
  String get deleteAllNotificationsSuccess =>
      translate('deleteAllNotificationsSuccess');
  String get markedAllAsRead => translate('markedAllAsRead');

  // Deal/Product Modals
  String get paymentEmailTemplateGenerated =>
      translate('paymentEmailTemplateGenerated');
  String get aiGenerationFailed => translate('aiGenerationFailed');
  String get dealUpdatedSuccess => translate('dealUpdatedSuccess');
  String get allowOnlinePayment => translate('allowOnlinePayment');
  String get allowOnlinePaymentSubtitle =>
      translate('allowOnlinePaymentSubtitle');
  String get paymentAndEmail => translate('paymentAndEmail');
  String get generating => translate('generating');
  String get enterDealDescriptionPrompt =>
      translate('enterDealDescriptionPrompt');
  String get dealDescriptionHint => translate('dealDescriptionHint');
  String get enterProductDescriptionPrompt =>
      translate('enterProductDescriptionPrompt');
  String get productDescriptionHint => translate('productDescriptionHint');
  String get optionalAutoAssigned => translate('optionalAutoAssigned');
  String get defaultYourAccount => translate('defaultYourAccount');
  String get currentUserYou => translate('currentUserYou');
  String get loadingProductDetails => translate('loadingProductDetails');
  String get loading => translate('loading');
  String get ibanBankAccount => translate('ibanBankAccount');
  String get accountOwner => translate('accountOwner');
  String get referenceTemplate => translate('referenceTemplate');
  String get paymentInstructions => translate('paymentInstructions');
  String get paymentEmailSubject => translate('paymentEmailSubject');
  String get paymentEmailBody => translate('paymentEmailBody');
  String get ended => translate('ended');
  String get dealHasEnded => translate('dealHasEnded');
  String get endsIn1Day => translate('endsIn1Day');
  String get endsInDays => translate('endsInDays');
  String get endsIn1Hour => translate('endsIn1Hour');
  String get endsInHours => translate('endsInHours');
  String get endsSoon => translate('endsSoon');
  String get categories => translate('categories');
  String get itemsCount => translate('itemsCount');

  // Shipment Tracking
  String get pleaseEnterTrackingNumber => translate('pleaseEnterTrackingNumber');
  String get pleaseSelectAtLeastOneItemToShip =>
      translate('pleaseSelectAtLeastOneItemToShip');
  String get pleaseEnterTrackingUrlForOther =>
      translate('pleaseEnterTrackingUrlForOther');
  String get selectItemsToShip => translate('selectItemsToShip');
  String get noItemsAvailableForShipment =>
      translate('noItemsAvailableForShipment');
  String get selectCarrier => translate('selectCarrier');
  String get selectCarrierHint => translate('selectCarrierHint');
  String get carrierName => translate('carrierName');
  String get enterCarrierName => translate('enterCarrierName');
  String get trackingNumberRequired => translate('trackingNumberRequired');
  String get trackingUrlAutoGenerated =>
      translate('trackingUrlAutoGenerated');
  String get trackingUrlRequiredForOther =>
      translate('trackingUrlRequiredForOther');
  String get pleaseEnterValidUrl => translate('pleaseEnterValidUrl');
  String get estimatedDeliveryDate => translate('estimatedDeliveryDate');
  String get selectDate => translate('selectDate');
  String get internalNotesShipment => translate('internalNotesShipment');
  String get trackingUrlHintAuto => translate('trackingUrlHintAuto');
  String get trackShipment => translate('trackShipment');
  String get enterTrackingNumber => translate('enterTrackingNumber');
  String get trackShipmentHint => translate('trackShipmentHint');
  String get trackingDetails => translate('trackingDetails');
  String get shipmentNotFound => translate('shipmentNotFound');
  String get pleaseCheckTrackingNumber =>
      translate('pleaseCheckTrackingNumber');
  String get noNotifications => translate('noNotifications');
  String get youreAllCaughtUp => translate('youreAllCaughtUp');

  // Feature audit – previously hardcoded strings (only new keys; others exist)
  String get platformMobile => translate('platformMobile');
  String get platformWeb => translate('platformWeb');
  String get pleaseWait => translate('pleaseWait');
  String get defaultVariant => translate('defaultVariant');
  String get trackOnCarrierWebsite => translate('trackOnCarrierWebsite');
  String get minOrderQtyRequired => translate('minOrderQtyRequired');
  String get dealPriceRequired => translate('dealPriceRequired');
  String get targetQuantityRequired => translate('targetQuantityRequired');
  String get baseShippingCostEur => translate('baseShippingCostEur');
  String get freeShippingThresholdQuantity =>
      translate('freeShippingThresholdQuantity');
  String get perUnitShippingCostEur => translate('perUnitShippingCostEur');
  String get descriptionOptional => translate('descriptionOptional');
  String get enterBannerDescription => translate('enterBannerDescription');
  String get bannerType => translate('bannerType');
  String get targetUrl => translate('targetUrl');
  String get skuRequired => translate('skuRequired');
  String get productToPromoteHint => translate('productToPromoteHint');
  String get selectDealToPromote => translate('selectDealToPromote');
  String get titleOptional => translate('titleOptional');
  String get giveReviewTitle => translate('giveReviewTitle');
  String get yourReviewOptional => translate('yourReviewOptional');
  String get shareExperienceWithProduct =>
      translate('shareExperienceWithProduct');
  String get dealUpdatedSuccessfully => translate('dealUpdatedSuccessfully');
  String get dealPriceMustBeValidNumber =>
      translate('dealPriceMustBeValidNumber');
  String get pleaseEnterMinOrderQuantity =>
      translate('pleaseEnterMinOrderQuantity');
  String get paymentEmailPlaceholdersSubject =>
      translate('paymentEmailPlaceholdersSubject');
  String get paymentEmailPlaceholdersBody =>
      translate('paymentEmailPlaceholdersBody');
  // Legal Terms
  String get legalDocumentsTitle => translate('legalDocumentsTitle');
  String get readAndAcceptAgbPrefix => translate('readAndAcceptAgbPrefix');
  String get agbLinkText => translate('agbLinkText');
  String get readAndAcceptAgbSuffix => translate('readAndAcceptAgbSuffix');
  String get acceptCompliancePrefix => translate('acceptCompliancePrefix');
  String get complianceLinkText => translate('complianceLinkText');
  String get acceptComplianceSuffix => translate('acceptComplianceSuffix');
  String get agreePrivacyPrefix => translate('agreePrivacyPrefix');
  String get privacyLinkText => translate('privacyLinkText');
  String get agreePrivacySuffix => translate('agreePrivacySuffix');
  String get confirmFrameworkPrefix => translate('confirmFrameworkPrefix');
  String get frameworkLinkText => translate('frameworkLinkText');
  String get confirmFrameworkSuffix => translate('confirmFrameworkSuffix');

  String get failed => translate('failed');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLanguages.supportedCodes.contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
