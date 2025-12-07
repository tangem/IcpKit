//
//  ICPNftMetadata.swift
//
//
//  Created by Konstantinos Gaitanis on 30.08.24.
//

import Foundation
import BigInt

public indirect enum ICPNftMetadataItem: Sendable, Equatable {
    case string(String)
    case number(BigInt)
    case url(URL)
    case data(Data)
    case array([ICPNftMetadataItem])
    case dictionary([String: ICPNftMetadataItem])

    static func number(_ number: BigUInt) -> ICPNftMetadataItem {
        .number(BigInt(number))
    }
}

