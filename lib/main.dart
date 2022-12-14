import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide MenuItem;
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';

enum TaskType {video, music, document, unknown}

class ATask {
  ATask(this.uri, this.title) {
    type = TaskType.unknown;
    createTime = DateTime.now();
    progress = Random().nextInt(100) / 100;
  }

  // 任务地址
  final String uri;
  // 任务类型
  late TaskType type;
  // 任务标题
  late String title;
  // 任务创建时间
  late DateTime createTime;

  late Duration leftDuration = const Duration(seconds: 0);

  late DateTime finishTime;

  late double progress;
}

class ATaskListView extends Container {
  List<ATask> tasks = [];
  ATaskListView({super.key});

  @override
  Widget build(BuildContext context) {
    var provider = Provider.of<ATaskProvider>(context, listen: true);
    tasks = provider.tasks;
    return Expanded(
        child: ListView.builder(
          itemCount: provider.tasks.length,
          itemBuilder: taskBuilder
        )
    );
  }

  Widget taskBuilder(BuildContext context, int index) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Image(image: FileImage(File("assets/images/doc.png")), width: 48, height: 48,),
          Expanded(
            flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      children: [
                        Text(tasks[index].title),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text("大小：100G/200G"),
                      Text("剩余时间: 00:00:01"),
                      Text("10Mb/s"),
                    ],
                  ),
                  LinearProgressIndicator(value: tasks[index].progress)
                ],
              )
          )
        ],
      )
    );
  }
}

class ATaskProvider with ChangeNotifier, DiagnosticableTreeMixin {
  List<ATask> tasks = [
    ATask("uri", "test1"),
    ATask("uri", "test1"),
    ATask("uri", "test1"),
    ATask("uri", "test1"),
  ];

  int get count => tasks.length;


  int addTask(ATask task) {
    tasks.add(task);
    notifyListeners();
    return tasks.length;
  }

  void updateTask(int index, ATask task){
    tasks[index] = task;
    notifyListeners();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty("task count", tasks.length));
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ATaskProvider())
      ],
      child: const MyApp()
    )
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatelessWidget with TrayListener {

  const MyHomePage({super.key, required this.title});

  final String title;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          OutlinedButton(
            child: const Text("progress"),
            onPressed: () {
              var taskProvider = context.read<ATaskProvider>();
              taskProvider.addTask(ATask("uri", "add test"));

              var timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
                var t = taskProvider.tasks[0];
                t.progress += 0.01;
                taskProvider.updateTask(0, t);
                if (t.progress >= 1) {
                  timer.cancel();
                }
              });
            },
          ),
          OutlinedButton(
            child: const Text("http"),
            onPressed: () async {
              windowManager.hide();

              final TrayManager trayManager = TrayManager.instance;
              String tryIconPath = 'assets/images/avatar.ico';
              trayManager.setIcon(tryIconPath);

              Menu menu = Menu(
                items: [
                  MenuItem(
                    key: "show",
                    label: "show"
                  ),
                  MenuItem.separator(),
                  MenuItem(
                    key: 'quit',
                    label: '退出'
                  )
                ]
              );
              await trayManager.setToolTip("hello");
              await trayManager.setContextMenu(menu);
              trayManager.addListener(this);

              Future<http.Response> resp = http.get(Uri.parse("https://jsonplaceholder.typicode.com/albums/1"));
              resp.then((value) => {
                if (value.statusCode == 200) {
                  debugPrint("ok")
                }
              });
          }),
          ATaskListView()
        ],
      ),
    );
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch(menuItem.key) {
      case 'show':
        debugPrint("show");
        windowManager.show(inactive: true).then((value) => null);
        trayManager.destroy().then((value) => null);
        break;
      case 'quit':
        trayManager.destroy().then((value) => exit(0));
    }
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }
}
