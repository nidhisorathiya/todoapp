import 'package:flutter/material.dart';
import 'package:todoapp/task.dart';
import 'package:todoapp/readandwrite.dart';

void main() {
  runApp(MaterialApp(
    home: ToDoApp(),
  ));
}

class ToDoApp extends StatefulWidget {
  @override
  _ToDoAppState createState() => _ToDoAppState();
}

class _ToDoAppState extends State<ToDoApp> {
  final List<Task> _tasks = [];
  final Storage storage = Storage();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    storage.readTasks().then((taskList) {
      setState(() {
        _tasks.addAll(taskList);
      });
    });
  }

  void _addNewTask(String title) {
    final newTask = Task(
      title: title,
      id: DateTime.now().toString(),
    );

    setState(() {
      _tasks.add(newTask);
    });
    _listKey.currentState?.insertItem(_tasks.length - 1);
    storage.writeTasks(_tasks);
  }

  void _startAddNewTask(BuildContext context) {
    String taskTitle = '';

    showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text('Add New Task'),
            content: TextField(
              onChanged: (value) {
                taskTitle = value;
              },
              decoration: InputDecoration(
                labelText: 'Task Title',
              ),
            ),
            actions: <Widget>[
              ElevatedButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
              ),
              ElevatedButton(
                child: Text('Add'),
                onPressed: () {
                  if (taskTitle.isNotEmpty) {
                    _addNewTask(taskTitle);
                    Navigator.of(ctx).pop();
                  }
                },
              ),
            ],
          );
        });
  }

  void _deleteTask(int index) {
    Task removedTask = _tasks[index];

    setState(() {
      _tasks.removeAt(index);
    });

    _listKey.currentState?.removeItem(
      index,
          (BuildContext context, Animation<double> animation) {
        return SizeTransition(
          sizeFactor: animation,
          child: Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              title:
              Text(removedTask.title, style: TextStyle(decoration: TextDecoration.lineThrough)),
              leading: Icon(
                Icons.check_circle,
                color: Colors.green,
              ),
            ),
          ),
        );
      },
      duration: Duration(milliseconds: 250),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${removedTask.title} deleted'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            setState(() {
              _tasks.insert(index, removedTask);
            });
            _listKey.currentState?.insertItem(index);
          },
        ),
        duration: Duration(seconds: 2),
      ),
    );

    storage.writeTasks(_tasks);
  }

  Widget _buildTaskItem(BuildContext context, int index) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        title: Text(
          _tasks[index].title,
          style: TextStyle(decoration: _tasks[index].completed ? TextDecoration.lineThrough : null),
        ),
        leading: Icon(
          _tasks[index].completed ? Icons.check_circle : Icons.radio_button_unchecked,
          color: _tasks[index].completed ? Colors.green : null,
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete),
          onPressed: () => _deleteTask(index),
        ),
        onTap: () {
          setState(() {
            _tasks[index].toggleCompleted();
          });
          storage.writeTasks(_tasks);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter ToDo App'),
      ),
      body: AnimatedList(
        key: _listKey,
        initialItemCount: _tasks.length,
        itemBuilder: (context, index, animation) {
          return _buildTaskItem(context, index);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _startAddNewTask(context),
        tooltip: 'Add Task',
        child: Icon(Icons.add),
      ),
    );
  }
}