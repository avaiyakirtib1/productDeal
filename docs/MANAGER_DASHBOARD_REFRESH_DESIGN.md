# Manager Dashboard Data Freshness – Design

## Problem

When a user places an order from another phone, the manager dashboard does not show the latest data until the user manually pulls to refresh or navigates away and back.

## Current State

- **Manager dashboard** uses `managerStatsProvider` (FutureProvider) → fetches `/manager/stats` once when mounted
- **Refresh** only via pull-to-refresh (`RefreshIndicator`)
- **Deals** already poll: `DealLiveDataService` every 15s, `DealProgressAndOrdersCard` every 5s
- **Backend** sends push notifications for: `new_product_order`, `new_deal_order`, `order_status_changed`, `deal_status_changed`, etc.
- **Flutter FCM handler** currently only handles `deal_closed` (invalidates deal detail)

## Solution Options

| Approach | Server Load | DB Load | UX | Notes |
|----------|-------------|---------|-----|-------|
| **1. Notification-driven** | None | None | Instant when push delivered | Backend already sends pushes |
| **2. App resume refresh** | 1 req on resume | 1 query | Good | Catches when user returns to app |
| **3. Polling (e.g. 30s)** | N req/min | N queries | Good | Adds load; deals already poll heavily |
| **4. Polling (60–90s)** | Low | Low | Acceptable | Fallback only |

## Recommendation

**Primary: Notification-driven + App resume**

1. **Extend FCM handler** – When order-related push arrives, invalidate `managerStatsProvider` (and manager orders list if needed). Zero extra load; backend already sends these pushes.
2. **App resume refresh** – When app comes to foreground, invalidate manager stats. One extra request only when user returns; no continuous polling.

**Avoid:** Adding polling for manager dashboard. Deals already poll every 5–15s; adding more would increase server/DB load without clear benefit.

## Notification Types That Affect Manager Dashboard

| Type | Affects | Action |
|------|---------|--------|
| `new_product_order` | Stats, recent orders | Invalidate manager stats |
| `new_deal_order` | Stats, recent orders | Invalidate manager stats |
| `order_status_changed` | Stats, recent orders | Invalidate manager stats |
| `deal_status_changed` | Stats, recent orders | Invalidate manager stats |
| `order_quantity_changed` | Stats | Invalidate manager stats |
| `deal_order_quantity_changed` | Stats | Invalidate manager stats |
| `payment_reported_by_buyer` | Stats | Invalidate manager stats |
| `deal_closed` | Deal detail (existing) | Invalidate deal detail |

## Implementation

1. **FCM handler** – Extend `fcmDealClosedHandlerProvider` (or rename to `fcmNotificationHandlerProvider`) to handle all above types. For order-related types → `ref.invalidate(managerStatsProvider)`.
2. **App lifecycle** – Add `AppLifecycleHandler` widget with `WidgetsBindingObserver`. On `AppLifecycleState.resumed` → `ref.invalidate(managerStatsProvider)`.
