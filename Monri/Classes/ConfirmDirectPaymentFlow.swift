//
//  ConfirmDirectPaymentFlow.swift
//  Monri
//
//  Created by Karolina Škunca on 04.04.2024..
//

import Foundation

protocol ConfirmDirectPaymentFlow {
    func handleResult(_ response: ConfirmPaymentResponse)
}
