class LabValuesSheetModel {
  final List<String> parameters;
  final List<String> dates;
  final Map<String, Map<String, String>> entries;

  LabValuesSheetModel({
    this.parameters = const [],
    this.dates = const [],
    this.entries = const {},
  });

  factory LabValuesSheetModel.fromJson(Map<String, dynamic> json) {
    // Parameters
    final params = List<String>.from(json['parameters'] ?? []);

    // Dates
    final dts = List<String>.from(json['dates'] ?? []);

    // Entries: { paramName: { dateStr: value } }
    final jsonEntries = json['entries'] as Map<String, dynamic>? ?? {};
    final Map<String, Map<String, String>> ents = {};

    jsonEntries.forEach((param, datesMap) {
      if (datesMap is Map<String, dynamic>) {
        ents[param] = datesMap.map((d, v) => MapEntry(d, v.toString()));
      }
    });

    return LabValuesSheetModel(
      parameters: params,
      dates: dts,
      entries: ents,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'parameters': parameters,
      'dates': dates,
      'entries': entries,
    };
  }

  LabValuesSheetModel copyWith({
    List<String>? parameters,
    List<String>? dates,
    Map<String, Map<String, String>>? entries,
  }) {
    return LabValuesSheetModel(
      parameters: parameters ?? this.parameters,
      dates: dates ?? this.dates,
      entries: entries ?? this.entries,
    );
  }
}
