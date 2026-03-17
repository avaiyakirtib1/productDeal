# All Dart Files – Localization Status (Comma-Separated)

Format: `file_path, status, notes`

Use this for quick scanning and script parsing.

---

```
lib/app.dart, Done, Localized
lib/app_router.dart, Done, Route error messages localized
lib/main.dart, N/A, Entry point
lib/firebase_options.dart, N/A, Config
lib/core/config/app_config.dart, N/A, Config
lib/core/constants/app_colors.dart, N/A, Colors
lib/core/constants/app_sizes.dart, N/A, Sizes
lib/core/localization/app_localizations.dart, N/A, Localization system
lib/core/localization/en_file.dart, N/A, EN translations
lib/core/localization/ar_file.dart, N/A, AR translations
lib/core/localization/de_file.dart, N/A, DE translations
lib/core/localization/hi_file.dart, N/A, HI translations
lib/core/localization/ru_file.dart, N/A, RU translations
lib/core/localization/tr_file.dart, N/A, TR translations
lib/core/localization/ur_file.dart, N/A, UR translations
lib/core/localization/currency_controller.dart, N/A, Logic
lib/core/localization/language_controller.dart, N/A, Logic
lib/core/location/location_service.dart, N/A, Service
lib/core/networking/api_client.dart, N/A, API
lib/core/networking/api_exception.dart, N/A, Errors
lib/core/networking/api_timing.dart, N/A, Timing
lib/core/permissions/permissions.dart, N/A, Permissions
lib/core/repositories/base_repository.dart, N/A, Base
lib/core/services/currency_service.dart, N/A, Service
lib/core/services/fcm_service.dart, N/A, FCM
lib/core/services/image_picker_helper.dart, N/A, Helper
lib/core/services/upload_service.dart, N/A, Upload
lib/core/storage/session_storage.dart, N/A, Storage
lib/core/theme/app_theme.dart, N/A, Theme
lib/core/utils/file_utils.dart, N/A, Utils
lib/core/utils/file_utils_stub.dart, N/A, Stub
lib/core/utils/snackbar.dart, N/A, Caller passes localized
lib/core/widgets/banner_carousel.dart, Done, Localized
lib/core/widgets/image_preview_widget.dart, N/A, Minimal
lib/features/account/data/models/account_models.dart, N/A, Model
lib/features/account/data/models/document_type.dart, N/A, Model
lib/features/account/data/repositories/account_repository.dart, N/A, Repo
lib/features/account/presentation/providers/account_status_provider.dart, N/A, Provider
lib/features/account/presentation/screens/delete_account_screen.dart, Done, Localized
lib/features/account/presentation/screens/waiting_approval_screen.dart, Done, Localized
lib/features/account/presentation/utils/status_helpers.dart, Done, Localized
lib/features/account/presentation/widgets/approved_state_widget.dart, Done, Localized
lib/features/account/presentation/widgets/categorized_upload_section.dart, Done, Localized
lib/features/account/presentation/widgets/document_list_item.dart, Done, Localized
lib/features/account/presentation/widgets/document_upload_card.dart, Done, Localized
lib/features/account/presentation/widgets/email_section.dart, Done, Localized
lib/features/account/presentation/widgets/status_section.dart, Done, Localized
lib/features/account/presentation/widgets/upload_section.dart, Done, Localized
lib/features/admin/data/models/admin_user_model.dart, N/A, Model
lib/features/admin/data/repositories/admin_repository.dart, N/A, Repo
lib/features/admin/presentation/screens/admin_banner_manage_screen.dart, Done, Localized
lib/features/admin/presentation/screens/manage_users_screen.dart, Done, Localized
lib/features/admin/presentation/widgets/document_grid_viewer.dart, Done, Localized
lib/features/auth/data/legal_document_content.dart, N/A, Legal text
lib/features/auth/data/models/auth_models.dart, N/A, Model
lib/features/auth/data/repositories/auth_repository.dart, N/A, Repo
lib/features/auth/presentation/controllers/auth_controller.dart, N/A, Controller
lib/features/auth/presentation/controllers/login_form_controller.dart, N/A, Controller
lib/features/auth/presentation/controllers/register_form_controller.dart, N/A, Controller
lib/features/auth/presentation/screens/login_screen.dart, Done, Localized
lib/features/auth/presentation/screens/register_screen.dart, Done, Localized
lib/features/auth/presentation/screens/terms_consent_screen.dart, Done, Localized
lib/features/auth/presentation/widgets/auth_header.dart, N/A, Minimal
lib/features/auth/presentation/widgets/auth_role_selector.dart, N/A, Via parent
lib/features/auth/presentation/widgets/legal_document_viewer.dart, N/A, Renders
lib/features/dashboard/data/models/dashboard_models.dart, N/A, Model
lib/features/dashboard/data/repositories/banner_repository.dart, N/A, Repo
lib/features/dashboard/data/repositories/dashboard_repository.dart, N/A, Repo
lib/features/dashboard/domain/models/banner_model.dart, N/A, Model
lib/features/dashboard/presentation/controllers/banner_controller.dart, N/A, Controller
lib/features/dashboard/presentation/controllers/dashboard_controller.dart, N/A, Controller
lib/features/dashboard/presentation/controllers/story_view_state.dart, N/A, State
lib/features/dashboard/presentation/controllers/wholesaler_directory_controller.dart, N/A, Controller
lib/features/dashboard/presentation/screens/categories_list_screen.dart, Done, Localized
lib/features/dashboard/presentation/screens/category_detail_screen.dart, Done, Localized
lib/features/dashboard/presentation/screens/dashboard_screen.dart, Done, Localized
lib/features/dashboard/presentation/screens/kiosk_statistics_screen.dart, Done, Localized
lib/features/dashboard/presentation/screens/product_detail_screen.dart, Done, Localized
lib/features/dashboard/presentation/screens/product_search_screen.dart, Done, Localized
lib/features/dashboard/presentation/screens/products_list_screen.dart, Done, Localized
lib/features/dashboard/presentation/screens/story_viewer_screen.dart, N/A, Viewer
lib/features/dashboard/presentation/screens/wholesaler_profile_screen.dart, Done, Localized
lib/features/dashboard/presentation/screens/wholesalers_list_screen.dart, Done, Localized
lib/features/dashboard/presentation/widgets/active_deals_section.dart, Done, Localized
lib/features/dashboard/presentation/widgets/category_chips.dart, Done, Localized
lib/features/dashboard/presentation/widgets/kiosk_stats_section.dart, Done, Localized
lib/features/dashboard/presentation/widgets/product_grid_item.dart, Done, Localized
lib/features/dashboard/presentation/widgets/product_image_gallery.dart, Done, Localized
lib/features/dashboard/presentation/widgets/product_list_item.dart, N/A, Minimal
lib/features/dashboard/presentation/widgets/story_carousel.dart, Done, Localized
lib/features/dashboard/presentation/widgets/variant_selector.dart, Done, Localized
lib/features/dashboard/presentation/widgets/wholesaler_directory.dart, Done, Localized
lib/features/dashboard/presentation/widgets/wholesaler_strip.dart, Done, Localized
lib/features/deals/data/deal_live_data_service.dart, N/A, Service
lib/features/deals/data/deal_providers.dart, N/A, Providers
lib/features/deals/data/models/deal_models.dart, Done, Shipping via DealShippingDisplay
lib/features/deals/data/repositories/deal_repository.dart, N/A, Repo
lib/features/deals/presentation/screens/deal_detail_screen.dart, Done, Localized
lib/features/deals/presentation/screens/deal_list_screen.dart, Done, Localized
lib/features/deals/presentation/screens/my_deal_orders_screen.dart, Done, Localized
lib/features/deals/presentation/widgets/create_deal_shipment_modal.dart, Done, Localized
lib/features/deals/presentation/widgets/deal_final_payment_card.dart, Done, Localized
lib/features/deals/presentation/widgets/deal_order_form.dart, Done, Localized
lib/features/deals/presentation/widgets/deal_order_management.dart, Done, Localized
lib/features/deals/presentation/widgets/deal_progress_and_orders.dart, Done, Localized
lib/features/deals/presentation/widgets/deal_timer.dart, Done, Localized
lib/features/info/presentation/screens/about_us_screen.dart, Done, Localized
lib/features/info/presentation/screens/faq_screen.dart, Done, Localized
lib/features/info/presentation/screens/help_support_screen.dart, Done, Localized
lib/features/manager/data/models/manager_models.dart, N/A, Model
lib/features/manager/data/providers/manager_data_providers.dart, N/A, Providers
lib/features/manager/data/repositories/manager_repository.dart, N/A, Repo
lib/features/manager/presentation/screens/inactive_members_screen.dart, Done, Localized
lib/features/manager/presentation/screens/manager_banners_screen.dart, Done, Localized
lib/features/manager/presentation/screens/manager_categories_screen.dart, Done, Localized
lib/features/manager/presentation/screens/manager_dashboard_screen.dart, Done, Localized
lib/features/manager/presentation/screens/manager_deals_screen.dart, Done, Localized
lib/features/manager/presentation/screens/manager_orders_screen.dart, Done, Localized
lib/features/manager/presentation/screens/manager_products_screen.dart, Done, Localized
lib/features/manager/presentation/screens/select_category_screen.dart, Done, Localized
lib/features/manager/presentation/screens/select_deal_screen.dart, Done, Localized
lib/features/manager/presentation/screens/select_product_screen.dart, Done, Localized
lib/features/manager/presentation/screens/select_wholesaler_screen.dart, Done, Localized
lib/features/manager/presentation/widgets/banner_form.dart, Done, Localized
lib/features/manager/presentation/widgets/csv_import_modal.dart, Done, Localized
lib/features/manager/presentation/widgets/file_download_stub.dart, N/A, Stub
lib/features/manager/presentation/widgets/file_download_web.dart, N/A, Web
lib/features/manager/presentation/widgets/stats_card.dart, N/A, Numbers
lib/features/notifications/data/models/notification_model.dart, N/A, Model
lib/features/notifications/data/repositories/notification_repository.dart, N/A, Repo
lib/features/notifications/presentation/controllers/notification_controller.dart, N/A, Controller
lib/features/notifications/presentation/screens/notification_history_screen.dart, Done, Localized
lib/features/notifications/presentation/widgets/notification_item.dart, N/A, Renders
lib/features/options/presentation/screens/currency_selection_screen.dart, Done, Localized
lib/features/options/presentation/screens/language_selection_screen.dart, Done, Localized
lib/features/options/presentation/screens/options_screen.dart, Done, Localized
lib/features/orders/data/models/order_models.dart, N/A, Model
lib/features/orders/data/repositories/order_repository.dart, N/A, Repo
lib/features/orders/presentation/controllers/cart_controller.dart, N/A, Controller
lib/features/orders/presentation/screens/cart_screen.dart, Done, Localized
lib/features/orders/presentation/screens/my_order_detail_screen.dart, Done, Localized
lib/features/orders/presentation/screens/my_orders_screen.dart, Done, Localized
lib/features/orders/presentation/screens/quantity_change_result_screen.dart, Done, Localized
lib/features/orders/presentation/screens/shipment_tracking_screen.dart, Done, Localized
lib/features/orders/presentation/widgets/cart_icon_button.dart, Done, Localized
lib/features/orders/presentation/widgets/create_shipment_modal.dart, Done, Localized
lib/features/orders/presentation/widgets/order_status_timeline.dart, N/A, Status
lib/features/orders/presentation/widgets/shipment_timeline.dart, Done, Localized
lib/features/payments/data/repositories/payment_repository.dart, N/A, Repo
lib/features/profile/presentation/profile_screen.dart, Done, Localized
lib/features/reviews/data/models/review_models.dart, N/A, Model
lib/features/reviews/data/repositories/review_repository.dart, N/A, Repo
lib/features/reviews/presentation/widgets/rating_widget.dart, N/A, Stars
lib/features/reviews/presentation/widgets/review_form_modal.dart, Done, Localized
lib/features/reviews/presentation/widgets/review_item.dart, N/A, Renders
lib/features/reviews/presentation/widgets/reviews_section.dart, N/A, Section
lib/features/splash/presentation/splash_screen.dart, N/A, Minimal
lib/features/stories/data/repositories/story_repository.dart, N/A, Repo
lib/features/stories/presentation/screens/create_story_screen.dart, Done, Localized
lib/features/wholesaler/data/models/wholesaler_models.dart, N/A, Model
lib/features/wholesaler/data/providers/wholesaler_data_providers.dart, N/A, Providers
lib/features/wholesaler/data/repositories/wholesaler_repository.dart, N/A, Repo
lib/features/wholesaler/presentation/widgets/create_deal_modal.dart, Done, Localized
lib/features/wholesaler/presentation/widgets/create_product_modal.dart, Done, Localized
lib/features/wholesaler/presentation/widgets/edit_deal_modal.dart, Done, Localized
lib/features/wholesaler/presentation/widgets/edit_product_modal.dart, Done, Localized
lib/features/wholesaler/presentation/widgets/stats_card.dart, N/A, Numbers
lib/shared/utils/snackbar_utils.dart, N/A, Callers pass msg
lib/shared/widgets/curved_bottom_nav_bar.dart, N/A, Icons
lib/shared/widgets/main_scaffold.dart, Done, Localized
lib/shared/widgets/network_avatar.dart, N/A, Avatar
lib/shared/widgets/primary_button.dart, N/A, Generic
lib/shared/widgets/primary_text_field.dart, N/A, Generic
lib/shared/widgets/search_bar.dart, N/A, Hint passed in
```
