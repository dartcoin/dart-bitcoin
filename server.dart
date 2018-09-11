//part of bitcoin.core;
import 'dart:async';
import 'dart:html';

import 'package:bitcoin/core.dart';
import 'package:bitcoin/src/node/node.dart';
import 'package:grpc/grpc.dart' as grpc;

//import 'package:grpc/src/server/call.dart';

import 'package:bitcoin/generated/proto/blockchain.pb.dart';
import 'package:bitcoin/generated/proto/walletservice.pb.dart';
import 'package:bitcoin/generated/proto/walletservice.pbgrpc.dart';
import 'package:grpc/grpc.dart';

main(List<String> args) async {

  await new Server().main(args);
}

class WalletService extends WalletServiceBase {
  @override
  Future<Return> broadcastTransaction(grpc.ServiceCall call, dynamic request) {
    // TODO: implement broadcastTransaction
  }

  @override
  Future<TransactionMessage> createTransaction(grpc.ServiceCall call, Coin request) async {
     return new TransactionMessage();
  }

  @override
  Future<Balance> getBalance(grpc.ServiceCall call, Empty request) async {
    Balance bal = new Balance();
    bal.amount = 1;
    return bal;
  }

}

class FeeCalculator {}

class Mempool {
  Blockchain chain;
  FeeCalculator fees;

  Mempool({chain, fees});
}

class Blockchain {
  NetworkParameters params;

  Blockchain({params});
}


class Server {
  Future<Null> main(List<String> args) async {

    PublicKeyCredential;

    Datastore store = new Sqllite();
    store.init(); // TODO Move to construct? // Bootstrap

    // Test code
    BlockMessage message = BlockMessage.create();
    message.transactions.add(TransactionMessage.create());
    store.save(message);

//    final server = new grpc.Server.inscure([new WalletService()], port: 8080); // TODO secure
//    await server.serve();
//    print('Server listening on port ${server.port}...');

    // Make up some params
    NetworkParameters params = NetworkParameters.UNIT_TEST;

    Blockchain chain = new Blockchain(params: params);

    FeeCalculator fees = new FeeCalculator();

    Mempool mempool = new Mempool(
      chain: chain,
      fees: fees
    );

    Network network = new Network(
//      chain: chain,
//      mempool: mempool
    );

    // Miner = chain + mempool

    FullNode node = new FullNode(
      params: params,
      store: store,
      network: network,
      mempool: mempool,
      chain: chain,
    );

    // Seed = node

    network.peers.changes.listen((l) { // TODO test, does it check attribute changes/connection state
      print('Peer added');
//      l.forEach((c) {
        if (network.peers.connected.length >= params.min_peers) {
          node.sync();
        }
//      });
    });

    network.discover();
    network.peers.add(new Peer());

    new Timer(new Duration(seconds: 5), () {
      print(network.peers.first);
      network.peers.first.state = ConnectionStatus.disconnected;
    });

    final channel = new ClientChannel(
        '127.0.0.1',
        port: 8080,
        options: const ChannelOptions(
            credentials: const ChannelCredentials.insecure()
        )
    );

    final client = new WalletClient(channel,
        options: new CallOptions(timeout: new Duration(seconds: 30))
    );

    for (BlockMessage block in await client.getBlocks({startHeight: 1})) { // Stream of block from height 1 and up

    }
  }
}

// ???
// JWT ES256 ECDSA P-256(K) ECDSASigner ipv SSL?
// Maar niet alle endpoints pk specifiek

// U2F Webauthn fido2 ctap uaf
// fido universal server
// github fido2 server paycoin-com

// https://www.youtube.com/watch?v=gfBDOOpZqOU