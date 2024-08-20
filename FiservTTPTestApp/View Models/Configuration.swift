//
//  Configuration.swift
//  FiservTTPTestApp
//
//  Created by Richard Tilt on 4/13/23.
//

import Foundation
import FiservTTP

//class Configuration: ObservableObject {
//    
//    @Published var secretKey: String = "YOUR-SECRET-KEY"
//    @Published var apiKey: String = "YOUR-API-KEY"
//    let environment: FiservTTPEnvironment = .Sandbox
//    let currencyCode: String = "USD"
//    @Published var appleTtpMerchantId: String?
//    @Published var merchantId: String = "190009000000700"
//    @Published var merchantName: String = "Tom's Tacos"
//    @Published var merchantCategoryCode: String = "1000"
//    @Published var terminalId: String = "10000001"
//    @Published var terminalProfileId: String = "3c00e000-a009-a14f-5a63-cf156a000001"
//}

class Configuration: ObservableObject {
    @Published var secretKey: String = "OW6prOMR3ut7VJvjfkkBywCSmDvhPlDmRzw2PD6W8u9"
    @Published var apiKey: String = "O0lVfgyThiZ0AYynRSdEuMDP5syAZ96I"
    let environment: FiservTTPEnvironment = .QA
    let currencyCode: String = "USD"
    @Published var appleTtpMerchantId: String?
    @Published var merchantId: String = "100043202016058"
    @Published var merchantName: String = "QA-6058"
    @Published var merchantCategoryCode: String = "1000"
    @Published var terminalId: String = "10000001"
    @Published var terminalProfileId:String = "4c840000-0000-0000-0cf1-ed816626ccc6"
}
