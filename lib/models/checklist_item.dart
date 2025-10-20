class ChecklistItem {
  int? id;
  String name;
  bool isChecked;

  ChecklistItem({this.id, required this.name, this.isChecked = false});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isChecked': isChecked ? 1 : 0,
    };
  }

  static ChecklistItem fromMap(Map<String, dynamic> map) {
    return ChecklistItem(
      id: map['id'],
      name: map['name'],
      isChecked: map['isChecked'] == 1,
    );
  }
}
