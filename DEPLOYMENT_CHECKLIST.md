# Deployment Checklist - Consultation API Integration

## 📋 Pre-Deployment Checklist

### ✅ Configuration
- [ ] Update base URL in `lib/core/services/consultation_api_service.dart`
  - [ ] Development: `http://10.0.2.2:3001/api` (Android Emulator)
  - [ ] Staging: `http://YOUR_STAGING_IP:3001/api`
  - [ ] Production: `https://api.yourdomain.com/api`
- [ ] Verify timeout settings (currently 15 seconds)
- [ ] Check authentication token handling

### ✅ Dependencies
- [ ] Run `flutter pub get`
- [ ] Verify `http: ^1.2.1` in pubspec.yaml
- [ ] Verify `provider` package installed
- [ ] Verify `flutter_secure_storage` installed

### ✅ Code Quality
- [ ] Run `flutter analyze` - no errors
- [ ] Run `flutter test` - all tests pass
- [ ] Check for TODO comments
- [ ] Review error messages for user-friendliness

### ✅ Backend Verification
- [ ] Backend server running and accessible
- [ ] `/api/doctors` endpoint working
- [ ] `/api/appointments` GET endpoint working
- [ ] `/api/appointments` POST endpoint working
- [ ] JWT authentication working
- [ ] CORS configured for mobile app

### ✅ Testing

#### Unit Tests
- [ ] Test DoctorModel.fromJson()
- [ ] Test AppointmentModel.fromJson()
- [ ] Test data transformations
- [ ] Test time format conversions

#### Integration Tests
- [ ] Test API service calls
- [ ] Test provider state management
- [ ] Test error handling

#### UI Tests
- [ ] Test loading state displays
- [ ] Test error state displays
- [ ] Test doctor grid displays
- [ ] Test appointment dialog
- [ ] Test form validation

#### End-to-End Tests
- [ ] Login → Navigate to Consultations
- [ ] Load doctors successfully
- [ ] Click doctor → Dialog opens
- [ ] Fill form → Submit → Success
- [ ] Test with network offline
- [ ] Test with invalid token
- [ ] Test with backend down

## 🧪 Testing Scenarios

### Scenario 1: Happy Path
```
✓ User logs in
✓ Opens Consultation screen
✓ Doctors load from API
✓ Clicks on a doctor
✓ Fills appointment form
✓ Submits successfully
✓ Sees success message
✓ Appointment appears in list
```

### Scenario 2: Network Error
```
✓ User opens screen
✓ Network is offline
✓ Error message displays
✓ Retry button appears
✓ User clicks retry
✓ Network comes online
✓ Doctors load successfully
```

### Scenario 3: Session Expired
```
✓ User's token expires
✓ Opens Consultation screen
✓ API returns 401
✓ "Session expired" message shows
✓ User redirected to login
```

### Scenario 4: Validation Errors
```
✓ User opens appointment dialog
✓ Tries to submit empty form
✓ Validation errors show
✓ User fills required fields
✓ Submits successfully
```

### Scenario 5: Backend Error
```
✓ User submits appointment
✓ Backend returns error
✓ Error message displays
✓ Dialog stays open
✓ User can retry
```

## 🔍 Code Review Checklist

### Models
- [ ] All fields properly typed
- [ ] Null safety handled correctly
- [ ] fromJson() handles missing fields
- [ ] toJson() includes all fields
- [ ] Conversion methods tested

### API Service
- [ ] Timeout configured
- [ ] Headers include auth token
- [ ] Error handling comprehensive
- [ ] Result objects properly typed
- [ ] No hardcoded values

### Provider
- [ ] State properly initialized
- [ ] notifyListeners() called appropriately
- [ ] No memory leaks
- [ ] Error states handled
- [ ] Loading states managed

### UI
- [ ] Loading indicators shown
- [ ] Error messages user-friendly
- [ ] Empty states handled
- [ ] Forms validated
- [ ] Dialogs dismissible

## 📱 Device Testing

### Android
- [ ] Test on emulator
- [ ] Test on physical device
- [ ] Test different Android versions
- [ ] Test different screen sizes
- [ ] Test with slow network

### iOS
- [ ] Test on simulator
- [ ] Test on physical device
- [ ] Test different iOS versions
- [ ] Test different screen sizes
- [ ] Test with slow network

## 🔐 Security Checklist

- [ ] JWT tokens stored securely
- [ ] No sensitive data in logs
- [ ] HTTPS used in production
- [ ] API keys not hardcoded
- [ ] User data encrypted
- [ ] Session timeout handled

## 🚀 Deployment Steps

### Step 1: Prepare
```bash
# Clean build
flutter clean
flutter pub get

# Run tests
flutter test

# Analyze code
flutter analyze

# Check for issues
flutter doctor
```

### Step 2: Build
```bash
# Android
flutter build apk --release
# or
flutter build appbundle --release

# iOS
flutter build ios --release
```

### Step 3: Test Build
- [ ] Install on test device
- [ ] Test all features
- [ ] Check performance
- [ ] Monitor memory usage
- [ ] Check battery usage

### Step 4: Deploy
- [ ] Upload to Play Store (Android)
- [ ] Upload to App Store (iOS)
- [ ] Update version number
- [ ] Write release notes

## 📊 Monitoring

### Post-Deployment
- [ ] Monitor API call success rate
- [ ] Track error rates
- [ ] Monitor response times
- [ ] Check crash reports
- [ ] Review user feedback

### Metrics to Track
- [ ] Doctor load time
- [ ] Appointment creation success rate
- [ ] API error rate
- [ ] User session duration
- [ ] Feature usage statistics

## 🐛 Known Issues & Workarounds

### Issue 1: Slow Doctor Loading
**Workaround:** Add loading skeleton or cached data

### Issue 2: Network Timeout
**Workaround:** Increase timeout or add retry logic

### Issue 3: Large Response Size
**Workaround:** Implement pagination

## 📝 Documentation

- [ ] API integration guide complete
- [ ] Architecture documented
- [ ] Code comments added
- [ ] README updated
- [ ] Changelog maintained

## 🎯 Performance Benchmarks

### Target Metrics
- [ ] Doctor load time: < 2 seconds
- [ ] Appointment creation: < 1 second
- [ ] UI response time: < 100ms
- [ ] Memory usage: < 100MB
- [ ] Battery drain: < 5% per hour

### Actual Metrics
- Doctor load time: _____ seconds
- Appointment creation: _____ seconds
- UI response time: _____ ms
- Memory usage: _____ MB
- Battery drain: _____ % per hour

## ✅ Final Checks

### Before Release
- [ ] All tests passing
- [ ] No console errors
- [ ] No memory leaks
- [ ] Performance acceptable
- [ ] UI/UX smooth
- [ ] Error handling robust
- [ ] Documentation complete

### Release Approval
- [ ] QA team approval
- [ ] Product owner approval
- [ ] Technical lead approval
- [ ] Security review passed

## 🎉 Post-Release

### Immediate (Day 1)
- [ ] Monitor crash reports
- [ ] Check error logs
- [ ] Review user feedback
- [ ] Monitor API metrics

### Short-term (Week 1)
- [ ] Analyze usage patterns
- [ ] Identify bottlenecks
- [ ] Plan optimizations
- [ ] Address critical bugs

### Long-term (Month 1)
- [ ] Review performance metrics
- [ ] Plan feature enhancements
- [ ] Optimize based on data
- [ ] Update documentation

## 📞 Support Contacts

### Technical Issues
- Backend Team: _______________
- Mobile Team: _______________
- DevOps: _______________

### Business Issues
- Product Owner: _______________
- Project Manager: _______________

## 🔄 Rollback Plan

### If Critical Issues Found
1. Revert to previous version
2. Notify users
3. Fix issues
4. Re-test thoroughly
5. Re-deploy

### Rollback Steps
```bash
# Revert code
git revert <commit-hash>

# Rebuild
flutter clean
flutter build apk --release

# Redeploy
# Upload to store
```

## 📚 Additional Resources

- API Documentation: `API_INTEGRATION_GUIDE.md`
- Architecture: `ARCHITECTURE.md`
- Quick Start: `QUICK_START.md`
- Implementation: `IMPLEMENTATION_SUMMARY.md`

---

**Deployment Date:** _______________
**Version:** _______________
**Deployed By:** _______________
**Status:** ⬜ Pending | ⬜ In Progress | ⬜ Complete
