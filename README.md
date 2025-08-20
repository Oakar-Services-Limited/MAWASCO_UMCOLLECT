# MAWASCO UM Collector - Firebase Notifications Setup

## 🚀 Quick Setup Guide

### 1. Firebase Project Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create new project: `mawasco-notifications`
3. Add Android app with package: `com.example.um_collect`
4. Download `google-services.json` and place in `android/app/`
5. Add Web app for backend
6. Generate service account key and place in `MAWASCO_API/src/configs/`

### 2. Update Configuration Files

#### Flutter App (`google-services.json`)

Replace placeholder values with your actual Firebase project details:

```json
{
  "project_info": {
    "project_number": "123456789012",
    "project_id": "mawasco-notifications",
    "storage_bucket": "mawasco-notifications.appspot.com"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:123456789012:android:abcdef123456",
        "android_client_info": {
          "package_name": "com.example.um_collect"
        }
      },
      "oauth_client": [],
      "api_key": [
        {
          "current_key": "AIzaSyC..."
        }
      ]
    }
  ]
}
```

#### Backend (`serviceAccountKey.json`)

Place your downloaded service account key in `MAWASCO_API/src/configs/`

### 3. Install Dependencies

```bash
# Flutter App
cd MAWASCO_UM_Collector
flutter pub get

# Backend
cd MAWASCO_API
npm install firebase-admin
```

### 4. Test the System

1. Start the backend server
2. Run the Flutter app
3. Create an incident report with status "Received"
4. Check for notification on mobile device

## 🔧 How It Works

- **Incident Reported** → Backend detects status "Received"
- **Backend** → Sends FCM notification to all registered devices
- **Mobile App** → Receives notification in foreground/background/terminated states

## 📱 Notification Flow

1. App registers FCM token with backend
2. Backend stores token in database
3. When incident is reported, notification is sent to all devices
4. App handles notification based on state (foreground/background/terminated)

## 🚨 Troubleshooting

- **Firebase not initialized**: Check `google-services.json` configuration
- **No notifications**: Verify FCM token is sent to backend
- **Backend errors**: Check service account key and Firebase project ID
