// import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// class SecureStorageService {
//   final FlutterSecureStorage _storage = const FlutterSecureStorage();

//   Future<void> saveUsername(String username) async {
//     await _storage.write(key: 'username', value: username);
//   }

//   Future<void> saveToken(String token) async {
//     await _storage.write(key: 'token', value: token);
//   }

//   Future<void> saveUserId(int id) async {
//     await _storage.write(key: 'userId', value: id.toString());
//   }

//   // Future<void> savePassword(String password) async {
//   //   await _storage.write(key: 'password', value: password);
//   // }

//   Future<String?> getUsername() async {
//     return await _storage.read(key: 'username');
//   }

//   Future<String?> getToken() async {
//     return await _storage.read(key: 'token');
//   }

//   Future<String?> getUserId() async {
//     return await _storage.read(key: 'userId');
//   }

//   // Future<String?> getPassword() async {
//   //   return await _storage.read(key: 'password');
//   // }

//   Future<void> deleteAll() async {
//     await _storage.deleteAll();
//   }
// }
