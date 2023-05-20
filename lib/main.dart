import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MyApp());
}

@JsonSerializable()
class ToDoItem {
  String title;
  String description;
  String lvl;
  bool isCompleted;
  ToDoItem(
      {required this.title,
      required this.description,
      required this.lvl,
      required this.isCompleted});
  factory ToDoItem.fromJson(Map<String, dynamic> json) =>
      _$ToDoItemFromJson(json);
  Map<String, dynamic> toJson() => _$ToDoItemToJson(this);
}

ToDoItem _$ToDoItemFromJson(Map<String, dynamic> json) => ToDoItem(
    title: json['title'] as String,
    description: json['description'] as String,
    lvl: json['lvl'] as String,
    isCompleted: json['isCompleted'] as bool);

Map<String, dynamic> _$ToDoItemToJson(ToDoItem item) => <String, dynamic>{
      'title': item.title,
      'description': item.description,
      'lvl': item.lvl,
      'isCompleted': item.isCompleted,
    };

class Database {
  final String _dataBaseFilename = 'todo.json';

  Database();

  Future<File> _getLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path + '/$_dataBaseFilename';
    return File(path);
  }

  Future<List<ToDoItem>> loadToDoList() async {
    final file = await _getLocalFile();
    if (!file.existsSync()) return [];
    final content = await file.readAsString();
    final List<dynamic> jsonList = json.decode(content);
    return jsonList.map((e) => ToDoItem.fromJson(e)).toList();
  }

  Future<void> saveToDoList(List<ToDoItem> todoList) async {
    final file = await _getLocalFile();
    final jsonList = todoList.map((e) => e.toJson()).toList();
    final jsonString = json.encode(jsonList);
    await file.writeAsString(jsonString);
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ToDo App',
      theme: ThemeData(
        brightness: Brightness.dark,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final db = Database();
  List<ToDoItem> _newTodoList = [];
  List<ToDoItem> _fList = [];
  bool _filter = false;

  Future<void> readJson() async {
    _newTodoList = await db.loadToDoList();
    setState(() {});
  }

  Future<void> saveJson() async {
    await db.saveToDoList(_newTodoList);
  }

  void _addTodoItem(ToDoItem item) {
    setState(() {
      _newTodoList.add(item);
    });
  }

  void _addTodoNewItem(ToDoItem item) {
    setState(() {
      _newTodoList.add(item);
    });
  }

  void _removeTodoItem(int index) {
    setState(() {
      _newTodoList.removeAt(index);
    });
  }

  void _editToDoItem(
      ToDoItem item, String title, String description, String lvl) {
    setState(() {
      item.title = title;
      item.description = description;
      item.lvl = lvl;
    });
  }

  void _checkTodoItem(int index) {
    setState(() {
      _newTodoList[index].isCompleted = !_newTodoList[index].isCompleted;
    });
  }

  void _filterList(String text) {
    setState(() {
      if (text.isEmpty) {
        _filter = false;
        return;
      }
      _filter = true;
      _fList = [];
      _newTodoList.forEach((element) {
        if (element.title.contains(text) || element.description.contains(text))
          _fList.add(element);
      });
    });
  }

  Widget _buildSearchBar() {
    return Container(
      child: TextField(
        onChanged: (value) => _filterList(value),
        decoration: InputDecoration(prefix: Icon(Icons.search)),
      ),
      padding: EdgeInsets.only(bottom: 12, left: 25, right: 25),
      margin: EdgeInsets.only(bottom: 20, top: 20, left: 50, right: 50),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildJsonButtons() {
    return Container(
      child: Row(
        children: [
          IconButton(onPressed: readJson, icon: Icon(Icons.read_more)),
          IconButton(onPressed: saveJson, icon: Icon(Icons.save))
        ],
      ),
    );
  }

  Widget _buildTodoList() {
    final ScrollController _sC = ScrollController();
    return Scrollbar(
      controller: _sC,
      child: ListView.builder(
        controller: _sC,
        scrollDirection: Axis.vertical,
        itemCount: 50, // _filter ? _fList.length : _newTodoList.length
        shrinkWrap: true,
        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
        itemBuilder: (context, index) {
          if (!_filter) {
            if (index < _newTodoList.length) {
              return _buildTodoItem(_newTodoList[index], index);
            }
          } else {
            if (index < _fList.length) {
              return _buildTodoItem(_fList[index], index);
            }
          }
        },
      ),
    );
  }

  Widget _buildTodoItem(ToDoItem item, int index) {
    return Container(
        margin: EdgeInsets.only(bottom: 20),
        child: ListTile(
          onTap: () => _showEditTodoDialog(item),
          title: Row(
            children: [
              Expanded(
                  child: Text(
                item.title,
                style: TextStyle(
                  decoration:
                      item.isCompleted ? TextDecoration.lineThrough : null,
                ),
              )),
              Expanded(
                  child: Align(
                alignment: Alignment.centerRight,
                child: Text(item.lvl.toString()),
              ))
            ],
          ),
          tileColor: item.isCompleted
              ? Color.fromARGB(255, 76, 93, 73)
              : Color.fromARGB(255, 83, 83, 83),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          leading: IconButton(
            icon: item.isCompleted
                ? Icon(Icons.check_box)
                : Icon(Icons.check_box_outline_blank),
            onPressed: () => _checkTodoItem(index),
          ),
          subtitle: Text(item.description),
          trailing: IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => _removeTodoItem(index),
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: _buildSearchBar(),
        ),
        body: _buildTodoList(),
        /*
        Column(
          children: [
            _buildSearchBar(),
            _buildTodoList()
          ],
        ),
         */
        floatingActionButton: Container(
          margin: EdgeInsets.symmetric(horizontal: 50),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FloatingActionButton(
                onPressed: _showAddTodoDialog,
                tooltip: 'Add ToDo Item',
                child: Icon(Icons.add),
              ),
              FloatingActionButton(
                onPressed: saveJson,
                tooltip: 'Save ToDo items',
                child: Icon(Icons.save),
              ),
              FloatingActionButton(
                onPressed: readJson,
                tooltip: 'Load ToDo items',
                child: Icon(Icons.read_more),
              ),
            ],
          ),
        ));
  }

  void _showEditTodoDialog(ToDoItem item) {
    final _formKey = GlobalKey<FormState>();
    String _newTodoTitle = '';
    String _newTodoDescription = '';
    String _lvl = '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit ToDo Item'),
          content: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    autofocus: true,
                    initialValue: item.title,
                    onSaved: (value) => _newTodoTitle = value!,
                    decoration: InputDecoration(
                      hintText: 'Enter title',
                    ),
                  ),
                  TextFormField(
                    autofocus: false,
                    initialValue: item.description,
                    onSaved: (value) => _newTodoDescription = value!,
                    decoration: InputDecoration(
                      hintText: 'Enter discription',
                    ),
                  ),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    autofocus: false,
                    initialValue: item.lvl,
                    onSaved: (value) => _lvl = value!,
                    decoration: InputDecoration(
                      hintText: 'Enter lvl',
                    ),
                  )
                ],
              )),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  _editToDoItem(item, _newTodoTitle, _newTodoDescription, _lvl);
                  Navigator.pop(context);
                }
              },
              child: Text('Edit'),
            ),
          ],
        );
      },
    );
  }

  void _showAddTodoDialog() {
    final _formKey = GlobalKey<FormState>();
    String _newTodoTitle = '';
    String _newTodoDescription = '';
    String _lvl = '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add ToDo Item'),
          content: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    autofocus: true,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter title';
                      }
                      return null;
                    },
                    onSaved: (value) => _newTodoTitle = value!,
                    decoration: InputDecoration(
                      hintText: 'Enter title',
                    ),
                  ),
                  TextFormField(
                    autofocus: false,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter description';
                      }
                      return null;
                    },
                    onSaved: (value) => _newTodoDescription = value!,
                    decoration: InputDecoration(
                      hintText: 'Enter discription',
                    ),
                  ),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    autofocus: false,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter lvl';
                      }
                      return null;
                    },
                    onSaved: (value) => _lvl = value!,
                    decoration: InputDecoration(
                      hintText: 'Enter lvl',
                    ),
                  )
                ],
              )),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  _addTodoItem(ToDoItem(
                      title: _newTodoTitle,
                      description: _newTodoDescription,
                      lvl: _lvl,
                      isCompleted: false));
                  Navigator.pop(context);
                }
              },
              child: Text('ADD'),
            ),
          ],
        );
      },
    );
  }
}
