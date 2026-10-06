# PetCareAI 1.1.0: what you need to do manually

Code changes are done in two places:

- **App:** `C:\Users\wwwvi\ai_pet_care`
- **Backend (pet files only):** `...\Kimi_Agent_TailAdmin Procurement RBAC Dashboard\app\server`

Nothing has been deployed or published. Do the steps in this order.

---

## 1. Deploy the backend first

Only these server files changed. No other app on the server was touched.

| File | Change |
|---|---|
| `services/pet.services.js` | Scan-cap bug fix, weekly free scan, Plus entitlements, chat limit, pets, referrals, events, Play verification, mock-login lock |
| `services/pet.billing.js` | **New.** Google Play Developer API calls |
| `controllers/pet.controller.js` | New handlers, proper status codes |
| `routes/pet.routes.js` | New `/api/pet/*` routes |
| `models/pet.user.js`, `pet.scan.js`, `pet.iap.purchase.js` | New fields |
| `models/pet.subscription.js`, `pet.event.js` | **New** |

- No new npm packages are needed (`google-auth-library` is already installed).
- New MongoDB collections are created automatically: `pet_subscriptions` and `pet_events`.
- Restart the Node server after uploading.

**Optional settings** (`.env`). The defaults are already sensible:

```
PET_WELCOME_SCANS=3            # free scans for a new account
PET_FREE_WEEKLY_SCANS=1        # free users topped up to this every Monday
PET_FREE_CHAT_PER_DAY=5        # free AI Vet messages per day
PET_PLUS_SCANS_PER_30_DAYS=60  # Plus fair-use cap
PET_PLUS_CHAT_PER_DAY=100      # Plus fair-use cap
PET_REFERRAL_BONUS_SCANS=2
```

> Never set `PET_ALLOW_MOCK_LOGIN=true` on the live server. It allows signing in as anyone and is for local testing only.

Your existing `WELCOME_SCANS`, `DAILY_SCAN_REWARD` and `MAX_SCAN_BALANCE` variables were never read by the code and are still unused.

**Old app versions keep working** with the new backend. The only visible difference: users on the old app now hit the 5-messages-a-day chat limit and see a generic error message.

## 2. Google Play service account (purchase verification)

Until this is set, the server **trusts purchase tokens without checking them**, as it did before. Purchases still work, but this is not secure and buyer country is not recorded.

1. Google Cloud Console → pick or create a project → **APIs & Services → Enable "Google Play Android Developer API"**.
2. **IAM → Service accounts → Create**. Then open **Keys → Add key → JSON** and download the file.
3. Play Console → **Users and permissions → Invite new users** → paste the service account email → add the PetCareAI app with these permissions:
   - View financial data, orders, and cancellation survey responses
   - Manage orders and subscriptions
4. Upload the JSON file to the server **outside the public web folder**, and add to `.env`:
   ```
   PET_PLAY_SERVICE_ACCOUNT_FILE=/absolute/path/to/service-account.json
   ```
5. Restart the server. The log line `Play verification is OFF` should disappear. Permissions can take up to 24–36 hours to start working.

## 3. Play Console: products and prices

**a) Create two subscriptions** (Monetize → Products → Subscriptions). The IDs must match exactly:

| Product ID | Base plan | Price (US) | Offer |
|---|---|---|---|
| `petcare_plus_yearly` | Auto-renewing, 1 year | $29.99 | Free trial, 3 days, new customers only. **The offer ID must contain "trial"** (e.g. `free-trial`) so the app and server can show trial status. |
| `petcare_plus_weekly` | Auto-renewing, 1 week | $4.99 | none |

Until these exist, the paywall shows only the scan-packs tab, which is fine.

**b) Set scan-pack prices per country** (Monetize → In-app products). Suggested US/UK/CA/AU prices; keep India low:

| Product | US | India |
|---|---|---|
| `scans_starter_5` | $2.99 | keep current |
| `scans_popular_25` | $9.99 | keep current |
| `scans_value_100` | $19.99 | keep current |

**c) Fix the "action required" warning on your payments profile**, otherwise payouts can be held.

## 4. Play Console: policy forms

- **Data safety:** it currently says "No data collected", which is wrong. Declare:
  - Personal info: name and email (account)
  - Photos (scan uploads)
  - Messages (AI Vet chat)
  - Financial info: purchase history
  - App activity: in-app interactions (analytics events)

  All collected, encrypted in transit, not shared, and used for app functionality and analytics.
- **Privacy policy** (`asharinfotech.com/privacy.html`): make sure it covers subscriptions, the photos and chats stored on your server, and analytics.
- **Store listing:** update screenshot 6 to remove "Instant Alerts / Find Vet Near Me", or keep it: the app now has reminders and an emergency-vet map search. Use the new title and description from `aso/play_listing.md`.
- **App content → Notifications:** the app now asks for notification permission on Android 13+.

## 5. Build and release

```
flutter build appbundle --release
```

- Version is now **1.1.0 (12)**.
- Upload to **Internal testing** first.
- Add your Gmail as a **License tester** (Settings → License testing) so test purchases are free.

## 6. Test on a phone before going to production

- [ ] New install: Welcome → Add pet → Sign in → Home shows the pet and **3 scans**.
- [ ] Run a scan → result shows the correct remaining balance.
- [ ] Moderate result → "Track healing" → reminder created → Recovery screen opens.
- [ ] Use all scans → "Out of scans" sheet appears.
- [ ] Buy a 5-scan pack → balance +5.
- [ ] Start the yearly trial → "Welcome to PetCare Plus" → scans no longer decrease → chat shows "Plus".
- [ ] Profile → Restore purchases → "PetCare Plus is active".
- [ ] Send 5 chat messages on a free account → limit card appears.
- [ ] Add a care reminder a few minutes ahead → notification arrives.
- [ ] Share invite code → second account redeems it → both get +2 scans.
- [ ] Cancel the test subscription in Play → after expiry the account returns to the free plan.

## What was intentionally not added

- **Firebase / push from the server:** every notification is scheduled on the phone, so no Firebase setup is needed.
- **Razorpay:** removed from the app (Play requires Play Billing for scans). The backend Razorpay endpoints were left in place, unused.
- **iOS:** not configured.
