//
// Created by Jasmin Suljic on 01/09/2020.
//

import Foundation
import os.log

class ActionRequiredFlowImpl: ActionRequiredFlow {

    private var uiDelegate: UiDelegate
    private let clientSecret: String

    let atomicInteger = AtomicInteger()
    let monriApi: MonriHttpApi

    var logger: MonriLogger {
        MonriLoggerImpl(log: OSLog(subsystem: "Monri", category: "ActionRequiredFlow"))
    }

    var invocationState: InvocationState = InvocationState.CALLBACK_NOT_INVOKED

    init(uiDelegate: UiDelegate,
         monriApi: MonriHttpApi,
         clientSecret: String) {
        self.uiDelegate = uiDelegate
        self.monriApi = monriApi
        self.clientSecret = clientSecret
        self.uiDelegate.setFlowDelegate(delegate: self)
    }

    func handleResult(_ response: ConfirmPaymentResponse) {
        logger.trace("Received response [\(response.status.rawValue)]")
        
        guard let actionRequired = response.actionRequired else {
            logger.fatal("Invoked with nil action required \(response.status)")
            return
        }

        executeIfStatus(InvocationState.CALLBACK_NOT_INVOKED, InvocationState.HANDLE_RESULT, {
            let acsUrl = actionRequired.acsUrl
            guard let redirectUrl = try? URLRequest(url: actionRequired.redirectTo, method: .get) else {
                logger.fatal("Received invalid redirectUrl [\(actionRequired.redirectTo)]")
                return
            }


            logger.info("Handle result invoked with acsUrl = \(acsUrl)")

            DispatchQueue.main.async {
                self.uiDelegate.showLoading()
                self.uiDelegate.hideWebView()
                self.uiDelegate.loadWebViewUrl(url: redirectUrl)
            }
        })

    }

    func executeIfStatus(_ state: InvocationState, _ newState: InvocationState, _ runnable: () -> Void) {
        logger.info("Changing state to state = [\(newState)] from currentState = [\(state)]")
        self.invocationState = newState
        runnable()
    }


    enum InvocationState {
        case CALLBACK_NOT_INVOKED,
             THREE_DS_RESULT,
             REDIRECTING_TO_ACS,
             ACS_LOAD_FINISHED,
             ACS_AUTHENTICATION_FINISHED,
             HANDLE_RESULT
    }
}

extension ActionRequiredFlowImpl: TransactionAuthorizationFlowDelegate {

    func threeDs1Result(status: String, clientSecret: String) {
        logger.info("ThreeDs1Result, status = \(status), clientSecret = \(clientSecret)");

        DispatchQueue.main.async {
            self.uiDelegate.hideWebView()
            self.uiDelegate.showLoading()
        }

        checkPaymentStatus(clientSecret: clientSecret, count: atomicInteger.incrementAndGet())
    }

    func checkPaymentStatus(clientSecret: String, count: Int) {
        if (count >= 3) {
            logger.info("Retry count exceeded \(count)")
            uiDelegate.pending()
        } else {
            monriApi.paymentStatus(PaymentStatusParams(clientSecret: clientSecret)) {
                result in
                
                switch (result) {
                case .error:
                    self.checkPaymentStatus(clientSecret: clientSecret, count: self.atomicInteger.incrementAndGet())
                case .result(let r):
                    if let paymentResult = r.paymentResult {
                        self.uiDelegate.handlePaymentResult(paymentResult: ConfirmPaymentResult.result(paymentResult))
                    } else {
                        self.uiDelegate.pending()
                    }
                }
            }
        }
    }

    func redirectingToAcs() {
        executeIfStatus(InvocationState.HANDLE_RESULT, InvocationState.REDIRECTING_TO_ACS, {

            logger.info("redirectingToAcs");

            DispatchQueue.main.async {
                self.uiDelegate.showWebView()
                self.uiDelegate.hideLoading()
            }
        })
    }

    func acsLoadFinished() {
        executeIfStatus(InvocationState.REDIRECTING_TO_ACS, InvocationState.ACS_LOAD_FINISHED, {

            logger.info("acsLoadFinished");

            DispatchQueue.main.async {
                self.uiDelegate.showWebView()
                self.uiDelegate.hideLoading()
            }
        })
    }

    func acsAuthenticationFinished() {
        executeIfStatus(InvocationState.REDIRECTING_TO_ACS, InvocationState.ACS_AUTHENTICATION_FINISHED, {

            logger.info("acsAuthenticationFinished");

            DispatchQueue.main.async {
                self.uiDelegate.hideWebView()
                self.uiDelegate.showLoading()
            }
        })
    }
}
