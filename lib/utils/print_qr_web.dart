// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
/*import 'dart:html' as html;

// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

void printQR(String destinationName, String qrData) {
  
  final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <title>Destination QR</title>
  <style>
    body {
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
      font-family: Arial;
    }
    .card { text-align: center; }
    img { width: 300px; height: 300px; }
  </style>
</head>
<body>
  <div class="card">
    <h1>$destinationName</h1>
    <img src="https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=$qrData" />
  </div>
</body>
</html>
''';

  final win = html.window.open('', '_blank');
  if (win == null) return;

  win.document!
    ..open()
    ..write(htmlContent)
    ..close();

  win.print();
  
}*/
