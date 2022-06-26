import 'package:algolia/algolia.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future main() async {
  await dotenv.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Algolia _algoliaClient = Algolia.init(
    applicationId: dotenv.env["APPLICATION_ID"]!,
    apiKey: dotenv.env["API_KEY"]!,
  );

  String _searchText = "";
  List<SearchHit> _hitsList = [];
  final _textFieldController = TextEditingController();

  Future<void> _getSearchResult(String query) async {
    AlgoliaQuery algoliaQuery = _algoliaClient.instance
        .index("recipe_published_timestamp_desc")
        .setHitsPerPage(100)
        .query(query);
    AlgoliaQuerySnapshot snapshot = await algoliaQuery.getObjects();
    final rawHits = snapshot.toMap()['hits'] as List;
    final hits =
        List<SearchHit>.from(rawHits.map((hit) => SearchHit.fromJson(hit)));
    setState(() {
      _hitsList = hits;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Algolia & Flutter'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _hitsList.isEmpty
                  ? const Center(child: Text('No results'))
                  : ListView.builder(
                      itemCount: _hitsList.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Container(
                          color: Colors.white,
                          height: 100,
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: <Widget>[
                              SizedBox(
                                width: 160,
                                child: Image.network(_hitsList[index].image),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Text(_hitsList[index].title),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            SizedBox(
              height: 44,
              child: TextField(
                controller: _textFieldController,
                decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter a search term',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchText.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              setState(
                                () {
                                  _textFieldController.clear();
                                },
                              );
                            },
                            icon: const Icon(Icons.clear),
                          )
                        : null),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _textFieldController.addListener(() {
      if (_searchText != _textFieldController.text) {
        setState(() {
          _searchText = _textFieldController.text;
        });
        _getSearchResult(_searchText);
      }
    });
    _getSearchResult('');
  }

  @override
  void dispose() {
    _textFieldController.dispose();
    super.dispose();
  }
}

class SearchHit {
  final String id;
  final String title;
  final String description;
  final String published;
  final int publishedTimestamp;
  final int views;
  final int likes;
  final String image;
  final String url;
  final String objectID;

  SearchHit(
      this.id,
      this.title,
      this.description,
      this.published,
      this.publishedTimestamp,
      this.views,
      this.likes,
      this.image,
      this.url,
      this.objectID);

  static SearchHit fromJson(Map<String, dynamic> json) {
    return SearchHit(
      json['id'],
      json['title'],
      json['description'],
      json['published'],
      json['published_timestamp'],
      json['views'],
      json['likes'],
      json['image'],
      json['url'],
      json['objectID'],
    );
  }
}
