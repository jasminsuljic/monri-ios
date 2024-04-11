//
// Created by Jasmin Suljic on 01/09/2020.
//

import Foundation
import os.log

class PaymentErrorFlowImpl: PaymentErrorFlow {

    private var uiDelegate: UiDelegate
    private let clientSecret: String

    var logger: MonriLogger {
        MonriLoggerImpl(log: OSLog(subsystem: "Monri", category: "PaymentErrorFlow"))
    }

    init(uiDelegate: UiDelegate, clientSecret: String) {
        self.uiDelegate = uiDelegate
        self.clientSecret = clientSecret
    }

    func handleResult(error: Error) {
        uiDelegate.handlePaymentResult(paymentResult: .error(PaymentResultError.error(error)))
    }
}
