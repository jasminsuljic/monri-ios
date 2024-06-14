//
// Created by Jasmin Suljic on 02/09/2020.
//

import Foundation

class UnknownFlowImpl: UnknownFlow {
    private var uiDelegate: UiDelegate

    private let clientSecret: String

    init(uiDelegate: UiDelegate, clientSecret: String) {
        self.uiDelegate = uiDelegate
        self.clientSecret = clientSecret
    }

    func handleResult(_ response: ConfirmPaymentResponse) {

    }
}
