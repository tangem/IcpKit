//
//  ICPPrincipal.swift
//  Runner
//
//  Created by Konstantinos Gaitanis on 19.04.23.
//

import Foundation

/// from https://internetcomputer.org/docs/current/references/ic-interface-spec/#principal
public struct ICPPrincipal {
    public let bytes: Data
    public let string: String
    
    public init(_ string: String) throws {
        self.string = string
        self.bytes = try ICPCryptography.decodeCanonicalText(string)
    }
    
    public init(_ bytes: Data) {
        self.bytes = bytes
        self.string = ICPCryptography.encodeCanonicalText(bytes)
    }
}

public extension ICPPrincipal {
    static let dummy: ICPPrincipal = {
        let data = Data([4])
        return ICPPrincipal(Data([4]))
    }()
    
    static func selfAuthenticatingPrincipal(derEncodedPublicKey publicKey: Data) throws -> ICPPrincipal {
        let bytes = Cryptography.sha224(publicKey) + Data([0x02])
        return ICPPrincipal(bytes)
    }
}
