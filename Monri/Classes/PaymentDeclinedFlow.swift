//
// Created by Jasmin Suljic on 01/09/2020.
//

import Foundation

protocol PaymentDeclinedFlow {
    func handleResult(_ response: ConfirmPaymentResponse)
}
