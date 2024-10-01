//
//  ICPMethod.swift
//  Runner
//
//  Created by Konstantinos Gaitanis on 21.04.23.
//

import Foundation

public struct ICPMethod {
    internal init(canister: ICPPrincipal, methodName: String, args: CandidValue? = nil) {
        self.canister = canister
        self.methodName = methodName
        self.args = args
    }
    
    let canister: ICPPrincipal
    let methodName: String
    let args: CandidValue?
}

public extension ICPMethod {
    static func balance(account: Data) -> ICPMethod {
        ICPMethod(
            canister: ICPSystemCanisters.ledger,
            methodName: "account_balance",
            args: .record([
                "account": .blob(account)
            ])
        )
    }
    
    static func transfer(params: ICPTransaction.TransactionParams) -> ICPMethod {
        ICPMethod(
            canister: ICPSystemCanisters.ledger,
            methodName: "transfer",
            args: .record([
                "from_subaccount": .option(.blob(Data(repeating: 0, count: 32))),
                "to": .blob(params.destination),
                "amount": .ICPAmount(params.amount),
                "fee": .ICPAmount(10000),
                "memo": .natural64(params.memo ?? 0),
                "created_at_time": .ICPTimestamp(date: params.date)
            ])
        )
    }
}
