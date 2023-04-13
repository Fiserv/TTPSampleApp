//
//  Configuration.swift
//  FiservTTPTestApp
//
//  Created by Richard Tilt on 4/13/23.
//

import Foundation
import FiservTTP

class Configuration: ObservableObject {
    
    @Published var secretKey: String = "RH2aSkDW8J3OeKtmsTXNnXnGQqVRQ2NnEBv9pts9Gm6"
    @Published var apiKey: String = "0JvVe4QCtT3srMmflNuUrs1zxZLswmmi"
    let environment: FiservTTPEnvironment = .Sandbox
    let currencyCode: String = "USD"
    @Published var merchantId: String = "190009000000700"
    @Published var merchantName: String = "Tom's Tacos"
    @Published var merchantCategoryCode: String = "1000"
    @Published var terminalId: String = "10000001"
    @Published var terminalProfileId: String = "3c00e000-a00e-2043-6d63-936859000002"
    
}
