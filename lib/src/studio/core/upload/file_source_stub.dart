import 'file_source.dart';
import 'picked_file.dart';

StudioFileSource createFileSource() => _NoFileSource();

class _NoFileSource implements StudioFileSource {
  @override
  Future<PickedFile?> fromPath(String path) async => null;
  @override
  Future<List<PickedFile>> pickFiles({bool multiple = true}) async => [];
  @override
  Future<List<PickedFile>> pickMedia({bool multiple = true}) async => [];
}
