import 'package:flutter/material.dart';
//import 'package:objectbox/objectbox.dart';
//classes do objectbox
import 'package:erpsrv/objectbox.g.dart';
import 'package:path_provider/path_provider.dart';
import 'objectbox.dart';
import 'package:path/path.dart';
//import 'models/person.dart';
import 'models/usuario.dart';
import 'models/grpusuario.dart';
//classes do servidor Rest
//import 'dart:ui';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'dart:convert';
//import 'package:html/parser.dart';
//import 'package:http/http.dart' as http;
import 'dart:async';
import 'process/request_proc.dart';
//classes pra criptografar
//import 'package:crypto/crypto.dart';
//import 'dart:convert';
import 'package:encrypt/encrypt.dart' as e;
import 'package:flutter/services.dart' show rootBundle;

late Store _store;
String ipNum = '';
String portNum = '';
void main() {
  /// Provides access to the ObjectBox Store throughout the app.
  late ObjectBox objectbox;

  Future<void> main() async {
    // This is required so ObjectBox can get the application directory
    // to store the database in.
    WidgetsFlutterBinding.ensureInitialized();

    objectbox = await ObjectBox.create();
  }

  runApp(const MyApp());
}

restSrv(fn) async {
  var handler =
      const Pipeline().addMiddleware(logRequests()).addHandler(_echoRequest);
  ipNum = await rootBundle.loadString('assets/ip.config');
  portNum = await rootBundle.loadString('assets/port.config');
  //pra debug rode tudo ou no windows ou tudo no mesmo dispositivo android

  var server = await shelf_io.serve(handler, ipNum, int.parse(portNum));
  fn();
  server.autoCompress = true; // Enable content compression
}

//exemplo de chamada do endpoint sem encriptação
//http://localhost:8080?vldusr?user=admin?pswd=1234  --vldusr
Future<Response> _echoRequest(Request request) async {
  final url = request.url.toString();
  var key = e.Key.fromUtf8('GDaDF6f0U40Je8XSw1R-13run0H0rv@t');
  final encrypter = e.Encrypter(e.AES(key));
  final iv = e.IV.fromUtf8('13run0H0rv@t'); //fromSecureRandom(16);

  //final e.Encrypted encrypted = encrypter.encrypt('vldusr?user=admin?pswd=123', iv: iv);

  try {
    final decrypted = encrypter.decrypt64(url, iv: iv);
    List urlData = decrypted.split('?'); //futuramente usar o corpo do request
    String rota = urlData[0];
    //validar rota depois
    if (rota == 'vldusr') {
      var user = urlData[1].split('=')[1];
      var pswd = urlData[2].split('=')[1];
      var box = _store.box<Usuario>();

      var query = box
          .query(Usuario_.nome.equals(user) &
              Usuario_.senha.equals(pswd)) //poderia ser login
          /*.order(Person_.name)*/
          .build();
      final usr = query.find();
      query.close();
      if (usr.isEmpty) {
        throw Exception('Acesso negado.');
      }
    } else {
      throw Exception('rota errada.');
    }

    String keyPesq = 'milho';
    Map<String, String> result = {};
    result = await RequestProc(keyPesq);

    return Response.ok(json.encode(result));
  } on FormatException catch (exception) {
    return Response.forbidden(exception.toString().substring(17));
  } on Exception catch (exception) {
    return Response.forbidden(exception.toString().substring(11));
  } catch (error) {
    return Response.badRequest();
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  void fn() => setState(() {});

  @override
  Widget build(BuildContext context) {
    restSrv(fn); //inicializo o serviço na porta configurada
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyHomePage(title: 'Nano Erp Server by Bruno Horvat'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //int _counter = 0;

  //late Store _store;
  bool storeInicializado = false;

  //String nome = ''; //people.
  //String tpPessoa = '';
  //int cpfCnpj = 0;

  @override
  void initState() {
    super.initState();

    getApplicationDocumentsDirectory().then((dir) {
      _store = Store(
        getObjectBoxModel(),
        directory: /*'${dir.path}/objectbox'*/
            join(dir.path, 'objectbox'),
      );
      //definindo usuario admin inicial - talvez melhor definir em objectbox...

      final grpBox = _store.box<GrpUsuario>();
      final queryGrp = grpBox.query(GrpUsuario_.tpGrupo.equals('1')).build();

      final results = queryGrp.find();
      queryGrp.close();
      if (results.isEmpty) {
        grpBox.put(GrpUsuario(tpGrupo: '1', nome: 'Administrador'));
        grpBox.put(GrpUsuario(tpGrupo: '2', nome: 'Usuario'));
        grpBox.put(GrpUsuario(tpGrupo: '3', nome: 'consulta'));
      }

      final userBox = _store.box<Usuario>();
      final queryuser = userBox.query(Usuario_.tpGrupo.equals('1')).build();
      if (results.isEmpty) {
        userBox.put(Usuario(tpGrupo: '1', nome: 'admin', senha: '123'));
        userBox.put(Usuario(tpGrupo: '2', nome: 'usuario', senha: 'abc'));
        userBox.put(Usuario(tpGrupo: '3', nome: 'consulta', senha: 'consulta'));
      }

      setState(() {
        storeInicializado = true;
      });
    });
  }

  @override
  void dispose() {
    //_store.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Nano Erp Server by Bruno Horvat'),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Text(
                ipNum == ''
                    ? "Servidor inicializando. Aguarde o processo antes de usar.\n\n"
                    : "Servidor iniciado em $ipNum na porta $portNum\n\n",
                style:
                    const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const Text(
              "Minimize o aplicativo para mantê-lo \n rodando em segundo plano.\n\n",
              style: TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const Text(
              "Atenção!\nEncerrar o aplicativo causará a \n interrupção do serviço.",
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ));
  }
}
