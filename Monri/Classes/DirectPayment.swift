//
//  DirectPayment.swift
//  Monri
//
//  Created by Karolina Škunca on 02.04.2024..
//

import Foundation

public class DirectPayment {
    
    private let paymentProvider: Provider
    
    public init(paymentProvider: Provider) {
        self.paymentProvider = paymentProvider
    }
}

extension DirectPayment: PaymentMethod {
    public func paymentMethodType() -> PaymentMethodType {
        return PaymentMethodType.payCekHr
    }
    
    public func data() -> [String : Any] {
        return [:]
    }
    
    public func toPaymentMethodParams() -> PaymentMethodParams {
        return PaymentMethodParams(type: paymentProvider.paymentMethod, data: data())
    }
}

extension DirectPayment {
    public enum Provider {
        
        case PAY_CEK_HR

        var paymentMethod: String {
            switch self {
            case .PAY_CEK_HR:
                return PaymentMethodType.payCekHr.rawValue
            }
        }
    }
}
