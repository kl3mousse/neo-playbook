import 'package:cloud_firestore/cloud_firestore.dart';

/// A single move entry within a section.
class MoveEntry {
  final String name;
  final String input;
  final String category; // throw, command, special, super, ultra, other, ""
  final String? note;

  const MoveEntry({
    required this.name,
    required this.input,
    required this.category,
    this.note,
  });

  factory MoveEntry.fromMap(Map<String, dynamic> map) {
    return MoveEntry(
      name: map['name'] as String? ?? '',
      input: map['input'] as String? ?? '',
      category: map['category'] as String? ?? '',
      note: map['note'] as String?,
    );
  }
}

/// A section within command data (e.g. a character, common commands, controls).
class MoveListSection {
  final String title;
  final String? subtitle;
  final int order;
  final String sectionType; // controls, how_to_play, common, character, other
  final List<MoveEntry> moves;

  const MoveListSection({
    required this.title,
    this.subtitle,
    required this.order,
    required this.sectionType,
    required this.moves,
  });

  factory MoveListSection.fromMap(Map<String, dynamic> map) {
    final movesList = <MoveEntry>[];
    if (map['moves'] is List) {
      for (final m in map['moves'] as List) {
        if (m is Map<String, dynamic>) {
          movesList.add(MoveEntry.fromMap(m));
        }
      }
    }

    return MoveListSection(
      title: map['title'] as String? ?? '',
      subtitle: map['subtitle'] as String?,
      order: map['order'] as int? ?? 0,
      sectionType: map['section_type'] as String? ?? 'character',
      moves: movesList,
    );
  }
}

/// Full command.dat data for a romset, stored in Firestore at command_dat/{shortname}.
class CommandData {
  final String id;
  final List<String> romNames;
  final String title;
  final List<MoveListSection> sections;

  const CommandData({
    required this.id,
    required this.romNames,
    required this.title,
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
      sections: sections,
    );
  }
}
