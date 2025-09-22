// ignore_for_file: avoid_print, file_names

import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

// ฟังก์ชันเลือกภาพจาก gallery
Future<File?> pickImage() async {
  final picker = ImagePicker();
  final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
  if (pickedFile != null) return File(pickedFile.path);
  return null;
}

// ฟังก์ชันอัปโหลด profile + รูป
Future<String?> updateProfileWithImage(
  String username,
  Map<String, String> profileData,
  File? imageFile,
  String baseUrl,
) async {
  var uri = Uri.parse('$baseUrl/user/$username');
  var request = http.MultipartRequest('PUT', uri);

  request.fields.addAll(profileData);

  if (imageFile != null) {
    final mimeType =
        lookupMimeType(imageFile.path)?.split('/') ?? ['image', 'jpeg'];
    request.files.add(
      await http.MultipartFile.fromPath(
        'profile_image',
        imageFile.path,
        contentType: MediaType(mimeType[0], mimeType[1]),
      ),
    );
  }

  var response = await request.send();
  if (response.statusCode == 200) {
    print('Profile updated successfully with image!');
    // อ่าน response body
    final respStr = await response.stream.bytesToString();
    final data = jsonDecode(respStr);
    return data['user']['profile_image']; // ส่ง URL กลับ
  } else {
    print('Failed to update profile with image: ${response.statusCode}');
    return null;
  }
}
