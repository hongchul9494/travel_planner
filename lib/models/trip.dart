class Trip {
  int? id;
  String? destination;
  DateTime? startDate;
  DateTime? endDate;

  Trip({this.id, this.destination, this.startDate, this.endDate});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'destination': destination,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
    };
  }

  static Trip fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'],
      destination: map['destination'],
      startDate: map['startDate'] != null ? DateTime.parse(map['startDate']) : null,
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
    );
  }
}
