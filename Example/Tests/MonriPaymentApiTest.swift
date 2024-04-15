//
// Created by Jasmin Suljic on 03/09/2020.
// Copyright (c) 2020 CocoaPods. All rights reserved.
//

import XCTest
import Nimble
import Monri
import Monri_Example
import Alamofire

class MonriPaymentApiTest: XCTestCase {

    // TODO: replace with your merchant's authenticity monriToken
    let authenticityToken = "6a13d79bde8da9320e88923cb3472fb638619ccb"
    //TODO: replace with your merchant's merchant key
    let merchantKey = "TestKeyXULLyvgWyPJSwOHe"

    static let non3DSCard = Card(number: "4111 1111 1111 1111", cvc: "123", expMonth: 10, expYear: 2031).toPaymentMethodParams()
    static let threeDSCard = Card(number: "4341 7920 0000 0044", cvc: "123", expMonth: 10, expYear: 2031).toPaymentMethodParams()

    lazy var monri: MonriApi = {
        [unowned self] in
        let currentViewController = UIApplication.shared.keyWindow?.rootViewController ?? UIViewController()
        return MonriApi(currentViewController, options: MonriApiOptions(authenticityToken: authenticityToken, developmentMode: true));
    }()
    
    var monriHttpApi: MonriHttpApi!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        monriHttpApi = MonriFactory().createHttpApi(options: MonriApiOptions(authenticityToken: authenticityToken, developmentMode: true))
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        expect(true).to(equal(true))
    }

    func createPayment(_ callback: @escaping (String?, String?) -> Void) {
        AF.request(
            "https://dashboard.monri.com/api/examples/ruby/examples/create-payment-session",
            method: .post,
            parameters: [:],
            encoding: JSONEncoding.default
        )
                .responseJSON { dataResponse in
                    guard let data = dataResponse.data else {
                        callback(nil, nil)
                        return
                    }
                    do {
                        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                            callback(nil, nil)
                            return
                        }

                        callback(json["client_secret"] as? String, json["status"] as? String)
                    } catch {
                        callback(nil, nil)
                    }
                }
    }

    func confirmPayment(card: PaymentMethodParams = MonriPaymentApiTest.non3DSCard,
                        customerParams: CustomerParams? = nil,
                        _ callback: @escaping (_ error: String?, _ clientSecret: String?, _ response: ConfirmPaymentResponse?) -> Void) {
        
        createPayment { clientSecret, status in

            guard status != nil else {
                callback("Payment create failed", nil, nil)
                return
            }

            guard let clientSecret = clientSecret else {
                callback("Payment create failed", nil, nil)
                return
            }
            
            let customerParams = customerParams ?? CustomerParams(
                    email: "tester+ios_sdk@monri.com",
                    fullName: "Test iOS",
                    address: "Address",
                    city: "Sarajevo",
                    zip: "71000",
                    phone: "+38761000111",
                    country: "BA"
            )

            let params = ConfirmPaymentParams(paymentId: clientSecret,
                    paymentMethod: card,
                    transaction: TransactionParams.create().set(customerParams: customerParams)
                            .set("order_info", "iOS SDK payment session")
            )

            self.monriHttpApi.confirmPayment(params) { confirmPayment in
                switch (confirmPayment) {
                case .error(let e):
                    callback("Confirm payment error \(e)", nil, nil)
                case .unknownError(let e):
                    callback("Confirm payment error \(e)", nil, nil)
                case .result(let r):
                    callback(nil, clientSecret, r)
                case .pending:
                    callback("Confirm payment pending", nil, nil)
                }
            }
        }
    }
    
    func testPaymentResultCreate() throws {
        let json: [String: Any] = [

  "action_required": [
    "acs_url": "https://ipgtest.monri.com/processing/three_ds1/19d4a0ec1a1a9af74c83d66f7222456e6563cf5c/client_redirect",
    "redirect_to": "https://ipgtest.monri.com/processing/three_ds1/19d4a0ec1a1a9af74c83d66f7222456e6563cf5c/client_redirect"
  ],
  "client_secret": "19d4a0ec1a1a9af74c83d66f7222456e6563cf5c",
  "payment_result": [
    "amount": 100,
    "created_at": "2020-09-10T23:01:41.839+02:00",
    "currency": "HRK",
    "order_number": "hHbDrcyDBcEvbP4_TF54DPOVSBUBgtCJx-poikyb",
    "outgoing_amount": 100,
    "outgoing_currency": "HRK",
    "pan_token": "c32b3465be7278d239f68bb6d7623acf0530bf34574cf3b782754d281c76bd02",
    "payment_method": [
      "data": [
        "brand": "visa",
        "expiration_date": 2012,
        "issuer": "off-us",
        "masked": "434179-xxx-xxx-0044",
        "token": "c32b3465be7278d239f68bb6d7623acf0530bf34574cf3b782754d281c76bd02"
      ],
      "type": "card"
    ],
    "response_code": "0000",
    "response_message": "approved",
    "status": "approved",
    "transaction_type": "authorize"
  ],
  "payment_status": "executed",
  "status": "approved"
]

        let response: PaymentStatusResponse = PaymentStatusResponse.fromJson(json)!
        
        expect(response).notTo(beNil())
        
        expect(response.status).to(equal("approved"))
        
        expect(response.paymentResult?.paymentMethod).notTo(beNil())
        let pm = response.paymentResult!.paymentMethod!
        
        expect(pm.data["brand"]).to(equal("visa"))
        expect(pm.data["expiration_date"]).to(equal("2012"))
        expect(pm.data["issuer"]).to(equal("off-us"))
        expect(pm.data["masked"]).to(equal("434179-xxx-xxx-0044"))
        expect(pm.data["token"]).to(equal("c32b3465be7278d239f68bb6d7623acf0530bf34574cf3b782754d281c76bd02"))
        expect(pm.type).to(equal("card"))
        
    }

    func testConfirmPaymentActionRequired() throws {
//        let repo = OrdersRepository(authenticityToken: authenticityToken)
        let expectation = self.expectation(description: "testConfirmPaymentActionRequired")
        var confirmPaymentResponse: ConfirmPaymentResponse? = nil
        var confirmPaymentStatus: String? = nil
        var error: Error? = nil
        createPayment { clientSecret, status in

            guard status != nil else {
                return
            }

            guard let clientSecret = clientSecret else {
                return
            }


            let customerParams: CustomerParams = CustomerParams(
                    email: "tester+ios_sdk@monri.com",
                    fullName: "Test iOS",
                    address: "Address",
                    city: "Sarajevo",
                    zip: "71000",
                    phone: "+38761000111",
                    country: "BA"
            )

            let params = ConfirmPaymentParams(paymentId: clientSecret,
                    paymentMethod: Self.threeDSCard,
                    transaction: TransactionParams.create().set(customerParams: customerParams)
                            .set("order_info", "iOS SDK payment session")
            )

            self.monriHttpApi.confirmPayment(params) { confirmPayment in
                switch (confirmPayment) {
                case .error(let e):
                    error = e
                case .unknownError(let e):
                    error = e
                case .result(let r):
                    confirmPaymentResponse = r
                    confirmPaymentStatus = r.status.rawValue
                case .pending:
                    confirmPaymentStatus = "pending"
                }

                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 30, handler: nil)

        expect(error).to(beNil())
        expect(confirmPaymentStatus).to(equal("action_required"))
        expect(confirmPaymentResponse).notTo(beNil())
        expect(confirmPaymentResponse!.actionRequired).notTo(beNil())
        expect(confirmPaymentResponse!.actionRequired!.acsUrl).notTo(beNil())
        expect(confirmPaymentResponse!.actionRequired!.redirectTo).notTo(beNil())
    }

    func testPaymentStatus() throws {
        var error: String? = nil
        var clientSecret: String? = nil
        var response: ConfirmPaymentResponse? = nil
        var paymentStatusResponse: PaymentStatusResponseResult? = nil
        let expectation = self.expectation(description: "testPaymentStatus")
        confirmPayment {
            error = $0
            clientSecret = $1
            response = $2
            expectation.fulfill()
        }

        waitForExpectations(timeout: 30, handler: nil)
        expect(error).to(beNil())
        expect(clientSecret).notTo(beNil())
        expect(response).notTo(beNil())

        let expectation2 = self.expectation(description: "testPaymentStatus2")

        monriHttpApi.paymentStatus(PaymentStatusParams(clientSecret: clientSecret!)) {
            paymentStatusResponse = $0
            expectation2.fulfill()
        }

        waitForExpectations(timeout: 30, handler: nil)
        expect(paymentStatusResponse).notTo(beNil())
        switch (paymentStatusResponse!) {
        case .error(let e):
            expect(e).to(beNil(), description: "Got error \(e), expected status approved");
        case .result(let r):
            expect(r.status).to(equal("approved"))
        }
    }

    func testConfirmPaymentApproved() throws {
        //        let repo = OrdersRepository(authenticityToken: authenticityToken)
        let expectation = self.expectation(description: "testConfirmPaymentApproved")
        var confirmPaymentResponse: ConfirmPaymentResponse? = nil
        var confirmPaymentStatus: String? = nil
        var error: Error? = nil
        createPayment { clientSecret, status in

            guard status != nil else {
                return
            }

            guard let clientSecret = clientSecret else {
                return
            }


            let customerParams: CustomerParams = CustomerParams(
                    email: "tester+ios_sdk@monri.com",
                    fullName: "Test iOS",
                    address: "Address",
                    city: "Sarajevo",
                    zip: "71000",
                    phone: "+38761000111",
                    country: "BA"
            )

            let params = ConfirmPaymentParams(paymentId: clientSecret,
                    paymentMethod: MonriPaymentApiTest.non3DSCard,
                    transaction: TransactionParams.create().set(customerParams: customerParams)
                            .set("order_info", "iOS SDK payment session")
            )

            self.monriHttpApi.confirmPayment(params) { confirmPayment in
                switch (confirmPayment) {
                case .error(let e):
                    error = e
                case .unknownError(let e):
                    error = e
                case .result(let r):
                    confirmPaymentResponse = r
                    confirmPaymentStatus = r.status.rawValue
                case .pending:
                    confirmPaymentStatus = "pending"
                }

                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 30, handler: nil)

        expect(error).to(beNil())
        expect(confirmPaymentStatus).to(equal("approved"))
        expect(confirmPaymentResponse).notTo(beNil())
        expect(confirmPaymentResponse!.paymentResult).notTo(beNil())
        let paymentResult: PaymentResult = confirmPaymentResponse!.paymentResult!
        let json = paymentResult.toJSON();
        expect(json).notTo(beNil())
        expect(json["currency"] as? String).to(equal(paymentResult.currency))
        expect(json["transaction_type"] as? String).to(equal(paymentResult.transactionType))
        expect(json["amount"] as? Int).to(equal(paymentResult.amount))
        expect(json["status"] as? String).to(equal(paymentResult.status))
        expect(json["order_number"] as? String).to(equal(paymentResult.orderNumber))
        expect(json["created_at"] as? String).to(equal(paymentResult.createdAt))
        expect(paymentResult.status).notTo(beNil())
        expect(paymentResult.currency).notTo(beNil())
        expect(paymentResult.transactionType).notTo(beNil())
        expect(paymentResult.createdAt).notTo(beNil())
        expect(paymentResult.amount).notTo(beNil())
        expect(paymentResult.orderNumber).notTo(beNil())
    }

    func threeDSCard() -> PaymentMethodParams {
        return Card(number: "4341 7920 0000 0044", cvc: "123", expMonth: 10, expYear: 2027).toPaymentMethodParams()
    }

    func testCreateToken() throws {
        let date = Date()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions.insert(.withFractionalSeconds)
        let timestamp = formatter.string(from: date);
        let token = UUID.init().uuidString
        // merchantKey, token, timestamp
        let digest = "\(merchantKey)\(token)\(timestamp)".sha512
        let tokenRequest = TokenRequest(token: token, digest: digest, timestamp: timestamp)
        let card = Card(number: "4111 1111 1111 1111", cvc: "123", expMonth: 12, expYear: 2027)
        var createTokenResult: Token? = nil
        var error: Error? = nil
        // Create an expectation
        let expectation = self.expectation(description: "createToken")
        monriHttpApi.createToken(tokenRequest, paymentMethod: card) {
            switch $0 {
            case .error(let e):
                error = e
            case .token(let t):
                createTokenResult = t
            }

            expectation.fulfill()
        }

        waitForExpectations(timeout: 30, handler: nil)
        expect(error).to(beNil())
        expect(createTokenResult).notTo(be(nil))
        expect(createTokenResult!.id).to(equal(token))
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
