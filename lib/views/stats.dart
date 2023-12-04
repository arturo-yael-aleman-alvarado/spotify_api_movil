import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:py/utils/const.dart' as cons;
import 'package:py/views/home.dart';
import 'package:py/views/top.dart';
import 'package:py/views/user.dart';
import 'package:py/views/stats.dart';
import 'dart:developer';
import 'dart:convert';
import 'dart:io';
import 'package:spotify/spotify.dart' as spotify;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:py/utils/singleton.dart';
import 'package:py/utils/const.dart';
import 'package:crypto/crypto.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:url_launcher/url_launcher_string.dart';
class stats extends StatefulWidget {
  final String token;
  
  const stats({required this.token,super.key});

  @override
  State<stats> createState() => _statsState();
}

class _statsState extends State<stats> {
  String topGenre = "";
  int frequency = 0;
  int energetic = 0;
  int relaxed = 0;
  int dayscalc=30;
  int singeable = 0;
  int danceable = 0;
  Singleton singleton = Singleton();
  List<String>? topgenres;
  double? hours;
  int? tracks;
  List<String> topArtists = [];
  Future<double>? _dataFuture;
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    
    _dataFuture = fetchdata(widget.token);
  }
 Future<double> fetchdata(token) async {
 await totalhours(token);
 int yo = await getArtistsInfo(token);
  return 1;
}

 Future<int> getArtistsInfo(token) async {
    List<String> ra=[];
    List<String> raim=[];
    for (String artistId in topArtists) {
      final response = await http.get(
        Uri.parse('https://api.spotify.com/v1/artists/$artistId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data!=null && data['genres']!=null && (data['genres'] as List).isNotEmpty){
        String name =  data['genres'][0];
         List<String> words = name.split(' ');
         ra+=words;
        log("nombre del artista recomendado: $name");
        }
        
        
      } else {
        print('Error al obtener información del artista $artistId');
      }
    }
    log("generos escuchados: $ra");
  Map<String, int> frecuencia = {};

  // Iterar sobre la lista y contar la frecuencia de cada palabra
  for (String palabra in ra) {
    frecuencia[palabra] = (frecuencia[palabra] ?? 0) + 1;
  }

  // Encontrar la palabra más repetida y su frecuencia
  String palabraMasRepetida = "";
  int maxFrecuencia = 0;

  frecuencia.forEach((palabra, frec) {
    if (frec > maxFrecuencia) {
      maxFrecuencia = frec;
      palabraMasRepetida = palabra;
    }
  });

  // Imprimir resultados
  log("Palabra más repetida: $palabraMasRepetida");
  log("Frecuencia: $maxFrecuencia veces");
    int contador = 0;

  for (String elementoABuscar in singleton.danceable) {
    for (String elementoLista in ra) {
      if (elementoLista == elementoABuscar) {
        contador++;
      }
    }
  }
  int contador2=0;
  for (String elementoABuscar in singleton.energetics) {
    for (String elementoLista in ra) {
      if (elementoLista == elementoABuscar) {
        contador2++;
      }
    }
  }
  int contador3=0;
  for (String elementoABuscar in singleton.singables) {
    for (String elementoLista in ra) {
      if (elementoLista == elementoABuscar) {
        contador3++;
      }
    }
  }
  int contador4=0;
  for (String elementoABuscar in singleton.relaxed) {
    for (String elementoLista in ra) {
      if (elementoLista == elementoABuscar) {
        contador4++;
      }
    }
  }
  log("$contador2 de tus canciones son energetics");
  log("$contador3 de tus canciones son cantables");
  log("$contador4 de tus canciones son relaxed");
  log("$contador de tus canciones son danceables");
  int total = contador+contador2+contador3+contador4;
  setState(() {
    relaxed = ((contador4/total)*100).toInt();
    singeable = ((contador3/total)*100).toInt();
    danceable = ((contador/total)*100).toInt();
    energetic = ((contador2/total)*100).toInt();
    topGenre = palabraMasRepetida;
    frequency = maxFrecuencia;
  });
    return 1;
  }

Future<double> totalhours(token) async {
  final DateTime now = DateTime.now();
  final DateTime fourWeeksAgo = now.subtract(Duration(days: dayscalc));
  List<String> genres = [];
  final String endpoint = 'https://api.spotify.com/v1/me/player/recently-played?limit=50&after=${fourWeeksAgo.toIso8601String()}';

  final http.Response response = await http.get(
    Uri.parse(endpoint),
    headers: {'Authorization': 'Bearer $token'},
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> data = json.decode(response.body);
    final List<dynamic> items = data['items'];
    List<String> idsa=[];
    double totalHours = 0;
    int totaltracks = 0;
    for (var item in items) {
      final int durationMs = item['track']['duration_ms'];
      final String generos= item['track']['artists'][0]['id'] ?? "";
      idsa.add(generos);
      totaltracks +=1;
      final double durationHours = durationMs / (1000 * 60 * 60); // Convertir a horas
      totalHours += durationHours;
    }
    setState(() {
      isLoading = false;
      topArtists = idsa; 
    });
    log('Horas totales escuchadas en las últimas 4 semanas: $totalHours');
    setState(() {
     hours=totalHours;
     tracks = totaltracks;
    });
    return totalHours;
  } else {
    
    log('Error al obtener el historial de reproducción: ${response.statusCode}');
    return 0;
  }

}

Future<List<Map<String, dynamic>>> getRecentTracks(String accessToken) async {
  final response = await http.get(
    Uri.parse('https://api.spotify.com/v1/me/player/recently-played?limit=200'),
    headers: {'Authorization': 'Bearer $accessToken'},
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> data = json.decode(response.body);
    return List<Map<String, dynamic>>.from(data['items']);
  } else {
    throw Exception('Error al obtener las últimas canciones escuchadas');
  }
}

Future<List<String>> getGenresFromRecentTracks(String accessToken, List<Map<String, dynamic>> tracks) async {
  final List<String> genres = [];

  for (final track in tracks) {
    final genre = track['track'];
    print(genre);
    
  }

  return genres.toSet().toList(); // Eliminar duplicados
}

Future<Map<String, dynamic>> getArtistDetails(String accessToken, String artistId) async {
  final response = await http.get(
    Uri.parse('https://api.spotify.com/v1/artists/$artistId'),
    headers: {'Authorization': 'Bearer $accessToken'},
  );

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Error al obtener detalles del artista');
  }
}

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    int _selectedIndex = 1;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: singleton.dark_theme ? Colors.white : Colors.black,
        body: 
        FutureBuilder<double>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Muestra el indicador de progreso mientras se cargan los datos
              return Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.hasError) {
              // Manejar errores
              return Center(
                child: Text('Error al cargar datos'),
              );
            } else {
        return Center(
          child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
             children: <Widget>[
              Container(
                width: size.width * 0.95,
                height: size.height * 0.08,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        IconButton(
                          icon: Icon(Icons.search, color: singleton.dark_theme ? cons.white : cons.black),
                          onPressed: () {
                            // Acción al hacer clic 
                          },
                        ),
                        Container(
                          alignment: Alignment.center,
                width: size.height * 0.3,
                height: size.height * 0.10,
               child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                       children:<Widget>[ AutoSizeText(
                          'Stats',
              maxLines: 1, // Número máximo de líneas antes de truncar
              overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: singleton.dark_theme ? Colors.black : Colors.white, fontSize: 20),
                        ),
                    AutoSizeText(
                      (dayscalc==28 || dayscalc==30) ? 'past 4 Weeks' : 'past 6 months',
              maxLines: 1, // Número máximo de líneas antes de truncar
              overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: cons.gray,fontSize: 12),
                    ),
                        ]
                ),
                        ),

                        IconButton(
                          icon: Icon(Icons.person, color: singleton.dark_theme ? Colors.black : Colors.white),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => user( tooken: super.widget.token,)));
                          },
                        ),
                      ],
                    ),

                  ],
                ),
              ),
              Container(
                width: size.width * 0.95,
                height: size.height * 0.12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Container(
                      width: size.width * 0.45,
                      decoration: BoxDecoration(
                        color: cons.lightblack,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center, 
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(left: 20.0), 
                            child: Text(
                              (tracks==null) ? 'none' : tracks!.toString(),
                              style: TextStyle(color: cons.green, fontSize: 30, fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(height: size.height*0.00,),
                          Padding(
                            padding: const EdgeInsets.only(left: 20.0), 
                            child: AutoSizeText(
                              minFontSize: 6,
                              maxFontSize: 1000,
                              'Total tracks streamed',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: size.width * 0.45,
                      decoration: BoxDecoration(
                        color: cons.lightblack,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center, 
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(left: 20.0), 
                            child: Text(
                              (hours==null) ? 'none' : hours!.toStringAsFixed(2),
                              style: TextStyle(color: cons.green, fontSize: 30, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 20.0), 
                            child: AutoSizeText(
                              minFontSize: 6,
                              maxFontSize: 1000,
                              'Total hours streamed',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: size.height * 0.01),
              Container(
                width: size.width * 0.95,
                height: size.height * 0.35,
                decoration: BoxDecoration(
                  color: cons.lightblack,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0, top: 10.0), 
                      child: Text(
                        'Genres',
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(height: 2), 
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0), 
                      child: Text(
                        'Your top genre is $topGenre, appearing in $frequency of your artists',
                        style: TextStyle(color: cons.gray, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
//Poner codigo de la grafica-----------------------------------------------------------------
                  ],
                ),
              ),
              SizedBox(height: size.height * 0.01),
              Container(
                width: size.width * 0.95,
                height: size.height * 0.20,
                child:
                SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Container(
                      width: size.width * 0.40,
                      decoration: BoxDecoration(
                        color: cons.lightblack,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center, 
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(left: 20.0), 
                            child: Text(
                              '$energetic%',
                              style: TextStyle(color: cons.green, fontSize: 30, fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(height: 10,),
                          Padding(
                            padding: const EdgeInsets.only(left: 20.0), 
                            child: AutoSizeText(
                            minFontSize: 20,
                            maxFontSize: 40,
              maxLines: 2, // Número máximo de líneas antes de truncar
              overflow: TextOverflow.ellipsis,
                              'Of your tracks are energic',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10,),
                    Container(
                      width: size.width * 0.40,
                      decoration: BoxDecoration(
                        color: cons.lightblack,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center, 
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(left: 20.0), 
                            child: Text(
                              '$singeable%',
                              style: TextStyle(color: cons.green, fontSize: 30, fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(height: 10,),
                          Padding(
                            padding: const EdgeInsets.only(left: 20.0), 
                            child: AutoSizeText(
                              'Of your tracks are singeables',
                            minFontSize: 20,
                            maxFontSize: 40,
              maxLines: 2, // Número máximo de líneas antes de truncar
              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10,),
                    Container(
                      width: size.width * 0.40,
                      decoration: BoxDecoration(
                        color: cons.lightblack,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center, 
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(left: 20.0), 
                            child: Text(
                              '$danceable%',
                              style: TextStyle(color: cons.green, fontSize: 30, fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(height: 10,),
                          Padding(
                            padding: const EdgeInsets.only(left: 20.0), 
                            child: AutoSizeText(
                              'Of your tracks are danceable',
                            minFontSize: 20,
                            maxFontSize: 40,
              maxLines: 2, // Número máximo de líneas antes de truncar
              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10,),
                    Container(
                      width: size.width * 0.40,
                      decoration: BoxDecoration(
                        color: cons.lightblack,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center, 
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(left: 20.0), 
                            child: Text(
                              '$relaxed%',
                              style: TextStyle(color: cons.green, fontSize: 30, fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(height: 10,),
                          Padding(
                            padding: const EdgeInsets.only(left: 20.0), 
                            child: AutoSizeText(
                              'Of your tracks are relaxed',
                            minFontSize: 20,
                            maxFontSize: 40,
              maxLines: 2, // Número máximo de líneas antes de truncar
              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),

                    /*
                    Container(
                      width: size.width * 0.40,
                      decoration: BoxDecoration(
                        color: cons.lightblack,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center, 
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(left: 20.0), 
                            child: Text(
                              '17%',
                              style: TextStyle(color: cons.green, fontSize: 30, fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(height: 10,),
                          Padding(
                            padding: const EdgeInsets.only(left: 20.0), 
                            child: Text(
                              'Of your tracks are lively',
                              style: TextStyle(color: cons.white, fontSize: 25, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),*/
                  ],
                ),
              ),

              ),
              SizedBox(height: size.height * 0.01),
              Container(
                width: size.width * 0.95,
                height: size.height * 0.10,
                alignment: Alignment.center,
                child: 
                SingleChildScrollView(scrollDirection: Axis.horizontal,
                child:                 Column( 
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton(
                          onPressed: () async{
                            setState(() {
                              dayscalc=30;
                              _dataFuture=null;
                            });
                            _dataFuture = fetchdata(widget.token);

                          },
                          style: ElevatedButton.styleFrom(
                            primary: Colors.transparent, 
                            elevation: 0, 
                          ),
                          child: Text(
                             '4 Weeks',
                            style: TextStyle(
                              color: singleton.dark_theme ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async{
                            setState(() {
                              dayscalc=180;
                              _dataFuture=null;
                            });
                            _dataFuture = fetchdata(widget.token);

                          },
                          style: ElevatedButton.styleFrom(
                            primary: Colors.transparent, 
                            elevation: 0, 
                          ),
                          child: Text(
                            '6 Months',
                            style: TextStyle(
                              color: singleton.dark_theme ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async{
                            setState(() {
                              dayscalc=2;
                              _dataFuture=null;
                            });
                            _dataFuture = fetchdata(widget.token);

                          },
                          style: ElevatedButton.styleFrom(
                            primary: Colors.transparent, 
                            elevation: 0, 
                          ),
                          child: Text(
                            'Lifetime',
                            style: TextStyle(
                              color: singleton.dark_theme ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                ),
              ),
              SizedBox(height: size.height * 0.01),
            ],
          ),
          ),
        );
  }}),
      bottomNavigationBar: BottomNavigationBar(
          backgroundColor: const Color.fromARGB(232, 0, 0, 0),
          selectedItemColor: Color.fromARGB(255, 30, 241, 139),
          unselectedItemColor: Color.fromARGB(165, 241, 239, 239),
        items:  <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(

            icon: Icon(Icons.equalizer),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Top',
            
          ),

          /*BottomNavigationBarItem(
            backgroundColor: Colors.transparent,
            icon: Icon(Icons.music_note_sharp),
            label: 'Identity',
          ),*/
          /*BottomNavigationBarItem(
            backgroundColor: Colors.transparent,
            icon: Icon(Icons.person),
            label: 'Profile',
          ),*/ 
        ],
        currentIndex: _selectedIndex,
       
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
            if(_selectedIndex==0){
              Navigator.push(context, MaterialPageRoute(builder: (context) =>  home(token: super.widget.token,)));
            }
            if(_selectedIndex==1){
              
            }
            if(_selectedIndex==2){
              Navigator.push(context, MaterialPageRoute(builder: (context) => top(token: super.widget.token)));
            }
          });
        },
      ),

      ),
    );
  }
}