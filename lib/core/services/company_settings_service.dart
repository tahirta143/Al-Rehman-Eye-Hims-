// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../global/global_api.dart';
// import 'auth_storage_service.dart';

// class CompanySettingsService {
//   static const String _keyName = 'company_name_cache';
//   static const String _keyLogo = 'company_logo_cache';

//   /// Fetch settings gracefully from SharedPreferences
//   Future<Map<String, String?>> getCachedSettings() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       return {
//         'company_name': prefs.getString(_keyName),
//         'logo_url': prefs.getString(_keyLogo),
//       };
//     } catch (_) {
//       return {'company_name': null, 'logo_url': null};
//     }
//   }

//   /// Syncs settings with backend and caches them locally
//   Future<void> fetchAndCacheSettings() async {
//     try {
//       final url = '${GlobalApi.baseUrl}/company-settings';
//       print('Fetching company settings from: $url');
//       final storage = AuthStorageService();
//       final token = await storage.getToken();
//       final headers = {
//         'Content-Type': 'application/json',
//         if (token != null) 'Authorization': 'Bearer $token',
//       };

//       final response = await http
//           .get(Uri.parse(url), headers: headers)
//           .timeout(const Duration(seconds: 5));

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         print('Company settings response: $data');
//         if (data['success'] == true && data['data'] != null) {
//           final prefs = await SharedPreferences.getInstance();

//           final String? name = data['data']['company_name'];
//           final String? logoUrl = data['data']['logo_url'];

//           if (name != null && name.isNotEmpty) {
//             await prefs.setString(_keyName, name);
//           }
//           if (logoUrl != null && logoUrl.isNotEmpty) {
//             await prefs.setString(_keyLogo, logoUrl);
//           }
//         } else {
//           print('Failed to parse success data: $data');
//         }
//       } else {
//         print('Company settings API error: ${response.statusCode} - ${response.body}');
//       }
//     } catch (e) {
//       print('CompanySettingsService Exception: $e');
//     }
//   }
// }
