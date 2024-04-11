//
// Created by Jasmin Suljic on 01/09/2020.
//

import Foundation
import os.log

class ActionRequiredFlowImpl: ActionRequiredFlow {

//    private final PaymentAuthWebView webView;
//    private final ProgressBar progressBar;
//    private final MonriApi monriApi;

    weak var vc: ConfirmPaymentControllerViewController?
    private let clientSecret: String

    let atomicInteger = AtomicInteger()
    let monriApi: MonriHttpApi

    var logger: MonriLogger {
        MonriLoggerImpl(log: OSLog(subsystem: "Monri", category: "ActionRequiredFlow"))
    }

    var invocationState: InvocationState = InvocationState.CALLBACK_NOT_INVOKED
    let navigationDelegate: PaymentAuthWebViewNavigationDelegate

    init(vc: ConfirmPaymentControllerViewController,
         navigationDelegate: PaymentAuthWebViewNavigationDelegate,
         monriApi: MonriHttpApi,
         clientSecret: String) {
        self.vc = vc
        self.navigationDelegate = navigationDelegate
        self.monriApi = monriApi
        self.clientSecret = clientSecret
        vc.navigationDelegate.flowDelegate = self
    }

    func executeIfVc(action: String, _ callable: (ConfirmPaymentControllerViewController) -> Void) {
        guard let vc = vc else {
            logger.info("Tried executing \(action), vc is nil")
            return
        }

        callable(vc)
    }

    func handleResult(_ response: ConfirmPaymentResponse) {
        logger.trace("Received response [\(response.status.rawValue)]")
        guard let vc = vc else {
            logger.fatal("Invoked without available ViewController! Payment id = [\(response.status)]")
            return
        }

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
                vc.indicator.isHidden = false
                vc.webView.isHidden = true
                vc.webView.load(redirectUrl)
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
        
        guard let vc = vc else {
            logger.info("Tried executing threeDs1Result:\(status), vc is nil")
            return
        }

        DispatchQueue.main.async {
            vc.indicator.isHidden = false
            vc.indicator.startAnimating()
            vc.webView.isHidden = true
        }

        checkPaymentStatus(clientSecret: clientSecret, count: atomicInteger.incrementAndGet())
    }

    func checkPaymentStatus(clientSecret: String, count: Int) {
        if (count >= 3) {
            self.executeIfVc(action: "checkPaymentStatus") { vc in
                logger.info("Retry count exceeded \(count)")
                vc.paymentStatusRetryExceeded()
            }
        } else {
            monriApi.paymentStatus(PaymentStatusParams(clientSecret: clientSecret)) {
                result in
                self.executeIfVc(action: "paymentStatus") { vc in
                    switch (result) {
                    case .error:
                        self.checkPaymentStatus(clientSecret: clientSecret, count: self.atomicInteger.incrementAndGet())
                    case .result(let r):
                        vc.resultReceived(statusResponse: r)
                    }
                }
            }
        }
    }

    func redirectingToAcs() {
        executeIfVc(action: "redirectingToAcs") { vc in
            executeIfStatus(InvocationState.HANDLE_RESULT, InvocationState.REDIRECTING_TO_ACS, {

                logger.info("redirectingToAcs");

                DispatchQueue.main.async {
                    vc.webView.isHidden = false
                    vc.indicator.isHidden = true
                    vc.indicator.stopAnimating()
                }
            })
        }
    }

    func acsLoadFinished() {
        executeIfVc(action: "acsLoadFinished") { vc in
            executeIfStatus(InvocationState.REDIRECTING_TO_ACS, InvocationState.ACS_LOAD_FINISHED, {

                logger.info("acsLoadFinished");

                DispatchQueue.main.async {
                    vc.webView.isHidden = false
                    vc.indicator.isHidden = true
                    vc.indicator.stopAnimating()
                }
            })
        }
    }

    func acsAuthenticationFinished() {
        executeIfVc(action: "acsAuthenticationFinished") { vc in
            executeIfStatus(InvocationState.REDIRECTING_TO_ACS, InvocationState.ACS_AUTHENTICATION_FINISHED, {

                logger.info("acsAuthenticationFinished");

                DispatchQueue.main.async {
                    vc.webView.isHidden = true
                    vc.indicator.isHidden = false
                    vc.indicator.startAnimating()
                }
            })
        }
    }
}
