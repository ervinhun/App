// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/create_product_request.dart';
import '../models/product_response.dart';

part 'products_client.g.dart';

@RestApi()
abstract class ProductsClient {
  factory ProductsClient(Dio dio, {String? baseUrl}) = _ProductsClient;

  @GET('/api/products')
  Future<List<ProductResponse>> search({
    @Query('search') String? search,
    @Query('productTypeId') String? productTypeId,
  });

  @POST('/api/products')
  Future<ProductResponse> createProduct({
    @Body() required CreateProductRequest body,
  });

  @GET('/api/products/{barcode}')
  Future<ProductResponse> getByBarcode({
    @Path('barcode') required String barcode,
  });
}
