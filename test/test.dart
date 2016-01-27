
import "dart:typed_data";
import "package:crypto/crypto.dart";

void main() {

  Uint8List u1 = new Uint8List.fromList([1, 2, 4]);
  Uint8List u2 = new Uint8List.fromList([1, 2, 5]);

  SHA256 s1 = new SHA256();
  s1.add(u1);
  s1.add(u2);
  print(s1.close());

  Uint8List u3 = new Uint8List.fromList([1, 2, 4, 1, 2, 5]);

  SHA256 s2 = new SHA256();
  s2.add(u3);
  print(s2.close());
}