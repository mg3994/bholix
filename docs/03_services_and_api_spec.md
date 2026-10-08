# Services & API Specifications

## Overview
This document specifies the contracts, endpoints, request/response formats, and core business rules for all backend integration services in `bholix`.

---

## 1. AppsScript Bridge Service (`AppsScriptService`)

Interfaces with a serverless Google Apps Script deployment.

### Endpoint Base URL:
`https://script.google.com/macros/s/{DEPLOYMENT_ID}/exec`

### Actions:

#### A. Create Order (`createOrder`)
* **HTTP Method**: `POST`
* **Query Parameters**: `?action=createOrder`
* **Request Body (JSON)**:
  ```json
  {
    "cartItems": [
      {
        "name": "Product Name",
        "quantity": 2,
        "price": "499.00",
        "selectedPackage": "Standard",
        "addOns": [
          { "name": "Warranty", "quantity": 2, "price": "50.00" }
        ]
      }
    ],
    "address": {
      "name": "Customer Name",
      "street": "123 Main St",
      "pincode": "110001",
      "phone": "+919876543210"
    },
    "payment": {
      "method": "UPI",
      "txnId": "TXN_123456789",
      "status": "SUCCESS"
    }
  }
  ```
* **Response Body (JSON)**:
  ```json
  {
    "status": "success",
    "orderId": "ORD-987654",
    "message": "Order created successfully"
  }
  ```

#### B. Place Suggestions (`getPlaceSuggestions`)
* **HTTP Method**: `GET`
* **Query Parameters**: `?action=places&input={query}`
* **Response Body (JSON)**:
  ```json
  {
    "predictions": [
      {
        "description": "Connaught Place, New Delhi, Delhi, India",
        "place_id": "ChIJ213..."
      }
    ]
  }
  ```

---

## 2. Payment Service (`PaymentService`)

### UPI Deep Link Generator Contract

#### Function: `generateUpiUri`
* **Parameters**:
  - `vpa`: String (default: `"manishsharma3994@okhdfcbank"`)
  - `name`: String (default: `"Bholix Retail"`)
  - `mcc`: String (default: `"5251"`)
  - `txnId`: String
  - `note`: String
  - `amount`: Double
* **Output String**:
  `upi://pay?pa={vpa}&pn={urlEncoded(name)}&mc={mcc}&tr={txnId}&tn={urlEncoded(note)}&am={formattedAmount}&cu=INR`
* **Formatting Rules**:
  - `amount` formatted to 2 decimal places (`499.00`).
  - `name` and `note` must be URL-encoded (e.g. spaces converted to `%20`).

---

## 3. Geo & Address Verification Service (`GeoVerificationService`)

### Indian PIN Code Regex:
`^[1-9][0-9]{5}$`

### Schema.org Delivery Payload Builder:
Transforms checkout form input into Schema.org `ParcelDelivery`:
```json
{
  "@type": "ParcelDelivery",
  "deliveryAddress": {
    "@type": "PostalAddress",
    "streetAddress": "123 Main St",
    "addressLocality": "New Delhi",
    "postalCode": "110001",
    "addressCountry": "IN"
  },
  "geo": {
    "@type": "GeoCoordinates",
    "latitude": 28.6139,
    "longitude": 77.2090
  }
}
```

---

## 4. Phone Verification Service (`PhoneVerificationService`)

### E.164 Parsing Rules:
* Accepts raw inputs: `9876543210`, `+91 9876543210`, `09876543210`.
* Default country code: `+91` (India).
* Output format: `+919876543210`.
