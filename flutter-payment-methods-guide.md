# Flutter Mobile App Guide: Payment Methods & Checkout Logic

This document provides product logic, business rules, and UI/UX guidelines for Flutter mobile developers regarding payment methods, wallet usage, 100% discount orders, and order history display.

---

## 1. Overview of Payment Methods

The backend supports the following payment method keys in order payloads and responses:

| Method Key | Who Selects It | When It Appears | Refund / Gateway Handling |
| :--- | :--- | :--- | :--- |
| **`WALLET`** | System (Automatic) | Customer covers 100% of order with wallet balance (or Coupon + Wallet = 0 SAR). | Instant approval. No gateway webview. Refund goes back to wallet. |
| **`FREE`** | System (Automatic) | Order is 100% covered by a promo coupon or free grant (0 SAR payable, 0 SAR from wallet). | Instant approval. No gateway webview. No refund needed. |
| **`MANUAL`** | Admin Only | Administrative offline orders (cash in hand, POS terminal). | App users never select this at checkout. Visible only in order history if created by admin. |
| **`APPLE_PAY`** | User (iOS) | Payable amount > 0 SAR paid via Apple Pay sheet. | Processed via PayTabs gateway. |
| **`STC_PAY`** | User | Payable amount > 0 SAR paid via STC Pay mobile OTP. | Processed via PayTabs gateway. |
| **`CREDIT_CARD`** | User | Payable amount > 0 SAR paid via Visa/Mastercard/Mada. | Processed via PayTabs gateway. |
| **`IBAN`** | User | Payable amount > 0 SAR transferred via manual bank transfer. | Customer uploads transfer receipt; status remains awaiting verification. |

---

## 2. Checkout Screen Rules & Logic

### Rule 1: How `WALLET` and `FREE` Are Triggered
- The customer **never** picks a radio button called "FREE" or "WALLET" from the gateway list.
- Instead, the customer toggles **"Use Wallet Balance"** and/or applies a **Coupon Code**.

### Rule 2: When Payable Total Becomes 0.00 SAR
If the remaining payable amount becomes **0.00 SAR**:
1. **Hide or Disable Gateway Options**: Do not allow or force the user to choose Apple Pay, Credit Card, or STC Pay.
2. **Change the Action Button Text**: Update the primary CTA from *"Pay X SAR"* to *"Confirm Order"* (or in Arabic: *"تأكيد الطلب"*).
3. **No Payment Gateway Webview / SDK**: Do not invoke the PayTabs SDK or open an external payment screen.
4. **Backend Auto-Assignment**:
   - If wallet credits were used to reach 0 SAR: Backend sets `paymentMethod = "WALLET"`.
   - If coupon alone reached 0 SAR (no wallet used): Backend sets `paymentMethod = "FREE"`.
5. **Direct Navigation**: Send the user straight to the **Order Success / Confirmation Screen**.

### Rule 3: Partial Wallet Usage
If the customer has 20 SAR in wallet balance and the order total is 100 SAR:
- Wallet covers 20 SAR.
- Remaining payable amount = 80 SAR.
- Customer **must** select a gateway for the remaining 80 SAR (`APPLE_PAY`, `CREDIT_CARD`, `STC_PAY`, or `IBAN`).
- In this scenario, `paymentMethod` on the order will be the selected gateway (e.g. `APPLE_PAY`), while the order breakdown records the 20 SAR wallet deduction.

### Rule 4: `MANUAL` Is Forbidden for App Checkout
- Never display `MANUAL` as an option in the mobile checkout sheet.
- If a user receives an order with `MANUAL` in their order history, it means an Admin created the order offline on their behalf.

---

## 3. Localization & Display Guidelines (Order History & Details)

When displaying orders in the **My Orders** list and **Order Details** screen, translate the `paymentMethod` enum as follows:

### English & Arabic Labels

| Payment Method Key | English Label | Arabic Label (العربية) | UI Color Theme / Intent |
| :--- | :--- | :--- | :--- |
| **`WALLET`** | Wallet Balance | رصيد المحفظة | Purple / Indigo |
| **`FREE`** | Free Order | طلب مجاني | Emerald / Teal |
| **`MANUAL`** | Cash / Offline | نقدي / يدوي | Amber / Orange |
| **`APPLE_PAY`** | Apple Pay | أبل باي | Neutral / Dark |
| **`STC_PAY`** | STC Pay | إس تي سي باي | Green / Violet |
| **`CREDIT_CARD`** | Credit Card | بطاقة ائتمانية | Blue |
| **`IBAN`** | Bank Transfer | تحويل بنكي | Sky Blue |

---

## 4. Order Details & Receipt Breakdown UI

In the **Order Summary / Receipt** section of the mobile app, display an itemized breakdown depending on the payment method:

### Scenario A: Order paid 100% by Wallet (`paymentMethod == 'WALLET'`)
- **Subtotal**: `150.00 SAR`
- **VAT (15%)**: `22.50 SAR`
- **Delivery**: `Free`
- **Wallet Balance Used**: `-172.50 SAR`
- **Total Paid**: `0.00 SAR`
- **Payment Method Badge**: `Wallet Balance` (`رصيد المحفظة`)
- **Payment Status**: `PAID` (`مدفوع`)

### Scenario B: 100% Free / Discounted Order (`paymentMethod == 'FREE'`)
- **Subtotal**: `100.00 SAR`
- **Discount (Coupon: EID100)**: `-100.00 SAR`
- **Delivery**: `Free`
- **Total Paid**: `0.00 SAR`
- **Payment Method Badge**: `Free Order` (`طلب مجاني`)
- **Payment Status**: `PAID` (`مدفوع`)

### Scenario C: Partial Wallet + Gateway
- **Subtotal**: `200.00 SAR`
- **Wallet Balance Used**: `-50.00 SAR`
- **Total Paid**: `150.00 SAR`
- **Payment Method Badge**: `Apple Pay` (`أبل باي`)
- **Payment Status**: `PAID` (`مدفوع`)

### Scenario D: Admin Offline / Manual Order (`paymentMethod == 'MANUAL'`)
- **Total Paid**: `150.00 SAR`
- **Payment Method Badge**: `Cash / Offline` (`نقدي / يدوي`)
- **Note to Customer**: *"Payment collected offline or handled by customer support."*

---

## 5. Summary Checklist for Flutter Developers

- [ ] Ensure the order model parses all 7 enum strings: `CREDIT_CARD`, `APPLE_PAY`, `STC_PAY`, `IBAN`, `WALLET`, `FREE`, `MANUAL`.
- [ ] During checkout, recalculate the payable total whenever wallet toggle or coupon changes.
- [ ] When payable total is `0.00 SAR`, bypass payment gateway selection and launch order placement immediately.
- [ ] Do not expose `MANUAL`, `WALLET`, or `FREE` as selectable payment gateway radio buttons during checkout.
- [ ] In Order History and Details, render the appropriate localized title and badge color for `WALLET`, `FREE`, and `MANUAL`.
- [ ] Ensure receipt breakdown clearly shows wallet deduction and coupon discount lines so users understand why the cash total was 0 SAR.
