# `GET /subscriptions/{id}` — three fields to add to the response

**To:** Backend
**From:** Mobile (Flutter app — subscription details screen)
**Endpoint:** `GET /subscriptions/{id}`
_Staging:_ `https://api-staging.suqyarahiq.com/api/v1/subscriptions/{id}`

The subscription details screen has three pieces of UI built and waiting on data
this endpoint does not return yet: a **products** card, a **delivery locations**
card, and the **delivery progress** bar. The client-side parsing for all three is
already written, so the moment the response carries these keys the UI starts
using them — no further app change needed.

All three are optional and additive. If a key is missing or `null` the app falls
back to an empty list / `0` and simply hides the card, which is exactly what
happens today. Nothing else in the response changes.

## Summary

| JSON key | Type | Default if absent | Drives |
|---|---|---|---|
| `products` | array of object | `[]` (card hidden) | Products card |
| `deliveryLocations` | array of object | `[]` (card hidden) | Delivery locations card |
| `completedCount` | integer | `0` | Progress bar + "Delivered X of Y orders" |

---

## 1. `products`

The distinct products included in the subscription plan. One entry per product,
**not** one per delivery — this is "what you're subscribed to", not a
delivery history.

```jsonc
"products": [
  {
    "id": "prd_8f21c3",
    "name": "Rahiq Natural Water 330ml — Pack of 40",
    "nameAr": "رحيق مياه طبيعية ٣٣٠ مل - عبوة ٤٠",
    "image": "https://cdn.suqyarahiq.com/products/prd_8f21c3.png"
  }
]
```

| Field | Type | Notes |
|---|---|---|
| `id` | string | Product id. |
| `name` | string | English name, shown when the app is in English. |
| `nameAr` | string | Arabic name, shown when the app is in Arabic. **Please always send both** — the app picks by locale and does not fall back between them, so a missing `nameAr` renders as an empty row for Arabic users. |
| `image` | string | Absolute HTTPS URL. Rendered at 40×40, so a square asset works best. An empty string or an unreachable URL shows a broken-image placeholder; the row still renders. |

---

## 2. `deliveryLocations`

Where the subscription's deliveries go.

```jsonc
"deliveryLocations": [
  {
    "id": "loc_4a9b02",
    "name": "Al Olaya Tower — Floor 12",
    "nameAr": "برج العليا - الدور ١٢",
    "address": "King Fahd Rd, Al Olaya, Riyadh 12214"
  }
]
```

| Field | Type | Notes |
|---|---|---|
| `id` | string | Location id. |
| `name` | string | English label, shown when the app is in English. |
| `nameAr` | string | Arabic label, shown when the app is in Arabic. Same caveat as products — send both. |
| `address` | string | Parsed by the app but **not displayed yet**; it is reserved for a second line under each location. Send it if you have it, but it is not blocking. |

### Category locations are fine here

A delivery location does **not** have to be one specific site. When a
subscription targets a *category* or *city* rather than a particular place —
"Meqat Mosques", "Orphanages", — send the **category's** `name` and
`nameAr` in this object's `name` and `nameAr` fields, with the category's id as `id`.
"Makkah", "Jeddah", — send the **city's** `name` and
`nameAr` in this object's `name` and `nameAr` fields, with the category's id as `id`.

The app renders whatever string arrives, so no client-side change or type flag is
needed to support this. `address` can be an empty string for a category entry,
since there is no single street address to give.

```jsonc
// A category rather than a specific site — perfectly valid:
{
  "id": "cat_mosques",
  "name": "Mosques",
  "nameAr": "المساجد",
  "address": ""
}
```

Mixing the two kinds in the same array is fine.

---

## 3. `completedCount`

How many of the subscription's deliveries have been completed.

```jsonc
"completedCount": 7
```

> **Note the key name.** The app's model field is `completeCount` (no "d"), but it
> reads the JSON key **`completedCount`**. Please send `completedCount` — that is
> the string the parser looks for. The internal name mismatch is on our side and
> does not affect the contract.

It pairs with the existing `ordersCount`, which the app already receives and uses
as the denominator:

- Progress bar fill = `completedCount / ordersCount`
- Label = "Delivered `completedCount` of `ordersCount` orders"

Two things to keep consistent:

1. **`completedCount` must be ≤ `ordersCount`.** The app clamps it, so a larger
   value silently pins the bar at 100% rather than erroring — but the label will
   look wrong.
2. **Count the same statuses the calendar does.** The delivery calendar on the
   same screen colours a day green when every delivery on it has status
   `DELIVERED` or `COMPLETED`. If `completedCount` is computed from a different
   rule, the bar and the calendar will disagree on the same screen if the completedCount and the count of *deliveries* with a completed (confirmed) status differ.

---

## Full example

Existing fields trimmed for brevity; the three additions are marked.

```jsonc
{
  "success": true,
  "data": {
    "id": "sub_1029ab",
    "subscriptionNumber": "SUB-10294",
    "planName": "Monthly Water Plan",
    "planNameAr": "خطة المياه الشهرية",
    "planImage": "https://cdn.suqyarahiq.com/plans/monthly.png",
    "frequency": "MONTHLY",
    "status": "ACTIVE",
    "purchasedDate": "2026-03-01T09:12:00.000Z",
    "startDate": "2026-03-05T00:00:00.000Z",
    "endDate": "2026-09-05T00:00:00.000Z",
    "monthsCount": 6,
    "ordersCount": 12,
    "paymentMethod": "MADA",
    "totalAmount": 1440.00,
    "invoiceUrl": "https://cdn.suqyarahiq.com/invoices/sub_1029ab.pdf",
    "target": { "type": "MOSQUE", "label": "Mosques", "labelAr": "المساجد", "image": "" },
    "deliveries": [ /* unchanged */ ],
    "giftCards": [ /* unchanged */ ],

    // ── NEW ──────────────────────────────────────────────
    "completedCount": 7,
    "deliveryLocations": [
      {
        "id": "loc_4a9b02",
        "name": "Al Olaya Tower — Floor 12",
        "nameAr": "برج العليا - الدور ١٢",
        "address": "King Fahd Rd, Al Olaya, Riyadh 12214"
      },
      {
        "id": "cat_mosques",
        "name": "Mosques",
        "nameAr": "المساجد",
        "address": ""
      }
    ],
    "products": [
      {
        "id": "prd_8f21c3",
        "name": "Rahiq Natural Water 330ml — Pack of 40",
        "nameAr": "رحيق مياه طبيعية ٣٣٠ مل - عبوة ٤٠",
        "image": "https://cdn.suqyarahiq.com/products/prd_8f21c3.png"
      },
      {
        "id": "prd_5c77de",
        "name": "Rahiq Natural Water 600ml — Pack of 24",
        "nameAr": "رحيق مياه طبيعية ٦٠٠ مل - عبوة ٢٤",
        "image": "https://cdn.suqyarahiq.com/products/prd_5c77de.png"
      }
    ]
    // ─────────────────────────────────────────────────────
  }
}
```

---

## Backward compatibility

Nothing here breaks an older app build. Every one of the three keys is read
defensively:

- `products` / `deliveryLocations` — a missing key, `null`, or `[]` all parse to
  an empty list, and the card is hidden when the list is empty.
- `completedCount` — a missing key or `null` parses to `0`; the progress bar
  renders empty.
- Each string field inside the objects defaults to `""` if absent, so a partial
  object will not crash the screen.

So the fields can be rolled out on the API before or after the app ships — the
order does not matter.
