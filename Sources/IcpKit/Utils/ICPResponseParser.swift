//
//  ICPResponseParser.swift
//  
//
//  Created by Dmitry Fedorov on 05.07.2024.
//

import Foundation

public struct ICPResponseParser {
    public init() {}
    
    public func parseAccountBalanceResponse(_ data: Data) throws -> Decimal {
        let response = try parseQueryResponse(data)
        guard let balance = response.ICPAmount else {
            throw ICPLedgerCanisterError.invalidResponse
        }
        return Decimal(balance)
    }
    
    public func parseTransferResponse(_ data: Data) throws {
        _ = try parseCallResponse(data)
    }
    
    public func parseTransferStateResponse(_ data: Data, paths: [ICPStateTreePath]) throws -> UInt64 {
        let response = try parseReadStateResponse(data, paths)
        
        guard let variant = response?.variantValue else {
            throw ICPLedgerCanisterError.invalidResponse
        }
        
        guard let blockIndex = variant["Ok"]?.natural64Value else {
            guard let error = variant["Err"]?.variantValue else {
                throw ICPLedgerCanisterError.invalidResponse
            }
            if let badFee = error["BadFee"]?.recordValue,
               let expectedFee = badFee["expected_fee"]?.ICPAmount {
                throw ICPTransferError.badFee(expectedFee: expectedFee)
                
            } else if let insufficientFunds = error["InsufficientFunds"]?.recordValue,
                      let balance = insufficientFunds["balance"]?.ICPAmount {
                
                throw ICPTransferError.insufficientFunds(balance: balance)
                                                      
            } else if let txTooOld = error["TxTooOld"]?.recordValue,
                      let allowed = txTooOld["allowed_window_nanos"]?.natural64Value {
                throw ICPTransferError.transactionTooOld(allowedWindowNanoSeconds: allowed)
                
            } else if let _ = error["TxCreatedInFuture"] {
                throw ICPTransferError.transactionCreatedInFuture
                
            } else if let txDuplicate = error["TxDuplicate"]?.recordValue,
                      let blockIndex = txDuplicate["duplicate_of"]?.natural64Value {
                throw ICPTransferError.transactionDuplicate(blockIndex: blockIndex)
            }
            throw ICPLedgerCanisterError.invalidResponse
        }
        return blockIndex
    }
}

private extension ICPResponseParser {
    func parseQueryResponse(_ data: Data) throws -> CandidValue {
        let queryResponse = try ICPCryptography.CBOR.deserialise(ICPQueryResponseDecodable.self, from: data)
        guard queryResponse.status != .rejected else {
            throw ICPRemoteClientError.requestRejected
        }
        guard let candidRaw = queryResponse.reply?.arg else {
            throw ICPRemoteClientError.malformedResponse
        }
        let candidResponse = try CandidDeserialiser().decode(candidRaw)
        guard let firstCandidValue = candidResponse.first else {
            throw ICPRemoteClientError.malformedResponse
        }
        return firstCandidValue
    }
    
    func parseCallResponse(_ data: Data) throws -> CandidValue {
        return .null
    }
    
    func parseReadStateResponse(_ data: Data, _ paths: [ICPStateTreePath]) throws -> CandidValue? {
        let readStateResponse = try ICPCryptography.CBOR.deserialise(ICPReadStateResponseDecodable.self, from: data)
        let certificateCbor = try ICPCryptography.CBOR.deserialiseCbor(from: readStateResponse.certificate)
        let certificate = try ICPStateCertificate.parse(certificateCbor)
        
        let pathResponses = Dictionary(uniqueKeysWithValues: paths
            .map { ($0, certificate.tree.getValue(for: $0)) }
            .filter { $0.1 != nil }
            .map { ($0.0, $0.1!) }
        )
        let statusResponse = ICPReadStateResponse(stateValues: pathResponses)
        
        guard let statusString = statusResponse.stringValueForPath(endingWith: "status"),
              let status = ICPRequestStatusCode(rawValue: statusString) else {
            return nil
        }
        switch status {
        case .done:
            throw ICPPollingError.requestIsDone
        case .rejected:
            guard let rejectCodeValue = statusResponse.rawValueForPath(endingWith: "reject_code"),
                  let rejectCode = ICPRequestRejectCode(rawValue: UInt8.from(rejectCodeValue)) else {
                throw ICPPollingError.parsingError
            }
            let rejectMessage = statusResponse.stringValueForPath(endingWith: "reject_message")
            throw ICPPollingError.requestRejected(rejectCode, rejectMessage)
        case .replied:
            guard let replyData = statusResponse.rawValueForPath(endingWith: "reply"),
                  let candidValue = try CandidDeserialiser().decode(replyData).first else {
                throw ICPPollingError.parsingError
            }
            return candidValue
        case .processing, .received:
            return nil
        }
    }
}

public enum ICPRemoteClientError: Error {
    case malformedResponse, requestRejected
}

public enum ICPTransferError: Error {
    case badFee(expectedFee: UInt64)
    case insufficientFunds(balance: UInt64)
    case transactionTooOld(allowedWindowNanoSeconds: UInt64)
    case transactionCreatedInFuture
    case transactionDuplicate(blockIndex: UInt64)
    case couldNotFindPostedTransaction
}

public enum ICPPollingError: Error {
    case malformedRequestId
    case requestIsDone
    case requestRejected(ICPRequestRejectCode, String?)
    case parsingError
    case timeout
}

public enum ICPRequestRejectCode: UInt8, Decodable {
    case systemFatal = 1
    case systemTransient = 2
    case destinationInvalid = 3
    case canisterReject = 4
    case canisterError = 5
}

public enum ICPRequestStatusCode: String, Decodable {
    case received
    case processing
    case replied
    case rejected
    case done
}

fileprivate struct ICPReadStateResponse {
    public let stateValues: [ICPStateTreePath: Data]
       
    public func stringValueForPath(endingWith suffix: String) -> String? {
        guard let data = rawValueForPath(endingWith: suffix) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    public func rawValueForPath(endingWith suffix: String) -> Data? {
        stateValues.first { (path, value) in
            path.components.last?.stringValue == suffix
        }?.value
    }
}

fileprivate struct ICPQueryResponseDecodable: Decodable {
    let status: ICPRequestStatusCode
    let reply: Reply?
    let reject_code: ICPRequestRejectCode?
    let reject_message: String?
    let error_code: String?
    
    struct Reply: Decodable {
        let arg: Data
    }
}

fileprivate struct ICPReadStateResponseDecodable: Decodable {
    let certificate: Data
}

public enum ICPLedgerCanisterError: Error {
    case invalidAddress
    case invalidResponse
    case blockNotFound
    case transferFailed(ICPTransferError)
}
