library bitcoin.src.utils.checksum_reader;

import "dart:typed_data";

import "package:bytes/bytes.dart";
import "package:bytes/src/reader_base.dart";
import "package:pointycastle/api.dart";

/// A [Reader] implementation that checksums all data read from it.
class ChecksumReader extends ReaderBase {
  final Reader reader;
  final Digest digest;

  ChecksumReader(Reader this.reader, Digest this.digest);

  Uint8List checksum() {
    Uint8List sum = new Uint8List(digest.digestSize);
    digest.doFinal(sum, 0);
    return sum;
  }

  @override
  int get remainingLength => reader.remainingLength;

  @override
  int get length => reader.length;

  @override
  List<int> readBytes(int n) {
    Uint8List bytes = reader.readBytes(n);
    digest.update(bytes, 0, bytes.length);
    return bytes;
  }

  @override
  int readBytesInto(List<int> b) {
    int n = reader.readBytesInto(b);
    Uint8List copy = new Uint8List.fromList(b);
    digest.update(copy, 0, n);
    return n;
  }
}
