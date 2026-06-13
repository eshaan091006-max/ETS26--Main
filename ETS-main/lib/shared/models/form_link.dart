import 'dart:convert';

List<FormLink> formLinkFromJson(String str) =>
    List<FormLink>.from(json.decode(str).map((x) => FormLink.fromJson(x)));

String formLinkToJson(List<FormLink> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class FormLink {
  int id;
  int eventId;
  String link;
  String? label;
  List<int> visibleTo;

  FormLink({
    this.id = -1,
    this.eventId = -1,
    this.link = "https://docs.google.com/forms",
    this.label = 'Form Link',
    required this.visibleTo,
  });

  factory FormLink.fromJson(Map<String, dynamic> json) {
    List<int> parsedVisibleTo = [];
    final rawVisibleTo = json['visible_to'];
    if (rawVisibleTo is int) {
      for (int i = 0; i < 62; i++) {
        if ((rawVisibleTo & (1 << i)) != 0) {
          parsedVisibleTo.add(i);
        }
      }
    } else if (rawVisibleTo is List) {
      parsedVisibleTo = List<int>.from(rawVisibleTo);
    }
    
    return FormLink(
      id: json['id'],
      eventId: json['event_id'],
      link: json['link'],
      label: json['label'],
      visibleTo: parsedVisibleTo,
    );
  }

  static int _visibleToToBitmask(List<int> list) {
    int mask = 0;
    for (int id in list) {
      if (id >= 0 && id < 62) {
        mask |= (1 << id);
      }
    }
    return mask;
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "event_id": eventId,
    "link": link,
    "label": label,
    "visible_to": _visibleToToBitmask(visibleTo),
  };

  Map<String, dynamic> toInsertJson() => {
    "event_id": eventId,
    "link": link,
    "label": label,
    "visible_to": _visibleToToBitmask(visibleTo),
  };
}
