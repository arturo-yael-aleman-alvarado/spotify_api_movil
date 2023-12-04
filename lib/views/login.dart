import 'dart:developer';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:py/views/home.dart';
import 'dart:io';
import 'package:spotify/spotify.dart' as spotify;
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:crypto/crypto.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:url_launcher/url_launcher_string.dart';
class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}
final String scope = 'user-top-read user-library-read user-read-email user-read-recently-played';
const String clientId = 'bbb255f4913a438bbe697d0c7177671d';
const String clientSecret = '82a31d1531f14d59a7eb832061fe41db';
const String redirectUri = 'http://localhost/ejerciciosparcial3/spotify.php';
final _server = HttpServer;
class _LoginState extends State<Login> {
  @override
  void initState() {
    super.initState();
    

  }

  Future<String> _getAuthorizationCode() async {
    final authUrl = 'https://accounts.spotify.com/authorize?'
        'client_id=$clientId&'
        'redirect_uri=$redirectUri&'
        'scope=$scope&'
        'response_type=code';

    if (await canLaunchUrlString(authUrl)) {
      await launchUrlString(authUrl,
      webViewConfiguration:WebViewConfiguration(
        enableDomStorage: true,
        enableJavaScript: true,
        
      )
      );
    } else {
      throw 'No se pudo lanzar la URL de autorización';
    }

    // Esperar el redireccionamiento y obtener el código de autorización
    // (Deberás implementar lógica adicional para manejar el redireccionamiento)
    final String tokenEndpoint = 'https://accounts.spotify.com/api/token';
    final http.Response response = await http.post(
    Uri.parse(tokenEndpoint),
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Authorization': 'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}',
    },
    body: {
      'grant_type': 'authorization_code',
      'code': 'AQDCasgbHgGG2K75qaxfXIU2HRusjfxTAYZzj4t3GuvE3CckrA8EWgX_O3kG9Dxcp977IeMBAkvRhwFc6FrKIc2zpeoKirc2W4dOBOnqAbh8_ZDU1gDHkMny-SEURF6QjjTg_FCvMbW-9R6D88rz5yZfm0i-HITbcrNBZDas-yTfPGy8kwDWntt_I45L-pd5yNt8jlWyzOvGDKi_fTv85WpFcXKHEK59j9VHhzt32jSXW2YPxGVMSp9YOHQDJJ2XrzPRSkjudo9c50JzsavRbqTyzENaFysNQteuy-3OfzHK',
      'redirect_uri': redirectUri,
    },
  );
Map<String, dynamic> responseData = json.decode(response.body);

log('Token de Acceso: ${responseData['access_token']}');
log('Token de Actualización: ${responseData['refresh_token']}');
    return (responseData['access_token']==null) ? 'hola' :responseData['access_token'] ;
  }
  void authenticateWithSpotify() async {
    String clientId = '88ea6c48037c435085bdaf8096ce4d5d';
    String redirectUri = 'http://localhost:5173/callback';
    String scope = 'user-read-private user-read-email';

    String url = 'https://accounts.spotify.com/authorize?'
        'response_type=code'
        '&client_id=$clientId'
        '&scope=$scope'
        '&redirect_uri=$redirectUri';

    try {
      // Open a web page to authenticate with Spotify
      final result = await FlutterWebAuth.authenticate(
        url: url,
        callbackUrlScheme: redirectUri,
      );

      // Handle the result (access token, code, etc.)
      print(result);
      log(result);
    } catch (e) {
      // Handle errors
      print('Error: $e');
    }
  }
  Future<String> getSpotifyAccesToken()async {
    final credentials = '$clientId:$clientSecret';
  final base64Encoded = base64.encode(utf8.encode(credentials));

  final response = await http.post(
    Uri.parse('https://accounts.spotify.com/api/token'),
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Authorization': 'Basic $base64Encoded',
    },
    body: {
      'grant_type': 'client_credentials',
    },
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> data = json.decode(response.body);
    final String accessToken = data['access_token'];
    log(accessToken);
    print(accessToken);
    return accessToken;
  } else {
    throw Exception('Error al obtener el token de acceso');
  }
    
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
  log(imageUrls[0].toString());
  return imageUrls;
}
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF1E1E1E),
      body: SingleChildScrollView(
        child: SizedBox(
          height: screenSize.height, // Set a fixed height
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Center and space evenly
            children: [
              // First Row - Logo
              Image.asset(
                'assets/logo.png',
                width: 150,
                height: 100,
              ),
              // Second Row - Login Information
              Padding(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                String aut = await _getAuthorizationCode();
                                print(aut);
                                log("yo");
                                Navigator.push(context, MaterialPageRoute(builder: (context) => home(token: 'BQDOO1tGNl_otq6b5NkbprreRCHVk_KZqOUrNPxNl5OYOOMq1HfDGB0EelKeSp1dyrB0p-YHF8efCh6U4sVECpSCQm3yMuMCiMTsxGOlCR6bYYZA9A2OSqp2_gCusQMt2T9dJg-vGWPM5ly4_hIlbaWU9_85PV_qXmdrjaUxnbV_bswkKFXk0ZevjuXRrEVQFFwVQUQVheM',)));
                              },
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                backgroundColor: const Color(0xFF1EF18C),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/spotify.png',
                                    width: 30,
                                    height: 30,
                                  ),
                                  const SizedBox(width: 16.0),
                                  const Text(
                                    'Login with Spotify',
                                    style: TextStyle(
                                      color: Color(0xFF1E1E1E),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Third Row - "Sound Trends" Logo
              Image.asset(
                'assets/logo_text.png',
                width: 250,
                height: 50,
              ),
            ],
          ),
        ),
      ),
    );
  }
}