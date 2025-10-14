import 'package:flutter/material.dart';
import '../services/api_client.dart';

class AddPostScreen extends StatefulWidget {
  @override
  _AddPostScreenState createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController bodyController = TextEditingController();
  final TextEditingController userIdController = TextEditingController();

  bool isLoading = false;
  final ApiClient apiClient = ApiClient();

  void createPost() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await apiClient.postRequest('/posts', {
        "title": titleController.text,
        "body": bodyController.text,
        "userId": int.tryParse(userIdController.text) ?? 1,
      });

      setState(() {
        isLoading = false;
      });

      // Success dialog
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Success "),
          content: Text("Post yaratildi!\nID: ${response.data['id']}"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);   // dialog yopish
                Navigator.pop(context, true);  // back qaytish
              },
              child: Text("OK"),
            ),
          ],
        ),
      );

    } catch (e) {
      setState(() {
        isLoading = false;
      });

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Xato"),
          content: Text("Post yaratilmadi!\n$e"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create Post"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: "Title"),
            ),
            TextField(
              controller: bodyController,
              decoration: InputDecoration(labelText: "Body"),
              maxLines: 3,
            ),
            TextField(
              controller: userIdController,
              decoration: InputDecoration(labelText: "User ID"),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: createPost,
              child: Text("Create"),
            )
          ],
        ),
      ),
    );
  }
}
