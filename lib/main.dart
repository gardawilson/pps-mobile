import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pps_mobile/features/mapping/view/label_screen.dart';
import 'package:pps_mobile/shared/blok/blok_repository.dart';
import 'package:pps_mobile/shared/blok/blok_view_model.dart';
import 'package:pps_mobile/shared/lokasi/lokasi_repository.dart';
import 'package:pps_mobile/shared/lokasi/lokasi_view_model.dart';
import 'package:provider/provider.dart';

import 'core/network/network_mode_config.dart';
import 'features/home/view/home_screen.dart';
import 'features/login/view/login_screen.dart';
import 'features/profile/view_model/user_profile_view_model.dart';
import 'features/bj_jual/view/bj_jual_list_screen.dart';
import 'features/bj_jual/view_model/bj_jual_detail_view_model.dart';
import 'features/bj_jual/view_model/bj_jual_list_view_model.dart';
import 'features/stock_opname/view/stock_opname_list_screen.dart';
import 'features/stock_opname/view_model/stock_opname_detail_view_model.dart';
import 'features/stock_opname/view_model/stock_opname_list_view_model.dart';
import 'features/stock_opname/view_model/stock_opname_scan_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await NetworkModeConfig.initialize();
  NetworkModeConfig.attachNetworkChangeListener();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StockOpnameViewModel()),
        ChangeNotifierProvider(create: (_) => StockOpnameDetailViewModel()),
        ChangeNotifierProvider(create: (_) => UserProfileViewModel()),
        ChangeNotifierProvider(create: (_) => LokasiViewModel(repository: LokasiRepository())),
        ChangeNotifierProvider(create: (_) => StockOpnameScanViewModel()),
        ChangeNotifierProvider(create: (_) => BlokViewModel(repository: BlokRepository())),
        ChangeNotifierProvider(create: (_) => BjJualListViewModel()),
        ChangeNotifierProvider(create: (_) => BjJualDetailViewModel()),
      ],
      child: MaterialApp(
        title: 'PPS Mobile',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const LoginScreen(),
          '/home': (context) => HomeScreen(),
          '/stockopname': (context) => StockOpnameListScreen(),
          '/mapping': (context) => LabelScreen(),
          '/bj-jual': (context) => const BjJualListScreen(),
        },
      ),
    );
  }
}
