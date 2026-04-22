# API Integration Guide - Consultation Module

## Overview
This guide documents the API integration for the Consultation/Appointments module in the Flutter HIMS app.

## Files Created/Modified

### 1. Model Files
- **`lib/models/consultation_model/doctor_model.dart`**
  - `DoctorModel`: Maps API response from `/api/doctors`
  - `DoctorInfo`: UI-friendly model (existing structure maintained)
  - Conversion method: `toDoctorInfo()` transforms API data to UI format

- **`lib/models/consultation_model/appointment_model.dart`**
  - `AppointmentModel`: Maps API response from `/api/appointments`
  - `ConsultationAppointment`: UI-friendly model (existing structure maintained)
  - Conversion methods:
    - `toConsultationAppointment()`: API → UI format
    - `toApiRequest()`: UI → API format for POST requests

### 2. API Service
- **`lib/core/services/consultation_api_service.dart`**
  - `fetchDoctors()`: GET `/api/doctors`
  - `fetchAppointments()`: GET `/api/appointments`
  - `createAppointment()`: POST `/api/appointments`
  - `fetchSlotsForDoctor()`: GET `/api/appointments/slots` (optional)
  - Automatic JWT token attachment via `AuthStorageService`

### 3. Provider (Updated)
- **`lib/providers/opd/consultation_provider/cunsultation_provider.dart`**
  - Added loading states: `isLoading`, `isLoadingAppointments`
  - Added error handling: `errorMessage`
  - `loadDoctors()`: Fetches doctors from API on init
  - `loadAppointments()`: Fetches appointments from API on init
  - `addAppointment()`: Now async, POSTs to API and returns success/failure

### 4. Screen (Updated)
- **`lib/screens/cunsultations/cunsultations.dart`**
  - Added loading indicator while fetching doctors
  - Added error state with retry button
  - Updated `_submit()` method to be async
  - Shows loading dialog during appointment creation
  - Displays success/error messages based on API response

## API Endpoints Used

### 1. GET /api/doctors
**Response:**
```json
{
  "success": true,
  "data": [
    {
      "srl_no": 14,
      "doctor_id": "DOC003",
      "doctor_name": "Kashif",
      "doctor_specialization": "Neuro",
      "consultation_fee": "3000.00",
      "available_days": "Monday, Tuesday, Wednesday",
      "consultation_timings": "19:00 - 22:00",
      "consultation_time_from": "19:00:00",
      "consultation_time_to": "22:00:00",
      "hospital_name": "WMCTH",
      ...
    }
  ]
}
```

### 2. GET /api/appointments
**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 17,
      "appointment_id": "APT-249597-767",
      "mr_number": "00004",
      "patient_name": "ABDUL REHMAN",
      "patient_contact": "03014709600",
      "doctor_srl_no": 14,
      "appointment_date": "2026-03-06",
      "slot_time": "19:15:00",
      "is_first_visit": 1,
      "fee": "3000.00",
      "status": "booked",
      "doctor_name": "Kashif",
      ...
    }
  ]
}
```

### 3. POST /api/appointments
**Request:**
```json
{
  "mr_number": "00004",
  "patient_name": "ABDUL REHMAN",
  "patient_contact": "03014709600",
  "patient_address": "K-108 Al-Rehman Garden",
  "doctor_srl_no": 14,
  "appointment_date": "2026-03-06",
  "slot_time": "19:15:00",
  "is_first_visit": 1,
  "fee": "3000.00",
  "follow_up_charges": "2100.00",
  "status": "booked"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Appointment created successfully",
  "data": { /* appointment object */ }
}
```

## Configuration

### Base URL
Update the base URL in `lib/core/services/consultation_api_service.dart`:

```dart
static const String baseUrl = 'http://127.0.0.1:3001/api';
```

**For Android Emulator:** Use `http://10.0.2.2:3001/api`
**For iOS Simulator:** Use `http://127.0.0.1:3001/api`
**For Physical Device:** Use your computer's IP address (e.g., `http://192.168.1.100:3001/api`)

### Authentication
The API service automatically includes JWT tokens from `AuthStorageService`. Ensure users are logged in before accessing the consultation screen.

## Data Flow

### Loading Doctors
1. User opens Consultation Screen
2. `ConsultationProvider` constructor calls `loadDoctors()`
3. API service fetches from `/api/doctors`
4. Response mapped to `DoctorModel` → converted to `DoctorInfo`
5. UI displays doctor cards

### Creating Appointment
1. User fills appointment form and clicks "Book Appointment"
2. `_submit()` validates input
3. Shows loading dialog
4. `addAppointment()` converts data to API format
5. POST request to `/api/appointments`
6. On success: adds to local list, closes dialog, shows success message
7. On failure: shows error message

## Field Mappings

### Doctor API → UI
| API Field | UI Field | Transformation |
|-----------|----------|----------------|
| `srl_no` | `id` | Convert to string |
| `doctor_name` | `name` | Prefix with "Dr." |
| `doctor_specialization` | `specialty` | Direct |
| `consultation_fee` | `consultationFee` | Format (remove .00) |
| `available_days` | `availableDays` | Split by comma, convert to short names |
| `consultation_timings` | `timings` | Direct |
| `hospital_name` | `hospital` | Direct |

### Appointment UI → API
| UI Field | API Field | Transformation |
|----------|-----------|----------------|
| `mrNo` | `mr_number` | Direct |
| `patientName` | `patient_name` | Direct |
| `contactNo` | `patient_contact` | Direct |
| `address` | `patient_address` | Direct |
| `doctor.id` | `doctor_srl_no` | Parse to int |
| `appointmentDate` | `appointment_date` | Format as YYYY-MM-DD |
| `timeSlot` | `slot_time` | Convert 12h to 24h (HH:MM:SS) |
| `isFirstVisit` | `is_first_visit` | Boolean to int (1/0) |
| `consultationFee` | `fee` | Direct |
| `followUpCharges` | `follow_up_charges` | Direct |

## Error Handling

### Network Errors
- Timeout: 15 seconds
- Connection failures show user-friendly messages
- Retry button available on error state

### API Errors
- 401 Unauthorized: "Session expired. Please log in again."
- 4xx/5xx: Display error message from API response
- Validation errors: Show specific field errors

## Testing

### Test Scenarios
1. **Load Doctors**: Verify doctors display correctly from API
2. **Create Appointment**: Book appointment and verify POST request
3. **Error Handling**: Test with invalid token, network offline
4. **Loading States**: Verify spinners show during API calls
5. **Empty States**: Test with no doctors/appointments

### Mock Data
The provider previously used hardcoded data. This has been replaced with API calls. To test without backend:
- Comment out API calls in provider
- Uncomment old hardcoded data temporarily

## Future Enhancements

1. **Pagination**: Add pagination for large doctor/appointment lists
2. **Search/Filter**: Filter doctors by specialty, availability
3. **Real-time Slots**: Use `/api/appointments/slots` endpoint for live availability
4. **Caching**: Cache doctor data to reduce API calls
5. **Offline Support**: Store appointments locally for offline viewing
6. **Push Notifications**: Notify users of appointment confirmations

## Troubleshooting

### Issue: "Session expired" error
**Solution**: Ensure user is logged in and token is valid

### Issue: Doctors not loading
**Solution**: 
- Check base URL configuration
- Verify backend is running
- Check network connectivity
- Review API permissions

### Issue: Appointment creation fails
**Solution**:
- Verify all required fields are provided
- Check date/time format
- Ensure doctor_srl_no is valid
- Review backend validation rules

### Issue: Time format mismatch
**Solution**: The app converts between 12h (UI) and 24h (API) formats automatically. Verify conversion logic in `appointment_model.dart`

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
