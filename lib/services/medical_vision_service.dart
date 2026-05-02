import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/medical_vision_result_model.dart';
import 'api_config.dart';

class MedicalVisionService {
  Future<MedicalVisionResultModel> detectInjury(XFile file) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/medical/vision/injury');
    final request = http.MultipartRequest('POST', url);

    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: _safeFilename(file.name, 'injury.jpg'),
        ),
      );
    } else {
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          file.path,
          filename: _safeFilename(file.name, 'injury.jpg'),
        ),
      );
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Injury vision failed: ${response.statusCode} ${response.body}',
      );
    }

    if (response.body.trim().isEmpty) {
      throw Exception('Empty response from injury vision AI');
    }

    dynamic decoded = jsonDecode(response.body);
    if (decoded is String) {
      decoded = jsonDecode(decoded);
    }

    if (decoded is Map<String, dynamic>) {
      return MedicalVisionResultModel.fromJson(decoded);
    }

    throw Exception('Unexpected injury vision response format');
  }

  Future<MedicalVisionResultModel> detectGym(XFile file) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/medical/vision/gym');
    final request = http.MultipartRequest('POST', url);

    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: _safeFilename(file.name, 'gym.jpg'),
        ),
      );
    } else {
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          file.path,
          filename: _safeFilename(file.name, 'gym.jpg'),
        ),
      );
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Gym vision failed: ${response.statusCode} ${response.body}',
      );
    }

    if (response.body.trim().isEmpty) {
      throw Exception('Empty response from gym vision AI');
    }

    dynamic decoded = jsonDecode(response.body);
    if (decoded is String) {
      decoded = jsonDecode(decoded);
    }

    if (decoded is Map<String, dynamic>) {
      return MedicalVisionResultModel.fromJson(decoded);
    }

    throw Exception('Unexpected gym vision response format');
  }

  Future<Uint8List> readPreviewBytes(XFile file) {
    return file.readAsBytes();
  }

  String _safeFilename(String name, String fallback) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }
}
