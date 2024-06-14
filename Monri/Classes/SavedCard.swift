//
//  SavedCard.swift
//  Monri
//
//  Created by Jasmin Suljic on 13/11/2019.
//

import Foundation

public struct SavedCard {
    let panToken: String
    let cvc: String?

    public init(panToken: String, cvc: String?) {
        self.panToken = panToken
        self.cvc = cvc
    }
}

extension SavedCard: PaymentMethod {

    public func paymentMethodType() -> PaymentMethodType {
        return PaymentMethodType.savedCard
    }

    public func data() -> [String: Any] {
        guard let cvv = self.cvc else {
            return [
                "pan_token": panToken
            ]
        }

        return [
            "pan_token": panToken,
            "cvv": cvv
        ]
    }

    public func toPaymentMethodParams() -> PaymentMethodParams {
        return PaymentMethodParams(type: paymentMethodType().rawValue, data: data())
    }
}
