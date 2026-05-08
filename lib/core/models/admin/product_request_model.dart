import 'package:dio/dio.dart';

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
      'Status': status.toString(),
      'Price': price.toString(),
      'Quantity': quantity.toString(),
      'Discount': discount.toString(),
      'CategoryId': categoryId.toString(),
      'BrandId': brandId.toString(),
    };

    if (description != null && description!.isNotEmpty) {
      data['Description'] = description;
    }

    if (mainImgPath != null && mainImgPath!.isNotEmpty) {
      data['MainImg'] = await MultipartFile.fromFile(mainImgPath!);
    }

    return FormData.fromMap(data);
  }
}
