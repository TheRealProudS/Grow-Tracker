
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

void main() => runApp(GrowApp());

class GrowApp extends StatefulWidget {
  @override
  State<GrowApp> createState() => _GrowAppState();
}

class _GrowAppState extends State<GrowApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grow Tagebuch',
      theme: ThemeData(
        primarySwatch: Colors.green,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.green,
        brightness: Brightness.dark,
      ),
      themeMode: _themeMode,
      home: GrowHomePage(onToggleTheme: () {
        setState(() {
          _themeMode =
              _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
        });
      }),
    );
  }
}

class GrowHomePage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  GrowHomePage({required this.onToggleTheme});
  @override
  _GrowHomePageState createState() => _GrowHomePageState();
}

class _GrowHomePageState extends State<GrowHomePage> {
  final Map<String, List<Map<String, dynamic>>> _plantEntries = {};
  final _formKey = GlobalKey<FormState>();
  final _waterController = TextEditingController();
  final _fertilizerController = TextEditingController();
  final _fertilizerTypeController = TextEditingController();
  final _noteController = TextEditingController();
  final _plantNameController = TextEditingController();
  String _selectedPlant = "";
  DateTime _selectedDate = DateTime.now();
  Map<String, DateTime?> _germinationDates = {};
  Map<String, DateTime?> _floweringDates = {};
  Map<String, String> _thcLevels = {};
  File? _selectedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _submitData() {
    if (_selectedPlant.isEmpty) return;
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _plantEntries[_selectedPlant] ??= [];
      _plantEntries[_selectedPlant]!.add({
        'date': DateFormat('dd.MM.yyyy').format(_selectedDate),
        'water': _waterController.text,
        'fertilizer': _fertilizerController.text,
        'fertilizerType': _fertilizerTypeController.text,
        'notes': _noteController.text,
        'image': _selectedImage,
      });
      _waterController.clear();
      _fertilizerController.clear();
      _fertilizerTypeController.clear();
      _noteController.clear();
      _selectedImage = null;
    });
  }

  void _pickDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  int? _getFloweringDayCount(String plant) {
    final date = _floweringDates[plant];
    if (date == null) return null;
    return DateTime.now().difference(date).inDays;
  }

  DateTime? _getEstimatedHarvestDate(String plant) {
    final date = _floweringDates[plant];
    if (date == null) return null;
    return date.add(Duration(days: 63));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Grow Tagebuch'),
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _plantNameController,
              decoration: InputDecoration(labelText: 'Neue Pflanze hinzufügen'),
              onSubmitted: (value) {
                if (value.trim().isEmpty) return;
                setState(() {
                  _plantEntries[value] = [];
                  _germinationDates[value] = null;
                  _floweringDates[value] = null;
                  _thcLevels[value] = "";
                  _selectedPlant = value;
                  _plantNameController.clear();
                });
              },
            ),
            DropdownButton<String>(
              value: _selectedPlant.isNotEmpty ? _selectedPlant : null,
              hint: Text('Pflanze auswählen'),
              isExpanded: true,
              items: _plantEntries.keys
                  .map((plant) => DropdownMenuItem(
                        child: Text(plant),
                        value: plant,
                      ))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedPlant = val!;
                });
              },
            ),
            if (_selectedPlant.isNotEmpty)
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text("Datum: ${DateFormat('dd.MM.yyyy').format(_selectedDate)}"),
                        ),
                        TextButton(
                          onPressed: () => _pickDate(context),
                          child: Text('Datum ändern'),
                        ),
                      ],
                    ),
                    TextFormField(
                      controller: _waterController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Wassermenge (ml)'),
                    ),
                    TextFormField(
                      controller: _fertilizerController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Düngermenge (ml)'),
                    ),
                    TextFormField(
                      controller: _fertilizerTypeController,
                      decoration: InputDecoration(labelText: 'Düngertyp'),
                    ),
                    TextFormField(
                      controller: _noteController,
                      decoration:
                          InputDecoration(labelText: 'Notizen (Topping, Lollipopping, etc.)'),
                    ),
                    SizedBox(height: 12),
                    if (_selectedImage != null)
                      Image.file(_selectedImage!, height: 100),
                    TextButton.icon(
                      icon: Icon(Icons.photo),
                      label: Text('Bild hinzufügen'),
                      onPressed: _pickImage,
                    ),
                    ElevatedButton(
                      onPressed: _submitData,
                      child: Text('Eintrag speichern'),
                    ),
                    Divider(),
                    ListTile(
                      title: Text(
                          "Keimtag: ${_germinationDates[_selectedPlant] != null ? DateFormat('dd.MM.yyyy').format(_germinationDates[_selectedPlant]!) : 'Nicht gesetzt'}"),
                      trailing: IconButton(
                        icon: Icon(Icons.calendar_today),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null)
                            setState(() => _germinationDates[_selectedPlant] = picked);
                        },
                      ),
                    ),
                    ListTile(
                      title: Text(
                          "Blütetag: ${_floweringDates[_selectedPlant] != null ? DateFormat('dd.MM.yyyy').format(_floweringDates[_selectedPlant]!) : 'Nicht gesetzt'}"),
                      subtitle: _getFloweringDayCount(_selectedPlant) != null
                          ? Text("Blütetag: ${_getFloweringDayCount(_selectedPlant)}")
                          : null,
                      trailing: IconButton(
                        icon: Icon(Icons.lightbulb),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null)
                            setState(() => _floweringDates[_selectedPlant] = picked);
                        },
                      ),
                    ),
                    if (_getEstimatedHarvestDate(_selectedPlant) != null)
                      ListTile(
                        title: Text(
                            "Voraussichtlicher Erntezeitpunkt: ${DateFormat('dd.MM.yyyy').format(_getEstimatedHarvestDate(_selectedPlant)!)}"),
                      ),
                    ListTile(
                      title: Text("THC-Gehalt: ${_thcLevels[_selectedPlant] ?? ''}"),
                      trailing: IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () async {
                          final result = await showDialog<String>(
                            context: context,
                            builder: (ctx) {
                              final controller = TextEditingController(
                                  text: _thcLevels[_selectedPlant]);
                              return AlertDialog(
                                title: Text('THC-Gehalt eingeben'),
                                content: TextField(
                                  controller: controller,
                                  decoration: InputDecoration(labelText: '% THC'),
                                  keyboardType: TextInputType.number,
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(controller.text),
                                    child: Text('Speichern'),
                                  )
                                ],
                              );
                            },
                          );
                          if (result != null)
                            setState(() => _thcLevels[_selectedPlant] = result);
                        },
                      ),
                    ),
                    Divider(),
                    Text('Einträge:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...?_plantEntries[_selectedPlant]?.map((e) => ListTile(
                          title: Text(
                              "${e['date']}: ${e['water']}ml Wasser, ${e['fertilizer']}ml ${e['fertilizerType']}"),
                          subtitle: Text(e['notes'] ?? ''),
                          trailing: e['image'] != null
                              ? Image.file(e['image'], width: 50)
                              : null,
                        ))
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }
}
