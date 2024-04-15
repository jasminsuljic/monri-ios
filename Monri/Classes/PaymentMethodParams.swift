//
//  PaymentMethodParams.swift
//  Monri
//
//  Created by Jasmin Suljic on 01/09/2020.
//

import Foundation

public class PaymentMethodParams {
    let type: String
    let data: Dictionary<String, Any>
    
    public init(type: String, data: Dictionary<String, Any>) {
        self.data = data
        self.type = type
    }

    public func toJSON() -> Dictionary<String, Any> {
        [
            "type": type,
            "data": data
        ]
    }
}
