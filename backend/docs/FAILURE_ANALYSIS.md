# Green Basket Backend - Failure Analysis & Recovery Guide

This document outlines the current state of system failures, their root causes, and specific steps to resolve each issue.

## 🚨 Critical Failures (Prevents Core Functionality)

### 1. MongoDB Connection Refused
**Status:** 🔴 FAILED
**Impact:** Application cannot start; All Database operations fail.
**Error Message:** `MongooseServerSelectionError: Could not connect to any servers in your MongoDB Atlas cluster.`
**Root Cause:**
Your local IP address is not whitelisted in MongoDB Atlas Network Access settings.
**Fix:**
1. Log in to [MongoDB Atlas](https://cloud.mongodb.com).
2. Navigate to **Network Access**.
3. Click **Add IP Address** -> **Add Current IP Address**.
4. Confirm and wait 1-2 minutes.

### 2. Firebase Admin SDK Initialization
**Status:** ⚠️ PARTIAL FAILURE
**Impact:** Push Notifications will fail. Server starts with warnings.
**Error Message:** `Failed to parse private key: Error: Invalid PEM formatted message.`
**Root Cause:**
The `.env` file contains a placeholder `YOUR_PRIVATE_KEY_HERE` which is not a valid RSA key.
**Fix:**
1. Go to Firebase Console -> Project Settings -> Service Accounts.
2. Click **Generate new private key**.
3. Open the downloaded JSON file.
4. Copy the `private_key` value.
5. Update `.env`:
   ```env
   FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n..."
   ```
   *Note: Ensure the newline characters (`\n`) are preserved if using a single-line string.*

---

## ⚠️ Feature-Specific Failures (Prevents Specific Features)

### 3. Email Delivery System (Gmail)
**Status:** 🔴 WILL FAIL
**Impact:** User signup verification, order confirmations, and password resets will throw errors (`transporter.sendMail` failed).
**Root Cause:**
The `.env` file uses placeholder credentials:
```env
EMAIL_USER=your-email@gmail.com
EMAIL_APP_PASSWORD=your-16-digit-app-password
```
**Fix:**
1. Enable [2-Step Verification](https://myaccount.google.com/signinoptions/two-step-verification) on your Gmail account.
2. Go to [App Passwords](https://myaccount.google.com/apppasswords).
3. Generate a new password for "Mail" / "Mac".
4. Update `.env` with your real Gmail address and the 16-character App Password.

### 4. Payment Processing (Razorpay)
**Status:** 🔴 WILL FAIL
**Impact:** Checkout and Payment verification will crash or return authentication errors.
**Root Cause:**
The `.env` file uses invalid/placeholder keys:
```env
RAZORPAY_KEY_ID=rzp_test_xxxxxxxxxxxxxx
RAZORPAY_KEY_SECRET=xxxxxxxxxxxxxxxxxxxxxx
```
**Fix:**
1. Log in to [Razorpay Dashboard](https://dashboard.razorpay.com/).
2. Go to Settings -> API Keys.
3. Generate new **Test Mode** keys.
4. Update `.env` with the new Key ID and Secret.

### 5. Redis Caching
**Status:** ⚠️ POTENTIAL ISSUE
**Impact:** Caching layers may be bypassed, or connection errors will spam logs (`Redis Client Error`).
**Configuration:**
```env
REDIS_URL=redis://localhost:6379
```
**Assessment:**
The code gracefully handles Redis connection failures (`redis.js` catches errors), so the app *will* run, but performance features relying on Redis will be disabled if a local Redis instance is not running.
**Fix (Optional):**
- Ensure Redis is installed and running (`redis-server`).
- Or, ignore if testing in an environment where caching is not critical.

### 6. SMS Notifications (Twilio)
**Status:** 🔴 WILL FAIL
**Impact:** OTPs and SMS alerts will fail.
**Root Cause:** Placeholder credentials in `.env`.
**Fix:**
- Update `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, and `TWILIO_PHONE_NUMBER` with valid credentials from Twilio Console.

