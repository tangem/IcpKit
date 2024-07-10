//
//  File.swift
//  
//
//  Created by Dmitry Fedorov on 04.07.2024.
//

import Foundation

public struct ICPTransactionParams {
    let destination: Data
    let amount: UInt64
    let memo: UInt64?
    
    public init(destination: Data, amount: UInt64, memo: UInt64?) {
        self.destination = destination
        self.amount = amount
        self.memo = memo
    }
}
