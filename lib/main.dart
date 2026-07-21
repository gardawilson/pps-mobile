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
import 'features/stock_opname_v2/view/so_v2_category_screen.dart';
import 'features/mapping_v2/view/mapping_v2_screen.dart';

const String appEnvironment = String.fromEnvironment(
  'APP_ENV',
  defaultValue: 'development',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final envFile = switch (appEnvironment) {
    'development' => '.env.development',
    'production' => '.env.production',
    _ => throw UnsupportedError(
      'APP_ENV tidak valid: "$appEnvironment". '
      'Gunakan "development" atau "production".',
    ),
  };

  await dotenv.load(fileName: envFile);
  await NetworkModeConfig.initialize();
  NetworkModeConfig.attachNetworkChangeListener();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StockOpnameViewModel()),
        ChangeNotifierProvider(create: (_) => StockOpnameDetailViewModel()),
        ChangeNotifierProvider(create: (_) => UserProfileViewModel()),
        ChangeNotifierProvider(
          create: (_) => LokasiViewModel(repository: LokasiRepository()),
        ),
        ChangeNotifierProvider(create: (_) => StockOpnameScanViewModel()),
        ChangeNotifierProvider(
          create: (_) => BlokViewModel(repository: BlokRepository()),
        ),
        ChangeNotifierProvider(create: (_) => BjJualListViewModel()),
        ChangeNotifierProvider(create: (_) => BjJualDetailViewModel()),
      ],
      child: MaterialApp(
        title: 'PPS Mobile',
        theme: ThemeData(primarySwatch: Colors.blue),
        initialRoute: '/',
        routes: {
          '/': (context) => const LoginScreen(),
          '/home': (context) => HomeScreen(),
          '/stockopname': (context) => StockOpnameListScreen(),
          '/stockopname-v2': (context) => const SoV2CategoryScreen(),
          '/mapping': (context) => LabelScreen(),
          '/mapping-v2': (context) => const MappingV2Screen(),
          '/bj-jual': (context) => const BjJualListScreen(),
        },
      ),
    );
  }
}
