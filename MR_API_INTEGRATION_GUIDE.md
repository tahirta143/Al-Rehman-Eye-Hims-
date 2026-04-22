# MR Data API Integration Guide

## Overview
This guide documents the API integration for the MR (Medical Record) Details and MR View modules in the Flutter HIMS app.

## Files Created/Modified

### 1. Model File
- **`lib/models/mr_model/mr_patient_model.dart`**
  - `MrPatientApiModel`: Maps API response from `/api/mr-data`
  - `PatientModel`: UI-friendly model (existing structure maintained)
  - Conversion methods:
    - `toPatientModel()`: API → UI format
    - `toApiRequest()`: UI → API format for POST/PUT requests

### 2. API Service
- **`lib/core/services/mr_api_service.dart`**
  - `fetchAllPatients()`: GET `/api/mr-data` with pagination
  - `fetchPatientByMR()`: GET `/api/mr-data/:mr`
  - `fetchNextMRNumber()`: GET `/api/mr-data/next-mr`
  - `createPatient()`: POST `/api/mr-data`
  - `updatePatient()`: PUT `/api/mr-data/:mr`
  - `deletePatient()`: DELETE `/api/mr-data/:mr` (if supported)
  - Automatic JWT token attachment via `AuthStorageService`

### 3. Provider (Updated)
- **`lib/providers/mr_provider/mr_provider.dart`**
  - Replaced hardcoded data with API calls
  - Added loading states: `isLoading`, `isCreating`
  - Added error handling: `errorMessage`
  - `loadPatients()`: Fetches patients from API on init
  - `findByMrNumber()`: Now async, searches API if not in cache
  - `registerPatient()`: Now async, POSTs to API
  - `updatePatient()`: New method for updating via API
  - `deletePatient()`: Now async, DELETEs via API
  - `fetchNextMR()`: Fetches next available MR number

### 4. Screens (Updated)
- **`lib/screens/mr_details/mr_details.dart`** (MR Details - Create/Search)
  - Updated `_lookupMrNumber()` to async
  - Updated `_onRegisterTapped()` to async with loading dialog
  - Shows success/error messages based on API response

- **`lib/screens/mr_details/mr_view/mr_view.dart`** (MR View - List)
  - Added loading indicator while fetching patients
  - Added error state with retry button
  - Updated `_confirmDelete()` to async with loading dialog
  - Displays success/error messages based on API response

## API Endpoints Used

### 1. GET /api/mr-data
**Purpose:** Fetch all patients with pagination

**Query Parameters:**
- `page`: Page number (default: 1)
- `limit`: Items per page (default: 50)

**Response:**
```json
{
  "success": true,
  "count": 95879,
  "data": [
    {
      "id": 202303,
      "mr_number": "100003",
      "first_name": "Tahir",
      "last_name": "",
      "guardian_name": null,
      "guardian_relation": "Parent",
      "cnic": null,
      "dob": null,
      "age": 23,
      "gender": "Male",
      "phone": "03032256332",
      "email": null,
      "profession": null,
      "address": "Johar Town",
      "city": "Lahore",
      "blood_group": null,
      "status": 1,
      "created_at": "2026-02-20 10:03:30",
      "updated_at": "2026-02-20 10:03:30",
      "appointment_date": null,
      "patient_name": "Tahir",
      "phone_number": "03032256332",
      "father_husband_name": null
    }
  ],
  "currentPage": 1,
  "totalPages": 1918
}
```

### 2. GET /api/mr-data/:mr
**Purpose:** Fetch single patient by MR number

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 202303,
    "mr_number": "100003",
    "first_name": "Tahir",
    ...
  }
}
```

### 3. GET /api/mr-data/next-mr
**Purpose:** Get next available MR number

**Response:**
```json
{
  "success": true,
  "nextMR": "100004"
}
```

### 4. POST /api/mr-data
**Purpose:** Create new patient

**Request:**
```json
{
  "first_name": "John",
  "last_name": "Doe",
  "guardian_name": "Jane Doe",
  "guardian_relation": "Parent",
  "cnic": "3520264293471",
  "dob": "1995-05-15",
  "age": 28,
  "gender": "Male",
  "phone": "03001234567",
  "email": "john@example.com",
  "profession": "Engineer",
  "address": "123 Main St",
  "city": "Lahore",
  "blood_group": "O+",
  "status": 1
}
```

**Response:**
```json
{
  "success": true,
  "message": "Patient created successfully",
  "data": {
    "id": 202304,
    "mr_number": "100004",
    ...
  }
}
```

### 5. PUT /api/mr-data/:mr
**Purpose:** Update existing patient

**Request:** Same as POST

**Response:**
```json
{
  "success": true,
  "message": "Patient updated successfully",
  "data": {
    "id": 202304,
    "mr_number": "100004",
    ...
  }
}
```

## Configuration

### Base URL
Update the base URL in `lib/core/services/mr_api_service.dart`:

```dart
static const String baseUrl = 'http://127.0.0.1:3001/api';
```

**For Android Emulator:** Use `http://10.0.2.2:3001/api`
**For iOS Simulator:** Use `http://127.0.0.1:3001/api`
**For Physical Device:** Use your computer's IP address (e.g., `http://192.168.1.100:3001/api`)

### Authentication
The API service automatically includes JWT tokens from `AuthStorageService`. Ensure users are logged in before accessing MR screens.

## Data Flow

### Loading Patients (MR View)
1. User opens MR View Screen
2. `MrProvider` constructor calls `loadPatients()`
3. API service fetches from `/api/mr-data`
4. Response mapped to `MrPatientApiModel` → converted to `PatientModel`
5. UI displays patient table

### Searching Patient (MR Details)
1. User types MR number and presses Enter or 🔍
2. `_lookupMrNumber()` called
3. First checks local cache
4. If not found, calls API `/api/mr-data/:mr`
5. If found, fills form with patient data
6. If not found, allows new patient registration

### Creating Patient (MR Details)
1. User fills form and clicks "Register Patient"
2. `_onRegisterTapped()` validates input
3. Shows loading dialog
4. `registerPatient()` converts data to API format
5. POST request to `/api/mr-data`
6. On success: adds to local list, shows success message
7. On failure: shows error message

### Deleting Patient (MR View)
1. User clicks delete icon
2. Confirmation dialog appears
3. User confirms deletion
4. Shows loading dialog
5. DELETE request to `/api/mr-data/:mr`
6. On success: removes from list, shows success message
7. On failure: shows error message

## Field Mappings

### API → UI
| API Field | UI Field | Transformation |
|-----------|----------|----------------|
| `id` | - | Not used in UI |
| `mr_number` | `mrNumber` | Direct |
| `first_name` | `firstName` | Direct |
| `last_name` | `lastName` | Direct (empty string if null) |
| `guardian_name` | `guardianName` | Direct (empty string if null) |
| `guardian_relation` | `relation` | Default to "Parent" if null |
| `cnic` | `cnic` | Direct (empty string if null) |
| `dob` | `dateOfBirth` | Parse from YYYY-MM-DD |
| `age` | `age` | Direct |
| `gender` | `gender` | Direct |
| `phone` | `phoneNumber` | Direct |
| `email` | `email` | Direct (empty string if null) |
| `profession` | `profession` | Direct (empty string if null) |
| `address` | `address` | Direct (empty string if null) |
| `city` | `city` | Direct (empty string if null) |
| `blood_group` | `bloodGroup` | Direct (empty string if null) |
| `created_at` | `registeredAt` | Parse to DateTime |

### UI → API
| UI Field | API Field | Transformation |
|----------|-----------|----------------|
| `firstName` | `first_name` | Direct |
| `lastName` | `last_name` | Direct |
| `guardianName` | `guardian_name` | null if empty |
| `relation` | `guardian_relation` | Direct |
| `cnic` | `cnic` | null if empty |
| `dateOfBirth` | `dob` | Convert DD/MM/YYYY to YYYY-MM-DD |
| `age` | `age` | Direct |
| `gender` | `gender` | Direct |
| `phoneNumber` | `phone` | Direct |
| `email` | `email` | null if empty |
| `profession` | `profession` | null if empty |
| `address` | `address` | null if empty |
| `city` | `city` | null if empty |
| `bloodGroup` | `blood_group` | null if empty |
| - | `status` | Always 1 (active) |

## Error Handling

### Network Errors
- Timeout: 15 seconds
- Connection failures show user-friendly messages
- Retry button available on error state

### API Errors
- 401 Unauthorized: "Session expired. Please log in again."
- 404 Not Found: "Patient not found"
- 4xx/5xx: Display error message from API response
- Validation errors: Show specific field errors

## Features

### MR Details Screen
- ✅ Search existing patients by MR number
- ✅ Auto-fill form when patient found
- ✅ Create new patients
- ✅ Fetch next available MR number
- ✅ Loading states during API calls
- ✅ Success/error messages
- ✅ Form validation

### MR View Screen
- ✅ Display all patients in table
- ✅ Search/filter patients locally
- ✅ View patient details in modal
- ✅ Delete patients with confirmation
- ✅ Loading states during fetch
- ✅ Error handling with retry
- ✅ Pagination support (API ready)

## Testing

### Test Scenarios
1. **Load Patients**: Verify patients display correctly from API
2. **Search Patient**: Search by MR number and verify auto-fill
3. **Create Patient**: Register new patient and verify POST request
4. **Delete Patient**: Delete patient and verify DELETE request
5. **Error Handling**: Test with invalid token, network offline
6. **Loading States**: Verify spinners show during API calls
7. **Empty States**: Test with no patients

## Future Enhancements

1. **Pagination UI**: Add pagination controls for large datasets
2. **Advanced Search**: Search by name, phone, CNIC on backend
3. **Bulk Operations**: Import/export patients
4. **Patient History**: Show visit history and appointments
5. **Image Upload**: Add patient photo support
6. **Offline Support**: Cache patients for offline viewing
7. **Real-time Updates**: WebSocket for live patient updates

## Troubleshooting

### Issue: "Session expired" error
**Solution**: Ensure user is logged in and token is valid

### Issue: Patients not loading
**Solution**: 
- Check base URL configuration
- Verify backend is running
- Check network connectivity
- Review API permissions

### Issue: Patient creation fails
**Solution**:
- Verify all required fields are provided
- Check date format (DD/MM/YYYY → YYYY-MM-DD)
- Ensure phone number format is correct
- Review backend validation rules

### Issue: MR number not found
**Solution**: 
- Verify MR number format
- Check if patient exists in database
- Try with different MR numbers

### Issue: Delete not working
**Solution**:
- Verify DELETE endpoint is implemented in backend
- Check user permissions
- Review backend logs for errors

## Dependencies

Required packages (already in `pubspec.yaml`):
- `http: ^1.2.1` - HTTP requests
- `provider` - State management
- `flutter_secure_storage: ^9.2.2` - Token storage
- `shared_preferences: ^2.3.0` - Local storage

## Notes

- No UI changes were made - existing design maintained
- All existing functionality preserved
- API integration is transparent to UI layer
- Models handle all data transformation
- Provider manages state and API calls
- Pagination is API-ready but UI controls not yet implemented
- Delete endpoint may need to be added to backend routes
