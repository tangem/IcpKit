//
//  ICPRequestBuilder.swift
//  Runner
//
//  Created by Konstantinos Gaitanis on 02.05.23.
//

import Foundation

public struct ICPRequestBuilder {
    private static let defaultIngressExpirySeconds: TimeInterval = 4 * 60 // 4 minutes
    
    public static func makeCallRequestContent(
        method: ICPMethod,
        requestType: ICPRequestType,
        sender: ICPPrincipal = .dummy,
        nonce: Data
    ) -> ICPCallRequestContent {
        let serialisedArgs = CandidSerialiser().encode(method.args)
        return ICPCallRequestContent(
            requestType: requestType,
            sender: sender.bytes,
            nonce: nonce,
            ingressExpiry: makeIngressExpiry(),
            methodName: method.methodName,
            canisterID: method.canister.bytes,
            arg: serialisedArgs
        )
    }
    
    public static func makeReadStateRequestContent(
        paths: [ICPStateTreePath],
        sender: ICPPrincipal,
        nonce: Data
    ) -> ICPReadStateRequestContent {
        let encodedPaths = paths.map { $0.encodedComponents() }
        return ICPReadStateRequestContent(
            requestType: .readState,
            sender: sender.bytes,
            nonce: nonce,
            ingressExpiry: makeIngressExpiry(),
            paths: encodedPaths
        )
    }
    
    private static func makeIngressExpiry(_ seconds: TimeInterval = defaultIngressExpirySeconds) -> Int {
        let expiryDate = Date().addingTimeInterval(seconds)
        let nanoSecondsSince1970 = expiryDate.timeIntervalSince1970 * 1e9
        return Int(nanoSecondsSince1970)
    }
}
