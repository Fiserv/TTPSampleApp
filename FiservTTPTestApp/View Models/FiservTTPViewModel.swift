//  FiservTTPViewModel
//
//  Copyright (c) 2022 - 2023 Fiserv, Inc.
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
import Combine
import FiservTTP

class FiservTTPViewModel: ObservableObject {
    
    @Published var isBusy: Bool = false
    @Published var hasToken: Bool = false
    @Published var accountLinked: Bool = false
    @Published var cardValid: Bool = false
    @Published var cardReaderActive: Bool = false
    
    // Used to re-initialize session if lost, requires that we have already established a session at least once
    private var readyForPayments: Bool = false
    
    private var fiservTTPCardReader: FiservTTPCardReader
    
    private lazy var cancellables: Set<AnyCancellable> = .init()
    
    init(configuration: Configuration) {

        self.fiservTTPCardReader = FiservTTPCardReader.init(configuration: FiservTTPViewModel.applyConfiguration(config: configuration))

        self.fiservTTPCardReader.sessionReadySubject
            .receive(on: DispatchQueue.main)
            .sink { sessionReady in
                self.cardReaderActive = sessionReady
            }
            .store(in: &cancellables)
    }
    
    // CARD READER IS SUPPORTED
    public func readerIsSupported() -> Bool {
        return  self.fiservTTPCardReader.readerIsSupported()
    }

    // REQUEST SESSION TOKEN
    public func requestSessionToken() async throws {
        do {
            await MainActor.run { self.isBusy = true }
            try await self.fiservTTPCardReader.requestSessionToken()
            await MainActor.run {
                self.hasToken = true
                self.isBusy = false
            }
        } catch {
            await MainActor.run { self.isBusy = false }
            throw error
        }
    }
    
    // IS ACCOUNT LINKED
    public func isAccountLinked() async throws {
        do {
            await MainActor.run { self.isBusy = true }
            let isLinked = try await self.fiservTTPCardReader.isAccountLinked()
            await MainActor.run {
                self.isBusy = false
                self.accountLinked = isLinked
            }
        } catch {
            await MainActor.run { self.isBusy = false }
            throw error
        }
    }
    
    // LINK ACCOUNT
    public func linkAccount() async throws {
        do {
            await MainActor.run { self.isBusy = true }
            try await self.fiservTTPCardReader.linkAccount()
            await MainActor.run {
                self.isBusy = false
                self.accountLinked = true
            }
        } catch {
            await MainActor.run { self.isBusy = false }
            throw error
        }
    }
    
    // REINITIALIZE SESSION
    public func reinitializeSession() async throws {
        
        if self.readyForPayments && !self.cardReaderActive {
            
            try await self.initializeSession()
        }
    }
    
    // INITIALIZE SESSION
    public func initializeSession() async throws {
        do {
            await MainActor.run { self.isBusy = true }
            try await self.fiservTTPCardReader.initializeSession()
            await MainActor.run {
                self.isBusy = false
                self.cardReaderActive = true
                self.readyForPayments = true
            }
        } catch {
            await MainActor.run { self.isBusy = false }
            throw error
        }
    }
    
    // VALIDATE CARD
    public func validateCard() async throws -> FiservTTPValidateCardResponse {
        do {
            await MainActor.run { self.isBusy = true }
            let response = try await self.fiservTTPCardReader.validateCard()
            
            await MainActor.run {
                self.isBusy = false
                if let _ = response.generalCardData, let _ = response.paymentCardData {
                    self.cardValid = true
                }
            }
            return response
            
        } catch {
            await MainActor.run { self.isBusy = false }
            throw error
        }
    }
    
    // READ CARD
    public func readCard(amount: Decimal,
                         merchantOrderId: String,
                         merchantTransactionId: String) async throws -> FiservTTPChargeResponse {
        do {
            await MainActor.run { self.isBusy = true }

            let response = try await self.fiservTTPCardReader.readCard(amount: bankersAmount(amount: amount),
                                                                       merchantOrderId: merchantOrderId,
                                                                       merchantTransactionId: merchantTransactionId)
            await MainActor.run { self.isBusy = false }
            return response
        } catch {
            await MainActor.run { self.isBusy = false }
            throw error
        }
    }
    
    // INQUIRY
    public func inquiryTransaction(referenceTransactionId: String? = nil,
                                   referenceOrderId: String? = nil,
                                   referenceMerchantTransactionId: String? = nil,
                                   referenceMerchantOrderId: String? = nil) async throws -> [FiservTTPChargeResponse] {
        
        do {
            await MainActor.run { self.isBusy = true }

            let response = try await self.fiservTTPCardReader.inquiryTransaction(referenceTransactionId: referenceTransactionId,
                                                                                 referenceMerchantTransactionId: referenceMerchantTransactionId,
                                                                                 referenceMerchantOrderId: referenceMerchantOrderId,
                                                                                 referenceOrderId: referenceOrderId)

            await MainActor.run { self.isBusy = false }
            return response
        } catch {
            await MainActor.run { self.isBusy = false }
            throw error
        }
    }
    
    // VOID TRANSACTION
    public func voidTransaction(amount: Decimal,
                                referenceTransactionId: String? = nil,
                                referenceMerchantTransactionId: String? = nil) async throws -> FiservTTPChargeResponse {
        
        do {
            await MainActor.run { self.isBusy = true }

            let response = try await self.fiservTTPCardReader.voidTransaction(amount: bankersAmount(amount: amount),
                                                                              referenceTransactionId: referenceTransactionId,
                                                                              referenceMerchantTransactionId: referenceMerchantTransactionId)
            await MainActor.run { self.isBusy = false }
            return response
        } catch {
            await MainActor.run { self.isBusy = false }
            throw error
        }
    }
    
    // REFUND CARD
    public func refundCard(amount: Decimal,
                           merchantOrderId: String? = nil,
                           merchantTransactionId: String? = nil,
                           referenceTransactionId: String? = nil,
                           referenceMerchantTransactionId: String? = nil) async throws -> FiservTTPChargeResponse {
            
        do {
            await MainActor.run { self.isBusy = true }
             
            let response = try await self.fiservTTPCardReader.refundCard(amount: bankersAmount(amount: amount),
                                                                         merchantOrderId: merchantOrderId,
                                                                         merchantTransactionId: merchantTransactionId,
                                                                         referenceTransactionId: referenceTransactionId,
                                                                         referenceMerchantTransactionId: referenceMerchantTransactionId)
            
            await MainActor.run { self.isBusy = false }
            return response
        } catch {
            await MainActor.run { self.isBusy = false }
            throw error
        }
    }
    
    // REFUND TRANSACTION
    public func refundTransaction(amount: Decimal,
                                  referenceTransactionId: String? = nil,
                                  referenceMerchantTransactionId: String? = nil) async throws -> FiservTTPChargeResponse {
        
        do {
            await MainActor.run { self.isBusy = true }
             
            let response = try await self.fiservTTPCardReader.refundTransaction(amount: bankersAmount(amount: amount),
                                                                                referenceTransactionId: referenceTransactionId,
                                                                                referenceMerchantTransactionId: referenceMerchantTransactionId)
            
            await MainActor.run { self.isBusy = false }
            return response
        } catch {
            await MainActor.run { self.isBusy = false }
            throw error
        }
    }

    private func bankersAmount(amount: Decimal) -> Decimal {
        
        return amount.rounded(2, .bankers)
    }
}

extension Decimal {
    
    mutating func round(_ scale: Int, _ roundingMode: NSDecimalNumber.RoundingMode) {
        var localCopy = self
        NSDecimalRound(&self, &localCopy, scale, roundingMode)
    }

    func rounded(_ scale: Int, _ roundingMode: NSDecimalNumber.RoundingMode) -> Decimal {
        var result = Decimal()
        var localCopy = self
        NSDecimalRound(&result, &localCopy, scale, roundingMode)
        return result
    }
}

extension FiservTTPViewModel {

    static func applyConfiguration(config: Configuration) -> FiservTTPConfig {

        return FiservTTPConfig.init(secretKey: config.secretKey,
                                    apiKey: config.apiKey,
                                    environment: config.environment,
                                    currencyCode: config.currencyCode,
                                    merchantId: config.merchantId,
                                    appleTtpMerchantId: config.appleTtpMerchantId,
                                    merchantName: config.merchantName,
                                    merchantCategoryCode: config.merchantCategoryCode,
                                    terminalId: config.terminalId,
                                    terminalProfileId: config.terminalProfileId)
    }
}
