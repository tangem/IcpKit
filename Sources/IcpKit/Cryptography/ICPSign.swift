//
//  ICPSigning.swift
//
//
//  Created by Dmitry Fedorov on 05.07.2024.
//

import Foundation
import CryptoKit

/// Model for generation hashes to sign
/// from transaction parameters
public struct ICPSigningInput {
    /// Input transaction parameters
    public let transactionParams: ICPTransactionParams
    private let date: Date
    
    /// Creates instance
    /// - Parameters:
    ///   - destination: hex encoded destination address string
    ///   - amount: amount in ICP multiplied by decimals count (8)
    ///   - date: current date (Date())
    ///   - memo: memo value
    public init(destination: Data, amount: UInt64, date: Date, memo: UInt64? = nil) {
        self.transactionParams = ICPTransactionParams(destination: destination, amount: amount, memo: memo)
        self.date = date
    }
    
    /// Generates hashes for signing
    /// - Parameters:
    ///   - requestData: request data object passed from makeRequestData(for:nonce:)
    ///   - domain: domain of the requests
    /// - Returns: hashes for signing
    public func hashes(requestData: ICPRequestsData, domain: ICPDomainSeparator) throws -> [Data] {
        return requestData.hashes(for: domain)
    }
    
    /// Generate 'call' and 'read_state' requests data from public key
    /// - Parameters:
    ///   - publicKey: public key data
    ///   - nonce: random 32 bytes length data
    /// - Returns: Requests data
    public func makeRequestData(for publicKey: Data, nonce: Data) throws -> ICPRequestsData {
        let derEncodedPublicKey = try Cryptography.der(uncompressedEcPublicKey: publicKey)
        let sender = try ICPPrincipal.selfAuthenticatingPrincipal(derEncodedPublicKey: derEncodedPublicKey)
        
        let callRequestContent = ICPRequestBuilder.makeCallRequestContent(
            method: .transfer(
                params: transactionParams,
                createdAt: date
            ),
            requestType: .call,
            sender: sender,
            date: date,
            nonce: nonce
        )
        
        let requestID = try callRequestContent.calculateRequestId()
        
        let paths = ICPStateTreePath.readStateRequestPaths(requestID: requestID)
        
        let readStateRequestContent = ICPRequestBuilder.makeReadStateRequestContent(
            paths: paths,
            sender: sender,
            date: date,
            nonce: nonce
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
/// This struct aggregates data for generating both of them
public struct ICPRequestsData {
    let derEncodedPublicKey: Data
    let callRequestID: Data
    let readStateRequestID: Data
    let callRequestContent: ICPCallRequestContent
    let readStateRequestContent: ICPReadStateRequestContent
    let readStateTreePaths: [ICPStateTreePath]
    
    fileprivate func hashes(for domain: ICPDomainSeparator) -> [Data] {
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

/// Aggregates signed envelopes for further CBOR encoding and sending
public struct ICPSigningOutput {
    public let requestID: Data
    public let callEnvelope: ICPRequestEnvelope<ICPCallRequestContent>
    public let readStateEnvelope: ICPRequestEnvelope<ICPReadStateRequestContent>
    public let readStateTreePaths: [ICPStateTreePath]
    
    public init(data: ICPRequestsData, callSignature: Data, readStateSignature: Data) {
        requestID = data.callRequestID
        callEnvelope = ICPRequestEnvelope(
            content: data.callRequestContent,
            senderPubkey: data.derEncodedPublicKey,
            senderSig: callSignature
        )
        readStateEnvelope = ICPRequestEnvelope(
            content: data.readStateRequestContent,
            senderPubkey: data.derEncodedPublicKey,
            senderSig: readStateSignature
        )
        readStateTreePaths = data.readStateTreePaths
    }
}
