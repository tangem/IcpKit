//
//  File.swift
//  
//
//  Created by Dmitry Fedorov on 04.07.2024.
//

import Foundation

public enum ICPRequestType: String, Encodable {
    case call       = "call"
    case query      = "query"
    case readState  = "read_state"
}
