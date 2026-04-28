import 'package:flutter_test/flutter_test.dart';
import 'package:travel_app/models/journal_entry.dart';

void main() {
  group('JournalEntry Model Tests', () {
    test('Deve criar um JournalEntry com todos os campos', () {
      final entry = JournalEntry(
        id: 'test-id',
        tripId: 'trip-123',
        userId: 'user-456',
        userName: 'João Silva',
        date: DateTime(2024, 1, 15),
        content: 'Visitamos a Torre Eiffel hoje. Foi incrível!',
        mood: MoodIcon.veryHappy,
        photos: ['photo1.jpg', 'photo2.jpg'],
        locationName: 'Paris, França',
        createdAt: DateTime(2024, 1, 15, 18, 30),
        reactions: {
          'like': ['user1', 'user2'],
          'love': ['user3'],
        },
        isPublic: true,
        shareToken: 'abc123',
      );

      expect(entry.id, 'test-id');
      expect(entry.content, 'Visitamos a Torre Eiffel hoje. Foi incrível!');
      expect(entry.mood, MoodIcon.veryHappy);
      expect(entry.isPublic, true);
      expect(entry.shareToken, 'abc123');
      expect(entry.photos.length, 2);
      expect(entry.locationName, 'Paris, França');
    });

    test('Deve converter JournalEntry para Map corretamente', () {
      final entry = JournalEntry(
        id: 'test-id',
        tripId: 'trip-123',
        userId: 'user-456',
        userName: 'Maria Santos',
        date: DateTime(2024, 1, 15),
        content: 'Dia maravilhoso!',
        mood: MoodIcon.happy,
        photos: [],
        createdAt: DateTime.now(),
        reactions: {},
        isPublic: false,
      );

      final map = entry.toMap();

      expect(map['tripId'], 'trip-123');
      expect(map['content'], 'Dia maravilhoso!');
      expect(map['mood'], 'sentiment_satisfied');
      expect(map['moodValue'], 4);
      expect(map['isPublic'], false);
      expect(map['reactions'], {});
    });
  });

  group('MoodIcon Enum Tests', () {
    test('Deve ter 5 estados de humor', () {
      expect(MoodIcon.values.length, 5);
    });

    test('Deve ter os valores corretos', () {
      expect(MoodIcon.values, [
        MoodIcon.veryHappy,
        MoodIcon.happy,
        MoodIcon.neutral,
        MoodIcon.sad,
        MoodIcon.verySad,
      ]);
    });

    test('Deve converter string para MoodIcon', () {
      expect(MoodIcon.values.byName('veryHappy'), MoodIcon.veryHappy);
      expect(MoodIcon.values.byName('happy'), MoodIcon.happy);
      expect(MoodIcon.values.byName('neutral'), MoodIcon.neutral);
      expect(MoodIcon.values.byName('sad'), MoodIcon.sad);
      expect(MoodIcon.values.byName('verySad'), MoodIcon.verySad);
    });

    test('Deve obter nome do ícone correto', () {
      expect(MoodIcon.veryHappy.iconName, 'sentiment_very_satisfied');
      expect(MoodIcon.happy.iconName, 'sentiment_satisfied');
      expect(MoodIcon.neutral.iconName, 'sentiment_neutral');
      expect(MoodIcon.sad.iconName, 'sentiment_dissatisfied');
      expect(MoodIcon.verySad.iconName, 'sentiment_very_dissatisfied');
    });

    test('Deve obter label correto', () {
      expect(MoodIcon.veryHappy.label, 'Muito Feliz');
      expect(MoodIcon.happy.label, 'Feliz');
      expect(MoodIcon.neutral.label, 'Neutro');
      expect(MoodIcon.sad.label, 'Triste');
      expect(MoodIcon.verySad.label, 'Muito Triste');
    });

    test('Deve obter valor numérico correto', () {
      expect(MoodIcon.veryHappy.value, 5);
      expect(MoodIcon.happy.value, 4);
      expect(MoodIcon.neutral.value, 3);
      expect(MoodIcon.sad.value, 2);
      expect(MoodIcon.verySad.value, 1);
    });

    test('Deve converter valor numérico para MoodIcon', () {
      expect(MoodIcon.fromValue(5), MoodIcon.veryHappy);
      expect(MoodIcon.fromValue(4), MoodIcon.happy);
      expect(MoodIcon.fromValue(3), MoodIcon.neutral);
      expect(MoodIcon.fromValue(2), MoodIcon.sad);
      expect(MoodIcon.fromValue(1), MoodIcon.verySad);
    });

    test('Deve retornar neutral para valor inválido', () {
      expect(MoodIcon.fromValue(0), MoodIcon.neutral);
      expect(MoodIcon.fromValue(10), MoodIcon.neutral);
    });

    test('Deve converter string de ícone para MoodIcon', () {
      expect(
        MoodIcon.fromString('sentiment_very_satisfied'),
        MoodIcon.veryHappy,
      );
      expect(MoodIcon.fromString('sentiment_satisfied'), MoodIcon.happy);
      expect(MoodIcon.fromString('sentiment_neutral'), MoodIcon.neutral);
      expect(MoodIcon.fromString('sentiment_dissatisfied'), MoodIcon.sad);
      expect(
        MoodIcon.fromString('sentiment_very_dissatisfied'),
        MoodIcon.verySad,
      );
    });

    test('Deve retornar neutral para string inválida', () {
      expect(MoodIcon.fromString('invalid'), MoodIcon.neutral);
      expect(MoodIcon.fromString(''), MoodIcon.neutral);
    });
  });

  group('ReactionType Enum Tests', () {
    test('Deve ter 6 tipos de reação', () {
      expect(ReactionType.values.length, 6);
    });

    test('Deve ter os valores corretos', () {
      expect(ReactionType.values, [
        ReactionType.like,
        ReactionType.love,
        ReactionType.wow,
        ReactionType.celebrate,
        ReactionType.support,
        ReactionType.thanks,
      ]);
    });

    test('Deve obter nome do ícone correto', () {
      expect(ReactionType.like.iconName, 'favorite');
      expect(ReactionType.love.iconName, 'favorite_border');
      expect(ReactionType.wow.iconName, 'star');
      expect(ReactionType.celebrate.iconName, 'celebration');
      expect(ReactionType.support.iconName, 'thumb_up');
      expect(ReactionType.thanks.iconName, 'volunteer_activism');
    });

    test('Deve obter label correto', () {
      expect(ReactionType.like.label, 'Curtir');
      expect(ReactionType.love.label, 'Amei');
      expect(ReactionType.wow.label, 'Uau');
      expect(ReactionType.celebrate.label, 'Celebrar');
      expect(ReactionType.support.label, 'Apoiar');
      expect(ReactionType.thanks.label, 'Obrigado');
    });

    test('Deve converter string de ícone para ReactionType', () {
      expect(ReactionType.fromIcon('favorite'), ReactionType.like);
      expect(ReactionType.fromIcon('favorite_border'), ReactionType.love);
      expect(ReactionType.fromIcon('star'), ReactionType.wow);
      expect(ReactionType.fromIcon('celebration'), ReactionType.celebrate);
      expect(ReactionType.fromIcon('thumb_up'), ReactionType.support);
      expect(ReactionType.fromIcon('volunteer_activism'), ReactionType.thanks);
    });

    test('Deve retornar like para string inválida', () {
      expect(ReactionType.fromIcon('invalid'), ReactionType.like);
      expect(ReactionType.fromIcon(''), ReactionType.like);
    });
  });

  group('JournalEntry Reactions Tests', () {
    late JournalEntry entry;

    setUp(() {
      entry = JournalEntry(
        id: 'test-id',
        tripId: 'trip-123',
        userId: 'user-456',
        userName: 'Test User',
        date: DateTime.now(),
        content: 'Teste de reações',
        mood: MoodIcon.happy,
        photos: [],
        createdAt: DateTime.now(),
        reactions: {
          'like': ['user1', 'user2', 'user3'],
          'love': ['user4', 'user5'],
          'wow': ['user6'],
        },
        isPublic: true,
      );
    });

    test('Deve calcular total de reações corretamente', () {
      expect(entry.getTotalReactions(), 6);
    });

    test('Deve retornar 0 quando não há reações', () {
      final emptyEntry = JournalEntry(
        id: 'test-id',
        tripId: 'trip-123',
        userId: 'user-456',
        userName: 'Test User',
        date: DateTime.now(),
        content: 'Sem reações',
        mood: MoodIcon.happy,
        photos: [],
        createdAt: DateTime.now(),
        reactions: {},
        isPublic: false,
      );

      expect(emptyEntry.getTotalReactions(), 0);
    });

    test('Deve obter contagem de reações por tipo', () {
      final counts = entry.getReactionCounts();

      expect(counts['like'], 3);
      expect(counts['love'], 2);
      expect(counts['wow'], 1);
    });

    test('Deve verificar se usuário reagiu', () {
      expect(entry.hasUserReacted('user1'), true);
      expect(entry.hasUserReacted('user4'), true);
      expect(entry.hasUserReacted('user6'), true);
      expect(entry.hasUserReacted('user999'), false);
    });

    test('Deve obter tipo de reação do usuário', () {
      expect(entry.getUserReaction('user1'), 'like');
      expect(entry.getUserReaction('user4'), 'love');
      expect(entry.getUserReaction('user6'), 'wow');
      expect(entry.getUserReaction('user999'), null);
    });
  });

  group('JournalEntry CopyWith Tests', () {
    test('Deve criar cópia com campos modificados', () {
      final original = JournalEntry(
        id: 'test-id',
        tripId: 'trip-123',
        userId: 'user-456',
        userName: 'Test User',
        date: DateTime(2024, 1, 15),
        content: 'Original',
        mood: MoodIcon.happy,
        photos: [],
        createdAt: DateTime.now(),
        reactions: {},
        isPublic: false,
      );

      final modified = original.copyWith(
        content: 'Modificado',
        mood: MoodIcon.veryHappy,
        isPublic: true,
        shareToken: 'new-token',
      );

      expect(modified.id, original.id);
      expect(modified.content, 'Modificado');
      expect(modified.mood, MoodIcon.veryHappy);
      expect(modified.isPublic, true);
      expect(modified.shareToken, 'new-token');
    });
  });

  group('JournalEntry Public Sharing Tests', () {
    test('Deve marcar entry como público com token', () {
      final entry = JournalEntry(
        id: 'test-id',
        tripId: 'trip-123',
        userId: 'user-456',
        userName: 'Test User',
        date: DateTime.now(),
        content: 'Público',
        mood: MoodIcon.happy,
        photos: [],
        createdAt: DateTime.now(),
        reactions: {},
        isPublic: true,
        shareToken: 'unique-token-123',
      );

      expect(entry.isPublic, true);
      expect(entry.shareToken, isNotNull);
      expect(entry.shareToken!.isNotEmpty, true);
    });

    test('Deve permitir entry privado sem token', () {
      final entry = JournalEntry(
        id: 'test-id',
        tripId: 'trip-123',
        userId: 'user-456',
        userName: 'Test User',
        date: DateTime.now(),
        content: 'Privado',
        mood: MoodIcon.happy,
        photos: [],
        createdAt: DateTime.now(),
        reactions: {},
        isPublic: false,
      );

      expect(entry.isPublic, false);
      expect(entry.shareToken, isNull);
    });
  });

  group('JournalEntry Photos Tests', () {
    test('Deve adicionar fotos corretamente', () {
      final entry = JournalEntry(
        id: 'test-id',
        tripId: 'trip-123',
        userId: 'user-456',
        userName: 'Test User',
        date: DateTime.now(),
        content: 'Com fotos',
        mood: MoodIcon.happy,
        photos: ['photo1.jpg', 'photo2.jpg', 'photo3.jpg'],
        createdAt: DateTime.now(),
        reactions: {},
        isPublic: false,
      );

      expect(entry.photos.length, 3);
      expect(entry.photos[0], 'photo1.jpg');
      expect(entry.photos[2], 'photo3.jpg');
    });

    test('Deve permitir entry sem fotos', () {
      final entry = JournalEntry(
        id: 'test-id',
        tripId: 'trip-123',
        userId: 'user-456',
        userName: 'Test User',
        date: DateTime.now(),
        content: 'Sem fotos',
        mood: MoodIcon.happy,
        photos: [],
        createdAt: DateTime.now(),
        reactions: {},
        isPublic: false,
      );

      expect(entry.photos.isEmpty, true);
    });
  });

  group('JournalEntry Date Tests', () {
    test('Deve armazenar data corretamente', () {
      final testDate = DateTime(2024, 3, 15, 14, 30);
      final entry = JournalEntry(
        id: 'test-id',
        tripId: 'trip-123',
        userId: 'user-456',
        userName: 'Test User',
        date: testDate,
        content: 'Teste de data',
        mood: MoodIcon.happy,
        photos: [],
        createdAt: DateTime.now(),
        reactions: {},
        isPublic: false,
      );

      expect(entry.date.year, 2024);
      expect(entry.date.month, 3);
      expect(entry.date.day, 15);
      expect(entry.date.hour, 14);
      expect(entry.date.minute, 30);
    });
  });

  group('JournalEntry Location Tests', () {
    test('Deve armazenar localização quando fornecida', () {
      final entry = JournalEntry(
        id: 'test-id',
        tripId: 'trip-123',
        userId: 'user-456',
        userName: 'Test User',
        date: DateTime.now(),
        content: 'Com localização',
        mood: MoodIcon.happy,
        photos: [],
        locationName: 'Torre Eiffel, Paris',
        createdAt: DateTime.now(),
        reactions: {},
        isPublic: false,
      );

      expect(entry.locationName, 'Torre Eiffel, Paris');
    });

    test('Deve permitir entry sem localização', () {
      final entry = JournalEntry(
        id: 'test-id',
        tripId: 'trip-123',
        userId: 'user-456',
        userName: 'Test User',
        date: DateTime.now(),
        content: 'Sem localização',
        mood: MoodIcon.happy,
        photos: [],
        createdAt: DateTime.now(),
        reactions: {},
        isPublic: false,
      );

      expect(entry.locationName, isNull);
    });
  });
}

