//
//  UiDelegate.swift
//  Monri
//
//  Created by Karolina Škunca on 11.04.2024..
//

import Foundation
import WebKit

public protocol UiDelegate {
    func showLoading()

    func hideLoading()

    func showWebView()

    func loadWebViewUrl(url: URLRequest)

    func hideWebView()

    func handlePaymentResult(paymentResult: ConfirmPaymentResult)

    func pending()
    
    func setFlowDelegate(delegate: TransactionAuthorizationFlowDelegate)
}
