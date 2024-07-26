//
//  ConfirmDirectPaymentFlowTest.swift
//  Monri_Tests
//
//  Created by Karolina Škunca on 12.04.2024..
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import XCTest
import Monri
import Alamofire
import Nimble

class ConfirmDirectPaymentFlowTest: XCTestCase {

    private let PAYMENT_ID = "paymentId"
    private let AUTHENTICITY_TOKEN = "authenticityToken"

    func testCreateShouldReturnInstanceWithValidInputParameters() {
        // Given
        let uiDelegate = FakeUiDelegate()
        let monriApiOptions = MonriApiOptions(authenticityToken: AUTHENTICITY_TOKEN, developmentMode: true)
        let currentViewController = UIApplication.shared.keyWindow?.rootViewController ?? UIViewController()
        let monriApi = MonriApi(currentViewController, options: monriApiOptions)
        let confirmPaymentParams: ConfirmPaymentParams? = ConfirmPaymentParams(paymentId: "", paymentMethod: PaymentMethodParams.init(type: "", data: [:]), transaction: TransactionParams.create())

        // When
        let confirmDirectPaymentFlow = ConfirmDirectPaymentFlowImpl(uiDelegate: uiDelegate,
                                                                    apiOptions: monriApiOptions,
                                                                    monriApi: monriApi,
                                                                    confirmPaymentParams: confirmPaymentParams!)

        // Then
        expect(confirmDirectPaymentFlow).toNot(beNil())
    }

    func testExecuteShouldLoadCorrectUrlAndRenderUi() {
        // Given
        let uiDelegate = FakeUiDelegate()
        let confirmPaymentParams = ConfirmPaymentParams(
            paymentId: PAYMENT_ID,
            paymentMethod: DirectPayment(paymentProvider: DirectPayment.Provider.PAY_CEK_HR).toPaymentMethodParams(),
            transaction: TransactionParams.create()
                .set("order_info", "iOS SDK payment session")
        )
        let monriApiOptions = MonriApiOptions(authenticityToken: AUTHENTICITY_TOKEN, developmentMode: true)
        let currentViewController = UIApplication.shared.keyWindow?.rootViewController ?? UIViewController()
        let monriApi = MonriApi(currentViewController, options: monriApiOptions)
        
        let confirmDirectPaymentFlow = ConfirmDirectPaymentFlowImpl(uiDelegate: uiDelegate,
                                                                    apiOptions: monriApiOptions,
                                                                    monriApi: monriApi,
                                                                    confirmPaymentParams: confirmPaymentParams)
        
        let expectedUrl = "https://ipgtest.monri.com/v2/direct-payment/pay-cek-hr/\(PAYMENT_ID)/redirect-to-payment-url"
        
        // When
        confirmDirectPaymentFlow.execute()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            expect(uiDelegate.isWebViewVisible()).to(beTrue())
            expect(uiDelegate.isLoadingVisible()).to(beTrue())
            expect(uiDelegate.getCurrentUrl()).to(equal(expectedUrl))
        }
        
    }

    func testExecuteShouldKeepCheckingForStatusWhenHandlingPaymentMethodRequiredStatus() {
        // Given
        let expectation = expectation(description: "testExecuteShouldKeepCheckingForStatusWhenHandlingPaymentMethodRequiredStatus")
        let expectedStatusChecksCount = 5
        
        let expectedPaymentResult = PaymentResult(status: "transaction_status",
                                                  currency: nil,
                                                  amount: nil,
                                                  orderNumber: nil,
                                                  panToken: nil,
                                                  createdAt: nil,
                                                  transactionType: nil,
                                                  paymentMethod: nil,
                                                  responseCode: nil,
                                                  responseMessage: nil,
                                                  errors: [])
        
        let paymentMethodRequiredResponse = PaymentStatusResponse(paymentStatus: .payment_method_required, status: PaymentStatus.payment_method_required.rawValue, paymentResult: expectedPaymentResult)
        let approvedResponse = PaymentStatusResponse(paymentStatus: .approved, status: PaymentStatus.approved.rawValue, paymentResult: nil)
        
        let uiDelegate = FakeUiDelegate()
        
        let confirmPaymentParams = ConfirmPaymentParams(
            paymentId: PAYMENT_ID,
            paymentMethod: DirectPayment(paymentProvider: DirectPayment.Provider.PAY_CEK_HR).toPaymentMethodParams(),
            transaction: TransactionParams.create()
                .set("order_info", "iOS SDK payment session")
        )
        
        let monriApiOptions = MonriApiOptions(authenticityToken: AUTHENTICITY_TOKEN, developmentMode: true)
        let currentViewController = UIApplication.shared.keyWindow?.rootViewController ?? UIViewController()
        let monriApi = MonriApi(currentViewController, options: monriApiOptions)
        
        monriApi.httpApi = FakeMonriHttpApi(paymentStatusHandler: .result(paymentMethodRequiredResponse), monriHttpApi: monriApi.httpApi)
        
        let atomicInteger = AtomicInteger()
        
        if let fakeApi = monriApi.httpApi as? FakeMonriHttpApi {
            
            let params = PaymentStatusParams(clientSecret: confirmPaymentParams.paymentId)
            
            if atomicInteger.incrementAndGet() < expectedStatusChecksCount {
                fakeApi.paymentStatus(params) { result in
                    uiDelegate.handlePaymentResult(paymentResult: ConfirmPaymentResult.result(paymentMethodRequiredResponse.paymentResult!))
                }
            } else {
                fakeApi.paymentStatus(params) { result in
                    uiDelegate.handlePaymentResult(paymentResult: ConfirmPaymentResult.result(approvedResponse.paymentResult!))
                }
            }
        }
        
        let confirmDirectPaymentFlow = ConfirmDirectPaymentFlowImpl(uiDelegate: uiDelegate,
                                                                    apiOptions: monriApiOptions,
                                                                    monriApi: monriApi,
                                                                    confirmPaymentParams: confirmPaymentParams)

        // When
        confirmDirectPaymentFlow.execute()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.5) {
            expectation.fulfill()
        }

        // Then
        waitForExpectations(timeout: 7, handler: nil)
        
        guard let fakeMonriHttpApi = monriApi.httpApi as? FakeMonriHttpApi else {
            XCTFail()
            return
        }
        
        expect(fakeMonriHttpApi.getStatusCheckInvokedCount()).to(equal(expectedStatusChecksCount))
        expect(uiDelegate.getPaymentResultToHandle()).toNot(beNil())
    }

    func testExecuteShouldReturnExpectedPaymentResultAndRenderUiWhenPaymentStatusIsApproved() {
        // Given
        let expectation = expectation(description: "testExecuteShouldReturnExpectedPaymentResultAndRenderUiWhenPaymentStatusIsApproved")
        
        let expectedPaymentResult = PaymentResult(status: "approved",
                                                  currency: nil,
                                                  amount: nil,
                                                  orderNumber: nil,
                                                  panToken: nil,
                                                  createdAt: nil,
                                                  transactionType: nil,
                                                  paymentMethod: nil,
                                                  responseCode: nil,
                                                  responseMessage: nil,
                                                  errors: [])
        
        let paymentMethodRequiredResponse = PaymentStatusResponse(paymentStatus: .approved, status: PaymentStatus.approved.rawValue, paymentResult: expectedPaymentResult)
        
        let uiDelegate = FakeUiDelegate()
        let confirmPaymentParams = ConfirmPaymentParams(
            paymentId: PAYMENT_ID,
            paymentMethod: DirectPayment(paymentProvider: DirectPayment.Provider.PAY_CEK_HR).toPaymentMethodParams(),
            transaction: TransactionParams.create()
                .set("order_info", "iOS SDK payment session")
        )
        let monriApiOptions = MonriApiOptions(authenticityToken: AUTHENTICITY_TOKEN, developmentMode: true)
        let currentViewController = UIApplication.shared.keyWindow?.rootViewController ?? UIViewController()
        let monriApi = MonriApi(currentViewController, options: monriApiOptions)
        
        monriApi.httpApi = FakeMonriHttpApi(paymentStatusHandler: .result(paymentMethodRequiredResponse), monriHttpApi: monriApi.httpApi)
        
        let confirmDirectPaymentFlow = ConfirmDirectPaymentFlowImpl(uiDelegate: uiDelegate,
                                                                    apiOptions: monriApiOptions,
                                                                    monriApi: monriApi,
                                                                    confirmPaymentParams: confirmPaymentParams)

        // When
        confirmDirectPaymentFlow.execute()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            expectation.fulfill()
        }

        // Then
        waitForExpectations(timeout: 6, handler: nil)
        
        switch uiDelegate.getPaymentResultToHandle() {
        case .result(let paymentResult):
            expect(paymentResult.status).to(equal(PaymentStatus.approved.rawValue))
        default:
            break
        }
        
        expect(uiDelegate.isWebViewVisible()).to(beFalse())
        expect(uiDelegate.isLoadingVisible()).to(beFalse())
    }

    func testExecuteShouldReturnPaymentResultWhenGetPaymentStatusReturnsError() {
        //Given
        let expectation = expectation(description: "testExecuteShouldReturnPaymentResultWhenGetPaymentStatusReturnsError")
        
        let uiDelegate = FakeUiDelegate()
        let confirmPaymentParams = ConfirmPaymentParams(
            paymentId: PAYMENT_ID,
            paymentMethod: DirectPayment(paymentProvider: DirectPayment.Provider.PAY_CEK_HR).toPaymentMethodParams(),
            transaction: TransactionParams.create()
                .set("order_info", "iOS SDK payment session")
        )
        let monriApiOptions = MonriApiOptions(authenticityToken: AUTHENTICITY_TOKEN, developmentMode: true)
        let currentViewController = UIApplication.shared.keyWindow?.rootViewController ?? UIViewController()
        let monriApi = MonriApi(currentViewController, options: monriApiOptions)
        
        monriApi.httpApi = FakeMonriHttpApi(paymentStatusHandler: .error(.requestFailed("Network Error")), monriHttpApi: monriApi.httpApi)
        
        let confirmDirectPaymentFlow = ConfirmDirectPaymentFlowImpl(uiDelegate: uiDelegate,
                                                                    apiOptions: monriApiOptions,
                                                                    monriApi: monriApi,
                                                                    confirmPaymentParams: confirmPaymentParams)


        // When
        confirmDirectPaymentFlow.execute()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            expectation.fulfill()
        }

        // Then
        waitForExpectations(timeout: 6, handler: nil)

        let actualPaymentResult = uiDelegate.getPaymentResultToHandle()
        
        expect(actualPaymentResult).toNot(beNil())
        
        if let actualPaymentResult = actualPaymentResult {
            switch actualPaymentResult {
            case .error(let paymentResultError):
                expect(paymentResultError.localizedDescription).to(equal("The operation couldn’t be completed. (Monri.PaymentResultError error 1.)"))
            default:
                XCTFail()
            }
        }
        
    }
}

