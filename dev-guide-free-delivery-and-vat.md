# Developer Guide: Free Delivery & VAT Snapshotting

This guide explains how **Free Delivery Promotions** and **VAT Percentage Snapshots** are structured across the Checkout and User Order APIs.

---

## 1. Field Definitions

| Field | Type | Description |
| :--- | :--- | :--- |
| **`deliveryFee`** | `number` | The actual amount charged to the user for delivery. If free delivery is applied, this is `0`. Always used in totals and math calculations. |
| **`originalDeliveryFee`** | `number` | The baseline delivery charge before the waiver (e.g. `15.00`). Used to display strikethrough pricing (`~~15.00 SAR~~`). |
| **`isDeliveryFree`** | `boolean` | `true` if free delivery was applied to this order/checkout; `false` otherwise. Used to trigger the `FREE` badge. |
| **`vatPercentage`** | `number` | The exact VAT percentage applied at order time (e.g. `15.00`). Defaults to `15` for older orders. |
| **`vatAmount`** | `number` | The calculated VAT amount in SAR. |

---

## 2. API Endpoints

### A. Checkout API (`GET /api/v1/checkout`, `POST /api/v1/checkout`)
Located in `response.data.pricing`:

| Property | Value (Free Delivery Example) | Value (Standard Delivery Example) |
| :--- | :--- | :--- |
| `deliveryFee` | `0` | `15.00` |
| `originalDeliveryFee` | `15.00` | `15.00` |
| `isFreeDelivery` | `true` | `false` |
| `vatPercentage` | `15.00` | `15.00` |
| `vatAmount` | `15.00` | `17.25` |

---

### B. User Order Details API (`GET /api/v1/orders/:id`)
Located in `response.data.financials`:

| Property | Value (Free Delivery Example) | Value (Standard Delivery Example) |
| :--- | :--- | :--- |
| `deliveryFee` | `0` | `15.00` |
| `originalDeliveryFee` | `15.00` | `15.00` |
| `isDeliveryFree` | `true` | `false` |
| `vatPercentage` | `15.00` | `15.00` |
| `vatAmount` | `15.00` | `17.25` |

---

### C. Admin Order APIs (`GET /api/v1/admin/orders`, `GET /api/v1/admin/orders/:id`)
All sub-order items and parent order objects include `isDeliveryFree`, `originalDeliveryFee`, and `vatPercentage`.

---

## 3. UI Display Rules for Clients

### Delivery Fee Row
- **When `isDeliveryFree === true`**:
  - Render `originalDeliveryFee` with strikethrough (e.g. `~~15.00 SAR~~`).
  - Render a `FREE` / `مجاناً` badge next to it.
- **When `isDeliveryFree === false`**:
  - If `deliveryFee === 0`: Render `Free` / `مجاناً`.
  - If `deliveryFee > 0`: Render `${deliveryFee} SAR` as normal.

### VAT Row
- Render the label with the dynamic snapshot percentage: `VAT (${vatPercentage || 15}%)` / `ضريبة القيمة المضافة (${vatPercentage || 15}%)`.
- Render the value: `${vatAmount} SAR`.

### Math & Totals
- Never recalculate or re-add `originalDeliveryFee` on the client.
- Always use `totalAmount` / `finalTotal` directly from the API response.
