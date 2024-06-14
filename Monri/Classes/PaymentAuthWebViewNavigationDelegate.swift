//
// Created by Jasmin Suljic on 02/09/2020.
//

import Foundation
import WebKit
import os.log

class PaymentAuthWebViewNavigationDelegate: NSObject, WKNavigationDelegate {

    static let WHITELISTED_HOST_NAMES = [
        "https://ipgtest.monri.com",
        "https://ipg.monri.com",
        "https://ipgtest.webteh.hr",
        "https://ipg.webteh.hr"
    ]

    var flowDelegate: TransactionAuthorizationFlowDelegate? = nil

    var logger: MonriLogger {
        MonriLoggerImpl(log: OSLog(subsystem: "Monri", category: "PaymentAuthWebViewClient"))
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        guard let url = webView.url else {
            return
        }
        logger.info("didCommit \(url)")
        loadingUrlChange(uri: url, interceptedRequest: true)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!) {
        logger.info("didFail \(webView.url?.absoluteString ?? "")")
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let url = webView.url else {
            return
        }
        logger.info("didFinish \(url)")
        loadingUrlChange(uri: url, interceptedRequest: false)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        logger.info("didFail \(webView.url?.absoluteString ?? "") with error = \(error)")
    }

    func loadingUrlChange(uri: URL, interceptedRequest: Bool) {
        let url = "\(uri)"

        if (!validateHost(url: url)) {
            logger.trace("Host = [\(url)]validation failed")
            return
        }

        if (interceptedRequest) {
            logger.trace("intercepted url [\(url)]");
            if (url.contains("/client_redirect")) {
                flowDelegate?.redirectingToAcs()
            } else if (url.contains("/client_return")) {
                flowDelegate?.acsAuthenticationFinished()
            }
        } else {
            logger.trace("shouldOverrideUrlLoading url = [\(url)]");
            if (url.contains("v2/payment/hooks/3ds1")) {
                guard let status = uri.queryParameter("status"), let clientSecret = uri.queryParameter("client_secret") else {
                    logger.fatal("threeDs1Result result parsing failed for url = \(url)")
                    return
                }
                flowDelegate?.threeDs1Result(status: status, clientSecret: clientSecret)
            }
        }

    }

    func validateHost(url: String?) -> Bool {

        guard let url = url else {
            return false
        }

        if (!(url.contains("http"))) {
            return false
        }

        return PaymentAuthWebViewNavigationDelegate.WHITELISTED_HOST_NAMES.first { (whitelistedHostName: String) -> Bool in
            url.contains(whitelistedHostName)
        } != nil
    }
}

public protocol TransactionAuthorizationFlowDelegate {
    func threeDs1Result(status: String, clientSecret: String)
    func redirectingToAcs()
    func acsAuthenticationFinished()
}

extension URL {
    func queryParameter(_ name: String) -> String? {
        guard let url = URLComponents(string: self.absoluteString) else {
            return nil
        }
        return url.queryItems?.first(where: { $0.name == name })?.value
    }
}
