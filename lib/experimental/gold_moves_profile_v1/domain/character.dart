import 'package:meta/meta.dart';

@immutable
class CharacterSpec {
  final String id;
  final String name;
  const CharacterSpec({required this.id, required this.name});
}
