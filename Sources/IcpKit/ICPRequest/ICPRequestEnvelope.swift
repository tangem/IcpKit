//
//  ICPRequestEnvelope.swift
//  Runner
//
//  Created by Konstantinos Gaitanis on 02.05.23.
//

import Foundation

public struct ICPRequestEnvelope<T: ICPRequestContent>: Encodable {
    let content: T
    let senderPubkey: Data?
    let senderSig: Data?
    
    public init(content: T, senderPubkey: Data? = nil, senderSig: Data? = nil) {
        self.content = content
        self.senderPubkey = senderPubkey
        self.senderSig = senderSig
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(content, forKey: .content)
        try container.encode(senderPubkey, forKey: .senderPubkey)
        try container.encode(senderSig, forKey: .senderSig)
    }
    
    enum CodingKeys: String, CodingKey {
        case content
        case senderPubkey = "sender_pubkey"
        case senderSig = "sender_sig"
    }
}

public extension ICPRequestEnvelope {
    func cborEncoded() throws -> Data {
        try ICPCryptography.CBOR.serialise(self)
    }
}
