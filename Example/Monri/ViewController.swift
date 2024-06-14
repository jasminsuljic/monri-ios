//
//  ViewController.swift
//  Monri
//
//  Created by jasmin.suljic on 10/31/2019.
//  Copyright (c) 2019 jasmin.suljic. All rights reserved.
//

import UIKit
import Monri
import Alamofire

class ViewController: UIViewController {
    
    // TODO: replace with your merchant's authenticity monriToken
    let authenticityToken = "6a13d79bde8da9320e88923cb3472fb638619ccb"
    //TODO: replace with your merchant's merchant key
    let merchantKey = "TestKeyXULLyvgWyPJSwOHe";

    func createAccessToken(_ callback: @escaping (String) -> Void) {
        
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
                    let accessToken = "Bearer " + (json["access_token"] as? String ?? "")
                    
                    callback(accessToken)
                } else {
                    callback("nil")
                }
                
            } catch {
                callback("nil")
            }
        }
    }
    
    lazy var monri: MonriApi = {
        [unowned self] in
        return MonriApi(self.navigationController!, options: MonriApiOptions(authenticityToken: authenticityToken, developmentMode: true))
    }()
    
    var repository: OrdersRepository {
        OrdersRepository(authenticityToken: authenticityToken)
    }
    
    
    @IBAction func payWithSaved3DSCard(_ sender: Any) {
        let savedCard = SavedCard(panToken: "c32b3465be7278d239f68bb6d7623acf0530bf34574cf3b782754d281c76bd02", cvc: "123")
        
        repository.createPayment { response in
            guard let response = response else {
                return
            }
            
            let customerParams: CustomerParams = CustomerParams(
                customerUuid: self.createdCustomer?.uuid,
                email: "adnan.omerovic@monri.com",
                fullName: "Adnan Omerovic",
                address: "Address",
                city: "Sarajevo",
                zip: "71000",
                phone: "+38761000111",
                country: "BA"
            )
            
            let confirmPaymentParams = ConfirmPaymentParams(
                paymentId: response.clientSecret,
                paymentMethod: savedCard.toPaymentMethodParams(),
                transaction: TransactionParams.create().set(customerParams: customerParams)
                    .set("order_info", "iOS SDK payment session")
            )
            
            self.monri.confirmPayment(confirmPaymentParams) { result in
                switch (result) {
                case .result(let r):
                    self.alert("Transaction \(r.status)")
                    print("\(r)")
                case .error(let e):
                    self.alert("Transaction error \(e)")
                    print("\(e)")
                case .declined(let d):
                    self.alert("Transaction declined \(d.status)")
                    print("\(d)")
                case .pending:
                    self.alert("Transaction pending")
                    print("trx pending")
                }
            }
        }
    }
    
    @IBOutlet weak var saveCardForFuturePaymentsSwitch: UISwitch!
    
    let merchantUuid = UUID.init().uuidString
    var createdCustomer: Customer? = nil
    
    @IBAction func createCustomer(_ sender: Any) {
        let customerRequestBody = CustomerData(
            merchantCustomerUuid: merchantUuid,
            description: "description",
            email: "adnan.omerovic@monri.com",
            name: "Adnan",
            phone: "00387000111",
            metadata: ["a": "b", "c": "d"],
            zipCode: "71000",
            city: "Sarajevo",
            address: "Džemala Bijedića 2",
            country: "BA"
        )
        
        createAccessToken { accessToken in
            let createCustomerParams = CreateCustomerParams(accessToken: accessToken, customerData: customerRequestBody)
            
            self.monri.customers().create(createCustomerParams) { (result: CustomerResult) in
                
                switch (result) {
                case .result(let customer):
                    self.createdCustomer = customer
                    print("customer response\(customer.email)")
                    print("customer response\(customer.name)")
                case .error(let customerError):
                    print("customer error\(customerError)")
                }
                
            }
        }
    }
    
    @IBAction func updateCustomer(_ sender: Any) {
        guard let createdCustomer = createdCustomer else {
            return
        }
        
        let customerRequestBody = CustomerData(
            merchantCustomerUuid: merchantUuid,
            description: "description",
            email: "adnan.omerovic.updated@monri.com",
            name: "Adnan Updated",
            phone: "00387000111",
            metadata: ["Updated at": "\(NSDate().timeIntervalSince1970)", "c": "d"],
            zipCode: "71000",
            city: "Sarajevo",
            address: "Džemala Bijedića 2",
            country: "BA"
        )
        
        if(createdCustomer.uuid != nil){
            createAccessToken { accessToken in
                let customerUpdateRequest = UpdateCustomerParams(
                    customerData: customerRequestBody,
                    customerUuid: createdCustomer.uuid!,
                    accessToken: accessToken
                )
                
                self.monri.customers().update(customerUpdateRequest) { (result: CustomerResult) in
                    switch (result) {
                    case .result(let customerUpdateResponse):
                        print("customer update response\(customerUpdateResponse.name ?? "nil")")
                        print("customer update response\(customerUpdateResponse.metadata ?? ["nil":"nil"])")
                    case .error(let customerUpdateError):
                        print("customer update error\(customerUpdateError)")
                    }
                    
                }
            }
        }
        
    }
    
    
    @IBAction func deleteCustomer(_ sender: Any) {
        guard let createdCustomer = createdCustomer else {
            return
        }
        
        if(createdCustomer.uuid != nil){
            createAccessToken { accessToken in
                let customerDeleteRequest = DeleteCustomerParams(
                    customerUuid: createdCustomer.uuid!,
                    accessToken: accessToken
                )
                self.monri.customers().delete(customerDeleteRequest) { result in
                    switch (result) {
                    case .result(let customerDeleteResponse):
                        print("customer delete response\(customerDeleteResponse.deleted)")
                    case .error(let message):
                        print("customer update error\(message)")
                    }
                }
            }
        }
    }
    
    
    @IBAction func retrieveCustomer(_ sender: Any) {
        guard let createdCustomer = createdCustomer else {
            return
        }
        
        if(createdCustomer.uuid != nil){
            createAccessToken { accessToken in
                let customerRetrieveRequest = RetrieveCustomerParams(
                    accessToken: accessToken,
                    customerUuid: createdCustomer.uuid!
                )
                
                self.monri.customers().get(customerRetrieveRequest) { result in
                    switch (result) {
                    case .result(let customerResponse):
                        print("customer retrieve response\(customerResponse.city ?? "nil")")
                    case .error(let message):
                        print("customer retrieve error\(message)")
                    }
                }
            }
        }
        
        
    }
    
    
    @IBAction func retrieveCustomerViaMerchantId(_ sender: Any) {
        guard let createdCustomer = createdCustomer else {
            return
        }
        
        if(createdCustomer.merchantCustomerUuid != nil){
            createAccessToken { accessToken in
                let customerRetrieveMerchantIdRequest = RetrieveCustomerViaMerchantCustomerUuidParams(
                    accessToken: accessToken,
                    merchantCustomerUuid: createdCustomer.merchantCustomerUuid!
                )
                
                self.monri.customers().getViaMerchantCustomerUuid(customerRetrieveMerchantIdRequest) { result in
                    switch (result) {
                    case .result(let customerResponse):
                        print("customer retrieve response\(customerResponse.city ?? "nil")")
                    case .error(let message):
                        print("customer retrieve error\(message)")
                    }
                }
            }
        }
        
    }
    
    
    @IBAction func getAllCustomers(_ sender: Any) {
        createAccessToken { accessToken in
            self.monri.customers().all(accessToken) { result in
                switch (result) {
                case .result(let customerAllResponse):
                    print("All customers response: \(customerAllResponse.status)")
                    if (!customerAllResponse.customerResponseArray.isEmpty) {
                        let firstCustomer = customerAllResponse.customerResponseArray[0]
                        print("All customers response first customer email: \(firstCustomer.email ?? "nil")")
                    }
                case .error(let message):
                    print("retrieve customers error\(message)")
                }
            }
        }
    }
    
    
    @IBAction func retrieveSavedCardsFromCustomer(_ sender: Any) {
        guard let createdCustomer = createdCustomer else {
            return
        }
        
        if(createdCustomer.uuid != nil){
            createAccessToken { accessToken in
                let request = CustomerPaymentMethodParams(
                    customerUuid: createdCustomer.uuid!,
                    limit: 20,
                    offset: 0,
                    accessToken: accessToken
                )
                
                self.monri.customers().paymentMethods(request) { result in
                    switch (result) {
                    case .result(let paymentMethodResponse):
                        print("customer retrieve response\(paymentMethodResponse.status)")
                    case .error(let message):
                        print("customer retrieve error\(message)")
                    }
                }
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func confirmPayment(sender: UIButton) {
        var card = Card(number: "4111111111111111", cvc: "123", expMonth: 12, expYear: 2027);
        
        // Save card for future payments
        card.tokenizePan = saveCardForFuturePaymentsSwitch.isOn
        
        if (!card.validateCard()) {
            alert("Card validation failed")
            return
        }
        
        repository.createPayment { response in
            guard let response = response else {
                return
            }
            
            let customerParams: CustomerParams = CustomerParams(
                customerUuid: self.createdCustomer?.uuid,
                email: "tester+ios_sdk@monri.com",
                fullName: "Test iOS",
                address: "Address",
                city: "Sarajevo",
                zip: "71000",
                phone: "+38761000111",
                country: "BA"
            )
            
            let confirmPaymentParams = ConfirmPaymentParams(
                paymentId: response.clientSecret,
                paymentMethod: card.toPaymentMethodParams(),
                transaction: TransactionParams.create().set(customerParams: customerParams)
                    .set("order_info", "iOS SDK payment session")
            )
            
            self.monri.confirmPayment(confirmPaymentParams) { result in
                switch (result) {
                case .result(let r):
                    self.alert("Transaction \(r.status)")
                    print("\(r)")
                case .error(let e):
                    self.alert("Transaction error \(e)")
                    print("\(e)")
                case .declined(let d):
                    self.alert("Transaction declined \(d.status)")
                    print("\(d)")
                case .pending:
                    self.alert("Transaction pending")
                    print("trx pending")
                }
            }
        }
    }
    
    func non3DSCard() -> PaymentMethodParams {
        return Card(number: "4111 1111 1111 1111", cvc: "123", expMonth: 10, expYear: 2027).toPaymentMethodParams()
    }
    
    func threeDSCard() -> PaymentMethodParams {
        return Card(number: "4341 7920 0000 0044", cvc: "123", expMonth: 10, expYear: 2027).toPaymentMethodParams()
    }
    
    func alert(_ message: String) {
        let alert = UIAlertController(title: "Info", message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func directPayment(_ sender: Any) {
        repository.createPayment { response in
            guard let response = response else {
                return
            }
            
            let customerParams: CustomerParams = CustomerParams(
                customerUuid: self.createdCustomer?.uuid,
                email: "tester+ios_sdk@monri.com",
                fullName: "Tester Testerovic",
                address: "Address",
                city: "Sarajevo",
                zip: "71000",
                phone: "+38761000111",
                country: "BA"
            )
            
            let confirmPaymentParams = ConfirmPaymentParams(
                paymentId: response.clientSecret,
                paymentMethod: DirectPayment(paymentProvider: DirectPayment.Provider.PAY_CEK_HR).toPaymentMethodParams(),
                transaction: TransactionParams.create().set(customerParams: customerParams)
                    .set("order_info", "iOS SDK payment session")
            )
            
            self.monri.confirmPayment(confirmPaymentParams) { result in
                switch (result) {
                case .result(let r):
                    self.alert("Transaction \(r.status)")
                    print("\(r)")
                    break
                case .error(let e):
                    self.alert("Transaction error \(e)")
                    print("\(e)")
                case .declined(let d):
                    self.alert("Transaction declined \(d.status)")
                    print("\(d)")
                case .pending:
                    self.alert("Transaction pending")
                    print("trx pending")
                }
            }
        }
    }
    
}

