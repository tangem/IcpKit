//
//  ICPRequestContent.swift
//  Runner
//
//  Created by Konstantinos Gaitanis on 02.05.23.
//

import Foundation

public protocol ICPRequestContent: Encodable {
    var requestType: ICPRequestType { get }
    var sender: Data { get }
    var nonce: Data { get }
    var ingressExpiry: Int { get }
}

public extension ICPRequestContent {
    func calculateRequestId() throws -> Data {
        try ICPCryptography.orderIndependentHash(self)
    }
}

public struct ICPReadStateRequestContent: ICPRequestContent {
    public let requestType: ICPRequestType
    public let sender: Data
    public let nonce: Data
    public let ingressExpiry: Int
    
    public let paths: [[Data]]
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(self.requestType, forKey: CodingKeys.requestType)
        try container.encode(self.sender, forKey: CodingKeys.sender)
        try container.encode(self.nonce, forKey: CodingKeys.nonce)
        try container.encode(self.ingressExpiry, forKey: CodingKeys.ingressExpiry)
        try container.encode(self.paths, forKey: CodingKeys.paths)
    }
}

public struct ICPCallRequestContent: ICPRequestContent {
    public let requestType: ICPRequestType
    public let sender: Data
    public let nonce: Data
    public let ingressExpiry: Int
    
    let methodName: String
    let canisterID: Data
    let arg: Data
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(self.requestType, forKey: CodingKeys.requestType)
        try container.encode(self.sender, forKey: CodingKeys.sender)
        try container.encode(self.nonce, forKey: CodingKeys.nonce)
        try container.encode(self.ingressExpiry, forKey: CodingKeys.ingressExpiry)
        try container.encode(self.methodName, forKey: CodingKeys.methodName)
        try container.encode(self.canisterID, forKey: CodingKeys.canisterID)
        try container.encode(self.arg, forKey: CodingKeys.arg)
    }
}

fileprivate enum CodingKeys: String, CodingKey {
    case requestType = "request_type"
    case sender
    case nonce
    case ingressExpiry = "ingress_expiry"
    case methodName = "method_name"
    case canisterID = "canister_id"
    case paths
    case arg
}
