library bitcoin.src.utils.checksum_buffer;

import "dart:typed_data";

import "package:bytes/src/buffer_impl.dart";
import "package:pointycastle/api.dart";

/// A [Buffer] implementation that checksums all data put into it.
class ChecksumBuffer extends BufferImpl {
  final Digest digest;

  ChecksumBuffer(Digest this.digest) : super();

  Uint8List checksum() {
    Uint8List sum = new Uint8List(digest.digestSize);
    digest.doFinal(sum, 0);
    return sum;
  }

  @override
  void add(List<int> bytes) {
    super.add(bytes);
    digest.update(bytes, 0, bytes.length);
  }

  @override
  void clear() {
    super.clear();
    digest.reset();
  }
}
