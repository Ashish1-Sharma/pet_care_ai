# Pet AI Scanner Backend Module Documentation

This module provides a Pet AI Scanner backend subsystem for visual assessments and health triage of common pet conditions. It includes Google Authentication, scan analytics powered by the **OpenAI Responses API** (with local caching and `sharp` image compression), scan history records, and payments integration with **Razorpay**.

---

## Environment Variables

Ensure these environment variables are added to your `.env` file before running the server:

```env
# Google Authentication
GOOGLE_CLIENT_ID=your-google-client-id.apps.googleusercontent.com

# OpenAI Configuration
OPENAI_API_KEY=sk-proj-your-api-key
OPENAI_MODEL=gpt-5-mini

# Razorpay Configuration
RAZORPAY_KEY_ID=rzp_live_your-key-id
RAZORPAY_KEY_SECRET=your-razorpay-key-secret

# JWT Security
JWT_SECRET=your-auth-jwt-secret
```

---

## Collection Schemes (MongoDB)

### 1. `pet_users`
- `id` (integer): Auto-incrementing identifier.
- `googleId` (string): Authenticated Google subject ID.
- `name` (string): User's profile display name.
- `email` (string): User's email address.
- `profileImage` (string): Google profile picture URL.
- `remainingScans` (integer): Balance scans (default is `5` on signup).
- `lastDailyReward` (string): Date in `YYYY-MM-DD` when the last daily free scan was awarded.
- `createdAt` (string/ISO): Timestamp of account registration.
- `updatedAt` (string/ISO): Timestamp of last document modification.

### 2. `pet_scans`
- `id` (integer): Auto-incrementing identifier.
- `userId` (integer): The user's ID owning this record.
- `petType` (string): Type of pet (e.g. Dog, Cat).
- `bodyPart` (string): Evaluated body part (e.g. Ears, Skin).
- `symptoms` (array of strings): Selected symptoms.
- `imageUrls` (array of strings): Array of image URLs uploaded for this scan.
- `aiResponse` (object): Triage assessment JSON returned by the AI.
- `createdAt` (string/ISO): Creation timestamp.

### 3. `pet_payments`
- `id` (integer): Auto-incrementing identifier.
- `userId` (integer): The user's ID making the payment.
- `razorpayOrderId` (string): The Razorpay order ID generated.
- `razorpayPaymentId` (string): Razorpay payment ID (added on successful callback).
- `amount` (number): Price of transaction in INR.
- `scansPurchased` (integer): Number of scans purchased.
- `status` (string): Status of the payment (`pending` or `success`).
- `createdAt` (string/ISO): Transaction start timestamp.

---

## API Endpoints Reference

### 1. Google Login
Authenticates Google ID Tokens. Creates a new account with 5 free scans if the user does not exist, or updates daily scan rewards if they do exist. Returns a signed JWT.

- **Route:** `POST /api/pet/google-login`
- **Authentication:** Public
- **Request Headers:**
    - `Content-Type: application/json`
- **Request Body:**
  ```json
  {
    "token": "eyJhbGciOiJSUzI1NiIsImtp..." 
  }
  ```
  *(Note: Also accepts `idToken` in place of `token`)*
- **Response (200 OK):**
  ```json
  {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI...",
    "user": {
      "id": 1,
      "googleId": "1049281749284128",
      "name": "Alex Mercer",
      "email": "alex.mercer@gmail.com",
      "profileImage": "https://lh3.googleusercontent.com/a/ALm6w...",
      "remainingScans": 5,
      "lastDailyReward": "2026-07-03",
      "createdAt": "2026-07-03T09:00:00.000Z",
      "updatedAt": "2026-07-03T09:00:00.000Z"
    }
  }
  ```

---

### 2. Analyze Pet Health
Triages a pet's symptoms and images. Resizes and compresses images to 1024px on the longest side. Resolves local loopback `/uploads/` URLs directly to file buffers on disk to avoid loopback calls. Deducts one scan on a successful AI response.

- **Route:** `POST /api/pet/analyze`
- **Authentication:** Protected (JWT Bearer Token required)
- **Rate Limit:** 1 request every 10 seconds per user
- **Request Headers:**
    - `Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI...`
    - `Content-Type: application/json`
- **Predefined Symptoms Allowed:**
  `vomiting`, `diarrhea`, `lethargy`, `coughing`, `sneezing`, `itching`, `hair_loss`, `redness`, `swelling`, `limping`, `loss_of_appetite`, `increased_thirst`, `frequent_urination`, `constipation`, `bad_breath`, `drooling`, `shivering`, `breathing_difficulty`, `discharge_eye_nose`, `behavioral_change`, `scratching`, `blood_in_urine_stool`, `seizures`, `lump_bump`
- **Request Body:**
  ```json
  {
    "petType": "Dog",
    "bodyPart": "Skin",
    "symptoms": ["itching", "redness"],
    "imageUrls": [
      "http://localhost:3000/uploads/1783069588-123456.jpg"
    ],
    "description": "Scratching frequently near the neck area, causing minor red bumps."
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "scan": {
      "id": 1,
      "userId": 1,
      "petType": "Dog",
      "bodyPart": "Skin",
      "symptoms": ["itching", "redness"],
      "imageUrls": ["http://localhost:3000/uploads/1783069588-123456.jpg"],
      "aiResponse": { ... },
      "createdAt": "2026-07-03T09:06:28.000Z"
    },
    "aiResponse": {
      "possibleConditions": [
        {
          "name": "Flea Allergy Dermatitis (FAD)",
          "probability": 80
        },
        {
          "name": "Sarcoptic Mange",
          "probability": 45
        }
      ],
      "criticality": "Low",
      "reason": "Red bumps located around the neck and scratching symptoms suggest localized flea sensitivity or contact allergen.",
      "whatOwnerShouldDo": "Wash bedding, apply veterinary-approved topical flea control, and monitor closely.",
      "homeCare": [
        "Vacuum carpets and wash pet's bedding in hot water.",
        "Use a cool damp compress over red area for short-term comfort.",
        "Prevent the pet from scratching by using a protective collar."
      ],
      "emergencySigns": [
        "Uncontrolled swelling of the face or mouth",
        "Signs of difficulty breathing or rapid panting"
      ],
      "needVet": true,
      "visitWithin": "24 Hours",
      "disclaimer": "This assessment is generated by AI and is not a substitute for examination by a licensed veterinarian."
    }
  }
  ```

---

### 3. Get User Profile
Retrieves the logged-in user's profile and automatically rewards a daily scan increment if the date changed since `lastDailyReward`.

- **Route:** `GET /api/pet/profile`
- **Authentication:** Protected (JWT Bearer Token required)
- **Request Headers:**
    - `Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI...`
- **Response (200 OK):**
  ```json
  {
    "id": 1,
    "googleId": "1049281749284128",
    "name": "Alex Mercer",
    "email": "alex.mercer@gmail.com",
    "profileImage": "https://lh3.googleusercontent.com/...",
    "remainingScans": 5,
    "lastDailyReward": "2026-07-03",
    "createdAt": "2026-07-03T09:00:00.000Z",
    "updatedAt": "2026-07-03T09:00:00.000Z"
  }
  ```

---

### 4. Get Scan History
Retrieves all historical scans made by the authenticated user, sorted with the newest first.

- **Route:** `GET /api/pet/history`
- **Authentication:** Protected (JWT Bearer Token required)
- **Request Headers:**
    - `Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI...`
- **Response (200 OK):**
  ```json
  [
    {
      "id": 1,
      "userId": 1,
      "petType": "Dog",
      "bodyPart": "Skin",
      "symptoms": ["itching", "redness"],
      "imageUrls": ["http://localhost:3000/uploads/1783069588-123456.jpg"],
      "aiResponse": {
        "possibleConditions": [{"name": "Flea Allergy Dermatitis (FAD)", "probability": 80}],
        "criticality": "Low",
        "reason": "Typical localized scratching and red bumps.",
        "whatOwnerShouldDo": "Use flea control.",
        "homeCare": ["Wash bedding"],
        "emergencySigns": [],
        "needVet": true,
        "visitWithin": "24 Hours",
        "disclaimer": "AI assessment; not a substitute for a licensed vet."
      },
      "createdAt": "2026-07-03T09:06:28.000Z"
    }
  ]
  ```

---

### 5. Delete Scan History Item
Deletes a scan history item belonging to the user by its integer ID.

- **Route:** `DELETE /api/pet/history/:id`
- **Authentication:** Protected (JWT Bearer Token required)
- **Path Parameters:**
    - `id`: The scan's integer ID to delete (e.g. `1`).
- **Request Headers:**
    - `Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI...`
- **Response (200 OK):**
  ```json
  {
    "success": true
  }
  ```

---

### 6. Create Payment Order
Contacts Razorpay to create a transaction order for purchasing scan packages and writes a pending transaction locally.

- **Route:** `POST /api/pet/create-order`
- **Authentication:** Protected (JWT Bearer Token required)
- **Request Headers:**
    - `Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI...`
    - `Content-Type: application/json`
- **Request Body:**
  ```json
  {
    "amount": 299.00,
    "scansPurchased": 10
  }
  ```
- **Response (201 Created):**
  ```json
  {
    "id": "order_EKPA437882",
    "entity": "order",
    "amount": 29900,
    "currency": "INR",
    "receipt": "rcpt_1_1783069588",
    "status": "created"
  }
  ```

---

### 7. Verify Payment Transaction
Verifies the Razorpay transaction signature locally using a secure HMAC-SHA256 hash. If successful, updates the payment record status and increments the user's `remainingScans`.

- **Route:** `POST /api/pet/verify-payment`
- **Authentication:** Protected (JWT Bearer Token required)
- **Request Headers:**
    - `Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI...`
    - `Content-Type: application/json`
- **Request Body:**
  ```json
  {
    "razorpayOrderId": "order_EKPA437882",
    "razorpayPaymentId": "pay_ELKA536901",
    "razorpaySignature": "2c67de233b8a1c97a5a5bb1ef27ea0e932ffca123c53b27b9c9f2b84ef...",
    "scansPurchased": 10,
    "amount": 299.00
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "success": true
  }
  ```

---

## Daily Scan Reward Flow
No cron jobs are utilized. Daily free scans are awarded implicitly when either `/api/pet/google-login` or `/api/pet/profile` is triggered:
- The system checks if the user's `lastDailyReward` field is different from the current UTC date (`YYYY-MM-DD`).
- If different, `remainingScans` is incremented by `1` (capped at a maximum of `5`).
- The user's `lastDailyReward` is updated to the current date to prevent multiple rewards.

