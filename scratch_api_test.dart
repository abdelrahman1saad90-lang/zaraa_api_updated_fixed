import 'package:http/http.dart' as http;

void main() async {
  // Test if create/edit/delete endpoints exist (expect 401 = exists but needs auth, 404 = not found)
  final endpoints = [
    'apiAdmin/Products/Create',
    'apiAdmin/Products/Edit/1',
    'apiAdmin/Products/Delete/1',
  ];
  
  for (final ep in endpoints) {
    final url = Uri.parse('https://zaraaapi.runasp.net/' + ep);
    final res = await http.post(url);
    print(ep + ' (POST) -> Status: ' + res.statusCode.toString());
  }
}
