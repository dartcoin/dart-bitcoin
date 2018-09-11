import 'dart:async';

import 'package:grpc/grpc.dart';

//import 'generated/proto/walletservice.pb.dart';
//import 'generated/proto/walletservice.pbgrpc.dart';
//
//main(List<String> args) async {
//  await new Client().main(args);
//}
//
//class Client {
//  ClientChannel channel;
//  WalletClient stub;
//
//  Future<Null> main(List<String> args) async {
//    channel = new ClientChannel('127.0.0.1',
//        port: 8080,
//        options: const ChannelOptions(
//            credentials: const ChannelCredentials.insecure()));
//    stub = new WalletClient(channel,
//        options: new CallOptions(timeout: new Duration(seconds: 30)));
//    // Run all of the demos in order.
//    try {
//      Balance balance = await stub.getBalance(new Empty());
//      print('Balance is ${balance.amount}');
//    } catch (e) {
//      print('Caught error: $e');
//    }
//    await channel.shutdown();
//  }
//}