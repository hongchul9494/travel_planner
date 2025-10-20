class ItineraryItem {
  int? id;
  int tripId;
  String content;
  int order;

  ItineraryItem({this.id, required this.tripId, required this.content, required this.order});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'content': content,
      'item_order': order,
    };
  }

  static ItineraryItem fromMap(Map<String, dynamic> map) {
    return ItineraryItem(
      id: map['id'],
      tripId: map['trip_id'],
      content: map['content'],
      order: map['item_order'],
    );
  }
}
