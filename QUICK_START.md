# Quick Start Guide - Consultation API Integration

## 🚀 Get Started in 3 Steps

### Step 1: Update Base URL
Open `lib/core/services/consultation_api_service.dart` and update the base URL:

```dart
static const String baseUrl = 'http://YOUR_IP:3001/api';
```

**Choose based on your setup:**
- **Android Emulator:** `http://10.0.2.2:3001/api`
- **iOS Simulator:** `http://127.0.0.1:3001/api`
- **Physical Device:** `http://192.168.1.100:3001/api` (use your computer's IP)

### Step 2: Run the App
```bash
flutter pub get
flutter run
```

### Step 3: Test
1. Login to the app
2. Navigate to Consultations screen
3. Doctors should load from API
4. Click on a doctor to book appointment
5. Fill form and submit

## ✅ What Was Changed

### New Files (3)
1. `lib/models/consultation_model/doctor_model.dart`
2. `lib/models/consultation_model/appointment_model.dart`
3. `lib/core/services/consultation_api_service.dart`

### Updated Files (2)
1. `lib/providers/opd/consultation_provider/cunsultation_provider.dart`
2. `lib/screens/cunsultations/cunsultations.dart`

## 🎯 Key Features

✅ Fetches doctors from `/api/doctors`
✅ Fetches appointments from `/api/appointments`
✅ Creates appointments via POST `/api/appointments`
✅ Loading states & error handling
✅ No UI changes - existing design preserved
✅ Automatic JWT token handling

## 🔧 API Endpoints Used

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/doctors` | GET | Load doctors list |
| `/api/appointments` | GET | Load appointments |
| `/api/appointments` | POST | Create appointment |

## 📋 Data Flow

```
User Opens Screen
    ↓
Provider Constructor
    ↓
loadDoctors() → API Call → Display Doctors
    ↓
User Clicks Doctor
    ↓
Dialog Opens
    ↓
User Fills Form
    ↓
Submit → API Call → Success/Error Message
```

## 🧪 Quick Test

### Test 1: Load Doctors
1. Open Consultation screen
2. Should see loading spinner
3. Doctors should appear in grid
4. Each card shows: name, specialty, fee, timings

### Test 2: Create Appointment
1. Click any doctor card
2. Fill form:
   - MR No: 00001
   - Name: Test Patient
   - Contact: 03001234567
   - Select date & time
3. Click "Book Appointment"
4. Should see success message

### Test 3: Error Handling
1. Stop backend server
2. Open Consultation screen
3. Should see error message with retry button
4. Click retry
5. Start server
6. Should load successfully

## 🐛 Troubleshooting

### Doctors not loading?
```dart
// Check console for errors
// Verify base URL is correct
// Ensure backend is running
// Check user is logged in
```

### "Session expired" error?
```dart
// User needs to login again
// Token might be invalid
```

### Appointment creation fails?
```dart
// Check all required fields are filled
// Verify date/time format
// Check backend validation rules
```

## 📱 Screenshots Expected

### Loading State
- Spinner in center of screen

### Doctors Loaded
- Grid of doctor cards (2 per row)
- Each card shows doctor info
- Colored avatar circles

### Appointment Dialog
- Form with patient details
- Date picker
- Time slot dropdown
- Book button

### Success
- Green snackbar: "Appointment booked successfully!"

### Error
- Red snackbar with error message
- Or error screen with retry button

## 🔍 Verify Integration

Run these checks:

```bash
# 1. Check for syntax errors
flutter analyze

# 2. Check dependencies
flutter pub get

# 3. Run app
flutter run

# 4. Check logs
# Look for API calls in console
# Should see: "GET /api/doctors"
# Should see: "GET /api/appointments"
```

## 📞 API Request Examples

### GET Doctors
```http
GET http://127.0.0.1:3001/api/doctors
Authorization: Bearer YOUR_JWT_TOKEN
```

### POST Appointment
```http
POST http://127.0.0.1:3001/api/appointments
Authorization: Bearer YOUR_JWT_TOKEN
Content-Type: application/json

{
  "mr_number": "00004",
  "patient_name": "Test Patient",
  "patient_contact": "03001234567",
  "patient_address": "Test Address",
  "doctor_srl_no": 14,
  "appointment_date": "2026-03-06",
  "slot_time": "19:15:00",
  "is_first_visit": 1,
  "fee": "3000.00",
  "follow_up_charges": "2100.00",
  "status": "booked"
}
```

## 🎓 Understanding the Code

### Models
- Convert API JSON to Dart objects
- Handle data transformation
- Provide UI-friendly format

### API Service
- Makes HTTP requests
- Handles authentication
- Returns typed results

### Provider
- Manages state
- Calls API service
- Notifies UI of changes

### Screen
- Displays data
- Handles user input
- Shows loading/error states

## 📚 Full Documentation

For detailed information, see:
- `API_INTEGRATION_GUIDE.md` - Complete API documentation
- `IMPLEMENTATION_SUMMARY.md` - What was implemented

## ✨ That's It!

You're ready to use the API-integrated consultation module. The app will now fetch real data from your backend and create appointments via API calls.

**Need Help?** Check the troubleshooting section or review the full documentation files.
