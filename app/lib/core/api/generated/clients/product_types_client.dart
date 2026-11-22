// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/product_type_response.dart';

part 'product_types_client.g.dart';

@RestApi()
abstract class ProductTypesClient {
  factory ProductTypesClient(Dio dio, {String? baseUrl}) = _ProductTypesClient;

  @GET('/api/product-types')
  Future<List<ProductTypeResponse>> getProductTypes({
    @Query('categoryId') String? categoryId,
  });
}
