//
//  FakeMonriApi.swift
//  Monri_Example
//
//  Created by Karolina Škunca on 12.04.2024..
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import Monri

final class FakeMonriHttpApi: MonriHttpApi {
    
    private var paymentStatusHandler: PaymentStatusResponseResult?
    
    private var statusCheckInvokedCount: Int = 0
    public var monriHttpApi: MonriHttpApi?
    
    init(paymentStatusHandler: PaymentStatusResponseResult?, monriHttpApi: MonriHttpApi? = nil) {
        self.monriHttpApi = monriHttpApi
        self.paymentStatusHandler = paymentStatusHandler
    }
    
    func paymentStatusCalled() {
        statusCheckInvokedCount += 1
    }
    
    func getStatusCheckInvokedCount() -> Int {
        return statusCheckInvokedCount
    }
    
    func confirmPayment(_ params: Monri.ConfirmPaymentParams, _ callback: @escaping Monri.ConfirmPaymentCallback) {
        
    }
    
    func paymentStatus(_ params: Monri.PaymentStatusParams, _ callback: @escaping Monri.PaymentStatusResponseResultCallback) {
        
        paymentStatusCalled()
        
        if let paymentStatusHandler = paymentStatusHandler {
            callback(paymentStatusHandler)
        }
        
    }
    
    func createToken(_ request: Monri.TokenRequest, paymentMethod: Monri.PaymentMethod, _ callback: @escaping Monri.TokenResultCallback) {
        
    }
    
    func createCustomer(_ params: Monri.CreateCustomerParams, _ callback: @escaping Monri.CustomerCallback) {
        
    }
    
    func updateCustomer(_ params: Monri.UpdateCustomerParams, _ callback: @escaping Monri.CustomerCallback) {
        
    }
    
    func deleteCustomer(_ params: Monri.DeleteCustomerParams, _ callback: @escaping Monri.DeleteCustomerCallback) {
        
    }
    
    func retrieveCustomer(_ params: Monri.RetrieveCustomerParams, _ callback: @escaping Monri.CustomerCallback) {
        
    }
    
    func retrieveCustomerViaMerchantCustomerUuid(_ params: Monri.RetrieveCustomerViaMerchantCustomerUuidParams, _ callback: @escaping Monri.CustomerCallback) {
        
    }
    
    func retrieveAllCustomers(_ accessToken: String, _ callback: @escaping Monri.MerchantCustomersCallback) {
        
    }
    
    func retrieveCustomerPaymentMethods(_ params: Monri.CustomerPaymentMethodParams, _ callback: @escaping Monri.CustomerPaymentMethodResponseCallback) {
        
    }
    
    
}

extension FakeMonriHttpApi {
    typealias PaymentStatusHandler = (PaymentStatusResponseResultCallback) -> Void
}
