# Architecture Overview - Consultation API Integration

## 📐 System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         UI Layer                             │
│  ┌────────────────────────────────────────────────────┐    │
│  │  ConsultationScreen (cunsultations.dart)           │    │
│  │  - Displays doctors in grid                        │    │
│  │  - Shows loading/error states                      │    │
│  │  - Handles user interactions                       │    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                            ↕
┌─────────────────────────────────────────────────────────────┐
│                      Provider Layer                          │
│  ┌────────────────────────────────────────────────────┐    │
│  │  ConsultationProvider                              │    │
│  │  - Manages state (doctors, appointments)           │    │
│  │  - Calls API service                               │    │
│  │  - Notifies UI of changes                          │    │
│  │  - Handles loading/error states                    │    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                            ↕
┌─────────────────────────────────────────────────────────────┐
│                      Service Layer                           │
│  ┌────────────────────────────────────────────────────┐    │
│  │  ConsultationApiService                            │    │
│  │  - Makes HTTP requests                             │    │
│  │  - Attaches JWT tokens                             │    │
│  │  - Handles network errors                          │    │
│  │  - Returns typed results                           │    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                            ↕
┌─────────────────────────────────────────────────────────────┐
│                       Model Layer                            │
│  ┌──────────────────────┐  ┌──────────────────────┐        │
│  │  DoctorModel         │  │  AppointmentModel    │        │
│  │  - API format        │  │  - API format        │        │
│  │  - fromJson()        │  │  - fromJson()        │        │
│  │  - toJson()          │  │  - toJson()          │        │
│  └──────────────────────┘  └──────────────────────┘        │
│  ┌──────────────────────┐  ┌──────────────────────┐        │
│  │  DoctorInfo          │  │  ConsultationAppt    │        │
│  │  - UI format         │  │  - UI format         │        │
│  │  - Display logic     │  │  - Display logic     │        │
│  └──────────────────────┘  └──────────────────────┘        │
└─────────────────────────────────────────────────────────────┘
                            ↕
┌─────────────────────────────────────────────────────────────┐
│                      Backend API                             │
│  - GET  /api/doctors                                        │
│  - GET  /api/appointments                                   │
│  - POST /api/appointments                                   │
└─────────────────────────────────────────────────────────────┘
```

## 🔄 Data Flow Diagrams

### 1. Loading Doctors Flow

```
User Opens Screen
       ↓
ConsultationScreen.build()
       ↓
Provider.of<ConsultationProvider>()
       ↓
ConsultationProvider() constructor
       ↓
loadDoctors()
       ↓
_isLoading = true
notifyListeners() → UI shows spinner
       ↓
ConsultationApiService.fetchDoctors()
       ↓
HTTP GET /api/doctors
       ↓
Backend Response
       ↓
Parse JSON → List<DoctorModel>
       ↓
Convert to List<DoctorInfo>
       ↓
_doctors = converted list
_isLoading = false
notifyListeners() → UI shows doctors
```

### 2. Creating Appointment Flow

```
User Fills Form
       ↓
User Clicks "Book Appointment"
       ↓
_submit() called
       ↓
Validate Input
       ↓
Show Loading Dialog
       ↓
Create ConsultationAppointment object
       ↓
Provider.addAppointment(appointment)
       ↓
Find doctor_srl_no from doctor name
       ↓
Convert to API format (toApiRequest)
       ↓
ConsultationApiService.createAppointment()
       ↓
HTTP POST /api/appointments
       ↓
Backend Response
       ↓
Success?
  ├─ Yes → Add to local list
  │        notifyListeners()
  │        Close dialogs
  │        Show success message
  │        Return true
  │
  └─ No  → Set error message
           notifyListeners()
           Close loading dialog
           Show error message
           Return false
```

### 3. Error Handling Flow

```
API Call Fails
       ↓
Catch Exception
       ↓
Determine Error Type
  ├─ Network Timeout
  ├─ 401 Unauthorized
  ├─ 4xx Client Error
  └─ 5xx Server Error
       ↓
Create Error Result
       ↓
Return to Provider
       ↓
Provider sets errorMessage
       ↓
notifyListeners()
       ↓
UI shows error state
       ↓
User clicks Retry
       ↓
Call loadDoctors() again
```

## 🏗️ Component Responsibilities

### UI Layer (Screen)
**Responsibilities:**
- Display data from provider
- Handle user interactions
- Show loading/error states
- Navigate between screens
- Display dialogs and snackbars

**Does NOT:**
- Make API calls directly
- Transform data
- Manage business logic

### Provider Layer
**Responsibilities:**
- Manage application state
- Call API services
- Transform API data to UI format
- Notify UI of changes
- Handle loading/error states

**Does NOT:**
- Make HTTP requests directly
- Know about UI widgets
- Handle navigation

### Service Layer
**Responsibilities:**
- Make HTTP requests
- Attach authentication headers
- Handle network errors
- Parse JSON responses
- Return typed results

**Does NOT:**
- Manage state
- Know about UI
- Transform data for display

### Model Layer
**Responsibilities:**
- Define data structures
- Parse JSON to objects
- Convert between formats
- Validate data

**Does NOT:**
- Make API calls
- Manage state
- Handle UI logic

## 📦 File Dependencies

```
cunsultations.dart
    ↓ imports
    ├─ cunsultation_provider.dart
    └─ base_scaffold.dart

cunsultation_provider.dart
    ↓ imports
    ├─ consultation_api_service.dart
    ├─ doctor_model.dart
    └─ appointment_model.dart

consultation_api_service.dart
    ↓ imports
    ├─ auth_storage_service.dart
    ├─ doctor_model.dart
    └─ appointment_model.dart

doctor_model.dart
    ↓ imports
    └─ flutter/material.dart (for Color)

appointment_model.dart
    ↓ imports
    └─ flutter/material.dart (for Icons)
```

## 🔐 Authentication Flow

```
User Logs In
       ↓
JWT Token Generated
       ↓
Stored in AuthStorageService
       ↓
User Opens Consultation Screen
       ↓
Provider calls API Service
       ↓
API Service calls _authHeaders()
       ↓
Retrieves token from storage
       ↓
Adds to HTTP headers:
  Authorization: Bearer <token>
       ↓
Backend validates token
       ↓
Returns data or 401 error
```

## 🎨 State Management

### Provider State
```dart
class ConsultationProvider {
  // Data
  List<DoctorInfo> _doctors = [];
  List<ConsultationAppointment> _appointments = [];
  
  // Loading states
  bool _isLoading = false;
  bool _isLoadingAppointments = false;
  
  // Error state
  String? _errorMessage;
  
  // Getters
  List<DoctorInfo> get doctors => _doctors;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
}
```

### UI State Reactions
```
_isLoading = true
    → UI shows CircularProgressIndicator

_isLoading = false && _errorMessage != null
    → UI shows error message with retry button

_isLoading = false && _errorMessage == null && _doctors.isEmpty
    → UI shows "No doctors available"

_isLoading = false && _errorMessage == null && _doctors.isNotEmpty
    → UI shows doctor grid
```

## 🔄 Data Transformation Pipeline

### Doctor Data Pipeline
```
Backend JSON
    ↓
DoctorModel.fromJson()
    ↓
DoctorModel object
    ↓
toDoctorInfo()
    ↓
DoctorInfo object
    ↓
UI Display
```

### Appointment Data Pipeline (Create)
```
UI Form Data
    ↓
ConsultationAppointment object
    ↓
toApiRequest()
    ↓
JSON Map
    ↓
HTTP POST
    ↓
Backend
```

### Appointment Data Pipeline (Fetch)
```
Backend JSON
    ↓
AppointmentModel.fromJson()
    ↓
AppointmentModel object
    ↓
toConsultationAppointment()
    ↓
ConsultationAppointment object
    ↓
UI Display
```

## 🧩 Design Patterns Used

### 1. Repository Pattern
- API Service acts as repository
- Abstracts data source from business logic
- Easy to mock for testing

### 2. Provider Pattern (State Management)
- ChangeNotifier for reactive updates
- Separation of concerns
- Efficient rebuilds

### 3. Model-View-ViewModel (MVVM)
- Model: DoctorModel, AppointmentModel
- View: ConsultationScreen
- ViewModel: ConsultationProvider

### 4. Factory Pattern
- `fromJson()` factory constructors
- Consistent object creation

### 5. Result Pattern
- Typed result objects (DoctorsResult, etc.)
- Explicit success/failure handling

## 🎯 Key Principles

### Separation of Concerns
- Each layer has single responsibility
- No cross-layer dependencies
- Easy to test and maintain

### Type Safety
- All data strongly typed
- No dynamic types
- Compile-time error checking

### Error Handling
- Errors caught at service layer
- Propagated through result objects
- User-friendly messages in UI

### Null Safety
- All nullable fields marked with `?`
- Safe unwrapping with `??` operator
- No null pointer exceptions

## 📊 Performance Considerations

### Efficient Updates
- `notifyListeners()` only when needed
- Minimal rebuilds with Provider
- List operations optimized

### Network Optimization
- 15-second timeout prevents hanging
- Error recovery with retry
- Future: Add caching layer

### Memory Management
- Lists properly managed
- No memory leaks
- Proper disposal of controllers

## 🔮 Future Enhancements

### Caching Layer
```
API Service
    ↓
Cache Service (new)
    ↓
Provider
```

### Offline Support
```
API Service
    ↓
Local Database (new)
    ↓
Provider
```

### Real-time Updates
```
WebSocket Service (new)
    ↓
Provider
    ↓
UI auto-updates
```

This architecture provides a solid foundation for these enhancements while maintaining clean separation of concerns.
