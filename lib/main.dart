import 'package:flutter/material.dart';
import 'package:pps_mobile/features/mapping/view/label_screen.dart';
import 'package:pps_mobile/shared/blok/blok_repository.dart';
import 'package:pps_mobile/shared/blok/blok_view_model.dart';
import 'package:pps_mobile/shared/lokasi/lokasi_repository.dart';
import 'package:pps_mobile/shared/lokasi/lokasi_view_model.dart';
import 'package:provider/provider.dart';
import 'features/login/view/login_screen.dart';
import 'features/stock_opname/view/stock_opname_list_screen.dart'; // Import DashboardScreen
import 'features/home/view/home_screen.dart';  // Pastikan path sesuai dengan file Anda
import 'features/stock_opname/view_model/stock_opname_list_view_model.dart'; // Import StockOpnameViewModel
import 'features/stock_opname/view_model/stock_opname_detail_view_model.dart'; // Import StockOpnameInputViewModel
import 'features/profile/view_model/user_profile_view_model.dart'; // Import UserProfileViewModel
import 'features/stock_opname/view_model/stock_opname_scan_view_model.dart'; // Import UserProfileViewModel
import 'package:flutter_dotenv/flutter_dotenv.dart';



Future<void> main() async {
  await dotenv.load(fileName: ".env");  // ✅ Aman & async-safe
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(  // Menggunakan MultiProvider untuk mengelola lebih dari satu provider
      providers: [
        ChangeNotifierProvider(create: (_) => StockOpnameViewModel()),  // Memberikan StockOpnameViewModel ke seluruh aplikasi
        ChangeNotifierProvider(create: (_) => StockOpnameDetailViewModel()),  // Menambahkan StockOpnameInputViewModel
        ChangeNotifierProvider(create: (_) => UserProfileViewModel()), // Menambahkan UserProfileViewModel
        ChangeNotifierProvider(create: (_) => LokasiViewModel(repository: LokasiRepository())),
        ChangeNotifierProvider(create: (_) => StockOpnameScanViewModel()),
        ChangeNotifierProvider(create: (_) => BlokViewModel(repository: BlokRepository())),
      ],
      child: MaterialApp(
        title: 'PPS Mobile',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => LoginScreen(),
          '/home': (context) => HomeScreen(),
          '/stockopname': (context) => StockOpnameListScreen(),
          '/mapping': (context) => LabelScreen(),
        },
      ),
    );
  }
}
