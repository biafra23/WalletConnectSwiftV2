// 

import Foundation

public class WalletConnectClient {
    
    let metadata: AppMetadata
    
    let isController: Bool
    
    private let pairingEngine: SequenceEngine
    private let relay: Relay
    private let crypto = Crypto()
    
    public init(options: WalletClientOptions) {
        self.isController = options.isController
        self.metadata = options.metadata
        self.relay = Relay(transport: JSONRPCTransport(url: options.relayURL), crypto: crypto)
        let wcSubscriber = WCSubscriber(relay: relay)
        self.pairingEngine = PairingEngine(relay: relay, crypto: crypto, subscriber: wcSubscriber)
        // TODO: Store api key
    }
    
    public func pair(uriString: String, completion: @escaping (Result<String, Error>) -> Void) throws {
        print("start pair")
        guard let pairingURI = PairingType.ParamsUri(uriString) else {
            throw WalletConnectError.PairingParamsUriInitialization
        }
        let proposal = PairingType.Proposal.createFromURI(pairingURI)
        let approved = proposal.proposer.controller != isController
        if !approved {
            throw WalletConnectError.unauthorizedMatchingController
        }
        pairingEngine.respond(to: proposal) { result in
            switch result {
            case .success:
                print("Pairing Success")
            case .failure(let error):
                print("Pairing Failure: \(error)")
            }
            completion(result)
        }
    }
}