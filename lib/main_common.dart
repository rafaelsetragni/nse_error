import 'dart:isolate';
import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications_fcm/awesome_notifications_fcm.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

import 'flavors.dart';

Future<void> mainCommon(Flavor flavor) async {
  await NotificationController.initializeLocalNotifications(debug: true);
  await NotificationController.initializeRemoteNotifications(debug: true);
  await NotificationController.initializeIsolateReceivePort();
  await NotificationController.getInitialNotificationAction();
  runApp(const MyApp());
}


///  *********************************************
///     NOTIFICATION CONTROLLER
///  *********************************************

class NotificationController extends ChangeNotifier {
  /// *********************************************
  ///   SINGLETON PATTERN
  /// *********************************************

  static final NotificationController _instance =
  NotificationController._internal();

  factory NotificationController() {
    return _instance;
  }

  NotificationController._internal();

  /// *********************************************
  ///  OBSERVER PATTERN
  /// *********************************************

  String _firebaseToken = '';
  String get firebaseToken => _firebaseToken;

  String _nativeToken = '';
  String get nativeToken => _nativeToken;

  ReceivedAction? initialAction;

  /// *********************************************
  ///   INITIALIZATION METHODS
  /// *********************************************

  static Future<void> initializeLocalNotifications(
      {required bool debug}) async {
    await AwesomeNotifications().initialize(
      null, //'resource://drawable/res_app_icon',//
      [
        NotificationChannel(
            channelKey: 'alerts',
            channelName: 'Alerts',
            channelDescription: 'Notification tests as alerts',
            playSound: true,
            importance: NotificationImportance.High,
            defaultPrivacy: NotificationPrivacy.Private,
            defaultColor: Colors.deepPurple,
            ledColor: Colors.deepPurple)
      ],
      debug: debug,
      languageCode: 'ko',
    );
  }

  static Future<void> initializeRemoteNotifications(
      {required bool debug}) async {
    await Firebase.initializeApp();
    await AwesomeNotificationsFcm().initialize(
        onFcmTokenHandle: NotificationController.myFcmTokenHandle,
        onNativeTokenHandle: NotificationController.myNativeTokenHandle,
        onFcmSilentDataHandle: NotificationController.mySilentDataHandle,
        licenseKeys:
        // On this example app, the app ID / Bundle Id are different
        // for each platform, so i used the main Bundle ID + 1 variation
        [
          // com.example.nseError:
          '2024-02-15==j9pA1Z9FooDTkpNLuzmMNSpavRJEzBY9hQ4ygw7lgNktJmjZCcfK5G'
              'Gw73ZFuSZAw2NDWF1ke2BGPUMyADjpOk7fRXzDXKPH9DiiZ+k2Ko75jxdaco43'
              '8iNYYeduq6RMRM4dGupAAzAPCrjr2oaM+09qQwZ0zWyU4L5T3lDgUlvdbkiW9Q'
              'rW4G1zxU14a5aTQGxNkN2ujb0Y36NoSlgrJih8DXE2lLrqxKmqZI8Xm3KterQk'
              'j3BTjFanX9gf1sIbd5dc0mTdul263Goi+z7VMKw+sRtnnJVWDIoLpfwduEItpW'
              'gIITbAq6PnRiNLyRgv/+bcGgf3RmZBQn3lkCLwbg==',

          // com.example.nseError.dev:
          '2024-02-15==YLNuolDRGugMaLmCNU17pg4Zt77aDf/WUSaVTf+C/Be4kK0EdPDel6'
              'Hjt/wY5Y2OsCd9vbtIoilS9hgmSBbmu6zRIphNdCTsN6dYFRJbYC2+JIclUZef'
              '8U4kRgS9kh3seNXTVPWx79N8w69ZnFUxZa4thMTHi2S/nsRPuggMbf9eGMQrQI'
              'R88tNI6nA/MWs1hXige/Ls8fbUtokzHyqOAT68qqMoFNn30Y5fytXHQ93uc3rQ'
              'hK82Lez1pCjiWlybDI5/U0B6ya9JgoDyRVHkqV6tVlSuugtLOqA76Eb9npwzaW'
              'L4upmSdhinb/NSS7rVwZc+hQMuVq8cv+FBapnNcQ==',

          // com.example.nseError.stg:
          '2024-02-15==mmhyEt7tGu/fBHgTpuJxthyFW4rEThcyqlnsX2IrtdwHHrzBrbx0Bu'
              'n8FKg9NskdJueMYMw5nIa91vNt3SN63zq76K2/h//UliPmQ8jSeJLynfVT9R9K'
              'zNTCvkRFL9ZTJhnrcvz/371kRL8Qm1ncNRgpGYFyY0xAWMJqRu9gD1sohEJEtd'
              'qUe9f+e9sr1Tp2j2GguAHy1TDNG+zyXDaC9G4rrzmhPQUsGGjtMqUGQztr2m4W'
              'yOQIdy7qhOz7TnaHnxX5EUgzvz44w/+eaX5APvoHM4+H5gK7EP/v+x3l+GHaVU'
              'eOKv4ZXDNJtg8IBXycv9xtvk+kuWWveHn1ll6+YA==',

          // com.example.nse_error:
          '2024-02-15==cuZ3U5bamRWMz9H3xaAvWDImtydTAUwEoJSPFvxYcofOuWh9lkfj7N'
              'vt4XJiL31tP+bHqEfLyhWbdFFl+I15SDJfPUoPqPgArTFyKqAQN8+o5IX3B5Vc'
              '50BvznXpsoDaCokNNqsC/f78AxSp1IxUO8DgvlrUo+dM4IIyrWEidumI7J2nnh'
              'qqdI8L/33Oi4f5A2DX+kEPKr+inYh/xJsbIr7Psrpug9SiawqMmTLZr3fNrbY5'
              'F+y//9HW6sCKS2PDrmUAiYYEKykqmPFZOAX/m/N/Mr0bziT1AlOEIc50WgNuCp'
              'NS22UUDgZooNAV4+AHpBUufyAZ4+qQQ+G1qoWiOw==',

          // com.example.nse_error.dev:
          '2024-02-15==hN8JKlUxY6wHnaICMhJlfrwcdqXNpeK8nxX5YvAd+oesX8wPLUmcZm'
              'kAOJlmxBG59JFnDUZExzSHijpI+fWcV7bnu7W9ewD0QZlhjvZdt6b3iieDlIMs'
              'r9ldgQweMIm1TVjxLu8fqRa4feMOXufH66Zq+ZVzNrsoE+IE35iMBVWppkj0gZ'
              'ee5s0GTJBCF2vsZM7Fn0JsXozgPIsecnV8tP+BEGkEc4YWnp5cjN50jYobALKE'
              'mgKufe2+/PoK/qR7fkNC2Gich52WcNS21kXx9b3VCFEaaGbuORdRexTCoRO9dJ'
              '1OgVK4FsiUVoXDyX1wxXIluqqWfvbxU0ThZRYmrQ==',

          // com.example.nse_error.stg:
          '2024-02-15==Yn/TImh3qYCHSCuPlh0i3wsVEb2pPsbgSsZyhVEJFmp8vjEZHOivqO'
              'etPBNBi6tkV9GAY1NQwWLPfOLFqkCzHnG1kuW8y0khrvAPYnQYlM4Mdm074fBC'
              'PHB97CW2U8h57tAZw52P84SVXTACe2Wh5h+ynZptKQwDf2sPASTYBwy/enmnes'
              '0H9CsbSkoUCbA46F3iWyNc+5fzHECIIq3d8geTQb5Iudi1pjAUftRHsolNynpk'
              '1taR6ag8fT/L8cv/JM0aCYF4GJccogbKQAH8fZmz946wkpdN9Doe5PfnoLrSOG'
              'dd/dyiB0Zj1z3YD3Q8m15j0fBX2UH7WfuKq12DjQ==',
        ],
        debug: debug);
  }

  static Future<void> startListeningNotificationEvents() async {
    AwesomeNotifications()
        .setListeners(onActionReceivedMethod: onActionReceivedMethod);

    // Get initial notification action is optional
    _instance.initialAction = await AwesomeNotifications()
        .getInitialNotificationAction(removeFromActionEvents: false);
  }

  static ReceivePort? receivePort;
  static Future<void> initializeIsolateReceivePort() async {
    receivePort = ReceivePort('Notification action port in main isolate')
      ..listen(
              (silentData) => onActionReceivedImplementationMethod(silentData)
      );

    IsolateNameServer.registerPortWithName(
        receivePort!.sendPort,
        'notification_action_port'
    );
  }

  ///  *********************************************
  ///     LOCAL NOTIFICATION EVENTS
  ///  *********************************************

  static Future<void> getInitialNotificationAction() async {
    ReceivedAction? receivedAction = await AwesomeNotifications()
        .getInitialNotificationAction(removeFromActionEvents: true);
    _instance.initialAction = receivedAction;
    if (receivedAction == null) return;

    print('App launched by a notification action: $receivedAction');
  }

  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {

    if(
    receivedAction.actionType == ActionType.SilentAction ||
        receivedAction.actionType == ActionType.SilentBackgroundAction
    ){
      // For background actions, you must hold the execution until the end
      print('Message sent via notification input: "${receivedAction.buttonKeyInput}"');
      await executeLongTaskInBackground();
      return;
    }
    else {
      if (receivePort == null){
        // onActionReceivedMethod was called inside a parallel dart isolate.
        SendPort? sendPort = IsolateNameServer.lookupPortByName(
            'notification_action_port'
        );

        if (sendPort != null){
          // Redirecting the execution to main isolate process (this process is
          // only necessary when you need to redirect the user to a new page or
          // use a valid context)
          sendPort.send(receivedAction);
          return;
        }
      }
    }

    return onActionReceivedImplementationMethod(receivedAction);
  }

  static Future<void> onActionReceivedImplementationMethod(
      ReceivedAction receivedAction
      ) async {
    MyApp.navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/notification-page',
            (route) =>
        (route.settings.name != '/notification-page') || route.isFirst,
        arguments: receivedAction);
  }

  ///  *********************************************
  ///     REMOTE NOTIFICATION EVENTS
  ///  *********************************************

  /// Use this method to execute on background when a silent data arrives
  /// (even while terminated)
  @pragma("vm:entry-point")
  static Future<void> mySilentDataHandle(FcmSilentData silentData) async {
    Fluttertoast.showToast(
        msg: 'Silent data received',
        backgroundColor: Colors.blueAccent,
        textColor: Colors.white,
        fontSize: 16);

    print('"SilentData": ${silentData.toString()}');

    if (silentData.createdLifeCycle != NotificationLifeCycle.Foreground) {
      print("bg");
    } else {
      print("FOREGROUND");
    }

    print('mySilentDataHandle received a FcmSilentData execution');
    await executeLongTaskInBackground();
  }

  /// Use this method to detect when a new fcm token is received
  @pragma("vm:entry-point")
  static Future<void> myFcmTokenHandle(String token) async {

    if (token.isNotEmpty){
      Fluttertoast.showToast(
          msg: 'Fcm token received',
          backgroundColor: Colors.blueAccent,
          textColor: Colors.white,
          fontSize: 16);

      debugPrint('Firebase Token:"$token"');
    }
    else {
      Fluttertoast.showToast(
          msg: 'Fcm token deleted',
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16);

      debugPrint('Firebase Token deleted');
    }

    _instance._firebaseToken = token;
    _instance.notifyListeners();
  }

  /// Use this method to detect when a new native token is received
  @pragma("vm:entry-point")
  static Future<void> myNativeTokenHandle(String token) async {
    Fluttertoast.showToast(
        msg: 'Native token received',
        backgroundColor: Colors.blueAccent,
        textColor: Colors.white,
        fontSize: 16);
    debugPrint('Native Token:"$token"');

    _instance._nativeToken = token;
    _instance.notifyListeners();
  }

  ///  *********************************************
  ///     BACKGROUND TASKS TEST
  ///  *********************************************

  static Future<void> executeLongTaskInBackground() async {
    print("starting long task");
    await Future.delayed(const Duration(seconds: 4));
    final url = Uri.parse("http://google.com");
    final re = await http.get(url);
    print(re.body);
    print("long task done");
  }

  ///  *********************************************
  ///     REQUEST NOTIFICATION PERMISSIONS
  ///  *********************************************

  static Future<bool> displayNotificationRationale() async {
    bool userAuthorized = false;
    BuildContext context = MyApp.navigatorKey.currentContext!;
    await showDialog(
        context: context,
        builder: (BuildContext ctx) {
          return AlertDialog(
            title: Text('Get Notified!',
                style: Theme.of(context).textTheme.titleLarge),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Image.network(
                        'https://cdn-icons-png.flaticon.com/512/8297/8297354.png',
                        width: MediaQuery.sizeOf(context).width * 0.4,
                        height: MediaQuery.sizeOf(context).height * 0.2,
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                    'To visualize notifications (local and push), first you need to allow notifications on your device'),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                  },
                  child: Text(
                    'Maybe Later',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: Colors.red),
                  )),
              TextButton(
                  onPressed: () async {
                    userAuthorized = true;
                    Navigator.of(ctx).pop();
                  },
                  child: Text(
                    'Allow',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: Colors.deepPurple),
                  )),
            ],
          );
        });
    return userAuthorized &&
        await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  ///  *********************************************
  ///     LOCAL NOTIFICATION CREATION METHODS
  ///  *********************************************

  static requestNotificationPermissions() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();

    if (!isAllowed) {
      isAllowed = await displayNotificationRationale();
    }
  }

  static Future<void> createNewNotification() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();

    if (!isAllowed) {
      isAllowed = await displayNotificationRationale();
    }

    if (!isAllowed) return;

    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: -1, // -1 is replaced by a random number
            channelKey: 'alerts',
            title: 'Huston! The eagle has landed!',
            body:
            "A small step for a man, but a giant leap to Flutter's community!",
            bigPicture: 'https://storage.googleapis.com/cms-storage-bucket/d406c736e7c4c57f5f61.png',
            largeIcon: 'https://storage.googleapis.com/cms-storage-bucket/0dbfcc7a59cd1cf16282.png',
            notificationLayout: NotificationLayout.BigPicture,
            payload: {'notificationId': '1234567890'}),
        actionButtons: [
          NotificationActionButton(key: 'REDIRECT', label: 'Redirect'),
          NotificationActionButton(
              key: 'REPLY',
              label: 'Reply Message',
              requireInputText: true,
              actionType: ActionType.SilentAction
          ),
          NotificationActionButton(
              key: 'DISMISS',
              label: 'Dismiss',
              actionType: ActionType.DismissAction,
              isDangerousOption: true)
        ]);
  }

  static Future<void> resetBadge() async {
    await AwesomeNotifications().resetGlobalBadge();
  }

  static Future<void> deleteToken() async {
    await AwesomeNotificationsFcm().deleteToken();
    await Future.delayed(const Duration(seconds: 5));
    await requestFirebaseToken();
  }

  ///  *********************************************
  ///     REMOTE TOKEN REQUESTS
  ///  *********************************************

  static Future<String> requestFirebaseToken() async {
    if (await AwesomeNotificationsFcm().isFirebaseAvailable) {
      try {
        return await AwesomeNotificationsFcm().requestFirebaseAppToken();
      } catch (exception) {
        debugPrint('$exception');
      }
    } else {
      debugPrint('Firebase is not available on this project');
    }
    return '';
  }

  static subscribeTo(BuildContext context, String topicName) {
    final scaffold = ScaffoldMessenger.of(context);
    AwesomeNotificationsFcm()
        .subscribeToTopic(topicName)
        .then((value) {
            scaffold.showSnackBar(
              SnackBar(
                content: Text("Subscribed to topic '$topicName'"),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating, // Makes it float above the bottom of the screen
                margin: const EdgeInsets.fromLTRB(15.0, 5.0, 15.0, 60.0), // Customizes position
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)), // Rounded corners
              ),
            );
        });
  }

  static unsubscribeTo(BuildContext context, String topicName) {
    final scaffold = ScaffoldMessenger.of(context);
    AwesomeNotificationsFcm()
        .unsubscribeToTopic(topicName)
        .then((value) {
      scaffold.showSnackBar(
        SnackBar(
          content: Text("Unsubscribed to topic '$topicName'"),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating, // Makes it float above the bottom of the screen
          margin: const EdgeInsets.fromLTRB(15.0, 5.0, 15.0, 60.0), // Customizes position
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)), // Rounded corners
        ),
      );
    });
  }
}




///  *********************************************
///     MAIN WIDGET
///  *********************************************

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  // The navigator key is necessary to navigate using static methods
  static GlobalKey<NavigatorState> navigatorKey =
  GlobalKey<NavigatorState>();

  static Color mainColor = const Color(0xFF9D50DD);

  @override
  State<MyApp> createState() => _AppState();
}

class _AppState extends State<MyApp> {
  // This widget is the root of your application.

  static const String routeHome = '/', routeNotification = '/notification-page';

  @override
  void initState() {
    NotificationController.startListeningNotificationEvents();
    NotificationController.requestFirebaseToken();
    super.initState();
    print(NotificationController().initialAction);
  }

  List<Route<dynamic>> onGenerateInitialRoutes(String initialRouteName) {
    List<Route<dynamic>> pageStack = [];
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(content: Text('InitialAction: ${NotificationController().initialAction}')),
    // );
    pageStack.add(MaterialPageRoute(
        builder: (_) =>
        const MyHomePage(title: 'Awesome Notifications FCM Example App')));
    if (NotificationController().initialAction != null) {
      pageStack.add(MaterialPageRoute(
          builder: (_) => NotificationPage(
              receivedAction: NotificationController().initialAction!)));
    }
    return pageStack;
  }

  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case routeHome:
        return MaterialPageRoute(
            builder: (_) => const MyHomePage(
                title: 'Awesome Notifications FCM Example App'));

      case routeNotification:
        ReceivedAction receivedAction = settings.arguments as ReceivedAction;
        return MaterialPageRoute(
            builder: (_) => NotificationPage(receivedAction: receivedAction));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Awesome Notifications - Simple Example',
      navigatorKey: MyApp.navigatorKey,
      onGenerateInitialRoutes: onGenerateInitialRoutes,
      onGenerateRoute: onGenerateRoute,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
    );
  }
}





///  *********************************************
///     HOME PAGE
///  *********************************************

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  void initState() {
    NotificationController().addListener(() => setState(() {}));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const SizedBox(height: 40),
                  const Text('Firebase Token:'),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: NotificationController().firebaseToken))
                            .then((_) {
                          print('"FCM Token": ${NotificationController().firebaseToken}');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Firebase Token copied to clipboard')),
                          );
                        });
                      },
                      child: Text(
                        NotificationController().firebaseToken,
                        style: const TextStyle(decoration: TextDecoration.underline, color: Colors.blue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Native Token:'),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: NotificationController().nativeToken))
                            .then((_) {
                          print('"Native Token": ${NotificationController().nativeToken}');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Native Token copied to clipboard')),
                          );
                        });
                      },
                      child: Text(
                        NotificationController().nativeToken,
                        style: const TextStyle(decoration: TextDecoration.underline, color: Colors.blue),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'initial action: ${NotificationController().initialAction}',
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      'menu',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SimpleButton(
                          onPressed: () => NotificationController.requestNotificationPermissions(),
                          icon: Icons.local_police,
                          label: 'Request Permissions',
                        ),
                        const SizedBox(height: 20),
                        SimpleButton(
                          onPressed: () => NotificationController.createNewNotification(),
                          icon: Icons.outgoing_mail,
                          label: 'Create Local Notification',
                        ),
                        const SizedBox(height: 20),
                        SimpleButton(
                          onPressed: () => NotificationController.resetBadge(),
                          icon: Icons.exposure_zero,
                          label: 'Reset Badge counter',
                        ),
                        const SizedBox(height: 20),
                        SimpleButton(
                          onPressed: () => NotificationController.subscribeTo(context, 'positive'),
                          icon: Icons.notifications,
                          label: "Subscribe to 'positive' topic",
                        ),
                        const SizedBox(height: 20),
                        SimpleButton(
                          onPressed: () => NotificationController.unsubscribeTo(context, 'positive'),
                          icon: Icons.notifications_off,
                          label: "Unsubscribe from 'positive' topic",
                        ),
                        const SizedBox(height: 20),
                        SimpleButton(
                          onPressed: () => NotificationController.subscribeTo(context, 'negative'),
                          icon: Icons.notifications,
                          label: "Subscribe to 'negative' topic",
                        ),
                        const SizedBox(height: 20),
                        SimpleButton(
                          icon: Icons.notifications_off,
                          label: "Unsubscribe from 'negative' topic",
                          onPressed: () => NotificationController.unsubscribeTo(context, 'negative'),
                        ),
                        const SizedBox(height: 20),
                        SimpleButton(
                          onPressed: () => NotificationController.deleteToken(),
                          icon: Icons.recycling,
                          label: 'Request new FCM Token',
                        ),
                        const SizedBox(height: 20),
                        SimpleButton(
                          onPressed: () => NotificationController.deleteToken(),
                          icon: Icons.restore_from_trash_rounded,
                          label: 'Delete FCM Token',
                          isDangerous: true,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SimpleButton extends StatelessWidget {

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final bool isDangerous;

  const SimpleButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    this.isDangerous = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: isDangerous ? Colors.red : null,
        minimumSize: const Size(double.infinity, 50),
      ),
      child: Row(
        children: [
          Icon(icon),
          Expanded(child: Center(child: Text(label)))
        ],
      ),
    );
  }
}




///  *********************************************
///     NOTIFICATION PAGE
///  *********************************************

class NotificationPage extends StatelessWidget {
  const NotificationPage({
    super.key,
    required this.receivedAction
  });

  final ReceivedAction receivedAction;

  @override
  Widget build(BuildContext context) {
    bool hasLargeIcon = receivedAction.largeIconImage != null;
    bool hasBigPicture = receivedAction.bigPictureImage != null;
    double bigPictureSize = MediaQuery.of(context).size.height * .4;
    double largeIconSize =
        MediaQuery.of(context).size.height * (hasBigPicture ? .12 : .2);

    return Scaffold(
      appBar: AppBar(
        title: Text(receivedAction.title ?? receivedAction.body ?? ''),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                height:
                  hasBigPicture
                      ? bigPictureSize + 40
                      : hasLargeIcon
                          ? largeIconSize + 60
                          : 0,
                child: hasBigPicture
                    ? Stack(
                  children: [
                    if (hasBigPicture)
                      FadeInImage(
                        placeholder: const NetworkImage(
                            'https://cdn.syncfusion.com/content/images/common/placeholder.gif'),
                        //AssetImage('assets/images/placeholder.gif'),
                        height: bigPictureSize,
                        width: MediaQuery.of(context).size.width,
                        image: receivedAction.bigPictureImage!,
                        fit: BoxFit.cover,
                      ),
                    if (hasLargeIcon)
                      Positioned(
                        bottom: 15,
                        left: 20,
                        child: ClipRRect(
                          borderRadius: BorderRadius.all(
                              Radius.circular(largeIconSize)),
                          child: FadeInImage(
                            placeholder: const NetworkImage(
                                'https://cdn.syncfusion.com/content/images/common/placeholder.gif'),
                            //AssetImage('assets/images/placeholder.gif'),
                            height: largeIconSize,
                            width: largeIconSize,
                            image: receivedAction.largeIconImage!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                  ],
                )
                : Center(
                  child:
                    (hasLargeIcon)
                      ? ClipRRect(
                        borderRadius:
                        BorderRadius.all(Radius.circular(largeIconSize)),
                        child: FadeInImage(
                          placeholder: const NetworkImage(
                              'https://cdn.syncfusion.com/content/images/common/placeholder.gif'),
                          //AssetImage('assets/images/placeholder.gif'),
                          height: largeIconSize,
                          width: largeIconSize,
                          image: receivedAction.largeIconImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                      : const SizedBox.shrink(),
                )
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0, left: 20, right: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                      text: TextSpan(children: [
                        if ((hasLargeIcon || hasBigPicture) && (receivedAction.title?.isNotEmpty ?? false))
                          TextSpan(
                            text: receivedAction.title!,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        if ((receivedAction.title?.isNotEmpty ?? false) &&
                            (receivedAction.body?.isNotEmpty ?? false))
                          TextSpan(
                            text: '\n\n',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        if (receivedAction.body?.isNotEmpty ?? false)
                          TextSpan(
                            text: receivedAction.body!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                      ]))
                ],
              ),
            ),
            Container(
              color: Colors.black12,
              padding: const EdgeInsets.all(20),
              width: MediaQuery.of(context).size.width,
              child: Text(receivedAction.toString()),
            ),
          ],
        ),
      ),
    );
  }
}