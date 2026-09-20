import 'package:exercise_app/models/team.dart';
import 'package:exercise_app/theme/team_palette.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> row({String? color}) => <String, dynamic>{
      'id': 'g1',
      'name': 'Kadıköy Barbell',
      'description': null,
      'owner_id': 'u1',
      'invite_token': 'ABC123',
      'created_at': '2026-09-20T10:00:00.000Z',
      'color': ?color,
    };

void main() {
  test('parses the colour slug', () {
    final team = Team.fromJson(row(color: 'claret'));
    expect(team.color, 'claret');
    expect(team.kit, KitColor.claret);
  });

  test('a row without a colour falls back to the default kit', () {
    final team = Team.fromJson(row());
    expect(team.kit, kDefaultKit);
  });

  test('an unrecognised slug falls back rather than throwing', () {
    final team = Team.fromJson(row(color: 'chartreuse'));
    expect(team.kit, kDefaultKit);
  });

  test('toJson round-trips the colour', () {
    final team = Team.fromJson(row(color: 'gold'));
    expect(team.toJson()['color'], 'gold');
  });

  test('copyWith replaces the colour and equality notices', () {
    final team = Team.fromJson(row(color: 'gold'));
    final recoloured = team.copyWith(color: 'forest');
    expect(recoloured.kit, KitColor.forest);
    expect(recoloured == team, isFalse);
    expect(team.copyWith() == team, isTrue);
  });
}
