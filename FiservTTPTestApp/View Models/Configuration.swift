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

//// CAT ByPass
//class Configuration: ObservableObject {
//
//    @Published var secretKey: String = "48P9HNhp6AgCLd1byw6dHAHqZqk53p0sC5JT7FAjvdj"
//    @Published var apiKey: String = "0x4NNUtU5GsgKlGTaj9jEzujXhkc68Aj"
//    let environment: FiservTTPEnvironment = .Cat
//    let currencyCode: String = "USD"
//    @Published var appleTtpMerchantId: String?
//    @Published var merchantId: String = "100283000000027"
//    @Published var merchantName: String = "CAT-BP-0027"
//    @Published var merchantCategoryCode: String = "1000"
//    @Published var terminalId: String = "10000001"
//    @Published var terminalProfileId: String = "4c840000-0000-0000-0cf1-ed816626ccc6"
//}

// GC TEST - 08/22/2024
//class Configuration: ObservableObject {
//    @Published var secretKey: String = "ySbAM7dvFbztdxDH2PJkoFSlaTrgFAbLFIoXpljUrOK"
//    @Published var apiKey: String = "aAOxe2l5HAGY2wgiFekEHECcZHpafNzh"
//    let environment: FiservTTPEnvironment = .Sandbox
//    let currencyCode: String = "USD"
//    @Published var appleTtpMerchantId: String?
//    @Published var merchantId: String = "100046000000325"
//    @Published var merchantName: String = "GC-0325"
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

// Sandbox - Omaha
//class Configuration: ObservableObject {
//    @Published var secretKey: String = "uJEdscHKH0iEgddiGXqG4oyivJaUpSlqzGITyABfKZf"
//    @Published var apiKey: String = "AXl4FvMWIN151sgYzL60wFU5sz1CtrA8"
//    let environment: FiservTTPEnvironment = .Sandbox
//    let currencyCode: String = "USD"
//    @Published var appleTtpMerchantId: String?
//    @Published var merchantId: String = "100014000306019"
//    @Published var merchantName: String = "CERTOMA-6019"
//    @Published var merchantCategoryCode: String = "1000"
//    @Published var terminalId: String = "10000001"
//    @Published var terminalProfileId:String = "4c840000-0000-0000-0cf1-ed816626ccc6"
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

// CAT - Omaha
// Key: fINKcbPnxzcmpDvleoUPy5SAjk7NpIvS
// Secret: 6UvG09MNmPigSb7BWqbi5AUovJXdZ1g9ff1k4VLFZh9

//class Configuration: ObservableObject {
//    @Published var secretKey: String = "bAjGICAORzPerb83AkXBqH74TMA8nSo1WpJzxDA27Ki"
//    @Published var apiKey: String = "Osf2p3xQJ2TSXdQyjMzQdHWc1soDNzfS"
//    let environment: FiservTTPEnvironment = .Cat
//    let currencyCode: String = "USD"
//    @Published var appleTtpMerchantId: String?
//    @Published var merchantId: String = "190009000008890"
//    @Published var merchantName: String = "CAT-8890"
//    @Published var merchantCategoryCode: String = "1000"
//    @Published var terminalId: String = "10000001"
//    @Published var terminalProfileId:String = "4c840000-0000-0000-0cf1-ed816626ccc6"
//}

//class Configuration: ObservableObject {
//    @Published var secretKey: String = "bAjGICAORzPerb83AkXBqH74TMA8nSo1WpJzxDA27Ki"
//    @Published var apiKey: String = "Osf2p3xQJ2TSXdQyjMzQdHWc1soDNzfS"
//    let environment: FiservTTPEnvironment = .Cat
//    let currencyCode: String = "USD"
//    @Published var appleTtpMerchantId: String?
//    @Published var merchantId: String = "190009000008890"
//    @Published var merchantName: String = "CAT-8890"
//    @Published var merchantCategoryCode: String = "1000"
//    @Published var terminalId: String = "10000001"
//    @Published var terminalProfileId:String = "4c840000-0000-0000-0cf1-ed816626ccc6"
//}

// QA - Chandler
//class Configuration: ObservableObject {
//    @Published var secretKey: String = "OW6prOMR3ut7VJvjfkkBywCSmDvhPlDmRzw2PD6W8u9"
//    @Published var apiKey: String = "O0lVfgyThiZ0AYynRSdEuMDP5syAZ96I"
//    let environment: FiservTTPEnvironment = .QA
//    let currencyCode: String = "USD"
//    @Published var appleTtpMerchantId: String?
//    @Published var merchantId: String = "100043202016058"
//    @Published var merchantName: String = "QA-6058"
//    @Published var merchantCategoryCode: String = "1000"
//    @Published var terminalId: String = "10000001"
//    @Published var terminalProfileId:String = "4c840000-0000-0000-0cf1-ed816626ccc6"
//}

// STORE ID
//class Configuration: ObservableObject {
//    @Published var secretKey: String = "dkakJ0SGWPZpAQ5yrpARLzT5NZqszmIWiuNAfUugCQmqKdg0NuAWSjzSfZNqWJZl"
//    @Published var apiKey: String = "Y8l1VEVweMbCUI148QTorLWGZSGE6yQRnkhSObxkw1ZyPKi3"
//    let environment: FiservTTPEnvironment = .QA
//    let currencyCode: String = "USD"
//    @Published var appleTtpMerchantId: String?
//    @Published var merchantId: String = "9999999050005"
//    @Published var merchantName: String = "QA-0005"
//    @Published var merchantCategoryCode: String = "1000"
//    @Published var terminalId: String = "10000001"
//    @Published var terminalProfileId:String = "4c840000-0000-0000-0cf1-ed816626ccc6"
//}

//class Configuration: ObservableObject {
//    @Published var secretKey: String = "y5rahj0Zwdcoej0j5MyZ5QYaaISi6Xz89DastVdJbk2"
//    @Published var apiKey: String = "LxJvAiolAWutsjRdexiWJX3VGXuPIpGh"
//    let environment: FiservTTPEnvironment = .Int
//    let currencyCode: String = "USD"
//    @Published var appleTtpMerchantId: String?
//    @Published var merchantId: String = "100009000000035"
//    @Published var merchantName: String = "DEV-0035"
//    @Published var merchantCategoryCode: String = "1000"
//    @Published var terminalId: String = "10000001"
//    @Published var terminalProfileId:String = "4c840000-0000-0000-0cf1-ed816626ccc6"
//}

