import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ProductRequestModel {
  final String name;
  final String? description;
  final bool status;
  final double price;
  final int quantity;
  final double discount;
  final int categoryId;
  final int brandId;
  final String? mainImgPath; // Path to local file if uploading

  const ProductRequestModel({
    required this.name,
    this.description,
    this.status = true,
    required this.price,
    required this.quantity,
    required this.discount,
    required this.categoryId,
    required this.brandId,
    this.mainImgPath,
  });

  Future<FormData> toFormData() async {
    final Map<String, dynamic> data = {
      'Name': name,
      'Description': description ?? '',
      'Status': status,           // send as real bool for ASP.NET model binding
      'Price': price,
      'Quantity': quantity,
      'Discount': discount,
      'CategoryId': categoryId,
      'BrandId': brandId,
    };

    if (mainImgPath != null && mainImgPath!.isNotEmpty) {
      data['MainImg'] = await MultipartFile.fromFile(
        mainImgPath!,
        filename: mainImgPath!.split('/').last.split('\\').last,
      );
    }

    if (kDebugMode) {
      debugPrint('│ ProductRequestModel.toFormData() fields: ${{ ...data }..remove("MainImg")}');
    }

    return FormData.fromMap(data);
  }
}
