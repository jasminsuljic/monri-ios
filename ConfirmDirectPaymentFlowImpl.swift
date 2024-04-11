//
//  ConfirmDirectPaymentFlowImpl.swift
//  Monri
//
//  Created by Karolina Škunca on 02.04.2024..
//

import Foundation
import WebKit
import os.log

final class ConfirmDirectPaymentFlowImpl {
    
    private static let PAY_CEK_HR_ENDPOINT = "pay-cek-hr"
    private static let DIRECT_PAYMENT_REDIRECTION_ENDPOINT = "/v2/direct-payment/%@/%@/redirect-to-payment-url"
    
    private let monriApi: MonriApi
    private let apiOptions: MonriApiOptions?
    private let confirmPaymentParams: ConfirmPaymentParams?
    
    let navigationDelegate: DirectPaymentWebViewNavigationDelegate
    weak var vc: ConfirmPaymentControllerViewController?
    
    private let clientSecret: String
    
    private let paymentErrorFlow: PaymentErrorFlow
    
    init(
        vc: ConfirmPaymentControllerViewController,
        navigationDelegate: DirectPaymentWebViewNavigationDelegate,
        apiOptions: MonriApiOptions,
        monriApi: MonriApi,
        confirmPaymentParams: ConfirmPaymentParams) {
            self.vc = vc
            self.navigationDelegate = navigationDelegate
            self.monriApi = monriApi
            self.apiOptions = apiOptions
            self.confirmPaymentParams = confirmPaymentParams
            
            self.clientSecret = confirmPaymentParams.paymentId
            
            paymentErrorFlow = PaymentErrorFlowImpl(vc: vc, clientSecret: clientSecret)
        }
    
    func executeIfVc(action: String, _ callable: (ConfirmPaymentControllerViewController) -> Void) {
        guard let vc = vc else {
            return
        }
        
        callable(vc)
    }
    
    
    func checkPaymentStatus(clientSecret: String) {
        monriApi.httpApi.paymentStatus(PaymentStatusParams(clientSecret: clientSecret)) {
            result in
            self.executeIfVc(action: "paymentStatus") { vc in
                switch (result) {
                case .error(let e):
                    switch e {
                    case .requestFailed(let string):
                        self.paymentErrorFlow.handleResult(error: NSError(domain: string, code: 0))
                    case .confirmPaymentFailed:
                        self.paymentErrorFlow.handleResult(error: NSError(domain: "confirmPaymentFailed", code: 0))
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
    }
    
    func execute() {
        
        let redirectionUrl = String(format: ConfirmDirectPaymentFlowImpl.DIRECT_PAYMENT_REDIRECTION_ENDPOINT, getPaymentProviderEndpoint(), clientSecret)
        
        guard let url = URL(string: (apiOptions?.apiUrl ?? "") + redirectionUrl) else {
            fatalError(String(format: "Redirection URL not supported"))
        }
        
        guard let redirectUrl = try? URLRequest(url: url, method: .get) else {
            return
        }
        
        self.executeIfVc(action: "directPaymentRedirectURL") { vc in
            DispatchQueue.main.async {
                vc.indicator.isHidden = false
                vc.webView.isHidden = true
                vc.webView.load(redirectUrl)
            }
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
        
        executeIfVc(action: "handleResult") { vc in
            vc.indicator.isHidden = true
            vc.webView.isHidden = true

            vc.resultReceived(statusResponse: PaymentStatusResponse(paymentStatus: response.status, status: response.status.rawValue, paymentResult: response.paymentResult))
        }
        
    }
}



