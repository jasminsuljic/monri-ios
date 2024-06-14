//
//  MonriPaymentsCustomerApiTest.swift
//  Monri_Tests
//
//  Created by Adnan Omerovic on 4. 1. 2023..
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import XCTest
import Monri
import Alamofire

final class MonriPaymentsCustomerApiTest: XCTestCase {
    let authenticityToken = "6a13d79bde8da9320e88923cb3472fb638619ccb";
    
    static let non3DSCard = Card(number: "4111 1111 1111 1111", cvc: "123", expMonth: 10, expYear: 2031, tokenizePan: true).toPaymentMethodParams()
    
    lazy var monri: MonriApi = {
        [unowned self] in
        let viewController = UIViewController()
        return MonriApi(viewController, options: MonriApiOptions(authenticityToken: authenticityToken, developmentMode: true));
    }()
    
    lazy var monriHttpApi: MonriHttpApi = {
        return MonriFactory().createHttpApi(options: MonriApiOptions(authenticityToken: authenticityToken, developmentMode: true))
    }()
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }
    
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    private func createPayment(_ callback: @escaping (String?, String?) -> Void) {
        AF.request("https://dashboard.monri.com/api/examples/ruby/examples/create-payment-session", method: .post, parameters: [:], encoding: JSONEncoding.default)
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
    
    private var accessToken: String? = nil
    
    func createAccessToken(_ callback: @escaping (String) -> Void) {
        if (self.accessToken != nil) {
            callback(self.accessToken!)
        }
        
        AF.request(
            "https://dashboard.monri.com/api/examples/ruby/examples/access_token",
            method: .get,
            encoding: JSONEncoding.default
            
        )
        .responseJSON { dataResponse in
            guard let data = dataResponse.data else {
                callback("")
                return
            }
            do {
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    callback("")
                    return
                }
                
                if (json["access_token"] != nil) {
                    self.accessToken = "Bearer " + (json["access_token"] as? String ?? "")
                    
                    callback(self.accessToken!)
                } else {
                    callback("nil")
                }
                
            } catch {
                callback("nil")
            }
        }
    }
    
    func testCreateCustomer() throws {
        let merchantUuid = UUID().uuidString
        let customerData = CustomerData(
            merchantCustomerUuid: merchantUuid,
            description: "description",
            email: "adnan.omerovic.updated@monri.com",
            name: "Adnan",
            phone: "00387000111",
            metadata: ["Updated at": "\(NSDate().timeIntervalSince1970)", "c": "d"],
            zipCode: "71000",
            city: "Sarajevo",
            address: "Džemala Bijedića 2",
            country: "BA"
        )
        
        var customerResult: CustomerResult?
        let expectation = self.expectation(description: "testCreateCustomer")
        
        createAccessToken { accessToken in
            let createCustomerParams = CreateCustomerParams(accessToken: accessToken, customerData: customerData)
            self.monri.customers().create(createCustomerParams) { (result: CustomerResult) in
                customerResult = result
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 15, handler: nil)
        
        switch customerResult {
        case .result(let customer):
            XCTAssertNotNil(customer)
            XCTAssertEqual(customerData.name, customer.name)
            XCTAssertEqual(customerData.merchantCustomerUuid, customer.merchantCustomerUuid)
            XCTAssertEqual(customerData.description, customer.description)
            XCTAssertEqual(customerData.email, customer.email)
            XCTAssertEqual(customerData.name, customer.name)
            XCTAssertEqual(customerData.phone, customer.phone)
            XCTAssertEqual(customerData.metadata, customer.metadata)
            XCTAssertEqual(customerData.zipCode, customer.zipCode)
            XCTAssertEqual(customerData.city, customer.city)
            XCTAssertEqual(customerData.address, customer.address)
            XCTAssertEqual(customerData.country, customer.country)
        case .error(let customerError):
            XCTFail("\(customerError)")
        case .none:
            XCTFail("customer has not been created")
        }
    }
    
    
    func testUpdateCustomer() throws {
        let merchantUuid = UUID().uuidString
        let customerData = CustomerData(
            merchantCustomerUuid: merchantUuid,
            description: "description",
            email: "adnan.omerovic.updated@monri.com",
            name: "Adnan",
            phone: "00387000111",
            metadata: ["Updated at": "\(NSDate().timeIntervalSince1970)", "c": "d"],
            zipCode: "71000",
            city: "Sarajevo",
            address: "Džemala Bijedića 2",
            country: "BA"
        )
        
        var customerUpdateResponse: CustomerResult?
        
        let expectation = self.expectation(description: "testUpdateCustomer")
        
        createAccessToken { accessToken in
            let createCustomerParams = CreateCustomerParams(accessToken: accessToken, customerData: customerData)
            self.monri.customers().create(createCustomerParams) { (result: CustomerResult) in
                switch result {
                case .result(let customer):
                    XCTAssertNotNil(customer)
                    XCTAssertNotNil(customer.uuid)
                    let customerUpdateRequest = UpdateCustomerParams(
                        customerData: customerData
                            .setName("Adnan Update")
                            .setEmail("email.update@monri.com"),
                        customerUuid: customer.uuid ?? "",
                        accessToken: accessToken
                    )
                    self.monri.customers().update(customerUpdateRequest) { (result: CustomerResult) in
                        customerUpdateResponse = result
                        expectation.fulfill()
                    }
                case .error(let customerError):
                    XCTFail("\(customerError)")
                }
                
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
        
        switch customerUpdateResponse {
        case .result(let customer):
            XCTAssertNotNil(customer)
            XCTAssertEqual(customerData.name, customer.name)
            XCTAssertEqual(customerData.merchantCustomerUuid, customer.merchantCustomerUuid)
            XCTAssertEqual(customerData.description, customer.description)
            XCTAssertEqual(customerData.email, customer.email)
            XCTAssertEqual(customerData.name, customer.name)
            XCTAssertEqual(customerData.phone, customer.phone)
            XCTAssertEqual(customerData.metadata, customer.metadata)
            XCTAssertEqual(customerData.zipCode, customer.zipCode)
            XCTAssertEqual(customerData.city, customer.city)
            XCTAssertEqual(customerData.address, customer.address)
            XCTAssertEqual(customerData.country, customer.country)
        case .error(let customerError):
            XCTFail("\(customerError)")
        case .none:
            XCTFail("customer has not been updated")
        }
    }
    
    
    func testDeleteCustomer() throws {
        let merchantUuid = UUID().uuidString
        let customerData = CustomerData(
            merchantCustomerUuid: merchantUuid,
            description: "description",
            email: "adnan.omerovic@monri.com",
            name: "Adnan delete",
            phone: "00387000111",
            metadata: ["Updated at": "\(NSDate().timeIntervalSince1970)", "c": "d"],
            zipCode: "71000",
            city: "Sarajevo",
            address: "Džemala Bijedića 2",
            country: "BA"
        )
        
        var customerDeleteResult: DeleteCustomerResult?
        var customer: Customer?
        
        
        let expectation = self.expectation(description: "testDeleteCustomer")
        
        createAccessToken { accessToken in
            let createCustomerParams = CreateCustomerParams(accessToken: accessToken, customerData: customerData)
            self.monri.customers().create(createCustomerParams) { (result: CustomerResult) in
                switch result {
                case .result(let customerResponse):
                    XCTAssertNotNil(customerResponse)
                    customer = customerResponse
                    let customerDeleteRequest = DeleteCustomerParams(
                        customerUuid: customerResponse.uuid ?? "",
                        accessToken: accessToken
                    )
                    self.monri.customers().delete(customerDeleteRequest) { (result: DeleteCustomerResult) in
                        customerDeleteResult = result
                        expectation.fulfill()
                    }
                case .error(let customerError):
                    XCTFail("\(customerError)")
                }
                
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
        
        switch customerDeleteResult {
        case .result(let customerDeleteResponse):
            XCTAssertNotNil(customerDeleteResponse)
            XCTAssertEqual(customerDeleteResponse.deleted, true)
            XCTAssertEqual(customerDeleteResponse.status, "approved")
            XCTAssertEqual(customerDeleteResponse.uuid, customer?.uuid)
        case .error(let customerError):
            XCTFail("\(customerError)")
        case .none:
            XCTFail("customer has not been deleted")
        }
    }
    
    func testRetrieveCustomer() throws {
        let merchantId = UUID().uuidString
        let customerRequestBody = CustomerData(
            merchantCustomerUuid: merchantId,
            description: "description",
            email: "adnan.omerovic.updated@monri.com",
            name: "Adnan",
            phone: "00387000111",
            metadata: ["Updated at": "\(NSDate().timeIntervalSince1970)", "c": "d"],
            zipCode: "71000",
            city: "Sarajevo",
            address: "Džemala Bijedića 2",
            country: "BA"
        )
        
        var customerUpdateResult: CustomerResult?
        
        let expectation = self.expectation(description: "testRetrieveCustomer")
        
        createAccessToken { accessToken in
            let createCustomerParams = CreateCustomerParams(accessToken: accessToken, customerData: customerRequestBody)
            self.monri.customers().create(createCustomerParams) { (result: CustomerResult) in
                switch result {
                case .result(let customerResponse):
                    XCTAssertNotNil(customerResponse)
                    let customerRetrieveRequest = RetrieveCustomerParams(
                        accessToken: accessToken,
                        customerUuid: customerResponse.uuid ?? ""
                    )
                    self.monri.customers().get(customerRetrieveRequest) { (result: CustomerResult) in
                        customerUpdateResult = result
                        expectation.fulfill()
                    }
                case .error(let customerError):
                    XCTFail("\(customerError)")
                }
                
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
        
        switch customerUpdateResult {
        case .result(let customerResponse):
            XCTAssertNotNil(customerResponse)
            XCTAssertEqual(customerRequestBody.name, customerResponse.name)
            XCTAssertEqual(customerRequestBody.merchantCustomerUuid, customerResponse.merchantCustomerUuid)
            XCTAssertEqual(customerRequestBody.description, customerResponse.description)
            XCTAssertEqual(customerRequestBody.email, customerResponse.email)
            XCTAssertEqual(customerRequestBody.name, customerResponse.name)
            XCTAssertEqual(customerRequestBody.phone, customerResponse.phone)
            XCTAssertEqual(customerRequestBody.metadata, customerResponse.metadata)
            XCTAssertEqual(customerRequestBody.zipCode, customerResponse.zipCode)
            XCTAssertEqual(customerRequestBody.city, customerResponse.city)
            XCTAssertEqual(customerRequestBody.address, customerResponse.address)
            XCTAssertEqual(customerRequestBody.country, customerResponse.country)
        case .error(let customerError):
            XCTFail("\(customerError)")
        case .none:
            XCTFail("customer has not been retrieved")
        }
    }
    
    func createCustomers(accessToken: String, num: Int, callback: @escaping ([Customer]) -> Void) {
        var customerResponseArray: [Customer] = []
        
        for _ in (0..<num) {
            let customerData = CustomerData(
                description: "description: \(Int(NSDate().timeIntervalSince1970))",
                email: "adnan.omerovic.updated@monri.com",
                name: "Adnan",
                phone: "00387000111",
                metadata: ["c": "d"],
                zipCode: "71000",
                city: "Sarajevo",
                address: "Džemala Bijedića 2",
                country: "BA"
            )
            
            let customerRequest = CreateCustomerParams(accessToken: accessToken, customerData: customerData)
            self.monri.customers().create(customerRequest) { (result: CustomerResult) in
                switch result {
                case .result(let customerResponse):
                    customerResponseArray.append(customerResponse)
                    if (customerResponseArray.count == num) {
                        callback(customerResponseArray)
                    }
                case .error(let customerError):
                    XCTFail("\(customerError)")
                }
                
            }
        }
    }
    
    func testRetrieveAllCustomers() throws {
        var createdCustomers: [Customer] = []
        var customers: [Customer] = []
        let expectation = self.expectation(description: "testRetrieveCustomers")
        
        createAccessToken { accessToken in
            self.createCustomers(accessToken: accessToken, num: 3) { createdCustomersResponse in
                createdCustomers = createdCustomersResponse
                self.monri.customers().all(accessToken) { result in
                    switch result {
                    case .result(let customerResponse):
                        customers = customerResponse.customerResponseArray
                        expectation.fulfill()
                    case .error(let customerError):
                        XCTFail("\(customerError)")
                    }
                }
            }
        }
        
        waitForExpectations(timeout: 25, handler: nil)
        
        for i in (0..<createdCustomers.count) {
            XCTAssertEqual(customers[i].description, createdCustomers[i].description)
        }
        
    }
    
    func testRetrieveCustomerViaMerchantId() throws {
        let merchantUuid = UUID().uuidString
        let customerData = CustomerData(
            merchantCustomerUuid: merchantUuid,
            description: "description",
            email: "adnan.omerovic.updated@monri.com",
            name: "Adnan",
            phone: "00387000111",
            metadata: ["Updated at": "\(NSDate().timeIntervalSince1970)", "c": "d"],
            zipCode: "71000",
            city: "Sarajevo",
            address: "Džemala Bijedića 2",
            country: "BA"
        )
        
        var customerResult: CustomerResult?
        
        let expectation = self.expectation(description: "testRetrieveCustomerViaMerchantId")
        
        createAccessToken { accessToken in
            let createCustomerParams = CreateCustomerParams(accessToken: accessToken, customerData: customerData)
            self.monri.customers().create(createCustomerParams) { (result: CustomerResult) in
                switch result {
                case .result(let customer):
                    XCTAssertNotNil(customer)
                    let customerRetrieveRequest = RetrieveCustomerViaMerchantCustomerUuidParams(
                        accessToken: accessToken,
                        merchantCustomerUuid: customer.merchantCustomerUuid ?? ""
                    )
                    self.monri.customers().getViaMerchantCustomerUuid(customerRetrieveRequest) { (result: CustomerResult) in
                        customerResult = result
                        expectation.fulfill()
                    }
                case .error(let customerError):
                    XCTFail("\(customerError)")
                }
                
            }
        }
        waitForExpectations(timeout: 15, handler: nil)
        
        switch customerResult {
        case .result(let customer):
            XCTAssertNotNil(customer)
            XCTAssertEqual(customerData.name, customer.name)
            XCTAssertEqual(customerData.merchantCustomerUuid, customer.merchantCustomerUuid)
            XCTAssertEqual(customerData.description, customer.description)
            XCTAssertEqual(customerData.email, customer.email)
            XCTAssertEqual(customerData.name, customer.name)
            XCTAssertEqual(customerData.phone, customer.phone)
            XCTAssertEqual(customerData.metadata, customer.metadata)
            XCTAssertEqual(customerData.zipCode, customer.zipCode)
            XCTAssertEqual(customerData.city, customer.city)
            XCTAssertEqual(customerData.address, customer.address)
            XCTAssertEqual(customerData.country, customer.country)
        case .error(let customerError):
            XCTFail("\(customerError)")
        case .none:
            XCTFail("customer has not been retrieved")
        }
    }
    
    func confirmPayment(card: PaymentMethodParams = non3DSCard,
                        customerParams: CustomerParams,
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
            
            let params = ConfirmPaymentParams(paymentId: clientSecret,
                                              paymentMethod: card,
                                              transaction: TransactionParams.create()
                .set(customerParams: customerParams)
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
    
    func testPayment() {
        let merchantUuid = UUID().uuidString
        let customerData = CustomerData(
            merchantCustomerUuid: merchantUuid,
            description: "description",
            email: "adnan.omerovic.updated@monri.com",
            name: "Adnan",
            phone: "00387000111",
            metadata: ["Updated at": "\(NSDate().timeIntervalSince1970)", "c": "d"],
            zipCode: "71000",
            city: "Sarajevo",
            address: "Džemala Bijedića 2",
            country: "BA"
        )
        
        var customer: Customer?
        
        let expectation0 = self.expectation(description: "testCreateCustomer")
        
        var tmpAccessToken: String = ""
        
        createAccessToken { accessToken in
            tmpAccessToken = accessToken
            let createCustomerParams = CreateCustomerParams(accessToken: accessToken, customerData: customerData)
            self.monri.customers().create(createCustomerParams) { (result: CustomerResult) in
                switch result {
                case .result(let customerResponse):
                    XCTAssertNotNil(customerResponse)
                    customer = customerResponse
                    expectation0.fulfill()
                case .error(let customerError):
                    XCTFail("\(customerError)")
                    expectation0.fulfill()
                }
                
            }
        }
        waitForExpectations(timeout: 10, handler: nil)
        
        let customerParams = CustomerParams(
            customerUuid: customer?.uuid,
            email: customerData.email,
            fullName: customerData.name,
            address: customerData.address,
            city: customerData.city,
            zip: customerData.zipCode,
            phone: customerData.phone,
            country: customerData.country
        )
        
        let expectation1 = self.expectation(description: "confirmPayment")
        confirmPayment(customerParams: customerParams) { errorResult, clientSecretResult, responseResult in
            XCTAssertEqual(PaymentStatus.approved, responseResult?.status)
            expectation1.fulfill()
        }
        
        waitForExpectations(timeout: 15, handler: nil)
        
        var customerPaymentMethodResponseResult: CustomerPaymentMethodResponseResult?
        let expectation2 = self.expectation(description: "testRetrievePaymentMethod")
        
        let customerPaymentMethodParams = CustomerPaymentMethodParams(
            customerUuid: customer?.uuid ?? "",
            limit: 25,
            offset: 0,
            accessToken: tmpAccessToken
        )
        self.monri.customers().paymentMethods(customerPaymentMethodParams) { (result: CustomerPaymentMethodResponseResult) in
            customerPaymentMethodResponseResult = result
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 25)
        
        switch customerPaymentMethodResponseResult {
        case .result(let customerPaymentMethodResponse):
            XCTAssertNotNil(customerPaymentMethodResponse)
            XCTAssertNotNil(customerPaymentMethodResponse.customerPaymentMethod)
            let paymentMethod = customerPaymentMethodResponse.customerPaymentMethod[0]
            XCTAssertEqual("411111******1111", paymentMethod.maskedPan)
            XCTAssertNotNil(paymentMethod.token)
            XCTAssertEqual(false, paymentMethod.expired)
            XCTAssertEqual("2031-10-31", paymentMethod.expirationDate)
            XCTAssertEqual(customerParams.customerUuid, paymentMethod.customerUuid)
        case .error(let customerError):
            XCTFail("\(customerError)")
        case .none:
            XCTFail("customer has not been retrieved")
        }
        
    }
}
