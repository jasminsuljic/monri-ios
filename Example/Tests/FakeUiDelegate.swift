//
//  FakeUiDelegate.swift
//  Monri_Tests
//
//  Created by Karolina Škunca on 12.04.2024..
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import WebKit
import Monri
import Foundation

final class FakeUiDelegate: UiDelegate {
    
    private var currentUrl: URLRequest?
    
    private var webViewVisible: Bool = false
    private var loadingVisible: Bool = false
    private var paymentResultToHandle: ConfirmPaymentResult?
    
    func showLoading() {
        loadingVisible = true
    }
    
    func hideLoading() {
        loadingVisible = false
    }
    
    func showWebView() {
        webViewVisible = true
    }
    
    func hideWebView() {
        webViewVisible = false
    }
    
    func makeWebViewGone() {
        webViewVisible = false
    }
    
    func isWebViewVisible() -> Bool {
        return webViewVisible
    }
    
    func isLoadingVisible() -> Bool {
        return loadingVisible
    }
    
    func loadWebViewUrl(url: URLRequest) {
        currentUrl = url
    }
    
    func handlePaymentResult(paymentResult: ConfirmPaymentResult) {
        paymentResultToHandle = paymentResult
    }
    
    func pending() {
        paymentResultToHandle = .pending
    }
    
    func setFlowDelegate(delegate: Monri.TransactionAuthorizationFlowDelegate) {
        
    }
    
    func getCurrentUrl() -> String {
        return currentUrl?.url?.absoluteString ?? ""
    }
    
    func getPaymentResultToHandle() -> ConfirmPaymentResult? {
        return paymentResultToHandle
    }
}

