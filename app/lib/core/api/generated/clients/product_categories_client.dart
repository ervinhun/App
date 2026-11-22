// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/product_category_response.dart';

part 'product_categories_client.g.dart';

@RestApi()
abstract class ProductCategoriesClient {
  factory ProductCategoriesClient(Dio dio, {String? baseUrl}) =
      _ProductCategoriesClient;

  @GET('/api/product-categories')
  Future<List<ProductCategoryResponse>> getProductCategories();
}
