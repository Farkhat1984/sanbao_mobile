/// Implementation of the image generation repository.
///
/// Delegates to the remote data source for all operations.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/features/image_gen/data/datasources/image_gen_remote_datasource.dart';
import 'package:sanbao_flutter/features/image_gen/domain/entities/image_gen_result.dart';
import 'package:sanbao_flutter/features/image_gen/domain/repositories/image_gen_repository.dart';

/// Concrete implementation of [ImageGenRepository].
class ImageGenRepositoryImpl implements ImageGenRepository {
  ImageGenRepositoryImpl({
    required ImageGenRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final ImageGenRemoteDataSource _remoteDataSource;

  @override
  Future<ImageGenResult> generate({
    required String prompt,
    ImageGenStyle? style,
    ImageGenSize? size,
  }) =>
      _remoteDataSource.generate(
        prompt: prompt,
        style: style,
        size: size,
      );

  @override
  Future<ImageGenResult> edit({
    required String imageSource,
    required String prompt,
  }) =>
      _remoteDataSource.edit(
        imageSource: imageSource,
        prompt: prompt,
      );
}

/// Riverpod provider for [ImageGenRepository].
final imageGenRepositoryProvider = Provider<ImageGenRepository>((ref) {
  final remoteDataSource = ref.watch(imageGenRemoteDataSourceProvider);
  return ImageGenRepositoryImpl(remoteDataSource: remoteDataSource);
});
