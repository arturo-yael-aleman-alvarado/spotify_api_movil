import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:py/utils/const.dart' as cons;
import 'package:py/views/home.dart';
import 'package:py/views/stats.dart';
import 'package:py/views/user.dart';
import 'package:http/http.dart' as http;
import 'package:py/utils/singleton.dart';
class top extends StatefulWidget {
  final String token;
  const top({required this.token,super.key});
 
  @override
  State<top> createState() => _topState();
}
 
//Icono en la aplicacion que se vea bien
 
class _topState extends State<top> {
  Singleton singleton = Singleton();
  List<String> topSongs = [];
  List<String> topArtists = [];
  List<String> topSongImages = [];
  List<String> recommendedSongs = [];
  List<String> recommendedSongImages = [];
  List<String> recommendedArtists = [];
  List<String> recommendedArtistsImages = [];
  bool isLoading = true;
  bool artist = false;
 
  @override
  void initState() {
    super.initState();
    fetchTopSongs(widget.token);
  }
 
  Future<void> fetchTopSongs(String token) async {
    await getTopSongs(token);
    await getRecommendations(token);
    await getTopArtistsImages(widget.token);
    await getRecommendationsArtist(widget.token);
    await getArtistsInfo(token);
  }
 
 Future<void> getTopSongs(String token) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.spotify.com/v1/me/top/tracks?limit=5'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
 
      if (response.statusCode == 200) {
        final List<dynamic>? tracks = json.decode(response.body)['items'];
 
        if (tracks != null) {
          topSongs = tracks.map<String>((track) => track['id']).toList();
          topSongImages =
              tracks.map<String>((track) => track['album']['images'][0]['url']).toList();
 
          setState(() {
            topSongs;
            
          });
 
          // Imprimir los valores
          log('Top Songs: $topSongs');
          print('Top Song Images: $topSongImages');
        } else {
          // Manejar el caso donde tracks es null, si es necesario
        }
      } else {
        throw Exception('Error al obtener las canciones principales');
      }
    } catch (e) {
      log('Error fetching recommendations: $e'); // Agrega más detalles al mensaje de registro

    }
  }
 
 Future<List<String>> getTopArtistsImages(String accessToken) async {
  List<String> meta = [];

  final response = await http.get(
    Uri.parse('https://api.spotify.com/v1/me/top/artists?limit=5'),
    headers: {
      'Authorization': 'Bearer $accessToken',
    },
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> data = json.decode(response.body);
    final List<dynamic> items = data['items'];

    for (var item in items) {
      meta.add(item['id']);
    }
    log('ArtistasIds: $meta');
    setState(() {
      topArtists = meta;
    });
    return meta;
  } else {
    log("no se pudo");
    throw Exception('Error al obtener los artistas principales');
  }
}

 Future<void> getRecommendations(String token) async {
    try {
      log(topSongs.toString());
      final response = await http.get(
        Uri.parse('https://api.spotify.com/v1/recommendations?limit=5&seed_tracks=${topSongs.join(",")}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      print('URL de la solicitud: ${Uri.parse('https://api.spotify.com/v1/recommendations?limit=10&seed_tracks=${topSongs.join(",")}')}');
 
      if (response.statusCode == 200) {
        final List<dynamic>? tracks = json.decode(response.body)['tracks'];
 
        if (tracks != null) {
          recommendedSongs = tracks.map<String>((track) => track['name']).toList();
          recommendedSongImages =
              tracks.map<String>((track) => track['album']['images'][0]['url']).toList();
     List<String> artistNames = tracks.map<String>((track) => track['album']['artists'][0]['id']).toList();
      log("artistas id: $artistNames");
      setState(() {
        topArtists=artistNames;
      });
    

    // Iterar a través de cada track para obtener información del artista

    // Ahora, las listas artistNames y artistImages contienen la información del artista
    print('Nombres de artistas: $artistNames');
 
          // Imprimir los valores
          print('Recommended Songs: $recommendedSongs');
          print('Recommended Song Images: $recommendedSongImages');
        } else {
          // Manejar el caso donde tracks es null, si es necesario
        }
      } else {
        throw Exception('Error al obtener las recomendaciones');
      }
    } catch (e) {
      log('Error fetching recommendations: $e'); // Agrega más detalles al mensaje de registro

    }
  }
 
 Future<void> getRecommendationsArtist(String token) async {
    try {
      log('hola: $topArtists');
      final response = await http.get(
        Uri.parse('https://api.spotify.com/v1/recommendations?limit=5&seed_artists=${topArtists.join(",")}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      print('URL de la solicitud: ${Uri.parse('https://api.spotify.com/v1/recommendations?limit=10&seed_artists=${topArtists.join(",")}')}');
 
      if (response.statusCode == 200) {
        final List<dynamic>? tracks = json.decode(response.body)['tracks'];
 
        if (tracks != null) {
          recommendedArtists = tracks.map<String>((track) => track['name']).toList();
          recommendedArtistsImages =
              tracks.map<String>((track) => track['images'][0]['url']).toList();
 
          setState(() {
            isLoading = false;
          });
 
          // Imprimir los valores
          print('Recommended Artists: $recommendedArtists');
          print('Recommended Recommendedartist: $recommendedArtistsImages');
        } else {
          // Manejar el caso donde tracks es null, si es necesario
        }
      } else {
        throw Exception('Error al obtener las recomendaciones');
      }
    } catch (e) {
      log('Error fetching recommendations: $e'); // Agrega más detalles al mensaje de registro
      setState(() {
        isLoading = false;
      });
    }
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
        String name = data['name'];
        String imageUrl = data['images'][0]['url'];
        ra.add(name);
        raim.add(imageUrl);
        log("nombre del artista recomendado: $name");
        
      } else {
        print('Error al obtener información del artista $artistId');
      }
    }

    // Actualiza la interfaz gráfica después de obtener la información
    setState(() {
      recommendedArtists=ra;
      recommendedArtistsImages=raim;
    });
    return 1;
  }


  @override
  Widget build(BuildContext context) {
    int _selectedIndex = 2;
    final size = MediaQuery.of(context).size;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: singleton.dark_theme ? Colors.white : Colors.black,
        body: SingleChildScrollView( // Agrega SingleChildScrollView aquí
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: size.width * 0.95,
                  height: size.height * 0.10,
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
                          Text(
                            'Top Recommended',
                            style: TextStyle(color: !singleton.dark_theme ? cons.white : cons.black, fontSize: 20),
                          ),
                          IconButton(
                            icon: Icon(Icons.person, color: !singleton.dark_theme ? cons.white : cons.black),
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => user(tooken: super.widget.token,)));
                            },
                          ),
                        ],
                      ),

                    ],
                  ),
                ),
                SizedBox(width: size.width*1,
                height: size.height*0.04),
                Container(
                  width: size.width * 0.95,
                  height: size.height * 0.10,
                  child: Row(crossAxisAlignment: CrossAxisAlignment.center
                  ,mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: size.width * 0.4,
                      height: size.height * 0.10,
                      alignment: Alignment.center,
                      child: Column(
                        children:[
                          InkWell(
onTap: () {
  setState(() {
    artist = false;
  });
},
                          child:
                          Text(
                            'Tracks',
                            style: TextStyle(color: !singleton.dark_theme ? ((artist==false) ? cons.green : cons.white) : ((artist) ? cons.green :Colors.grey) , fontSize: 20),
                          ),),
                          SizedBox(width: 8), // Ajusta el espacio entre el texto y la línea
                          Container(
                            width: size.width * 0.2,
                            height: 1, // Ajusta el grosor de la línea
                            color: !singleton.dark_theme ? ((artist==false) ? cons.green : cons.white) : ((artist) ? cons.green :Colors.grey),
                          ),
                        ]
                      ),
                    ),              
                    Container(
                      width: size.width * 0.4,
                      height: size.height * 0.10,
                      alignment: Alignment.center,
                      child: Column(
                        children:[
                          InkWell(
onTap: () {
  setState(() {
    artist = true;
  });
}

                            ,

                            child:
                          Text(
                            'Artists',
                            style: TextStyle(color: !singleton.dark_theme ? ((artist) ? cons.green : cons.white) : ((artist) ? cons.green :Colors.grey), fontSize: 20),
                          ),
                          ),
                          SizedBox(width: 8), // Ajusta el espacio entre el texto y la línea
                          Container(
                            width: size.width * 0.2,
                            height: 1, // Ajusta el grosor de la línea
                            color: !singleton.dark_theme ? ((artist) ? cons.green : cons.white) : ((artist) ? cons.green :Colors.grey),
                          ),
                        ]
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(height: size.height * 0.02),
              Container(
              width: size.width * 0.95,
              height: size.height * 0.63,
              child: isLoading
                ? Center(child: CircularProgressIndicator()) // Indicador de carga
                : (artist==false) ? ListView.builder(
                    itemCount: recommendedSongs!.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Container(
                        width: size.width * 0.80,
                        height: size.height * 0.15,
                        decoration: BoxDecoration(
                          border: Border.all(color: cons.green),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: size.width * 0.3,
                              height: size.height * 0.13,
                              child: CircleAvatar(
                                backgroundImage: NetworkImage(recommendedSongImages ! [index]),
                                radius: 50,
                              ),
                            ),
                            Container(
                              width: size.width * 0.3,
                              height: size.height * 0.13,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(recommendedSongs ! [index], style: TextStyle(color: !singleton.dark_theme ? cons.white : cons.black, fontSize: 20)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ) : ListView.builder(
                    itemCount: recommendedArtists!.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Container(
                        width: size.width * 0.80,
                        height: size.height * 0.15,
                        decoration: BoxDecoration(
                          border: Border.all(color: cons.green),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: size.width * 0.3,
                              height: size.height * 0.13,
                              child: CircleAvatar(
                                backgroundImage: NetworkImage(recommendedArtistsImages ! [index]),
                                radius: 50,
                              ),
                            ),
                            Container(
                              width: size.width * 0.3,
                              height: size.height * 0.13,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(recommendedArtists ! [index], style: TextStyle(color: !singleton.dark_theme ? cons.white : cons.black, fontSize: 20)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ) , 
                
                ),
                Container(
                  width: size.width * 0.95,
                  height: size.height * 0.0,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                    ],
                  ),
                ),
                SizedBox(height: size.height * 0.01),
              ],
            ),
          ),
        ),
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
                Navigator.push(context, MaterialPageRoute(builder: (context) => home(token: super.widget.token,)));
              }
              if(_selectedIndex==1){
                Navigator.push(context, MaterialPageRoute(builder: (context) => stats(token: super.widget.token)));
              }
              if(_selectedIndex==2){                
              }
            });
          },
        ),
      ),
    );
  }
}
