//
//  PaymentMethod.swift
//  Monri
//
//  Created by Jasmin Suljic on 13/11/2019.
//

import Foundation

public enum PaymentMethodType: String {
    case newCard = "card"
    case savedCard = "saved_card"
    case payCekHr = "pay_cek_hr"
    
    public static let directPayments: [PaymentMethodType] = [PaymentMethodType.payCekHr]
    
}

public protocol PaymentMethod {
    func paymentMethodType() -> PaymentMethodType
    func data() -> [String: Any]
    func toPaymentMethodParams() -> PaymentMethodParams

}
