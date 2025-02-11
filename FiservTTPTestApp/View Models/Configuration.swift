//  ContentView
//
//  Copyright (c) 2022 - 2025 Fiserv, Inc.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

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

// QA - Omaha - Default
//class Configuration: ObservableObject {
//    @Published var secretKey: String = "W0tcspUD6AggWW2SBAz0pGvGEH22a0CrPzOCE3RkgsK"
//    @Published var apiKey: String = "GmHGvwBTARyTwfycqV2VAV1OxFLUqt6S"
//    let environment: FiservTTPEnvironment = .QA
//    let currencyCode: String = "USD"
//    @Published var appleTtpMerchantId: String?
//    @Published var merchantId: String = "100043202016058"
//    @Published var merchantName: String = "QAOMA-6058"
//    @Published var merchantCategoryCode: String = "1000"
//    @Published var terminalId: String = "10000001"
//    @Published var terminalProfileId:String = "4c840000-0000-0000-0cf1-ed816626ccc6"
//}

// CERT - Chandler
class Configuration: ObservableObject {
    @Published var secretKey: String = "RnrlUlhg9ibtiwsAX84N2aEmdKDo9MhydN7BZdGuUbN"
    @Published var apiKey: String = "zXhWhCG2PPX7ZkFOH1bx9iPxpKh5wr39"
    let environment: FiservTTPEnvironment = .Sandbox
    let currencyCode: String = "USD"
    @Published var appleTtpMerchantId: String?
    @Published var merchantId: String = "100014000306019"
    @Published var merchantName: String = "SBOX-6019"
    @Published var merchantCategoryCode: String = "1000"
    @Published var terminalId: String = "10000001"
    @Published var terminalProfileId:String = "4c840000-0000-0000-0cf1-ed816626ccc6"
}
