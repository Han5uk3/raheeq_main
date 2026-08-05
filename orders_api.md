# Order History Filtering Integration Guide

This guide documents the filters available on the Customer Order History endpoint.

---

## API Endpoint
`GET /v1/orders`

---

## Query Parameters

| Parameter | Type | Required | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `tab` | `string` | No | `upcoming` | The order status tab: `'upcoming' \| 'out_for_delivery' \| 'delivered' \| 'cancelled'`. |
| `page` | `number` | No | `1` | Page number for pagination. |
| `limit` | `number` | No | `10` | Number of items per page. |
| `preset` | `string` | No | - | Relative date range preset: `'today' \| 'yesterday' \| 'last_7_days' \| 'last_30_days' \| 'last_6_months' \| 'all'`. |
| `startDate`| `string` | No | - | Custom start date boundary in `YYYY-MM-DD` format (e.g., `"2026-08-01"`). |
| `endDate` | `string` | No | - | Custom end date boundary in `YYYY-MM-DD` format (e.g., `"2026-08-31"`). |
| `orderType`| `string` / `array` | No | - | Types of orders to filter by. Supports a single value, multiple array values, or a comma-separated list of enums: `'general' \| 'gift' \| 'subscription'`. |

---

## Date Filtering Behavior per Tab

To make date filtering intuitive, the backend queries the date field that matches the status tab currently active in the UI:

*   **`upcoming` tab:** Queries the order's `scheduledDate` (falls back to creation date `createdAt` if scheduledDate is not set).
*   **`out_for_delivery` tab:** Queries the sub-order's assignment date `assignedAt` (falls back to `createdAt`).
*   **`delivered` tab:** Queries the sub-order's admin confirmation date `confirmedAt` (falls back to `deliveredAt` or `createdAt`).
*   **`cancelled` tab:** Queries the sub-order's cancellation date `cancelledAt` (falls back to `createdAt`).

---

## Filter Combinations

Users can combine the period filter (either `preset` or a custom `startDate`/`endDate` range) and the `orderType` filters. 

### Examples

#### 1. Retrieve all General and Subscription orders delivered in August 2026:
`GET /v1/orders?tab=delivered&startDate=2026-08-01&endDate=2026-08-31&orderType=general,subscription`

#### 2. Retrieve upcoming Gift orders for the last 6 months:
`GET /v1/orders?tab=upcoming&preset=last_6_months&orderType=gift`

---
```
