//
//  ICPSigning.swift
//
//
//  Created by Dmitry Fedorov on 05.07.2024.
//

import Foundation
import CryptoKit

public struct ICPSign {
    /// Generate 'call' and 'read_state' requests data from public key
    /// - Parameters:
    ///   - publicKey: public key data
    ///   - nonce: random 32-bytes length data provider
    ///   - transactionParams: input transaction params
    /// - Returns: Requests data
    public static func makeRequestData(
        publicKey: Data,
        nonce: () throws -> Data,
        transactionParams: ICPTransactionParams
    ) throws -> ICPRequestsData {
        let derEncodedPublicKey = try Cryptography.der(uncompressedEcPublicKey: publicKey)
        let sender = try ICPPrincipal.selfAuthenticatingPrincipal(derEncodedPublicKey: derEncodedPublicKey)
        
        let callRequestContent = ICPRequestBuilder.makeCallRequestContent(
            method: .transfer(
                params: transactionParams
            ),
            requestType: .call,
            sender: sender,
            date: transactionParams.date,
            nonce: try nonce()
        )
        
        let requestID = try callRequestContent.calculateRequestId()
        
        let paths = ICPStateTreePath.readStateRequestPaths(requestID: requestID)
        
        let readStateRequestContent = ICPRequestBuilder.makeReadStateRequestContent(
            paths: paths,
            sender: sender,
            date: transactionParams.date,
            nonce: try nonce()
        )
        
        return ICPRequestsData(
            derEncodedPublicKey: derEncodedPublicKey,
            callRequestID: requestID,
            readStateRequestID: try readStateRequestContent.calculateRequestId(),
            callRequestContent: callRequestContent,
            readStateRequestContent: readStateRequestContent,
            readStateTreePaths: paths
        )
    }
}

/// In order to execute transfer 2 requests are required:
/// 'call' request and 'read_state' request.
/// This struct aggregates data for generating both
public struct ICPRequestsData {
    public let derEncodedPublicKey: Data
    let callRequestID: Data
    let readStateRequestID: Data
    public let callRequestContent: ICPCallRequestContent
    public let readStateRequestContent: ICPReadStateRequestContent
    public let readStateTreePaths: [ICPStateTreePath]
    
    public func hashes(for domain: ICPDomainSeparator) -> [Data] {
        [
            hash(for: domain, requestID: callRequestID),
            hash(for: domain, requestID: readStateRequestID),
        ]
    }
        
    private func hash(for domain: ICPDomainSeparator, requestID: Data) -> Data {
        let domainSeparatedData = domain.domainSeparatedData(requestID)
        return Cryptography.sha256(domainSeparatedData)
    }
}
