class Client {
  final String id;
  final String name;
  final String contactPerson;
  final String phone;
  final String email;
  final String address;
  final ClientType type;
  final String? website;
  final String? notes;
  final DateTime createdAt;
  final DateTime? lastContactDate;
  final int projectsCount; // Количество проектов (вычисляемое поле)

  Client({
    required this.id,
    required this.name,
    required this.contactPerson,
    required this.phone,
    required this.email,
    required this.address,
    required this.type,
    this.website,
    this.notes,
    required this.createdAt,
    this.lastContactDate,
    this.projectsCount = 0,
  });

  // Создаем копию объекта Client с обновленными полями
  Client copyWith({
    String? id,
    String? name,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    ClientType? type,
    String? website,
    String? notes,
    DateTime? createdAt,
    DateTime? lastContactDate,
    int? projectsCount,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      type: type ?? this.type,
      website: website ?? this.website,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      lastContactDate: lastContactDate ?? this.lastContactDate,
      projectsCount: projectsCount ?? this.projectsCount,
    );
  }

  // Преобразование в Map для сохранения в базе данных
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'contact_person': contactPerson,
      'phone': phone,
      'email': email,
      'address': address,
      'type': type.index,
      'website': website,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'last_contact_date': lastContactDate?.toIso8601String(),
    };
  }

  // Создание объекта Client из Map, полученного из базы данных
  factory Client.fromMap(Map<String, dynamic> map, {int projectsCount = 0}) {
    return Client(
      id: map['id'],
      name: map['name'],
      contactPerson: map['contact_person'],
      phone: map['phone'],
      email: map['email'],
      address: map['address'],
      type: ClientType.values[map['type']],
      website: map['website'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      lastContactDate:
          map['last_contact_date'] != null
              ? DateTime.parse(map['last_contact_date'])
              : null,
      projectsCount: projectsCount,
    );
  }
}

enum ClientType { individual, company, government, nonProfit }

extension ClientTypeExtension on ClientType {
  String get name {
    switch (this) {
      case ClientType.individual:
        return 'Физическое лицо';
      case ClientType.company:
        return 'Компания';
      case ClientType.government:
        return 'Государственное учреждение';
      case ClientType.nonProfit:
        return 'Некоммерческая организация';
    }
  }

  String get color {
    switch (this) {
      case ClientType.individual:
        return '#5C6BC0'; // Синий
      case ClientType.company:
        return '#26A69A'; // Бирюзовый
      case ClientType.government:
        return '#EF5350'; // Красный
      case ClientType.nonProfit:
        return '#FFB74D'; // Оранжевый
    }
  }
}
