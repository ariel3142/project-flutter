import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:water_drop_nav_bar/water_drop_nav_bar.dart';
import 'package:file_picker/file_picker.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> login(String email, String password) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final url = Uri.parse('https://reqres.in/api/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'];
        print('Login successful: $token');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MyHomePage()),
        );
      } else {
        final errorData = json.decode(response.body);
        setState(() {
          _errorMessage = errorData['error'];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again later.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login Dulu'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            if (_isLoading)
              CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: () {
                  final email = _emailController.text.trim();
                  final password = _passwordController.text.trim();
                  if (email.isNotEmpty && password.isNotEmpty) {
                    login(email, password);
                  } else {
                    setState(() {
                      _errorMessage = 'Please fill in all fields';
                    });
                  }
                },
                child: Text('Login'),
              ),
            if (_errorMessage != null) ...[
              SizedBox(height: 20),
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Color navigationBarColor = const Color.fromARGB(255, 75, 3, 244);
  int selectedIndex = 0;
  late PageController pageController;

  List<String> gridItems = List.generate(16, (index) => 'Item $index');
  List<String> favoriteItems = [];

  final TextEditingController _addItemController = TextEditingController();

  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: selectedIndex);
  }

  void addItemToGrid(String item) {
    setState(() {
      gridItems.add(item);
    });
  }

  void addItemToFavorites(String item) {
    setState(() {
      if (!favoriteItems.contains(item)) {
        favoriteItems.add(item);
      }
    });
  }

  void removeItemFromFavorites(String item) {
    setState(() {
      favoriteItems.remove(item);
    });
  }

  void deleteGridItem(int index) {
    setState(() {
      gridItems.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: PageView(
          physics: const NeverScrollableScrollPhysics(),
          controller: pageController,
          children: <Widget>[
            _buildGridView(),
            _buildFavoriteListView(),
            _buildCommentsSection(),
            _buildFileUploadSection(),
          ],
        ),
        bottomNavigationBar: WaterDropNavBar(
          backgroundColor: navigationBarColor,
          onItemSelected: (int index) {
            setState(() {
              selectedIndex = index;
            });
            pageController.animateToPage(selectedIndex,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutQuad);
          },
          selectedIndex: selectedIndex,
          barItems: <BarItem>[
            BarItem(
              filledIcon: Icons.bookmark_rounded,
              outlinedIcon: Icons.bookmark_border_rounded,
            ),
            BarItem(
              filledIcon: Icons.favorite_rounded,
              outlinedIcon: Icons.favorite_border_rounded,
            ),
            BarItem(
              filledIcon: Icons.comment_rounded,
              outlinedIcon: Icons.comment_bank_rounded,
            ),
            BarItem(
              filledIcon: Icons.folder_rounded,
              outlinedIcon: Icons.folder_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _addItemController,
                  decoration: InputDecoration(
                    labelText: 'Add Item',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  if (_addItemController.text.isNotEmpty) {
                    addItemToGrid(_addItemController.text);
                    _addItemController.clear();
                  }
                },
                child: Text('Add'),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: gridItems.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Item Details'),
                    content: Text(gridItems[index]),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Close'),
                      ),
                    ],
                  ),
                ),
                child: GridTile(
                  header: Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => deleteGridItem(index),
                    ),
                  ),
                  child: Container(
                    color: Colors.blue,
                    child: Center(
                      child: Text(
                        gridItems[index],
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteListView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _addItemController,
                  decoration: InputDecoration(
                    labelText: 'Add Favorite',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  if (_addItemController.text.isNotEmpty) {
                    addItemToFavorites(_addItemController.text);
                    _addItemController.clear();
                  }
                },
                child: Text('Add'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favoriteItems.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: Icon(Icons.favorite, color: Colors.red),
                title: Text(favoriteItems[index]),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => removeItemFromFavorites(favoriteItems[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsSection() {
    final comments = [
      'Great post!',
      'Thanks for sharing.',
      'Amazing content!',
      'Love this!',
      'Very helpful, thanks!'
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: comments.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: CircleAvatar(
            child: Text(comments[index][0]),
          ),
          title: Text(comments[index]),
        );
      },
    );
  }

  Widget _buildFileUploadSection() {
    return Center(
      child: ElevatedButton(
        onPressed: () async {
          FilePickerResult? result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['jpeg', 'png'],
          );

          if (result != null) {
            String? filePath = result.files.single.path;
            if (filePath != null) {
              if (filePath.endsWith('.jpeg') || filePath.endsWith('.png'))
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('File selected: $filePath')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('No file selected')),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('File selection cancelled')),
            );
          }
        },
        child: Text('Upload File'),
      ),
    );
  }
}

final ImagePicker _picker = ImagePicker();

Future<void> pickImage() async {
  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
  if (image != null) {
    print('Image path: ${image.path}');
  } else {
    print('No image selected.');
  }
}