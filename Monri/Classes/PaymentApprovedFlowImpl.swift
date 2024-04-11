//
// Created by Jasmin Suljic on 02/09/2020.
//

import Foundation
import os.log

class PaymentApprovedFlowImpl: PaymentApprovedFlow {

    private var uiDelegate: UiDelegate
    public let clientSecret: String

    var logger: MonriLogger {
        MonriLoggerImpl(log: OSLog(subsystem: "Monri", category: "PaymentApprovedFlow"))
    }

    init(uiDelegate: UiDelegate, clientSecret: String) {
        self.uiDelegate = uiDelegate
        self.clientSecret = clientSecret
    }

    func handleResult(_ response: ConfirmPaymentResponse) {

        guard let paymentResult = response.paymentResult else {
            logger.fatal("Invoked handleResult for clientSecret = \(clientSecret) without payment result, got \(response)")
            return
        }

        uiDelegate.hideLoading()
        uiDelegate.hideWebView()
        uiDelegate.handlePaymentResult(paymentResult: .result(paymentResult))
    }
}
