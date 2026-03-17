# Active Members / Active Shops Feature – Handoff

**Date:** Feb 4, 2025  
**Status:** Implemented (Backend + Flutter). Build passes; Flutter analyze has no **errors** (info/warnings only).

---

## What Was Implemented

### Client feedback (summary)
- Show **“X active members”** and **“X active shops”** so every shop and wholesaler sees this when opening the app.
- Optional **launch bump**: e.g. start with 300–400 and add real counts on top.
- **Inactive members**: if shops haven’t ordered for 2–3 months, **notify admin** so they can contact or remove them.

### User roles
- **Admin / Sub-admin**: see all stats + inactive count + get inactive-members push.
- **Wholesaler**: manager dashboard shows “Active Shops = 1” (self) and platform active members.
- **Kiosk / Shop**: user dashboard shows “X active shops” and “X active members”; nearby wholesalers section shows “X active shops” beside “View All”.

---

## Backend

### Config (`Backend/src/config/env.ts`)
- `ACTIVE_SHOPS_BASE_COUNT` – added to real wholesaler count (launch bump).
- `ACTIVE_MEMBERS_BASE_COUNT` – added to real member count (launch bump).
- `INACTIVE_MEMBER_DAYS` – days without order to consider inactive (default **60**).

### User model (`Backend/src/modules/users/user.model.ts`)
- New optional field: **`lastOrderAt`** (Date). Set when user places a product or deal order.

### Order creation
- **Product orders** (`Backend/src/modules/orders/order.service.ts`): after `OrderModel.create`, `UserModel.findByIdAndUpdate(buyerId, { lastOrderAt: new Date() })`.
- **Deal orders** (`Backend/src/modules/deals/deal.service.ts`): same update for buyer.

### Manager stats (`Backend/src/modules/manager/manager.service.ts`)
- **activeShops** – count of approved wholesalers (+ base for admin/sub-admin).
- **activeMembers** – Kiosk users with `lastOrderAt >= now - INACTIVE_MEMBER_DAYS` (+ base for admin).
- **inactiveMembersCount** – (admin only) Kiosk users with no order in N days or never ordered.

### Dashboard snapshot (`Backend/src/modules/catalog/catalog.service.ts`)
- **activeShopsCount**, **activeMembersCount** – same logic + base; returned in `/catalog/dashboard` for user dashboard and WholesalerDirectory.

### Cron (existing daily Vercel cron)
- **File:** `Backend/src/modules/cron/cron.routes.ts`
- New step: **`sendInactiveMembersAlert()`** (`Backend/src/services/notification.service.ts`).
- Finds Kiosk users with no order in `INACTIVE_MEMBER_DAYS` days; sends push to admins/sub-admins: e.g. “X shop(s) haven’t placed an order in 60 days…”

### Optional env (e.g. `.env`)
```env
ACTIVE_SHOPS_BASE_COUNT=400
ACTIVE_MEMBERS_BASE_COUNT=400
INACTIVE_MEMBER_DAYS=60
```

---

## Flutter

### Manager dashboard (`Flutter-Mobile/lib/features/manager/`)
- **ManagerStats** model: `activeShops`, `activeMembers`, `inactiveMembersCount`.
- **Manager dashboard UI**: for admin, two new stat cards (Active Shops, Active Members) and, if `inactiveMembersCount > 0`, an orange alert card “X Inactive Members” with subtitle “No order in 60+ days”.

### User dashboard (`Flutter-Mobile/lib/features/dashboard/`)
- **DashboardSnapshot** model: `activeShopsCount`, `activeMembersCount`.
- Chips under banner when counts > 0: “X active shops”, “X active members”.
- **WholesalerDirectory**: new optional `activeShopsCount`; when set, shown beside “View All” (e.g. “X active shops · View All”).

### Localization
- New keys: `activeShops`, `activeMembers`, `inactiveMembers`, `activeShopsSubtitle`, `activeMembersSubtitle`, `inactiveMembersSubtitle` (EN + hi, tr, ur, ar, de).

---

## Build & Analyze (as of handoff)

- **Backend:** `npm run build` – **passes** (tsc).
- **Flutter:** `flutter analyze` – **no errors**; 330 issues are **info/warning** (e.g. deprecated `withOpacity`, relative lib imports in tests). One fix applied: `upload_section.dart` was passing `List<File>` to `DocumentListItem` which expects `PickedFileData`; changed to `List<PickedFileData>` and use `upload_service.dart` for `PickedFileData`.

---

## If You Resume Tomorrow

1. **Git:** Commit and push both repos (Backend + Flutter-Mobile) with a single message covering active members/shops feature and upload_section type fix.
2. **Optional – Backfill `lastOrderAt`:** Existing users have no `lastOrderAt`. To classify them correctly, add a one-off script or migration that sets `User.lastOrderAt` from the latest order date (max of `Order.createdAt` / `DealOrder.createdAt` where `buyer = user._id`).
3. **Optional – Flutter:** Tidy `flutter analyze` info/warnings (e.g. replace `withOpacity` with `withValues()`, fix test imports) in a separate pass.
4. **Verify:** Log in as admin → manager dashboard (active shops, active members, inactive alert). Log in as Kiosk → user dashboard (chips + “X active shops” beside View All in wholesaler section).

---

## Files Touched (for reference)

**Backend:**  
`src/config/env.ts`, `src/modules/users/user.model.ts`, `src/modules/orders/order.service.ts`, `src/modules/deals/deal.service.ts`, `src/modules/manager/manager.service.ts`, `src/modules/catalog/catalog.service.ts`, `src/modules/catalog/catalog.controller.ts`, `src/modules/cron/cron.routes.ts`, `src/services/notification.service.ts`

**Flutter:**  
`lib/features/manager/data/models/manager_models.dart`, `lib/features/manager/presentation/screens/manager_dashboard_screen.dart`, `lib/features/dashboard/data/models/dashboard_models.dart`, `lib/features/dashboard/presentation/screens/dashboard_screen.dart`, `lib/features/dashboard/presentation/widgets/wholesaler_directory.dart`, `lib/features/account/presentation/widgets/upload_section.dart`, `lib/core/localization/*` (english_file, app_localizations, hi, tr, ur, ar, de)
