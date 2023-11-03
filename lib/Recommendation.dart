import 'package:acharya_capstone/utils/data.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';

class Recommendation extends StatefulWidget {
  late List<String> items;
  Recommendation({Key? key, required this.items}) : super(key: key);
  @override
  State<Recommendation> createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<Recommendation> {
  late List<String> items;
  late String url;
  late String title;
  @override
  void initState() {
    super.initState();
    items = widget.items;
    print(items.toString());
    recommend();
  }
  
  void recommend(){
    String i = items[0].toString()+","+items[1].toString();
    if(mockData.containsKey(i)){
      title = mockData[i]['title'];
      url = mockData[i]['url'];
    }
  }

  Future<void> _launchUrl() async {
    Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recommendations'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              title,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                _launchUrl();
                print('Link clicked');
              },
              child: Text('Visit Link'),
            ),
          ),
        ],
      ),
    );
  }
}