class EnglishFile {
  static const Map<String, String> englishTranslations = {
    // ============================================
    // Options Screen Related
    // ============================================
    'options': 'Options',
    'account': 'Account',
    'myOrders': 'My Orders',
    'myOrdersSubtitle': 'View and track your orders',
    'statistics': 'Statistics',
    'statisticsSubtitle': 'View your deal participation stats',
    'profile': 'Profile',
    'profileSubtitle': 'Manage your account',
    'management': 'Management',
    'manageCategories': 'Manage Categories',
    'manageCategoriesSubtitle': 'Create and manage product categories',
    'createNewProductSubtitle': 'Create a new product',
    'createNewDealSubtitle': 'Create a new deal',
    'viewOrdersSubtitle': 'View and manage orders',
    'inactiveMembersViewSubtitle': 'View shops with no recent orders',
    'manageBannersSubtitle': 'Manage app banners (admin)',
    'myBannersSubtitle': 'Manage your banners',
    'unableToLoadOptions': 'Unable to load options',
    'loggingOut': 'Logging out...',
    'manageUsers': 'Manage Users',
    'manageUsersSubtitle': 'View and manage user accounts',
    'analytics': 'Analytics',
    'analyticsSubtitle': 'View your business analytics',
    'information': 'Information',
    'faq': 'FAQ',
    'faqSubtitle': 'Frequently asked questions',
    'aboutUs': 'About Us',
    'aboutUsSubtitle': 'Learn more about our platform',
    'helpSupport': 'Help & Support',
    'helpSupportSubtitle': 'Get help and contact support',
    'accountActions': 'Account Actions',
    'deleteAccount': 'Delete Account',
    'deleteAccountSubtitle': 'Request to permanently delete your account',
    'logout': 'Logout',
    'logoutSubtitle': 'Sign out of your account',
    'confirmLogout': 'Confirm Logout',
    'confirmLogoutMessage': 'Are you sure you want to logout?',
    'cancel': 'Cancel',
    'loginAgain': 'Login again',

    // ============================================
    // Language Related
    // ============================================
    'language': 'Language',
    'languageSubtitle': 'Change app language',
    'notificationSettings': 'Notification Settings',
    'notificationSettingsSubtitle':
        'Choose which notifications you want to receive.',
    'notificationChannels': 'Channels',
    'pushNotifications': 'Push Notifications',
    'pushNotificationsSubtitle':
        'Receive push notifications on your device',
    'emailNotifications': 'Email Notifications',
    'emailNotificationsSubtitle': 'Receive notifications via email',
    'notificationModules': 'By Category',
    'notificationSettingsSaved': 'Notification settings saved',
    'notificationModuleProducts': 'Products',
    'notificationModuleProductOrders': 'Product Orders',
    'notificationModuleDeals': 'Deals',
    'notificationModuleDealOrders': 'Deal Orders',
    'notificationModuleBanners': 'Banners',
    'notificationModuleAdmin': 'Admin',
    'notificationModuleEngagement': 'Engagement',
    'notificationModulePayment': 'Payment',
    'push': 'Push',
    'currency': 'Currency',
    'currencySubtitle': 'Display currency for prices (default: device)',
    'systemDefault': 'System default',
    'syncFxRates': 'Sync FX rates',
    'syncFxRatesSubtitle': 'Fetch latest exchange rates from ECB',
    'syncFxRatesSuccess': 'FX rates updated successfully',
    'syncFxRatesFailed': 'Could not update FX rates. Using cached rates.',
    'changingLanguage': 'Changing language...',
    'languageChangeFailed':
        'Failed to sync language preference. Please try again.',
    'failedToChangeLanguage': 'Failed to change language. Please try again.',
    'english': 'English',
    'german': 'German',
    'turkish': 'Turkish',
    'arabic': 'Arabic',
    'urdu': 'Urdu',
    'hindi': 'Hindi',
    'russian': 'Russian',
    'sourceLanguageLabel': 'Content language',
    'sourceLanguageHint': 'Language of the text you enter (will be translated to other languages)',
    'selectYourLanguage': 'Select your language',
    'selectYourLanguageSubtitle':
        'Choose the language for the app. You can change it later in settings.',
    'continueButton': 'Continue',

    // ============================================
    // Common / General
    // ============================================
    'sessionExpired': 'Session expired',
    'sessionExpiredMessage':
        'Your session has expired. Please log in again to continue using the app.',
    'comingSoon': 'Coming soon',
    'retry': 'Retry',
    'error': 'Error',
    'errorWithDetail': 'Error: {detail}',
    'close': 'Close',
    'save': 'Save',
    'done': 'Done',
    'saving': 'Saving...',
    'update': 'Update',
    'edit': 'Edit',
    'delete': 'Delete',
    'add': 'Add',
    'remove': 'Remove',
    'select': 'Select',
    'all': 'All',
    'filter': 'Filter',
    'type': 'Type',
    'status': 'Status',
    'unknown': 'Unknown',

    // ============================================
    // About Us Related
    // ============================================
    'welcomeToProductDeal': 'Welcome to Product Deal',
    'trustedMarketplace':
        'Your trusted marketplace for wholesale products and deals',
    'ourMission': 'Our Mission',
    'ourMissionContent':
        'To connect wholesalers and retailers, making bulk purchasing accessible and efficient for businesses of all sizes.',
    'whatWeOffer': 'What We Offer',
    'whatWeOfferContent':
        '• Access to verified wholesalers\n• Exclusive bulk deals and discounts\n• Real-time inventory tracking\n• Secure order management\n• Location-based product discovery',
    'forWholesalers': 'For Wholesalers',
    'forRetailers': 'For Retailers',
    'forRetailersContent':
        'Discover products from nearby wholesalers, participate in bulk deals, and manage your orders efficiently.',
    'forWholesalersContent':
        'Showcase your products, create exclusive deals, manage orders, and reach a wider network of retailers.',

    // ============================================
    // FAQ Related
    // ============================================
    'frequentlyAskedQuestions': 'Frequently Asked Questions',
    'commonQuestions': 'Common Questions',
    'faqQuestion1': 'How do I place an order?',
    'faqAnswer1':
        'Browse active deals or products, select the quantity you need, and click "Place Order". Your order will be reviewed by the wholesaler.',
    'faqQuestion2': 'What are deal orders?',
    'faqAnswer2':
        'Deal orders are bulk purchasing opportunities where wholesalers offer discounted prices when a target quantity is reached. You can place multiple orders on the same deal.',
    'faqQuestion3': 'How is shipping handled?',
    'faqAnswer3':
        'Shipping details are arranged directly with the wholesaler after your order is confirmed. Contact information will be provided upon order confirmation.',
    'faqQuestion4': 'Can I cancel an order?',
    'faqAnswer4':
        'You can cancel pending orders. Once an order is confirmed by the wholesaler, cancellation policies apply as per the wholesaler\'s terms.',
    'faqQuestion5': 'How do I become a verified wholesaler?',
    'faqAnswer5':
        'Contact our support team to get verified. You\'ll need to provide business documentation and complete the verification process.',
    'faqQuestion6': 'How are products sorted by distance?',
    'faqAnswer6':
        'Products are automatically sorted by proximity to your location. Make sure to add your location in your profile for accurate distance-based sorting.',
    'faqQuestion7': 'What payment methods are accepted?',
    'faqAnswer7':
        'Payment methods vary by wholesaler. Payment details are discussed after order confirmation.',
    'faqQuestion8': 'How do I update my profile?',
    'faqAnswer8':
        'Go to your profile page from the dashboard, update your information, and save. You can add multiple addresses for different locations.',

    // ============================================
    // Wholesaler Directory Related
    // ============================================
    'couldNotLoadWholesalers': 'We couldn\'t load wholesalers right now.',
    'verifiedPartners': 'verified partners',
    'verifiedPartnersDescription': 'verified partners',
    'noWholesalersNearYou':
        'No wholesalers near you yet. Update your location to unlock nearby inventory.',

    // ============================================
    // Dashboard Related
    // ============================================
    'dashboard': 'Dashboard',
    'nearbyWholesalers': 'Nearby wholesalers',
    'allWholesalers': 'All Wholesalers',
    'noWholesalersFound': 'No wholesalers found',
    'errorLoadingWholesalers': 'Error loading wholesalers',
    'advertiseWithUs': 'Advertise with us',
    'boostYourSales': 'Boost your sales!',
    'promoteYourProducts':
        'Promote your products here and reach more customers.',
    'unableToLoadDashboard': 'Unable to load dashboard',
    'unableToLoadProduct': 'Unable to load product',
    'unableToLoadWholesaler': 'Unable to load wholesaler',
    'spotlight': 'Spotlight',
    'spotlightWholesalersEmpty':
        'Spotlight wholesalers will appear here once the marketplace is buzzing.',

    // ============================================
    // Orders Related
    // ============================================
    'orderId': 'Order ID',
    'payment': 'Payment',
    'paymentStatus': 'Payment Status',
    'placedOn': 'Placed on',
    'orderItems': 'Order Items',
    'createShipment': 'Create Shipment',
    'shippingAddress': 'Shipping Address',
    'notes': 'Notes',
    'orderNotes': 'Order Notes',
    'orderDetails': 'Order Details',
    'unableToLoadOrder': 'Unable to load order',
    'updateOrderStatus': 'Update Order Status',
    'subtotal': 'Subtotal',
    'shipping': 'Shipping',
    'shippingWithFreeThreshold': 'Shipping: {amount} (Free for {threshold}+ units)',
    'freeShippingForThreshold': 'Free shipping for {threshold}+ units',
    'shippingBaseOnly': 'Shipping: {amount}',
    'shippingWithPerUnit': 'Shipping: {base} + {perUnit} per unit',
    'total': 'Total',
    'reasonOptional': 'Reason (Optional)',
    'notesOptional': 'Notes (Optional)',
    'sku': 'SKU',
    'skuN/A': 'SKU: N/A',
    'trackingAvailable': 'TRACKING AVAILABLE',
    'shipped': 'Shipped',
    'shipments': 'Shipments',
    'shipmentId': 'Shipment {id}',
    'trackingLabel': 'Tracking: {number}',
    'track': 'Track',
    'couldNotOpenTrackingUrl': 'Could not open tracking URL',
    'carrierLabel': 'Carrier: {name}',
    'estDelivery': 'Est. delivery: {date}',
    'shippedAt': 'Shipped: {date}',
    'deliveredAt': 'Delivered: {date}',
    'each': 'each',
    'unit': 'Unit',
    'noOrdersYet': 'No orders yet',
    'noOrdersYetMessage':
        'Browse products and deals to place your first order.',
    'unableToLoadOrders': 'Unable to load your orders',
    'orderPlaced': 'Order Placed',
    'confirmed': 'Confirmed',
    'delivered': 'Delivered',
    'pendingOrders': 'Pending Orders',
    'viewOrders': 'View Orders',
    'allOrders': 'All Orders',
    'pendingConfirmation': 'Pending Confirmation',
    'packing': 'Packing',
    'packed': 'Packed',
    'dispatched': 'Dispatched',
    'outForDelivery': 'Out for Delivery',
    'viewDetails': 'View Details',
    'changeOrderStatus': 'Change Order Status',
    'orderStatusUpdatedSuccessfully': 'Order status updated successfully',
    'orderStatusUpdated': 'Order status updated successfully',
    'itemStatusUpdatedSuccessfully': 'Item status updated successfully',
    'itemStatusUpdated': 'Item status updated successfully',
    'ordersCountSuffix': 'orders',
    'order': 'order',
    'orderLabel': 'Order',
    'orders': 'orders',
    'ordered': 'ordered',
    'dealOrder': 'Deal order',
    'productOrder': 'Product order',
    'bid': 'Bid',
    'itemPlusMore': '{item} + {n} more',

    // ============================================
    // Cart Related
    // ============================================
    'yourCart': 'Your Cart',
    'cart': 'Cart',
    'emptyCart': 'Your cart is empty',
    'emptyCartMessage': 'Add products to your cart to get started.',
    'addProductsToSeeThemHere': 'Add products to see them here.',
    'placeOrderCashOnDelivery': 'Place Order (Cash on Delivery)',
    'cashOnDelivery': 'Cash on Delivery',
    'paymentMethodCash': 'Cash on Delivery',
    'paymentMethodCashDesc': 'Pay when you receive the delivery.',
    'paymentMethodInvoice': 'Invoice',
    'paymentMethodInvoiceDesc': 'We send you an invoice; shipment starts soon after order confirmation.',
    'paymentMethodBankTransfer': 'Bank Transfer',
    'paymentMethodBankTransferDesc': 'Pay first, then shipment. Payment instructions sent by email.',
    'sendPaymentInstructions': 'Send Payment Instructions',
    'paymentMode': 'Payment Mode',
    'paymentModeSubtitle': 'Default for your deals. You can change this later in your profile.',
    'paymentModeSubtitleMulti':
        'Select all payment methods you accept. You can change this later in your profile.',
    'paymentSettings': 'Payment Settings',
    'paymentSettingsSubtitle': 'Bank details for invoice/bank transfer orders. You can update these later in your profile.',
    'payWithCard': 'Pay with Card',
    'placeOrderPayNow': 'Place Order & Pay',
    'paymentAfterOrderConfirmed': 'Payment will be requested after your order is confirmed (e.g. bank transfer).',
    'paymentNotAvailable': 'Card payment is not available. Try Cash on Delivery.',
    'paymentCancelled': 'Payment was cancelled.',
    'dealSucceededPayNow': 'Deal succeeded – pay now',
    'totalToPay': 'Total to pay',
    'payByInvoice': 'Pay by invoice',
    'payByCard': 'Pay by card',
    'invoiceInstructionsSent': 'Payment instructions were sent by email.',
    'reportPayment': "I've made the payment",
    'buyerReportedPayment': "Buyer's payment info",
    'reportedAt': 'Reported at',
    'reportPaymentSubtitle': 'Share your payment details so we can verify',
    'reportPaymentSuccess': 'Payment details submitted. The seller will verify and update the order.',
    'referenceNumber': 'Reference number',
    'transactionId': 'Transaction ID',
    'bankName': 'Bank name',
    'paymentDetailsNotes': 'Additional notes (optional)',
    'paymentInstructionsBankOnly': 'Payment instructions were sent by email. Pay by bank transfer. If you\'ve already paid, the deal owner will confirm receipt.',
    'markAsPaid': 'Mark as paid',
    'paymentNotesOptional': 'Payment notes (e.g. bank reference)',
    'myDealStats': 'My deal stats',
    'dealsJoined': 'Deals joined',
    'totalOrderedQuantity': 'Total quantity ordered',
    'totalOrders': 'Total orders',
    'placeOrder': 'Place Order',
    'fxDisclaimer':
        'FX rate is subject to change. Displayed amount is indicative.',
    'placingOrder': 'Placing Order...',
    'orderPlacedSuccessfully': 'Order placed successfully!',
    'failedToPlaceOrder': 'Failed to place order',
    'onlyKioskCanOrder': 'Only Kiosk/Shop accounts can place orders.',
    'admins': 'Admins',
    'subAdmins': 'Sub-Admins',
    'wholesalers': 'Wholesalers',
    'canOnlyViewProducts':
        'can only view products. Only Kiosk/Shop accounts can place orders.',
    'addToCart': 'Add to cart',
    'addedToCart': '✅ Added to cart',
    'quantity': 'Quantity',
    'unitPrice': 'Unit Price',
    'totalAmount': 'Total Amount',
    'buyer': 'Buyer',
    'items': 'items',

    // ============================================
    // Registration Related
    // ============================================
    'register': 'Register',
    'createAccount': 'Create Account',
    'createAccountTitle': 'Create account',
    'createAccountSubtitle':
        'Unlock curated wholesalers, big deals and logistics support.',
    'fullName': 'Full Name',
    'email': 'Email',
    'workEmail': 'Work email',
    'phone': 'Phone',
    'password': 'Password',
    'confirmPassword': 'Confirm Password',
    'confirmPasswordLabel': 'Confirm password',
    'businessName': 'Business Name',
    'country': 'Country',
    'city': 'City',
    'address': 'Address',
    'streetAddress': 'Street address',
    'addressWillBeGeocoded':
        'Address will be automatically geocoded to get coordinates',
    'addressSearchHint': 'Search your address',
    'placesLookupFailed':
        'Could not load address details from the server. You can type or edit '
            'your address manually.',
    'placesNoAddressResults':
        'No addresses found. Try a different search.',
    'placesAddressSearchConfigError':
        'Address search is unavailable. Check your network and that this app '
            'uses the correct API server (API_BASE_URL).',
    'placesAddressSearchRequestFailed':
        'Address search failed. Check your connection or try again later.',
    'getLocation': 'Get Location',
    'selectRole': 'Select Role',
    'accountType': 'Account type',
    'alreadyHaveAccount': 'Already have an account?',
    'login': 'Login',
    'signIn': 'Sign in',
    'registrationReceived':
        'Registration received! We will notify you once the account is approved.',
    'fullNameRequired': 'Full name is required',
    'fullNameMinLength': 'Full name must be at least 3 characters',
    'emailRequired': 'Email is required',
    'provideValidEmail': 'Provide a valid email',
    'phoneNumberOptional': 'Phone number (optional)',
    'enterValidPhoneNumber': 'Enter a valid phone number',
    'kioskShopNameOptional': 'Kiosk / Shop name (optional)',
    'companyName': 'Company name',
    'latitudeOptional': 'Latitude (optional)',
    'longitudeOptional': 'Longitude (optional)',
    'locating': 'Locating...',
    'locatingEllipsis': 'Locating…',
    'useCurrentLocation': 'Use current location',
    'enableLocationServices':
        'Enable location services to autofill coordinates.',
    'enableLocationPermissions':
        'Enable location permissions to autofill coordinates.',
    'unableToFetchLocation': 'Unable to fetch location. Please try again.',
    'unableToFetchLocationShort': 'Unable to fetch location.',
    'pleaseEnterValidLatLng': 'Please enter valid latitude and longitude.',
    'createPassword': 'Create password',
    'minimum8CharactersRequired': 'Minimum 8 characters required',
    'weVerifyEveryBusiness':
        'We verify every business manually to keep the marketplace trusted.',
    'submitForReview': 'Submit for review',
    'alreadyVerifiedSignIn': 'Already verified? Sign in',
    'forgotPassword': 'Forgot password?',
    'welcomeBack': 'Welcome back',
    'signInToReach': 'Sign in to reach approved wholesalers near you.',
    'createKioskOrWholesalerAccount': 'Create a kiosk or wholesaler account',
    'accountSubmittedForApproval':
        'Account submitted for approval. Dashboard will unlock once approved.',
    'dashboardWillUnlock': 'Dashboard will unlock once approved.',
    'pleaseLoginToPlaceOrder': 'Please login to place an order',

    // ============================================
    // Legal / Compliance (T&C + GDPR)
    // ============================================
    'legalComplianceTitle': 'Legal & Compliance',
    'termsAndConditionsFullText':
        'By creating an account you enter into a business relationship with the platform operator and agree to the platform\'s Terms & Conditions (AGB). '
        'These Terms govern how you may use the marketplace, how deals and orders are handled, and which obligations apply to buyers and wholesalers. '
        'You confirm that all information you provide is accurate and that you will only use the platform for legitimate business purposes. '
        'You further agree that deals and orders may become binding once confirmed by the wholesaler or once a deal target is reached. '
        'Additional country-specific regulations may apply depending on your jurisdiction. Please review the full Terms & Conditions shared by the operator before continuing.',
    'scrollToAcceptTerms':
        'Scroll to the end of the Terms & Conditions to unlock the acceptance checkbox.',
    'scrollToBottom': 'Scroll to bottom',
    'acceptTermsLabel':
        'I have read and accept the Terms & Conditions (AGB).',
    'termsScrollHint':
        'Please scroll through the Terms & Conditions before accepting.',
    'acceptPrivacyLabel':
        'I have read and accept the Data Privacy / GDPR policy.',
    'privacySummaryText':
        'Your data will be processed for account management, orders, analytics and security in line with our privacy policy.',
    'mustAcceptAllLegalDocuments':
        'Please accept all legal documents and confirm the framework contract.',
    'mustAcceptTermsAndPrivacy':
        'Please accept the Terms & Conditions and Data Privacy / GDPR to continue.',

    // ============================================
    // Account Approval / Waiting Screen Related
    // ============================================
    'accountApproval': 'Account Approval',
    'accountApproved': 'Account approved!',
    'redirecting': 'Redirecting...',
    'pendingReview': 'Pending review',
    'needMoreInfo': 'Need more information',
    'wholesalerVerificationMessage':
        'Thanks! To activate your wholesaler account, please submit your business verification documents. Our admin will review and approve your account.',
    'buyerVerificationMessage':
        'Thanks! To activate your buyer account, please submit your identity verification documents. Our admin will review and approve your account.',
    'generalVerificationMessage':
        'Thanks! To activate your account, please submit verification documents. Our admin will review and approve your account.',
    'adminNote': 'Admin note',
    'uploadVerificationDocument': 'Upload Verification Document',
    'acceptedDocumentTypes': 'Accepted document types',
    'wholesalerDocumentTypes':
        'Business license, Tax ID, Company registration documents (PNG, JPG, PDF)',
    'buyerDocumentTypes':
        'Identity card, Driver\'s license, or any government-issued ID (PNG, JPG, PDF)',
    'generalDocumentTypes':
        'Business license, Driver\'s license, Identity card (PNG, JPG, PDF)',
    'selectedDocuments': 'Selected Documents',
    'addDocuments': 'Add Documents',
    'uploading': 'Uploading...',
    'uploaded': 'Uploaded',
    'selectFirst': 'Select First',
    'documentsUploadedSuccessfully':
        'document(s) uploaded successfully. Our admin will review and update your account status.',
    'documentUploadedSuccessfully':
        'Document uploaded successfully. Our admin will review and update your account status.',
    'failedToPickDocuments': 'Failed to pick documents',
    'passport': 'Passport',
    'passportDescription': 'Upload your passport for identity verification',
    'passportAlternative':
        'If you don\'t have a passport, you can upload a government-approved ID card with address (e.g., Aadhar in India, National ID, etc.)',
    'gewerbeschein': 'Gewerbeschein',
    'idCard': 'ID Card',
    'taxId': 'Tax ID',
    'companyRegistration': 'Company Registration',
    'document': 'Document',
    'gewerbescheinDescription':
        'Upload your Gewerbeschein (Trade License) for business verification',
    'gewerbescheinAlternative':
        'Upload your official trade license document issued by the authorities',
    'businessLicense': 'Business License / Gewerbeschein',
    'businessLicenseDescription':
        'Upload your business license or Gewerbeschein for business verification',
    'businessLicenseAlternative':
        'If you don\'t have a business license, you can upload company registration documents, tax ID, or any official business verification document',
    'selectDocument': 'Select Document',
    'changeDocument': 'Change Document',
    'pleaseSelectAtLeastOneDocument':
        'Please select at least one document to upload.',
    'sendByEmail': 'Send by Email',
    'emailOptionDescription':
        'Alternatively, you can send your verification documents directly via email. Our admin will verify the documents and update your account status accordingly.',
    'openEmailToAdmin': 'Open Email to Admin',
    'emailDraftOpened':
        'Email draft opened. Please send it to complete submission. Our admin will verify your documents and update your account status.',
    'couldNotOpenEmailApp': 'Could not open email app. Please send an email to',
    'manually': 'manually',
    'failedToOpenEmail': 'Failed to open email',
    'loadingAccountStatus': 'Loading account status...',
    'errorLoadingStatus': 'Error Loading Status',
    'pleaseReviewAndResubmit': 'Please review and resubmit your documents.',
    'useDifferentAccount': 'Use different account',
    'useDifferentAccountConfirm':
        'Sign out to log in or register with a different account?',
    'failedToUpdateStatus': 'Failed to update legal settings. Please try again.',

    // ============================================
    // Profile Related
    // ============================================
    'editProfile': 'Edit Profile',
    'profileUpdated': 'Profile updated successfully',
    'failedToUpdateProfile': 'Failed to update profile',
    'profileImageUpdated': 'Profile image updated',
    'failedToUploadImage': 'Failed to upload image',
    'tagline': 'Tagline',
    'locations': 'Locations',
    'addLocation': 'Add Location',
    'editLocation': 'Edit Location',
    'deleteLocation': 'Delete Location',
    'latitude': 'Latitude',
    'longitude': 'Longitude',
    'nameIsRequired': 'Name is required',
    'businessNameOptional': 'Business name (optional)',
    'phoneOptional': 'Phone (optional)',
    'addresses': 'Addresses',
    'addAddress': 'Add Address',
    'noAddressesAdded': 'No addresses added',
    'addYourFirstAddress': 'Add your first address to get started',
    'editAddress': 'Edit address',
    'removeAddress': 'Remove address',
    'editAddressTitle': 'Edit Address',
    'addAddressTitle': 'Add Address',
    'saveChanges': 'Save changes',
    'labelExample': 'Label (e.g. Home, Office, Main Outlet)',
    'streetAreaOptional': 'Street / Area (optional)',
    'countryOptional': 'Country (optional)',
    'cityOptional': 'City (optional)',
    'locationNotUpdating': 'Location not updating',
    'locationNotUpdatingSolution':
        'Go to Profile > Addresses and ensure your location coordinates are correct',

    // ============================================
    // Deals Related
    // ============================================
    'deals': 'Deals',
    'activeDeals': 'Active Deals',
    'allDeals': 'All Deals',
    'myDeals': 'My Deals',
    'manageDeals': 'Manage Deals',
    'noDealsFound': 'No deals found',
    'selectDeal': 'Select Deal',
    'unableToLoadDeals': 'Unable to load deals',
    'noDealsAvailable': 'No deals available',
    'noDealsYet': 'No deals yet',
    'checkBackLaterForNewDeals': 'Check back later for new deals',
    'noActiveDeals': 'No active deals',
    'filterDeals': 'Filter Deals',
    'progress': 'Progress',
    'dealClosed': 'Deal Closed',
    'ends': 'Ends',
    'variant': 'Variant',
    'min': 'Min:',
    'max': 'Max:',
    'perUnit': '/unit',
    'perUnitLabel': 'Per {unit}',
    'inStock': 'in stock',
    'similarProducts': 'Similar Products',
    'noActiveDealsForProduct': 'No active deals for this product',
    'activeDealsForProduct': 'Active deals for this product',
    'moreFromWholesaler': 'More from {name}',
    'dealsFromWholesaler': 'Deals from {name}',
    'productsFromWholesaler': 'Products from {name}',
    'searchProductsFromWholesaler': 'Search products from {name}...',
    'onlyKioskCanPurchase': 'Only Kiosk/Shop accounts can purchase products',
    'canOnlyReviewFromDelivered': 'You can only review products from delivered orders',
    'alreadyReviewedThisProduct': 'You have already reviewed this product from this order',
    'selectOrderToReview': 'Select Order to Review',
    'orderN': 'Order #{id}',
    'viewDeals': 'View deals',
    'locationInfoNotAvailable': 'Location information not available',
    'location': 'Location',
    'kfProductDealTagline': 'KF Product Deal, Helping you find the best deals',
    'errorSearchingProducts': 'Error searching products',
    'myDealOrders': 'My deal orders',
    'noDealOrdersYet': 'No deal orders yet',
    'browseDealsPlaceFirstOrder':
        'Browse active deals and place your first order.',
    'statusLabel': 'Status',
    'noProductsFoundForWholesaler': 'No products found for selected wholesaler',
    'noApprovedWholesalersAvailable': 'No approved wholesalers available',
    'searchByNameBusinessEmail':
        'Search by name, business name, email...',
    'selectWholesaler': 'Select Wholesaler',
    'selectProduct': 'Select Product',
    'pageNOfM': 'Page {current} of {total}',
    'priceLabel': 'Price',
    'pleaseSelectImageOrVideo': 'Please select an image or video',
    'onlyWholesalersCreateStories': 'Only wholesalers can create stories',
    'storyCreatedSuccessfully': 'Story created successfully! 🎉',
    'uploadingMedia': 'Uploading media...',
    'creatingStory': 'Creating story...',
    'storyMedia': 'Story Media',
    'videoSelected': 'Video selected',
    'activeShopsSuffix': 'active shops',
    'storiesCountSuffix': 'stories',
    'create': 'Create',
    'off': 'OFF',
    'minOrder': 'Min Order',
    'target': 'Target',
    'units': 'units',
    'dealCreatedSuccessfully': 'Deal created successfully',
    'createDeal': 'Create Deal',
    'editDeal': 'Edit Deal',
    'closeDeal': 'Close Deal',
    'closeDealConfirmMessage':
        'Are you sure you want to close this deal? This action cannot be undone.',
    'closeDealGoalReached': 'Goal reached',
    'closeDealGoalReachedHint':
        'If checked: all pending orders will be auto-confirmed (deal successfully filled). '
        'If unchecked: the deal will close but you can confirm orders manually later.',
    'createYourFirstDeal': 'Create Your First Deal',
    'dealTitle': 'Deal Title',
    'pleaseEnterDealTitle': 'Please enter deal title',
    'dealType': 'Deal Type',
    'dealPrice': 'Deal Price',
    'startDate': 'Start Date',
    'endDate': 'End Date',
    'pleaseEnterDealPrice': 'Please enter deal price',
    'originalPrice': 'Original Price',
    'targetQuantity': 'Target Quantity',
    'pleaseEnterTargetQuantity': 'Please enter target quantity',
    'targetQuantityMin': 'Target quantity must be at least 1',
    'minOrderQty': 'Min Order Qty',
    'pleaseEnterMinOrderQty': 'Please enter min order quantity',
    'minOrderQtyMin': 'Min order quantity must be at least 1',
    'maxOrderQuantityOptional': 'Max Order Quantity (Optional)',
    'endDateMustBeAfterStartDate': 'End date must be after start date',
    'pleaseSelectWholesalerFirst': 'Please select a wholesaler first',
    'auction': 'Auction',
    'priceDrop': 'Price Drop',
    'limitedStock': 'Limited Stock',
    'scheduled': 'Scheduled',
    'live': 'Live',
    'highlightedDeal': 'Highlighted Deal',
    'canOnlyViewDeals':
        'can only view deals. Only Kiosk/Shop accounts can place orders.',
    'dealProgressNotUpdating': 'Deal progress not updating',
    'dealProgressNotUpdatingSolution':
        'Deal progress updates automatically. If it seems stuck, refresh the page',
    'dealProgress': 'Deal Progress',
    'unableToLoadProgress': 'Unable to load progress: {detail}',
    'noOrdersPlacedYet': 'No orders have been placed on this deal yet.',
    'orderPlacedSuffix': 'order placed',
    'ordersPlacedSuffix': 'orders placed',
    'closed': 'closed',

    // ============================================
    // Products Related
    // ============================================
    'product': 'Product',
    'products': 'products',
    'productsSection': 'Products',
    'allProducts': 'All Products',
    'myProducts': 'My Products',
    'noProductsAvailable': 'No products available',
    'noProductsYet': 'No products yet',
    'addYourFirstProduct': 'Add Your First Product',
    'addFirstProduct': 'Add Your First Product',
    'addProduct': 'Add Product',
    'editProduct': 'Edit Product',
    'deleteProduct': 'Delete Product',
    'deletingProduct': 'Deleting product...',
    'deleteProductConfirmGeneric':
        'Are you sure you want to delete this product? This action cannot be undone.',
    'productUpdatedSuccessfully': 'Product updated successfully',
    'productCreatedSuccessfully': 'Product created successfully',
    'productDeletedSuccessfully': 'Product deleted successfully',
    'changeProductStatus': 'Change Product Status',
    'changeStatus': 'Change Status',
    'updatingStatus': 'Updating status...',
    'statusUpdatedToPending': 'Status updated to Pending',
    'statusUpdatedToApproved': 'Status updated to Approved',
    'statusUpdatedToRejected': 'Status updated to Rejected',
    'productsWillAppearHere': 'Products will appear here once they are added',
    'noProductsFound': 'No products found',
    'youveReachedEnd': "You've reached the end",
    'errorLoadingProducts': 'Error loading products',
    'featuredCatalog': 'Featured catalog',
    'viewAll': 'View All',
    'outOfStock': 'OUT OF STOCK',
    'onlyLeft': 'ONLY',
    'left': 'LEFT',
    'timeRemainingDay': '{count} day left',
    'timeRemainingDays': '{count} days left',
    'timeRemainingHour': '{count}h left',
    'timeRemainingHours': '{count}h left',
    'timeRemainingMinute': '{count}m left',
    'timeRemainingMinutes': '{count}m left',
    'pleaseSelectProduct': 'Please select a product',
    'tapToSelectProduct': 'Tap to select a product',
    'unknownProduct': 'Unknown Product',
    'searchProductsHint': 'Search products by name, SKU...',
    'loadingMoreProducts': 'Loading more products...',
    'reachedEnd': 'You\'ve reached the end',
    'productsCountSuffix': 'products',
    'price': 'Price',
    'kilogram': 'Kilogram',
    'gram': 'Gram',
    'liter': 'Liter',
    'milliliter': 'Milliliter',
    'piece': 'Piece',
    'box': 'Box',
    'pack': 'Pack',
    'kmAway': 'km away',
    'viewAllProducts': 'View All Products',

    // ============================================
    // Product Management Related
    // ============================================
    'productTitle': 'Product Title',
    'productTitleRequired': 'Please enter product title',
    'titleMinLength': 'Title must be at least 3 characters',
    'description': 'Description',
    'category': 'Category',
    'wholesaler': 'Wholesaler',
    'selectCategory': 'Select Category',
    'selectCategories': 'Select Categories',
    'pleaseSelectCategory': 'Please select a category',
    'tapToSelectCategory': 'Tap to select a category',
    'pleaseSelectWholesaler': 'Please select a wholesaler',
    'tapToSelectWholesaler': 'Tap to select a wholesaler',
    'unknownCategory': 'Unknown Category',
    'yourAccount': 'Your account',
    'currentUser': 'Current User',
    'variants': 'Variants',
    'useVariants': 'Use Variants',
    'addVariant': 'Add Variant',
    'addAttribute': 'Add Attribute',
    'variantSkuRequired': 'SKU is required',
    'addAtLeastOneVariant': 'Please add at least one variant',
    'selectVariant': 'Select Variant',
    'selectVariantHelper': 'Select a variant for this deal',
    'noVariantsMessage':
        'This product has no variants. Deal will be created on the product directly.',
    'unableToLoadVariantsMessage':
        'Unable to load variants. Deal will be created on product.',
    'featuredProduct': 'Featured Product',
    'default': 'Default',
    'updateProduct': 'Update Product',
    'createProduct': 'Create Product',
    'globalAttributes': 'Global Attributes',
    'globalAttributesDescription':
        'Define attributes like Color, Size to apply to all variants.',
    'attributeName': 'Attribute Name (e.g. Color)',
    'attributeNameHint': 'Color, Size, Material...',
    'imageUrl': 'Image URL',
    'productImages': 'Product Images',
    'firstImagePrimary': 'First image is primary',
    'addImageUrl': 'Add URL',
    'pasteImageUrlHint': 'Paste image URL',
    'costPrice': 'Cost Price',
    'stock': 'Stock',
    'stockRequired': 'Please enter stock',
    'stockNegative': 'Stock cannot be negative',
    'priceRequired': 'Please enter price',
    'pricePositive': 'Price must be greater than 0',
    'validationError': 'Validation error',
    'checkAllFields': 'Please check all fields',
    'pending': 'Pending',
    'approved': 'Approved',
    'rejected': 'Rejected',
    'draft': 'Draft',
    'failedToCreateDeal': 'Failed to create deal',
    'dealNotification24hLabel': '24h notification message',
    'dealNotification24hHint':
        'Optional. Use {dealTitle} and {remainingQuantity} as placeholders. Leave empty to use default.',
    'dealNotification7dLabel': '7 days notification message',
    'dealNotification7dHint':
        'Optional. Use {dealTitle} and {remainingQuantity} as placeholders. Leave empty to use default.',
    'notificationTemplatePlaceholdersError':
        'Template must either use no placeholders, or include both {dealTitle} and {remainingQuantity}.',
    'invalidDateTimeFormat':
        'Invalid date/time format. Please check your dates.',

    // ============================================
    // Categories Related
    // ============================================
    'noCategoriesFound': 'No categories found',
    'noCategoriesAvailable': 'No categories available',
    'allCategories': 'All Categories',
    'searchCategories': 'Search categories...',
    'noCategoriesMatchSearch': 'No categories match your search',
    'categoriesWillAppearHere':
        'Categories will appear here once they are added',
    'tryDifferentSearchTerm': 'Try a different search term',
    'errorLoadingCategories': 'Error loading categories',
    'unableToLoadCategory': 'Unable to load category',
    'productsCount': '{n} products',
    'categoryName': 'Category Name',
    'categoryDescription': 'Description',
    'categoryImageUrl': 'Image URL',
    'createCategory': 'Create Category',
    'editCategory': 'Edit Category',
    'deleteCategory': 'Delete Category',
    'deleteCategoryConfirm': 'Are you sure you want to delete "{name}"? This action cannot be undone.',
    'categoryCreatedSuccessfully': 'Category created successfully',
    'enterCategoryDescriptionToGenerate':
        'Enter a category description to generate content automatically.',
    'categoryDescriptionHint': 'E.g., Organic Vegetables...',
    'contentGeneratedSuccessfullyEnglish': 'Content generated successfully! (English)',
    'generationFailedWithError': 'Generation failed: {error}',
    'categoryUpdatedSuccessfully': 'Category updated successfully',
    'categoryDeletedSuccessfully': 'Category deleted successfully',
    'categoryCreationImportMessage':
        'Category creation is currently done through import. Please contact admin.',
    'pleaseEnterCategoryName': 'Please enter a category name',

    // ============================================
    // Reviews Related
    // ============================================
    'reviewed': 'Reviewed',
    'youHaveAlreadyReviewed':
        'You have already reviewed this product from this order',
    'reviewUpdatedSuccessfully': 'Review updated successfully',
    'reviewSubmittedSuccessfully': 'Review submitted successfully',
    'pleaseSelectRating': 'Please select a rating',
    'maximum5ImagesAllowed': 'Maximum 5 images allowed',
    'failedToPickImage': 'Failed to pick image',
    'failedToUploadImages': 'Failed to upload images',
    'uploadImages': 'Upload Images',
    'pickImage': 'Pick Image',
    'pickVideo': 'Pick Video',
    'uploadFailed': 'Upload failed',
    'upload': 'Upload',
    'invalidImageUrl': 'Invalid image URL',

    // ============================================
    // Banners Related
    // ============================================
    'viewProduct': 'View Product',
    'viewDeal': 'View Deal',
    'openLink': 'Open Link',
    'discoverGreatDealsNearby': 'Discover great deals nearby',
    'stayTunedForOffers': 'Stay tuned for new offers and stories from verified wholesalers.',
    'manageBanners': 'Manage Banners',
    'myBanners': 'My Banners',
    'noBannersFound': 'No banners found. Create one!',
    'bannerDetails': 'Banner Details',
    'bannerNotFound': 'Banner not found',
    'views': 'Views',
    'clicks': 'Clicks',
    'bannerRequestSubmitted': 'Banner request submitted!',
    'failedToSubmitRequest': 'Failed to submit request',
    'deleteBanner': 'Delete Banner',
    'deleteBannerConfirm': 'Are you sure you want to delete this banner?',
    'bannerDeleted': 'Banner deleted',
    'bannerUpdated': 'Banner updated.',
    'bannerEditSubmittedForApproval':
        'Banner updated. Changes will be reviewed by admin.',
    'failedToDeleteBanner': 'Failed to delete banner',
    'targetId': 'Target ID',
    'url': 'URL',
    'createNewBanner': 'Create New Banner',
    'bannerTitle': 'Banner Title',
    'enterBannerTitle': 'Enter banner title',
    'bannerImage': 'Banner Image',
    'webBannerImage': 'Web Image',
    'webBannerImageHint': 'Landscape/wide aspect ratio for web',
    'mobileBannerImage': 'Mobile Image',
    'mobileBannerImageHint': 'Portrait/square for mobile preview',
    'mobilePreview': 'Mobile Preview',
    'preview': 'Preview',
    'previewMobile': 'Preview Mobile',
    'previewWillAppearHere': 'Preview will appear here',
    'pasteImageUrlHere': 'Paste image URL here',
    'pleaseEnterImageUrlOrSwitch':
        'Please enter an Image URL or switch to Upload and choose an image.',
    'pleaseTapChooseImage':
        'Please tap "Choose Image" to upload a banner image, or switch to URL and paste an image link.',
    'tapToUploadWebImage': 'Tap to upload Web Image',
    'tapToUploadMobileImage': 'Tap to upload Mobile Image',
    'chooseImage': 'Choose Image',
    'replaceImage': 'Replace Image',

    // ============================================
    // Stories Related
    // ============================================
    'createStory': 'Create Story',
    'storiesFromVerifiedWholesalers': 'Stories from verified wholesalers',
    'storiesWillAppearHere': 'Stories will appear here once they are added',
    'selectImageOrVideoForStory': 'Select an image or video for your story',
    'post': 'Post',
    'expiresAt': 'Expires at',

    // ============================================
    // Shipment / Tracking Related
    // ============================================
    'trackingNumber': 'Tracking Number',
    'carrier': 'Carrier',
    'trackingUrl': 'Tracking URL',
    'openTrackingLink': 'Open tracking link',
    'statusTimeline': 'Status Timeline',

    // ============================================
    // Account Deletion Related
    // ============================================
    'submitDeletionRequest': 'Submit Deletion Request',
    'submitRequest': 'Submit Request',
    'reviewProcess': 'Review Process',
    'accountDeleted': 'Account Deleted',
    'whatHappensNext': 'What happens next?',
    'submitRequestDescription':
        'Enter your email address to request account deletion',
    'reviewProcessDescription':
        'Our team will review your request within 24-48 hours. You\'ll receive a confirmation email once your request is processed.',
    'accountDeletedDescription':
        'Your account and all associated data will be permanently deleted. This action cannot be undone.',
    'ourTeamReviewsYourRequest': 'Our team reviews your request',
    'reviewDetails': 'Review Details',
    'reviewDetailsDescription':
        'We verify your account and ensure all pending orders or transactions are completed before proceeding with deletion.',
    'yourAccountIsPermanentlyRemoved': 'Your account is permanently removed',
    'finalStep': 'Final Step',
    'finalStepDescription':
        'Once approved, your account data will be permanently deleted from our system. This action cannot be undone.',
    'importantInformation': 'Important Information',
    'accountDeletionIsPermanent':
        'Account deletion is permanent and cannot be reversed',
    'allDataWillBeRemoved':
        'All your data, orders, and history will be permanently removed',
    'pendingOrdersMustBeCompleted':
        'Pending orders must be completed before deletion can proceed',
    'youllReceiveEmailConfirmation':
        'You\'ll receive an email confirmation once the process is complete',
    'confirmActionPermanent':
        'Please confirm that you understand this action is permanent',
    'requestSubmitted': 'Request Submitted',
    'deletionRequestSubmittedMessage':
        'Your account deletion request has been submitted successfully. Our team will review it within 24-48 hours. You will receive a confirmation email once your request is processed.',
    'ok': 'OK',
    'failedToSubmitDeletionRequest':
        'Failed to submit deletion request. Please try again.',
    'requestAccountDeletion': 'Request Account Deletion',
    'sorryToSeeYouGo': 'We\'re sorry to see you go',
    'emailAddress': 'Email Address',
    'enterRegisteredEmail': 'Enter your registered email address',
    'emailAddressRequired': 'Email address is required',
    'pleaseEnterValidEmail': 'Please enter a valid email address',
    'reasonForDeletionOptional': 'Reason for Deletion (Optional)',
    'helpUsImproveLeaving':
        'Help us improve by sharing why you\'re leaving...',
    'understandActionPermanent':
        'I understand that this action is permanent and cannot be undone',

    // ============================================
    // Support / Help Related
    // ============================================
    'emailSupport': 'Email Support',
    'getHelpViaEmail': 'Get help via email',
    'phoneSupport': 'Phone Support',
    'callUsDuringBusinessHours': 'Call us during business hours',
    'liveChat': 'Live Chat',
    'chatWithUs': 'Chat with us',
    'chatWithSupportTeam': 'Chat with our support team',
    'commonIssues': 'Common Issues',
    'orderNotShowingUp': 'Order not showing up',
    'orderNotShowingUpSolution':
        'Refresh the dashboard or check your order history in "My Orders"',
    'liveChatComingSoon': 'Live chat coming soon!',
    'needHelpContactSupport': 'Need help? Contact Support',
    'contactSupportAt': 'Contact support at',
    'getInTouch': 'Get in Touch',
    'wereHereToHelp': 'We\'re here to help you',
    'businessEmail': 'Business email',
    'contactUsOnWhatsApp': 'Contact us on WhatsApp',
    'helloNeedAssistance': 'Hello! I need assistance.',
    'myDetails': 'My Details:',
    'nameLabel': 'Name:',
    'phoneLabel': 'Phone:',
    'emailLabel': 'Email:',
    'businessLabel': 'Business:',
    'howCanYouHelpMe': 'How can you help me?',
    'unableToOpenWhatsApp': 'Unable to open WhatsApp. Please try again.',
    'hello': 'Hello',

    // ============================================
    // Common Validation Related
    // ============================================
    'required': 'This field is required',
    'invalidEmail': 'Invalid email',
    'passwordTooShort': 'Password must be at least 6 characters',
    'passwordsDoNotMatch': 'Passwords do not match',

    // ============================================
    // Manager / Admin Related
    // ============================================
    'admin': 'Admin',
    'role': 'Role',
    'created': 'Created',
    'subAdmin': 'Sub-Admin',
    'accessDenied': 'Access Denied',
    'managersSectionOnly': 'This section is only available for managers',
    'totalRevenue': 'Total Revenue',
    'myRevenue': 'My Revenue',
    'revenueDetail': 'Revenue Detail',
    'myRevenueDetail': 'My Revenue Detail',
    'howCalculated': 'How is revenue calculated?',
    'productOrdersRevenue': 'Product orders (delivered)',
    'dealOrdersRevenue': 'Deal orders (delivered)',
    'totalGrossRevenue': 'Total gross revenue',
    'platformCut': 'Platform cut ({percent}%)',
    'platformCutDescription': 'Your share as platform admin (1% commission)',
    'revenueFromDeliveredOrders': 'Revenue from delivered product and deal orders.',
    'revenueDetailAdminInfo':
        'As admin, you receive 1% commission from all delivered orders (product + deal). Product owners receive the remaining 99%.',
    'revenueDetailOwnerInfo':
        'Your full revenue from delivered product orders and deal orders where you are the deal owner.',
    'revenueOrdersList': 'Orders contributing to revenue',
    'noRevenueOrdersYet': 'No delivered orders yet',
    'errorLoading': 'Error loading',
    'activeShops': 'Active Wholesalers',
    'activeMembers': 'Active Shops / Kiosk',
    'inactiveMembers': 'Inactive Shops',
    'activeShopsSubtitle': 'Verified wholesalers on the platform',
    'activeMembersSubtitle': 'Shops that ordered recently',
    'inactiveMembersSubtitle': 'No order in 60+ days',
    'lastOrder': 'Last order',
    'lastActive': 'Last active',
    'lastLogin': 'Last login',
    'joined': 'Joined',
    'selectToNotify': 'Select to send notification',
    'deselect': 'Deselect',
    'recipients': 'Recipients',
    'notificationSent': 'Notification sent',
    'notifyDealParticipantsTitle': 'Notify Deal Participants',
    'notifyDealParticipantsAudienceWarning':
        'This message will only be sent to users who have placed an order for this deal.',
    'notifyDealParticipantsSendUpdateTooltip': 'Send Update',
    'notifyDealParticipantsSending': 'Sending...',
    'notifyDealParticipantsNoParticipantsError':
        'Cannot send: No users have joined this deal yet.',
    'notifyDealParticipantsFailedToSend':
        'Failed to send notification: {error}',
    'noInactiveMembers': 'No inactive members',
    'selectAll': 'Select all',
    'sendNotification': 'Send notification',
    'title': 'Title',
    'body': 'Message',
    'send': 'Send',
    'generateWithAI': 'Generate with AI',
    'generateNotificationPrompt':
        'Describe the notification (e.g. re-engagement, flash sale, new products) to generate title and message.',
    'weMissYou': 'We miss you!',
    'reEngagementDefaultBody':
        'You haven\'t placed an order in a while. Browse our latest deals and products.',
    'notificationRemindHint': 'e.g., Remind inactive shops about our winter sale',
    'searchByNameEmail': 'Search by name, email...',
    'generate': 'Generate',
    'page': 'Page',
    'never': 'Never',
    'quickActions': 'Quick Actions',
    'recentOrders': 'Recent Orders',
    'noRecentOrders': 'No recent orders',
    'analyticsComingSoon': 'Analytics - Coming soon',
    'importCsv': 'Import from CSV',
    'importFromCsv': 'Import from CSV',
    'importProductsFromCsv': 'Import Products from CSV',
    'importProducts': 'Import Products',
    'importing': 'Importing...',
    'downloadCsvTemplate': 'Download CSV Template',
    'getSampleCsvWithColumns': 'Get a sample CSV file with all required columns',
    'selectCsvFile': 'Select CSV File',
    'chooseFile': 'Choose File',
    'tapToSelectWholesalerForImport': 'Tap to select a wholesaler for imported products',
    'importComplete': 'Import Complete',
    'inserted': 'Inserted',
    'updated': 'Updated',
    'skipped': 'Skipped',
    'fileLabel': 'File: {name}',
    'wholesalerRequired': 'Wholesaler *',
    'wholesalerLabel': 'Wholesaler {id}',
    'csvPreviewRows': 'CSV Preview ({n} rows)',
    'multipleRowsSameProductVariant':
        'Multiple rows with same product name = multiple variants',
    'errorsCount': 'Errors ({n})',
    'andMoreErrors': '... and {n} more errors',
    'failedToReadFileBytes': 'Failed to read file bytes',
    'failedToGetFilePath': 'Failed to get file path',
    'errorPickingFile': 'Error picking file: {error}',
    'csvFileEmpty': 'CSV file is empty',
    'errorParsingCsv': 'Error parsing CSV: {error}',
    'templateSavedSuccessfully': 'Template saved successfully',
    'templateDownloadCancelled': 'Template download cancelled',
    'errorGeneratingTemplate': 'Error generating template',
    'errors': 'Errors',
    'viewWholesaler': 'View wholesaler',
    'cropImage': 'Crop Image',
    'change': 'Change',
    'navigationError': 'Navigation error',

    // ============================================
    // Time Related
    // ============================================
    'hours': 'hours',
    'minutes': 'Minutes',
    'seconds': 'Seconds',
    'twentyFourHours': '24 hours',
    'twelveHours': '12 hours',
    'sixHours': '6 hours',

    // ============================================
    // Navigation / Route Errors
    // ============================================
    'noStoryDataProvided': 'No story data provided.',
    'missingWholesalerId': 'Missing wholesaler id.',
    'missingProductId': 'Missing product id.',
    'missingCategorySlug': 'Missing category slug.',
    'missingDealId': 'Missing deal id.',
    'missingOrderId': 'Missing order id.',
    'featuredProducts': 'Featured Products',

    // ============================================
    // Order Update / Quantity Change Result
    // ============================================
    'orderUpdate': 'Order Update',
    'viewMyOrders': 'View My Orders',
    'goToHome': 'Go to Home',
    'quantityChangeAccepted': 'Quantity change accepted',
    'quantityChangeDeclined': 'Quantity change declined',
    'somethingWentWrong': 'Something went wrong',
    'orderUpdatedMessage': 'Your order has been updated.',
    'orderRevertedMessage': 'Your order has been reverted to the previous quantity.',
    'pleaseTryAgainLater': 'Please try again later.',

    // ============================================
    // Deal Detail / Deal Errors
    // ============================================
    'unableToLoadDeal': 'Unable to load deal',
    'regularPrice': 'Regular Price',
    'stockLabel': 'Stock',
    'dealNotStarted': 'This deal has not started yet',
    'adminWholesalerManageHint':
        'As an Admin or Wholesaler, you can manage this deal but cannot place orders. Use the menu button (⋮) in the app bar to edit or close this deal.',
    'adminDealOnlyOwnerCanBid':
        'Only the admin (deal owner) can add bids on admin deals. Kiosk users cannot place orders on this deal.',
    'kioskOnlyPlaceOrders': 'Only Kiosk/Shop accounts can place orders on this deal.',
    'managementView': 'Management View',
    'ordering': 'Ordering',
    'failedToLoadDealData': 'Failed to load deal data',
    'dealClosedSuccess': 'Deal closed successfully',
    'failedToCloseDeal': 'Failed to close deal',
    'onlyAdminCanAddBidsOnAdminDeals':
        'Only the admin (deal owner) can add bids on admin deals.',

    // ============================================
    // Product Search / Detail
    // ============================================
    'searchProducts': 'Search Products',
    'youCanOnlyReviewFromDeliveredOrders':
        'You can only review products from delivered orders',
    'allImages': 'All images',
    'contentGeneratedSuccessfully':
        'Content generated successfully! Check category and other fields.',
    'generationFailed': 'Generation failed',
    'userIdRequired': 'User ID required',

    // ============================================
    // Admin Banner Management
    // ============================================
    'adminBannerManagement': 'Admin Banner Management',
    'requests': 'Requests',
    'active': 'Active',
    'noBannersFoundShort': 'No banners found.',
    'failedToUpdateBanner': 'Failed to update banner',
    'bannerSubmittedSuccessfully': 'Banner submitted successfully',
    'failedToCreateBanner': 'Failed to create banner',
    'failedToSubmitBannerRequest': 'Failed to submit banner request',

    // ============================================
    // User Management / Admin
    // ============================================
    'administratorsOnlySection':
        'This section is only available for administrators',
    'allRoles': 'All Roles',
    'allStatuses': 'All Statuses',
    'suspended': 'Suspended',
    'noUsersFound': 'No users found',
    'pageOf': 'Page',
    'ofLabel': 'of',
    'noDocumentsAvailable': 'No documents available',
    'userUpdatedSuccessfully': 'User updated successfully',
    'userCreatedSuccessfully': 'User created successfully',
    'userDeletedSuccessfully': 'User deleted successfully',
    'deleteUser': 'Delete User',
    'deleteUserConfirm': 'Are you sure you want to delete {name}? This action cannot be undone.',
    'verificationDocuments': 'Verification Documents',
    'noVerificationDocumentsYet': 'No verification documents uploaded yet.',
    'rejectionReason': 'Rejection Reason:',
    'createUser': 'Create User',
    'editUser': 'Edit User',
    'updateUser': 'Update User',
    'roleRequired': 'Role is required',
    'statusRequired': 'Status is required',
    'newPasswordLeaveEmpty': 'New Password (leave empty to keep current)',
    'passwordRequired': 'Password is required',
    'passwordMinLength': 'Password must be at least 6 characters',
    'needInfo': 'Need Info',
    'business': 'Business',
    'searchByNameEmailPhone': 'Search by name, email, phone...',
    'daysAgo': 'day(s) ago',
    'activeDaysLast14': 'Active days (last 14)',
    'docsCount': '{count} doc(s)',
    'noPassportDocuments': 'No passport documents',
    'noGewerbescheinDocuments': 'No Gewerbeschein documents',
    'noBusinessLicenseDocuments': 'No business license documents',
    'documentN': 'Document {n}',
    'openInBrowser': 'Open in Browser',
    'pdfDocument': 'PDF Document',
    'kiosk': 'Kiosk',

    // ============================================
    // Order Management (Deal Orders)
    // ============================================
    'errorLoadingOrders': 'Error loading orders',
    'errorLoadingDeals': 'Error loading deals',
    'orderManagement': 'Order Management',
    'orderCountSuffix': 'order',
    'confirmOrder': 'Confirm Order',
    'confirmOrderMessage': 'Are you sure you want to confirm this order?',
    'confirm': 'Confirm',
    'markAsDelivered': 'Mark as Delivered',
    'markDelivered': 'Mark Delivered',
    'cancelOrder': 'Cancel Order',
    'cancelOrderConfirm': 'Are you sure you want to cancel this order?',
    'no': 'No',
    'reduceQuantity': 'Reduce quantity',
    'orderConfirmedSuccess': 'Order confirmed successfully',
    'orderMarkedDelivered': 'Order marked as delivered',
    'failedToConfirmOrder': 'Failed to confirm order',
    'failedToMarkDelivered': 'Failed to mark as delivered',
    'orderCancelled': 'Order cancelled',
    'failedToCancelOrder': 'Failed to cancel order',
    'orderMarkedPaid': 'Order marked as paid',
    'failedToMarkOrderPaid': 'Failed to mark order as paid',
    'quantityUpdatedSuccess': 'Quantity updated successfully',
    'failedToUpdateQuantity': 'Failed to update quantity',
    'deliveryNotesOptional': 'Delivery Notes (Optional)',
    'newQuantity': 'New quantity',
    'reduceQuantityHint':
        'Enter the new quantity. Minimum is 1 (or the deal\'s min order quantity). Use 0 to cancel this order.',
    'quantityUpdatedTo': 'Quantity updated to',

    // ============================================
    // Deal Order Form
    // ============================================
    'enterQuantity': 'Enter quantity',
    'pleaseEnterQuantity': 'Please enter quantity',
    'invalidQuantity': 'Invalid quantity',
    'minimumOrderIs': 'Minimum order is',
    'maximumOrderIs': 'Maximum order is',
    'addSpecialInstructions': 'Add any special instructions...',
    'minQuantityLabel': 'Min',
    'selectedLabel': 'Selected',
    'maxQuantityLabel': 'Max',

    // ============================================
    // Shipment / Carrier
    // ============================================
    'pleaseSelectCarrier': 'Please select a carrier',
    'pleaseEnterCarrierNameForOther': 'Please enter carrier name for "Other"',
    'shipmentCreatedSuccess': 'Shipment created successfully',
    'shipmentCreatedAndOrderShipped': 'Shipment created and order marked as shipped',
    'failedToCreateShipment': 'Failed to create shipment',

    // ============================================
    // Stories
    // ============================================
    'failedToPickMedia': 'Failed to pick media',
    'onlyWholesalersCanCreateStories': 'Only wholesalers can create stories',
    'storyCreatedSuccess': 'Story created successfully! 🎉',
    'failedToCreateStory': 'Failed to create story',

    // ============================================
    // Payment
    // ============================================
    'paymentCompletedSuccess': 'Payment completed successfully!',
    'paymentFailed': 'Payment failed',

    // ============================================
    // Notifications
    // ============================================
    'notifications': 'Notifications',
    'markAllAsRead': 'Mark all as read',
    'deleteAll': 'Delete all',
    'filterNotifications': 'Filter Notifications',
    'unread': 'Unread',
    'read': 'Read',
    'deleteAllNotificationsConfirm': 'Delete All Notifications?',
    'deleteAllNotificationsMessage':
        'Are you sure you want to delete all notifications? This action cannot be undone.',
    'deleteAllNotificationsSuccess': 'All notifications deleted',
    'markedAllAsRead': 'All marked as read',

    // ============================================
    // Deal / Product Modals
    // ============================================
    'paymentEmailTemplateGenerated': 'Payment email template generated',
    'aiGenerationFailed': 'AI generation failed',
    'dealUpdatedSuccess': 'Deal updated successfully',
    'allowOnlinePayment': 'Allow online payment',
    'allowOnlinePaymentSubtitle':
        'If unchecked, customers can only place order; payment (e.g. bank transfer) is requested after order is confirmed.',
    'paymentAndEmail': 'Payment & email',
    'generating': 'Generating…',
    'enterDealDescriptionPrompt':
        'Enter a clear description of your deal to generate content automatically.',
    'dealDescriptionHint':
        'e.g., Flash sale: 50% off on all winter jackets',
    'enterProductDescriptionPrompt':
        'Enter a description or product details to generate content automatically.',
    'productDescriptionHint':
        'E.g., A premium leather office chair with ergonomic design...',
    'optionalAutoAssigned': 'Optional - will be auto-assigned if empty',
    'defaultYourAccount': 'Default: Your account (tap to change)',
    'currentUserYou': 'Current User (You)',
    'loadingProductDetails': 'Loading product details...',
    'loading': 'Loading...',
    'ibanBankAccount': 'IBAN / Bank account',
    'accountOwner': 'Account owner',
    'referenceTemplate': 'Reference template (e.g. DEAL-{dealCode}-{buyerId})',
    'paymentInstructions': 'Payment instructions (free text)',
    'paymentEmailSubject': 'Payment email subject',
    'paymentEmailBody':
        'Payment email body (placeholders: {dealTitle}, {amount}, {accountOwner}, {iban}, {reference}, {additionalInstructions})',
    'ended': 'Ended',
    'dealEnded': 'Deal Ended',
    'dealHasEnded': 'Deal has ended',
    'endingSoon': 'Ending Soon!',
    'endsIn1Day': 'Ends in 1 day',
    'endsInDays': 'Ends in {n} days',
    'endsIn1Hour': 'Ends in 1 hour',
    'endsInHours': 'Ends in {n} hours',
    'endsSoon': 'Ends soon',
    'categories': 'Categories',
    'itemsCount': '{n} Items',

    // ============================================
    // Shipment Tracking
    // ============================================
    'pleaseEnterTrackingNumber': 'Please enter a tracking number',
    'pleaseSelectAtLeastOneItemToShip': 'Please select at least one item to ship',
    'pleaseEnterTrackingUrlForOther': 'Please enter tracking URL for "Other" carrier',
    'selectItemsToShip': 'Select Items to Ship',
    'noItemsAvailableForShipment': 'No items available for shipment',
    'selectCarrier': 'Select a carrier',
    'selectCarrierHint': 'Select a carrier...',
    'carrierName': 'Carrier Name',
    'enterCarrierName': 'Enter carrier name',
    'trackingNumberRequired': 'Tracking number is required',
    'enterTrackingNumber': 'Enter tracking number',
    'trackingUrlAutoGenerated': 'Tracking URL will be auto-generated',
    'trackingUrlRequiredForOther': 'Tracking URL is required for "Other" carrier',
    'pleaseEnterValidUrl': 'Please enter a valid URL',
    'estimatedDeliveryDate': 'Estimated Delivery Date',
    'selectDate': 'Select date',
    'internalNotesShipment': 'Internal notes about this shipment',
    'trackingUrlHintAuto': 'Auto-generated when carrier and tracking number are provided',
    'trackShipment': 'Track Shipment',
    'trackShipmentHint': 'Track your shipment using the tracking number provided',
    'trackingDetails': 'Tracking Details',
    'shipmentNotFound': 'Shipment not found',
    'pleaseCheckTrackingNumber': 'Please check your tracking number and try again',
    'noNotifications': 'No notifications',
    'youreAllCaughtUp': "You're all caught up!",

    // ============================================
    // Select Deal / Category
    // ============================================

    // ============================================
    // Feature audit – previously hardcoded strings
    // ============================================
    'platformMobile': 'Mobile',
    'platformWeb': 'Web',
    'pleaseWait': 'Please wait...',
    'defaultVariant': 'Default',
    'trackOnCarrierWebsite': 'Track on Carrier Website',
    'minOrderQtyRequired': 'Min Order Qty *',
    'dealPriceRequired': 'Deal Price *',
    'targetQuantityRequired': 'Target Quantity *',
    'baseShippingCostEur': 'Base Shipping Cost (€)',
    'freeShippingThresholdQuantity': 'Free Shipping Threshold (Quantity)',
    'perUnitShippingCostEur': 'Per Unit Shipping Cost (€)',
    'descriptionOptional': 'Description (Optional)',
    'enterBannerDescription': 'Enter banner description',
    'bannerType': 'Banner Type',
    'targetUrl': 'Target URL',
    'skuRequired': 'SKU *',
    'productToPromoteHint': 'product to promote',
    'selectDealToPromote': 'Select a deal to promote',
    'titleOptional': 'Title (Optional)',
    'giveReviewTitle': 'Give your review a title',
    'yourReviewOptional': 'Your Review (Optional)',
    'shareExperienceWithProduct': 'Share your experience with this product',
    'dealUpdatedSuccessfully': 'Deal updated successfully',
    'dealPriceMustBeValidNumber': 'Deal price must be a valid number',
    'pleaseEnterMinOrderQuantity': 'Please enter min order quantity',
    'paymentEmailPlaceholdersSubject':
        'Placeholders: {dealTitle}, {amount}, {reference}',
    'paymentEmailPlaceholdersBody':
        'Placeholders: {dealTitle}, {amount}, {accountOwner}, {iban}, '
        '{reference}, {additionalInstructions}',
    'failed': 'Failed',

    // ============================================
    // Order status (product orders – display only)
    // ============================================
    'orderStatusPendingConfirmation': 'Pending confirmation',
    'orderStatusConfirmed': 'Confirmed',
    'orderStatusPacking': 'Packing',
    'orderStatusDispatched': 'Dispatched',
    'orderStatusOutForDelivery': 'Out for delivery',
    'orderStatusDelivered': 'Delivered',
    'orderStatusCancelled': 'Cancelled',
    'orderStatusReturned': 'Returned',
    'orderStatusRefunded': 'Refunded',

    // ============================================
    // Notifications (backend localization keys)
    // ============================================
    'notificationProductApprovalNeededTitle': 'New Product Pending Approval',
    'notificationProductApprovalNeededBody':
        '{0} created a new product: {1}',
    'notificationProductStatusUpdatedTitle': 'Product Status Updated',
    'notificationProductApprovedBody': 'Your product "{0}" has been approved!',
    'notificationProductRejectedBody': 'Your product "{0}" has been rejected.',
    'notificationProductPendingBody':
        'Your product "{0}" is pending approval.',
    'notificationProductStatusChangedBody':
        'Your product "{0}" status changed to {1}',
    'notificationNewProductOrderTitle': 'New Order on Your Products',
    'notificationNewProductOrderBody':
        '{0} placed an order for {1} unit(s) of {2}',
    'notificationNewDealOrderTitle': 'New Order on Your Deal',
    'notificationNewDealOrderBody': '{0} placed an order for {1} units',
    'notificationPaymentReportedTitle': 'Buyer reported payment',
    'notificationPaymentReportedBody':
        '{0} reported payment for order. Details: {1}',
    'notificationDealPaymentReportedBody':
        '{0} reported payment for deal order. Details: {1}',
    'notificationDealOrderStatusUpdatedTitle': 'Deal order status updated',
    'notificationDealOrderConfirmedBody':
        'Your order on "{0}" has been confirmed!',
    'notificationDealOrderShippedBody':
        'Your order on "{0}" has been shipped!',
    'notificationDealOrderDeliveredBody':
        'Your order on "{0}" has been delivered!',
    'notificationDealOrderCancelledBody':
        'Your order on "{0}" has been cancelled.',
    'notificationDealOrderRefundedBody':
        'Your order on "{0}" has been refunded.',
    'notificationDealOrderPendingBody':
        'Your order on "{0}" is pending confirmation.',
    'notificationDealOrderStatusChangedBody':
        'Status of your order on "{0}" changed to {1}',
    'notificationOrderQuantityUpdatedTitle': 'Order quantity updated',
    'notificationDealOrderQuantityCancelledBody':
        'Your order on "{0}" (was {1} units) has been cancelled by the seller.',
    'notificationDealOrderQuantityChangedBody':
        'Your order on "{0}" has been updated: quantity changed from {1} to {2} units by the seller.',
    'notificationQuantityChangeDeclinedTitle': 'Quantity change declined',
    'notificationQuantityChangeDeclinedBody':
        '{0} declined the quantity change. Order reverted from {1} to {2} units.',
    'notificationDealNowLiveTitle': 'New deal is live',
    'notificationDealNowLiveBody':
        '"{0}" is now live. Place your order before the deal ends.',
    'notificationDealTarget70PercentTitle': 'Deal almost there',
    'notificationDealTarget70PercentBody':
        '"{0}" is {1}% full! Join fellow retailers and help the deal owner reach their goal – it strengthens your relationship and shows your commitment to the partnership.',
    'notificationDealEnding24hTitle': 'Deal ending soon',
    'notificationDealEnding24hBody':
        'Last 24 hours! "{0}" – only {1} orders left to close this deal.',
    'notificationDealEnding7dTitle': 'Deal ending in 7 days',
    'notificationDealEnding7dBody':
        '"{0}" – only {1} orders left to close this deal.',
    'notificationDealSuccessTitle': 'Deal successfully filled',
    'notificationDealSuccessBody':
        'Your group deal "{0}" has reached the required quantity and is now confirmed. Please prepare for payment and shipping according to the instructions from the wholesaler.',
    'notificationDealClosedTitle': 'Deal closed',
    'notificationDealClosedBody':
        'The deal "{0}" has been closed. It will no longer appear in active deals.',
    'deal_closed_title': 'Deal Closed!',
    'deal_closed_body':
        "The deal '{0}' has been officially closed. Thank you for participating!",
    'notificationOrderStatusUpdatedTitle': 'Order status updated',
    'notificationOrderConfirmedBody':
        'Your order for "{0}" has been confirmed!',
    'notificationOrderDispatchedBody':
        'Your order for "{0}" has been dispatched!',
    'notificationOrderDeliveredBody':
        'Your order for "{0}" has been delivered!',
    'notificationOrderCancelledBody':
        'Your order for "{0}" has been cancelled.',
    'notificationOrderPackingBody':
        'Your order for "{0}" is being packed!',
    'notificationOrderOutForDeliveryBody':
        'Your order for "{0}" is out for delivery!',
    'notificationOrderReturnedBody':
        'Your order for "{0}" has been returned.',
    'notificationOrderRefundedBody':
        'Your order for "{0}" has been refunded.',
    'notificationOrderStatusChangedBody':
        'Your order for "{0}" status changed to {1}',
    'notificationOrderItemRemovedBody':
        'Your order item "{0}" (was {1} units) has been removed by the seller.',
    'notificationOrderItemQuantityChangedBody':
        'Your order item "{0}" has been updated: quantity changed from {1} to {2} units by the seller.',
    'notificationProductQuantityChangeDeclinedBody':
        '{0} declined the quantity change on order item. Reverted from {1} to {2} units.',
    'notificationDailyEngagementTitle': "Check out today's deals!",
    'notificationDailyEngagementBody':
        'Today: {0} banners, {1} deals, {2} featured products. Check the app for offers.',
    'notificationInactiveMembersAlertTitle': 'Inactive members alert',
    'notificationInactiveMembersAlertBody':
        "{0} shop(s) haven't placed an order in {1} days. Consider reaching out or reviewing.",
    'notificationBulkImportCompletedTitle': 'Bulk Import Completed',
    'notificationBulkImportCompletedBody':
        'Successfully imported {0} products. {1} skipped.',
    'notificationBannerApprovalNeededTitle': 'New Banner Pending Approval',
    'notificationBannerApprovalNeededBody':
        '{0} has requested approval for banner: {1}',
    'notificationNewUserRegistrationTitle': 'New User Registration',
    'notificationNewUserRegistrationBody':
        '{0} ({1}) registered as {2}. Pending approval.',
    'notificationBannerStatusChangedTitle': 'Banner status changed',
    'notificationBannerApprovedBody':
        'Your banner "{0}" has been approved and is now active!',
    'notificationBannerRejectedBody':
        'Your banner "{0}" has been rejected. Please review and resubmit if needed.',
    'notificationBannerDeactivatedBody':
        'Your banner "{0}" has been deactivated.',
    'notificationBannerStatusChangedBody':
        'Your banner "{0}" status changed to {1}',
    'notificationAdminCustomTitle': '{0}',
    'notificationAdminCustomBody': '{0}',
    'kioskShopRole': 'Kiosk / Shop',
  };
}
