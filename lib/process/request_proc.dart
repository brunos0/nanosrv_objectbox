import 'dart:async';
//import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;

//No postman chamar: http://localhost:8080?q=bola
Future<Result> fetchPesq(String keyPesq) async {
  Map<String, String> headers = {
    "Access-Control-Allow-Origin": "*",
    'Content-Type': 'application/json',
    'Accept': '*/*'
  };

  Uri url = Uri.https("www.google.com", '/search', {'q': keyPesq});
  http.Response res = await http.get(
    url,
    headers: headers,
  );

  if (res.statusCode == 200) {
    //resposta Ok
    return Result(title: res.body);
  } else {
    //falha na resposta - verificar saida nesse caso posteriormente
    throw Exception(const Result(title: 'Falha ao retornar dados do Google.'));
  }
}

class Result {
  final String title;

  const Result({
    required this.title,
  });

  get gtitle {
    return title;
  }

  factory Result.fromJson(Map<String, dynamic> json) {
    return Result(
      title: json['title'],
    );
  }
}

Future<Map<String, String>> RequestProc(String keyPesq) async {
  late Result futurePesq;
  late Map<String, String> itensMap = {};

  futurePesq = await fetchPesq(keyPesq);
  final xmlDoc = parse(futurePesq.gtitle);

  //montar list com os dados do html
  List xmlElements = xmlDoc.getElementsByTagName('a');
  int nRep = xmlElements.length;

  for (int nVez = 0; nVez < nRep; nVez++) {
    if (xmlElements[nVez].outerHtml.toString().contains("<h3")) {
      String url = xmlElements[nVez].attributes["href"]!;
      if (url.contains("/url?q=")) {
        url = url.substring(7);
      }
      if (url.contains("&sa=")) {
        int nPos = url.indexOf("&sa=");
        url = url.substring(0, nPos);
      }

      String title = (parse(xmlElements[nVez].outerHtml.toString())
              .getElementsByTagName('h3'))
          .elementAt(0)
          .text;
      itensMap[url] = title;
    }
  }

  return itensMap;
  /*
  itensMap["Resultado"] =
      "Não foram encontrados resultados para o dado informado.\n"
      " Tente informar outra palavra na busca.";
  */
}
