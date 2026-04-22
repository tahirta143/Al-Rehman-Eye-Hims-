# Quick Start Guide - MR Data API Integration

## 🚀 Get Started in 3 Steps

### Step 1: Update Base URL
Open `lib/core/services/mr_api_service.dart` and update the base URL:

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
2. Navigate to MR Details screen
3. Try searching for an existing patient
4. Try registering a new patient
5. Navigate to MR View screen
6. View all patients
7. Try deleting a patient

## ✅ What Was Changed

### New Files (2)
1. `lib/models/mr_model/mr_patient_model.dart`
2. `lib/core/services/mr_api_service.dart`

### Updated Files (3)
1. `lib/providers/mr_provider/mr_provider.dart`
2. `lib/screens/mr_details/mr_details.dart`
3. `lib/screens/mr_details/mr_view/mr_view.dart`

## 🎯 Key Features

✅ Fetches patients from `/api/mr-data`
✅ Searches patient by MR number via `/api/mr-data/:mr`
✅ Gets next MR number from `/api/mr-data/next-mr`
✅ Creates patients via POST `/api/mr-data`
✅ Updates patients via PUT `/api/mr-data/:mr`
✅ Deletes patients via DELETE `/api/mr-data/:mr`
✅ Loading states & error handling
✅ No UI changes - existing design preserved
✅ Automatic JWT token handling

## 🔧 API Endpoints Used

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/mr-data` | GET | Load patients list |
| `/api/mr-data/:mr` | GET | Search patient by MR |
| `/api/mr-data/next-mr` | GET | Get next MR number |
| `/api/mr-data` | POST | Create patient |
| `/api/mr-data/:mr` | PUT | Update patient |
| `/api/mr-data/:mr` | DELETE | Delete patient |

## 📋 Data Flow

### MR Details (Create/Search)
```
User Types MR Number
    ↓
Press Enter or 🔍
    ↓
Search Local Cache
    ↓
If Not Found → API Call
    ↓
If Found → Auto-fill Form
    ↓
User Fills/Edits Form
    ↓
Click "Register Patient"
    ↓
API Call → Success/Error
```

### MR View (List/Delete)
```
User Opens Screen
    ↓
Provider Constructor
    ↓
loadPatients() → API Call
    ↓
Display Patients Table
    ↓
User Clicks Delete
    ↓
Confirmation Dialog
    ↓
API Call → Success/Error
```

## 🧪 Quick Test

### Test 1: Load Patients
1. Open MR View screen
2. Should see loading spinner
3. Patients should appear in table
4. Each row shows: MR No, Name, Guardian, Phone, etc.

### Test 2: Search Patient
1. Open MR Details screen
2. Type MR number (e.g., "100003")
3. Press Enter or click 🔍
4. Form should auto-fill if patient exists

### Test 3: Create Patient
1. Open MR Details screen
2. Leave MR field empty (auto-generates)
3. Fill form:
   - First Name: Test
   - Last Name: Patient
   - Gender: Male
   - Phone: 03001234567
4. Click "Register Patient"
5. Should see success message with MR number

### Test 4: Delete Patient
1. Open MR View screen
2. Click delete icon on any patient
3. Confirm deletion
4. Should see success message
5. Patient should disappear from table

### Test 5: Error Handling
1. Stop backend server
2. Open MR View screen
3. Should see error message with retry button
4. Click retry
5. Start server
6. Should load successfully

## 🐛 Troubleshooting

### Patients not loading?
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

### Patient creation fails?
```dart
// Check all required fields are filled
// Verify phone number format
// Check backend validation rules
```

### MR number not found?
```dart
// Verify MR number exists in database
// Check MR number format
// Try with different MR numbers
```

## 📱 Screenshots Expected

### MR Details Screen
- Form with patient fields
- MR number search field with 🔍 icon
- Auto-fill when patient found
- Register button

### MR View Screen
- Loading spinner initially
- Table with patient data
- Search bar at top
- Stats card showing total patients
- Delete icons on each row

### Success States
- Green snackbar: "Patient registered! MR: 100004"
- Green snackbar: "Patient removed successfully"

### Error States
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
# Should see: "GET /api/mr-data"
# Should see: "POST /api/mr-data"
```

## 📞 API Request Examples

### GET All Patients
```http
GET http://127.0.0.1:3001/api/mr-data?page=1&limit=50
Authorization: Bearer YOUR_JWT_TOKEN
```

### GET Single Patient
```http
GET http://127.0.0.1:3001/api/mr-data/100003
Authorization: Bearer YOUR_JWT_TOKEN
```

### POST Create Patient
```http
POST http://127.0.0.1:3001/api/mr-data
Authorization: Bearer YOUR_JWT_TOKEN
Content-Type: application/json

{
  "first_name": "Test",
  "last_name": "Patient",
  "guardian_name": "Test Guardian",
  "guardian_relation": "Parent",
  "cnic": null,
  "dob": null,
  "age": 25,
  "gender": "Male",
  "phone": "03001234567",
  "email": null,
  "profession": null,
  "address": null,
  "city": null,
  "blood_group": null,
  "status": 1
}
```

### DELETE Patient
```http
DELETE http://127.0.0.1:3001/api/mr-data/100003
Authorization: Bearer YOUR_JWT_TOKEN
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
- Caches data locally

### Screens
- Display data
- Handle user input
- Show loading/error states

## 📚 Full Documentation

For detailed information, see:
- `MR_API_INTEGRATION_GUIDE.md` - Complete API documentation
- `MR_IMPLEMENTATION_SUMMARY.md` - What was implemented

## ✨ That's It!

You're ready to use the API-integrated MR module. The app will now fetch real patient data from your backend and perform CRUD operations via API calls.

**Need Help?** Check the troubleshooting section or review the full documentation files.

## 🔄 Comparison with Consultation Module

Both modules now work the same way:
- Same architecture pattern
- Same error handling approach
- Same loading states
- Same API integration style
- Consistent user experience

You can apply the same pattern to other modules in your app!
