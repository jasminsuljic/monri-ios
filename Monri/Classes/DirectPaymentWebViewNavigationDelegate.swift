//
//  DirectPaymentWebViewClient.swift
//  Monri
//
//  Created by Karolina Škunca on 02.04.2024..
//

import UIKit
import WebKit
import os.log

public protocol Delegate {
    func onPageLoadFinished()
}

class DirectPaymentWebViewNavigationDelegate: NSObject, WKNavigationDelegate {
    
    var webView: WKWebView!
    private var delegate: Delegate
    
    var logger: MonriLogger {
        MonriLoggerImpl(log: OSLog(subsystem: "Monri", category: "DirectPaymentWebViewClient"))
    }

    init(delegate: Delegate) {
        self.delegate = delegate
        self.webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let url = webView.url else {
            return
        }
        logger.info("didFinish \(url)")
        delegate.onPageLoadFinished()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        logger.info("didFail \(webView.url?.absoluteString ?? "") with error = \(error)")
    }
}
