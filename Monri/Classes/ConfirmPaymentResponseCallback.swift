//
// Created by Jasmin Suljic on 01/09/2020.
//

import Foundation

class ConfirmPaymentResponseCallback {
    
    private let actionRequiredFlow: ActionRequiredFlow
    private let paymentApprovedFlow: PaymentApprovedFlow
    private let paymentDeclinedFlow: PaymentDeclinedFlow
    private let unknownFlow: UnknownFlow
    private let paymentErrorFlow: PaymentErrorFlow
    
    init(actionRequiredFlow: ActionRequiredFlow, paymentApprovedFlow: PaymentApprovedFlow, paymentDeclinedFlow: PaymentDeclinedFlow, unknownFlow: UnknownFlow, paymentErrorFlow: PaymentErrorFlow) {
        self.actionRequiredFlow = actionRequiredFlow
        self.paymentApprovedFlow = paymentApprovedFlow
        self.paymentDeclinedFlow = paymentDeclinedFlow
        self.unknownFlow = unknownFlow
        self.paymentErrorFlow = paymentErrorFlow
    }
    
    static func create(uiDelegate: UiDelegate,
                       monriHttpApi: MonriHttpApi,
                       confirmPaymentParams: ConfirmPaymentParams) -> ConfirmPaymentResponseCallback {
        let clientSecret: String = confirmPaymentParams.paymentId
        return ConfirmPaymentResponseCallback(
            actionRequiredFlow: ActionRequiredFlowImpl(uiDelegate: uiDelegate,
                                                       monriApi: monriHttpApi,
                                                       clientSecret: clientSecret),
            paymentApprovedFlow: PaymentApprovedFlowImpl(uiDelegate: uiDelegate, clientSecret: clientSecret),
            paymentDeclinedFlow: PaymentDeclinedFlowImpl(uiDelegate: uiDelegate, clientSecret: clientSecret),
            unknownFlow: UnknownFlowImpl(uiDelegate: uiDelegate, clientSecret: clientSecret),
            paymentErrorFlow: PaymentErrorFlowImpl(uiDelegate: uiDelegate, clientSecret: clientSecret)
        )
    }
    
    func onError(error: Error) {
        paymentErrorFlow.handleResult(error: error)
    }
    
    func onSuccess(result: ConfirmPaymentResponse) {
        switch (result.status) {
        case .action_required:
            actionRequiredFlow.handleResult(result)
        case .approved:
            paymentApprovedFlow.handleResult(result)
        case .declined:
            paymentDeclinedFlow.handleResult(result)
        default:
            unknownFlow.handleResult(result)
        }
    }
}
