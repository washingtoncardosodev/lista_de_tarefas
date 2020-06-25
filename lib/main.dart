import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';

void main() {
  runApp(MaterialApp(
    home: Home()
  ));
}

class Home extends StatefulWidget {
  Home({Key key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  final _toDoController = TextEditingController();

  List _toDoList = [];  
  
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos;

  @override
  void initState() {
    super.initState();

    _readData()
      .then((data) => {
        setState(() {
          _toDoList = json.decode(data);
        })
      });
  }

  void _addTodo() {
    setState(() {
      if (_toDoController.text.isEmpty) {
        return;
      }
      Map<String, dynamic> newToDo = Map();
      newToDo["title"] = _toDoController.text;
      newToDo["status"] = false;
      _toDoController.text = ""; // Reset form
      _toDoList.add(newToDo);
      _saveData();
    });
  }

  Future<Null> _refresh() async {
    setState(() {
      _toDoList.sort((a, b) {
        if (a["status"] && !b["status"]) return 1; // a > b
        else if (!a["status"] && b["status"]) return -1; //  
        else return 0; //
      });

      _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas"),
        centerTitle: true
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(7.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(labelText: "Nova tarefa", labelStyle: TextStyle(color: Colors.blueAccent)),
                    controller: _toDoController,
                  ),
                ),
                RaisedButton(
                  child: Text("ADD"),
                  color: Colors.blueAccent,
                  textColor: Colors.white,
                  onPressed: _addTodo
                )
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                padding: EdgeInsets.only(top: 10.0),
                itemCount: _toDoList.length,
                itemBuilder: buildItem
              ) 
            )
          )
        ],
      )
    );
  }

  Widget buildItem(BuildContext context, int index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(Icons.delete, color: Colors.white)
        )
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["status"],
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]["status"] ? Icons.check : Icons.error)
        ),
        onChanged: (c) {
          setState(() {
            _toDoList[index]["status"] = c;
            _saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedPos = index;
          _toDoList.removeAt(index);
          _saveData();   

          final snack = SnackBar(
            content: Text("Tarefa \"${_lastRemoved["title"]}\" removida!"),
            action: SnackBarAction(
              label: "Desfazer",
              onPressed: () {
                setState(() {
                  _toDoList.insert(_lastRemovedPos, _lastRemoved);
                  _saveData();
                });
              }
            ),
            duration: Duration(seconds: 5),
          );

          Scaffold.of(context).removeCurrentSnackBar(); 
          Scaffold.of(context).showSnackBar(snack);
        });        
      },
    );
  }

  

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);

    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();

      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}

