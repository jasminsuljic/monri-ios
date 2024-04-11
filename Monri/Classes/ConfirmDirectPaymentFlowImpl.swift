//
//  ConfirmDirectPaymentFlowImpl.swift
//  Monri
//
//  Created by Karolina Škunca on 02.04.2024..
//

import Foundation
import WebKit
import os.log

public final class ConfirmDirectPaymentFlowImpl {
    
    private static let PAY_CEK_HR_ENDPOINT = "pay-cek-hr"
    private static let DIRECT_PAYMENT_REDIRECTION_ENDPOINT = "/v2/direct-payment/%@/%@/redirect-to-payment-url"
    
    private let monriApi: MonriApi
    private let apiOptions: MonriApiOptions?
    private let confirmPaymentParams: ConfirmPaymentParams?
    
    private var uiDelegate: UiDelegate
    
    private let clientSecret: String
    
    private let paymentErrorFlow: PaymentErrorFlow
    
    init(uiDelegate: UiDelegate,
         apiOptions: MonriApiOptions,
         monriApi: MonriApi,
         confirmPaymentParams: ConfirmPaymentParams) {
        self.uiDelegate = uiDelegate
        self.monriApi = monriApi
        self.apiOptions = apiOptions
        self.confirmPaymentParams = confirmPaymentParams
        
        self.clientSecret = confirmPaymentParams.paymentId
        
        paymentErrorFlow = PaymentErrorFlowImpl(uiDelegate: uiDelegate, clientSecret: clientSecret)
    }
    
    
    func checkPaymentStatus(clientSecret: String) {
        monriApi.httpApi.paymentStatus(PaymentStatusParams(clientSecret: clientSecret)) {
            result in
            switch (result) {
            case .error(let e):
                switch e {
                    
                case .requestFailed(let string):
                    self.paymentErrorFlow.handleResult(error: NSError(domain: string, code: 0))
                case .confirmPaymentFailed:
                    self.paymentErrorFlow.handleResult(error: NSError(domain: "confirmDirectPaymentFailed", code: 0))
                case .jsonParsingError(let string):
                    self.paymentErrorFlow.handleResult(error: NSError(domain: string, code: 0))
                case .unknownError(let error):
                    self.paymentErrorFlow.handleResult(error: error)
                }
            case .result(let r):
                
                switch r.paymentStatus {
                    
                case .approved, .declined, .executed:
                    
                    self.handleResult(ConfirmPaymentResponse(status: r.paymentStatus, actionRequired: nil, paymentResult: r.paymentResult))
                case .action_required:
                    break
                case .payment_method_required:
                    self.checkPaymentStatus(clientSecret: clientSecret)
                }
            }
        }
    }
    
    func execute() {
        
        let redirectionUrl = String(format: ConfirmDirectPaymentFlowImpl.DIRECT_PAYMENT_REDIRECTION_ENDPOINT, getPaymentProviderEndpoint(), clientSecret)
        
        guard let url = URL(string: (apiOptions?.apiUrl ?? "") + redirectionUrl) else {
            fatalError(String(format: "Redirection URL not supported"))
        }
        
        guard let redirectUrl = try? URLRequest(url: url, method: .get) else {
            return
        }
        
        DispatchQueue.main.async {
            self.uiDelegate.hideLoading()
            self.uiDelegate.showWebView()
            self.uiDelegate.loadWebViewUrl(url: redirectUrl)
        }
        
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 3) {
            self.checkPaymentStatus(clientSecret: self.clientSecret)
        }
    }
    
    private func getPaymentProviderEndpoint() -> String {
        
        if let paymentProviderPaymentMethod = confirmPaymentParams?.paymentMethod.type, paymentProviderPaymentMethod == DirectPayment.Provider.PAY_CEK_HR.paymentMethod {
            return ConfirmDirectPaymentFlowImpl.PAY_CEK_HR_ENDPOINT
        } else {
            fatalError("Payment provider \(String(describing: confirmPaymentParams?.paymentMethod.type)) not supported")
        }
    }
    
}

extension ConfirmDirectPaymentFlowImpl: ConfirmDirectPaymentFlow {
    func handleResult(_ response: ConfirmPaymentResponse) {
        
        uiDelegate.hideLoading()
        uiDelegate.hideWebView()
        
        if let paymentResult = response.paymentResult {
            
            uiDelegate.handlePaymentResult(paymentResult: .result(paymentResult))
        } else {
            
            uiDelegate.pending()
        }
        
    }
}



