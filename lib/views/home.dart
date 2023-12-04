import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:py/utils/const.dart' as cons;
import 'package:py/views/top.dart';
import 'package:py/views/stats.dart';
import 'dart:developer';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:py/views/home.dart';
import 'package:py/views/user.dart';
import 'dart:io';
import 'package:spotify/spotify.dart' as spotify;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:py/utils/singleton.dart';
import 'package:crypto/crypto.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:url_launcher/url_launcher_string.dart';

class home extends StatefulWidget {
  final String token;
  const home({required this.token, super.key});
  
  @override
  State<home> createState() => _registroState();
}

//Icono en la aplicacion que se vea bien

class _registroState extends State<home> {
  Singleton singleton = Singleton();
  Future<int>? _dataFuture;
  List<String>? idsongs;
  List<String>? songimages;
  List<String>? artistimagesl;
  List<String>? artistnamel;
  List<String>? artistdata;
  List<String>? playlistdata;
  Map<String, dynamic>? userdata;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _dataFuture = fetchdata(widget.token);
  }

  Future<int> fetchdata(token) async {
    setState(() {
      isLoading = true;
    });

    idsongs = await (getTopSongs(token));
    List<String> Ids = [];
    for (String id in idsongs!) {
      Ids.add(id.split('#')[1]);
    }
    artistdata = await getTopArtistsImages(token);
    songimages = await getSongImages(token, Ids);
    userdata = await getUserProfile(token);
    getAlbums(token);
    playlistdata = await getPlaylists(token);

    setState(() {
      isLoading = false;
    });

    log(playlistdata!.toString());
    log("hola");
    return songimages!.length;
  }

  Future<List<String>> getTopSongs(String accessToken) async {
    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/me/top/tracks?limit=5'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> items = data['items'] ;

      List<String> topSongs = [];
      for (var item in items) {
        final String songName = item['name']+ "#"+item['id'];
        topSongs.add(songName);
      }
      log(topSongs.toString());
      return topSongs;
    } else {
      throw Exception('Error al obtener las canciones principales');
    }
  }
  Future<List<String>> getSongImages(String accessToken, List<String> songIds) async {
    List<String> imageUrls = [];

    for (var songId in songIds) {
      final response = await http.get(
        Uri.parse('https://api.spotify.com/v1/tracks/$songId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> images = data['album']['images'];

        if (images.isNotEmpty) {
          final String imageUrl = images.first['url'];
          
          imageUrls.add(imageUrl);
        }
      }
    }
    log(imageUrls.length.toString());
    log(imageUrls[1].toString());
    return imageUrls;
  }
  Future<List<String>> getPlaylists(String accessToken) async {
    List<String> PlayListList = [];
    try {
      final response = await http.get(
        Uri.parse('https://api.spotify.com/v1/me/playlists'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Obtener las primeras 5 playlists
        final List<dynamic> playlists = data['items'].take(5).toList();

        // Iterar sobre cada playlist e imprimir el nombre y la imagen
        playlists.forEach((playlist) {
          final String namelll = playlist['name'];
          final String imageUrlll = playlist['images'][0]['url'];
          PlayListList.add(namelll+"#"+imageUrlll);
          log(PlayListList[0]);
          log('Nombre de la playlist: $namelll');
          log('URL de la imagen: $imageUrlll');
          log('---');
        });
        return PlayListList;
      } else {
        log('Error al obtener las playlists: ${response.statusCode}');
      }
    } catch (e) {
      log('Error: $e');
    }
    return PlayListList;
  }
  Future<Map<String, dynamic>> getUserProfile(String accessToken) async {
    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/me'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> userProfile = json.decode(response.body);
      log(userProfile.toString());
      log(userProfile['display_name']);
      return userProfile;
    } else {
      throw Exception('Error al obtener datos del perfil');
    }
  }
  Future<void> getAlbums(String token) async {
    final url = 'https://api.spotify.com/v1/me/albums?limit=5';

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      List<Map<String, dynamic>> albums = [];

      for (var item in data['items']) {
        final Map<String, dynamic> albumData = {
          'nombre': item['album']['name'],
          'imagen': item['album']['images'][0]['url'],
        };
        albums.add(albumData);
      }

      // Imprimir los nombres e imágenes de los álbumes
      for (var album in albums) {
        log('Nombre del álbum: ${album['nombre']}');
        log('URL de la imagen: ${album['imagen']}');
        log('---');
      }
    } else {
      log('Error al obtener los álbumes. Código de estado: ${response.statusCode}');
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
        final String artistName = item['name'];
        final List<dynamic> images = item['images'];
        
        // Obtener la URL de la imagen del primer elemento (podría haber múltiples tamaños)
        if (images.isNotEmpty) {
          final String imageUrl = images[0]['url'];
          log('Artista: $artistName, Imagen: $imageUrl');
          meta.add(artistName+"#"+imageUrl);

        }
      }
      return meta;
    } else {
      log("no se pudo");
      throw Exception('Error al obtener los artistas principales');
    }
  }

 @override
  Widget build(BuildContext context) {
    int _selectedIndex = 0;
    final size = MediaQuery.of(context).size;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
         backgroundColor: singleton.dark_theme ? Colors.white : Colors.black,
        body: FutureBuilder<int>(
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
              // Resto del contenido cuando los datos están cargados
              return Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      isLoading
                          ? Container(
                              margin: EdgeInsets.only(top: 20),
                              child: CircularProgressIndicator(),
                            )
                          : Container(),
                          SizedBox(height: 45,),
                      Container(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 10.0,
                          children: [
                            Container(
                              width: size.width * 0.80,
                              child: Row(
                                children: [
                                  Text(
                                    'Welcome,',
                                    style: TextStyle(
                                      color: singleton.dark_theme ? Colors.black : Colors.white,
                                      fontSize: _calculateFontSize(size, 35),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    ' ' + userdata!['display_name'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: cons.green,
                                      fontSize: _calculateFontSize(size, 35),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: size.width * 0.80,
                              child: Row(
                                children: [
                                  Text(
                                    'Your ',
                                    style: TextStyle(
                                      color: singleton.dark_theme ? Colors.black : Colors.white,
                                      fontSize: _calculateFontSize(size, 35),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    'Weekly',
                                    style: TextStyle(
                                      color: cons.green,
                                      fontSize: _calculateFontSize(size, 35),
                                      decoration: TextDecoration.underline,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: size.width * 0.80,
                              child: Text(
                                'Stats',
                                style: TextStyle(
                                  color: singleton.dark_theme ? Colors.black : Colors.white,
                                  fontSize: _calculateFontSize(size, 35),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: 20),
                    Container(
                      width: size.width * 0.80,
                      child: Text('Your top artists.', style: TextStyle(color: singleton.dark_theme ? Colors.black : Colors.white, fontSize: 35)),
                    ),
                    SizedBox(height: 20,),
                    Container(
                      width: size.width * 0.80,
                      height: size.height * 0.15,
                      decoration: BoxDecoration(
                        border: Border.all(color: cons.green),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(width: size.width*0.02,),
                          Expanded(
                            child: (artistdata!.length>0) ? ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: artistdata!.length,
                              itemBuilder: (BuildContext context, int index) {
                                return Card(
                                  child: Row(
                                    children: [
                                      Container(
                                        width: size.width * 0.2,
                                        height: size.height * 0.13,
                                        child: CircleAvatar(
                                          backgroundImage: Image.network(artistdata![index].split("#")[1],fit: BoxFit.cover,).image,
                                          radius: size.width*0.1,
                                        ),
                                      ),
                                      SizedBox(width: 4.0),
                                      Container(
                                        width: size.width * 0.3,
                                        height: size.height * 0.13,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                              artistdata![index].split("#")[0], style: TextStyle(color: Colors.black, fontSize: 20)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ) : Container()
                          
                          ),
                        SizedBox(width: size.width*0.02,),
                        ],                
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      width: size.width * 0.80,
                      child: Text('Your top sounds.', style: TextStyle(color: singleton.dark_theme ? Colors.black : Colors.white, fontSize: 35)),
                    ),
                    SizedBox(height: 20,),
                    Container(
                      width: size.width * 0.80,
                      height: size.height * 0.15,
                      decoration: BoxDecoration(
                        border: Border.all(color: cons.green),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(width: size.width*0.02,),
                          Expanded(
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: idsongs!.length,
                              itemBuilder: (BuildContext context, int index) {
                                return Card(
                                  child: Row(
                                    children: [
                                      Container(
                                        width: size.width * 0.2,
                                        height: size.height * 0.13,
                                        child: CircleAvatar(
                                          backgroundImage: Image.network(songimages![index],fit: BoxFit.cover,).image,
                                          radius: size.width*0.1,
                                        ),
                                      ),
                                      SizedBox(width: 4.0),
                                      Container(
                                        width: size.width * 0.3,
                                        height: size.height * 0.13,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                              idsongs![index].split("#")[0], style: TextStyle(color: Colors.black, fontSize: 20)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        SizedBox(width: size.width*0.02,),
                        ],                
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      width: size.width * 0.80,
                      child: Text('Your top PlayLists.', style: TextStyle(color: singleton.dark_theme ? Colors.black : Colors.white, fontSize: 35)),
                    ),
                    SizedBox(height: 20,),
                    Container(
                      width: size.width * 0.80,
                      height: size.height * 0.15,
                      decoration: BoxDecoration(
                        border: Border.all(color: cons.green),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(width: size.width*0.02,),
                          Expanded(
                            child: (playlistdata!.length>0) ? ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: playlistdata!.length,
                              itemBuilder: (BuildContext context, int index) {
                                return Card(
                                  child: Row(
                                    children: [
                                      Container(
                                        width: size.width * 0.2,
                                        height: size.height * 0.13,
                                        child: CircleAvatar(
                                          backgroundImage: (playlistdata![index].split("#")[1]==null) ? AssetImage('assets/profile_image.jpg') : Image.network(playlistdata![index].split("#")[1],fit: BoxFit.cover,).image,
                                          radius: size.width*0.1,
                                        ),
                                      ),
                                      SizedBox(width: 4.0),
                                      Container(
                                        width: size.width * 0.3,
                                        height: size.height * 0.13,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                              playlistdata![index].split("#")[0], style: TextStyle(color: Colors.black, fontSize: 20)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ) : Container()
                          ),
                          SizedBox(width: size.width*0.02,), 
                        ],
                      )
                    )
                    ]
                  )
                )
              );
            }
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: const Color.fromARGB(232, 0, 0, 0),
          selectedItemColor: Color.fromARGB(255, 30, 241, 139),
          unselectedItemColor: Color.fromARGB(165, 241, 239, 239),
          items: <BottomNavigationBarItem>[
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
          ],
          currentIndex: _selectedIndex,
          onTap: (int index) {
            setState(() {
              _selectedIndex = index;
              if (_selectedIndex == 0) {
              }
              if (_selectedIndex == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => stats(token: widget.token),
                  ),
                );
              }
              if (_selectedIndex == 2) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => top(token: super.widget.token),
                  ),
                );
              }
            });
          },
        ),
      ),
    );
  }
}

double _calculateFontSize(Size screenSize, double baseFontSize) {
  // Ajustar el tamaño de la fuente según el ancho de la pantalla
  if (screenSize.width < 420) {
    return baseFontSize * 0.75;
  } else if (screenSize.width < 450) { 
    return baseFontSize * 0.8;
  } else if (screenSize.width < 300) {
    return baseFontSize * 0.5;
  } else {
    return baseFontSize;
  }
}