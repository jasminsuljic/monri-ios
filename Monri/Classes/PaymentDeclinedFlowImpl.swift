//
// Created by Jasmin Suljic on 02/09/2020.
//

import Foundation
import os.log

class PaymentDeclinedFlowImpl: PaymentDeclinedFlow {
    private var uiDelegate: UiDelegate
    public let clientSecret: String

    var logger: MonriLogger {
        MonriLoggerImpl(log: OSLog(subsystem: "Monri", category: "PaymentDeclinedFlow"))
    }

    init(uiDelegate: UiDelegate, clientSecret: String) {
        self.uiDelegate = uiDelegate
        self.clientSecret = clientSecret
    }

    func handleResult(_ response: ConfirmPaymentResponse) {

        uiDelegate.hideLoading()
        uiDelegate.hideWebView()
        uiDelegate.handlePaymentResult(paymentResult: .declined(ConfirmPaymentDeclined(status: response.status.rawValue, clientSecret: clientSecret)))
        
    }
}
