import 'package:cloud_firestore/cloud_firestore.dart';

/// Map command.dat category tokens to display categories.
String _mapCategory(String token) {
  return switch (token) {
    '_(' => 'throw',
    '_)' => 'command',
    '_@' => 'special',
    '_*' => 'super',
    '_`' => 'other',
    _ => token,
  };
}

/// A single entry within a section.
/// Discriminated union: type is "move", "control", "cheat", or "text".
class MoveEntry {
  final String type;
  final String name;
  final String input;
  final String category;
  final String? note;
  final List<MoveEntry> followUps;

  const MoveEntry({
    required this.type,
    required this.name,
    required this.input,
    required this.category,
    this.note,
    this.followUps = const [],
  });

  factory MoveEntry.fromMap(Map<String, dynamic> map) {
    final type = map['type'] as String? ?? 'move';
    switch (type) {
      case 'control':
        return MoveEntry(
          type: 'control',
          name: '${map['label'] ?? ''}  ${map['description'] ?? ''}',
          input: '',
          category: '',
          note: 'info',
        );
      case 'cheat':
        return MoveEntry(
          type: 'cheat',
          name: map['name'] as String? ?? '',
          input: '',
          category: _mapCategory(map['category'] as String? ?? ''),
          note: (map['details'] as List<dynamic>?)?.join('\n'),
        );
      case 'text':
        return MoveEntry(
          type: 'text',
          name: map['text'] as String? ?? '',
          input: '',
          category: '',
          note: 'info',
        );
      case 'move':
      default:
        final followUps = <MoveEntry>[];
        if (map['follow_ups'] is List) {
          for (final fu in map['follow_ups'] as List) {
            if (fu is Map<String, dynamic>) {
              followUps.add(MoveEntry.fromMap({...fu, 'type': 'move'}));
            }
          }
        }
        return MoveEntry(
          type: 'move',
          name: map['name'] as String? ?? '',
          input: map['input_raw'] as String? ?? '',
          category: _mapCategory(map['category'] as String? ?? ''),
          note: map['note'] as String?,
          followUps: followUps,
        );
    }
  }
}

/// A section within command data (e.g. a character, common commands, controls).
class MoveListSection {
  final String title;
  final String? subtitle;
  final int order;
  final String sectionType; // "controls", "cheats", "other"
  final List<MoveEntry> entries;

  const MoveListSection({
    required this.title,
    this.subtitle,
    required this.order,
    required this.sectionType,
    required this.entries,
  });

  factory MoveListSection.fromMap(Map<String, dynamic> map) {
    final entries = <MoveEntry>[];
    if (map['entries'] is List) {
      for (final e in map['entries'] as List) {
        if (e is Map<String, dynamic>) {
          entries.add(MoveEntry.fromMap(e));
        }
      }
    }

    return MoveListSection(
      title: map['title'] as String? ?? '',
      subtitle: map['subtitle'] as String?,
      order: map['order'] as int? ?? 0,
      sectionType: map['section_type'] as String? ?? 'other',
      entries: entries,
    );
  }
}

/// Full command.dat data for a romset, stored in Firestore at command_dat/{shortname}.
class CommandData {
  final String id;
  final List<String> romNames;
  final String title;
  final String? gameId;
  final List<MoveListSection> sections;

  const CommandData({
    required this.id,
    required this.romNames,
    required this.title,
    this.gameId,
    required this.sections,
  });

  factory CommandData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final romNames = <String>[];
    if (data['rom_names'] is List) {
      romNames.addAll(List<String>.from(data['rom_names']));
    }

    final sections = <MoveListSection>[];
    if (data['sections'] is List) {
      for (final s in data['sections'] as List) {
        if (s is Map<String, dynamic>) {
          sections.add(MoveListSection.fromMap(s));
        }
      }
    }
    sections.sort((a, b) => a.order.compareTo(b.order));

    return CommandData(
      id: doc.id,
      romNames: romNames,
      title: data['title'] as String? ?? '',
      gameId: data['game_id'] as String?,
      sections: sections,
    );
  }
}
