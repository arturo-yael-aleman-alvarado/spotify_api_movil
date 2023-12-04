import 'dart:developer';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:py/utils/const.dart' as cons;
import 'package:py/views/home.dart';
import 'package:py/views/stats.dart';
import 'package:flutter/material.dart';
import 'package:py/views/home.dart';
import 'package:py/views/user.dart';
import 'dart:io';
import 'package:py/utils/singleton.dart';
import 'package:spotify/spotify.dart' as spotify;
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:crypto/crypto.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:url_launcher/url_launcher_string.dart';

class user extends StatefulWidget {
  
  final String tooken;
  const user({required this.tooken, super.key});
  
  @override
  State<user> createState() => _userState();
}

//Icono en la aplicacion que se vea bien

class _userState extends State<user> {
  late Future<int> userDataFuture;
  Singleton singleton = Singleton();
  void initState() {
    super.initState();
    userDataFuture = fetchdata( super.widget.tooken); 

  }
  Map<String,dynamic>? userdata;
   Future<int> fetchdata(token) async {
                                userdata = await getUserProfile(token);
                                setState(() {
                                  userdata;
                                });
                                return userdata!.length;
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

  @override
  Widget build(BuildContext context) {
  final size = MediaQuery.of(context).size;
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: singleton.dark_theme ? Colors.white : Colors.black,
      body: FutureBuilder(
        future: userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(height: 45,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: !singleton.dark_theme ? cons.white : cons.black),
                        onPressed: () {
                          setState(() {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => home( token: super.widget.tooken, )));
                          });
                        },
                      ),
                      Text(
                        'Profile',
                        style: TextStyle(color: !singleton.dark_theme ? cons.white : cons.black, fontSize: 20),
                      ),
                      IconButton(
                        icon: Icon(Icons.person, color: singleton.dark_theme ? cons.white : cons.black),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center, // Alinea en el centro horizontalmente
                      children: <Widget>[
                        SizedBox(height: size.height * 0.04),
                        CircleAvatar(
                          radius: size.width * 0.15,
                          backgroundImage: (userdata!['images'].length==0) ?  AssetImage('assets/profile_image.jpg') as ImageProvider : NetworkImage(userdata!['images'][0]['url']) as ImageProvider,
                        ),
                        SizedBox(height: size.height * 0.02),
                        SizedBox(height: 20),
                        Text(
                          userdata!['display_name'],
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: !singleton.dark_theme ? cons.white : cons.black),
                        ),
                        SizedBox(height: 10,),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            (userdata!['email']!=null) ? userdata!['email'] : 'No access to email',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: !singleton.dark_theme ? cons.white : cons.black),
                          ),
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                  SizedBox(height: 50,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(primary: Colors.green),
                        onPressed: () {
                          setState(() {
                            if (singleton.dark_theme == true) {
                              singleton.dark_theme = false;
                            } else {
                              singleton.dark_theme = true;
                            }
                          });
                        },
                        child: Text('Change theme', style: TextStyle(color: cons.white),),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // Detalles adicionales o estadísticas
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }
}