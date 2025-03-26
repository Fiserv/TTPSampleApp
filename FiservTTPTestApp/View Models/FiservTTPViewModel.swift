//  FiservTTPViewModel
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
import Combine
import FiservTTP

class FiservTTPViewModel: ObservableObject {
    
    @Published var isBusy: Bool = false
    @Published var hasToken: Bool = false
    @Published var accountLinked: Bool = false
    @Published var cardValid: Bool = false
    @Published var cardReaderActive: Bool = false
    
    @Published var expectsToken: Bool = false
    @Published var useAddress: Bool = false
    @Published var createToken: Bool = false
    
    // USED FOR PAYMENT TYPE CAPTURE
    @Published var authTransactionId: String?
    // USED FOR CANCELS, RETURNS
    @Published var referenceTransactionId: String = ""
    // USED WHEN CREATE PAYMENT TYPE FLAG IS SET
    // @Published var paymentTokenSourceRequest: Models.PaymentTokenSourceRequest?
    @Published var paymentTokens: [Models.PaymentTokenSourceRequest]?
    
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

    public func accountVerification(billingAddress: BillingAddress,
                                    createPaymentToken: Bool = false,
                                    merchantTransactionId: String? = nil,
                                    merchantOrderId: String? = nil,
                                    merchantInvoiceNumber: String? = nil) async throws -> Models.AccountVerificationResponse {

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        await MainActor.run { self.isBusy = true }
        
        do {
            
            let transactionDetailsRequest = Models.TransactionDetailsRequest(merchantTransactionId: merchantTransactionId,
                                                                             merchantOrderId: merchantOrderId,
                                                                             merchantInvoiceNumber: merchantInvoiceNumber,
                                                                             captureFlag: false,
                                                                             createToken: createPaymentToken)
            
            var addressRequest: Models.AddressRequest?
            var billingAddressRequest: Models.BillingAddressRequest?
                        
            if self.useAddress {
                
                addressRequest = Models.AddressRequest(street: billingAddress.streetName,
                                                       houseNumberOrName: billingAddress.houseNumber,
                                                       city: billingAddress.city,
                                                       stateOrProvince: billingAddress.state,
                                                       postalCode: billingAddress.postalCode,
                                                       country: billingAddress.country)
                
                billingAddressRequest = Models.BillingAddressRequest(firstName: billingAddress.firstName,
                                                                     lastName: billingAddress.lastName,
                                                                     addressRequest: addressRequest)
            }
            
            // Models.AccountVerificationResponse
            let response = try await self.fiservTTPCardReader.accountVerification(transactionDetailsRequest: transactionDetailsRequest,
                                                                                  paymentTokenSourceRequest: self.paymentTokens?.first,
                                                                                  billingAddressRequest: billingAddressRequest)
            await MainActor.run {
                
                // WARNING
                self.createToken = false
                
                paymentTokenHelper(from: "accountVerification:Verified",
                                   sourceResponse: response.source,
                                   tokensResponse: response.paymentTokens)
            }
            
            await MainActor.run { self.isBusy = false }
            return response
            
        }  catch {
            await MainActor.run { self.isBusy = false }
            throw error
        }
    }
    
    public func tokenizeCard(merchantTransactionId: String? = nil,
                             merchantOrderId: String? = nil,
                             merchantInvoiceNumber: String? = nil) async throws -> Models.TokenizeCardResponse {
        
        let transactionDetailsRequest = Models.TransactionDetailsRequest(merchantTransactionId: merchantTransactionId,
                                                                         merchantOrderId: merchantOrderId,
                                                                         merchantInvoiceNumber: merchantInvoiceNumber)
        
        await MainActor.run { self.isBusy = true }
        
        do {
            
            // Models.TokenizeCardResponse
            let response = try await self.fiservTTPCardReader.tokenizeCard(transactionDetailsRequest: transactionDetailsRequest)
            
            await MainActor.run {
                
                // Grab the PaymentToken
                if response.gatewayResponse?.transactionState == "AUTHORIZED" {
                    
                    paymentTokenHelper(from: "tokenize:Authorized",
                                       sourceResponse: response.source,
                                       tokensResponse: response.paymentTokens)
                }
                
                self.isBusy = false
            }
            return response
        } catch {
            await MainActor.run { self.isBusy = false }
            throw error
        }
    }
    
    public func transactionInquiry(referenceTransactionId: String? = nil,
                                   referenceMerchantTransactionId: String? = nil,
                                   referenceOrderId: String? = nil,
                                   referenceMerchantOrderId: String? = nil) async throws -> [Models.InquireResponse] {
        
        let referenceTransactionDetails = Models.ReferenceTransactionDetailsRequest(referenceTransactionId: referenceTransactionId,
                                                                                    referenceMerchantTransactionId: referenceMerchantTransactionId,
                                                                                    referenceOrderId: referenceOrderId,
                                                                                    referenceMerchantOrderId: referenceMerchantOrderId,
                                                                                    referenceClientRequestId: nil)
        await MainActor.run { self.isBusy = true }
        
        do {
            
            let response = try await self.fiservTTPCardReader.transactionInquiry(referenceTransactionDetailsRequest: referenceTransactionDetails)
            
            await MainActor.run { self.isBusy = false }
            return response
        } catch {
            await MainActor.run { self.isBusy = false }
            throw error
        }
    }

    // TRANS TYPE           CAP FLAG        READ CARD       CREATE TOKEN
    //
    // USE PAY_TOKEN        TRUE            FALSE           FALSE
    //
    // AUTH                 FALSE           TRUE            FALSE
    //
    // CAPTURE              TRUE            FALSE           FALSE
    //
    // SALE                 TRUE            TRUE            FALSE
    
    // ADDITIONAL
    //
    // AUTH + CAPTURE == SALE
    // SALE == CURRENT SDK
    //
    // ARGS                            SALE     AUTH    CAPTURE   TOKEN
    //
    // SOURCE (CARD DATA)               Y        Y         N        N
    // MERCHANT DETAILS                 Y        Y         Y        Y
    // CAPTURE FLAG (MD)                T        F         T        T
    // TRANSACTION DETAILS              Y        Y         Y        Y
    // REFERENCE TRANSACTION DETAILS    N        N         B        N
    
    public func charges(amount: Decimal,
                        createPaymentToken: Bool = false,
                        transactionType: PaymentTransactionType,
                        paymentTokenSource: Models.PaymentTokenSourceRequest? = nil,
                        merchantOrderId: String? = nil,
                        merchantTransactionId: String? = nil,
                        merchantInvoiceNumber: String? = nil,
                        referenceTransactionId: String? = nil,
                        referenceMerchantTransactionId: String? = nil,
                        referenceOrderId: String? = nil,
                        referenceMerchantOrderId: String? = nil) async throws -> Models.CommerceHubResponse {
        
        await MainActor.run { self.isBusy = true }
        
        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        
        do {
            // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            
            let captureFlag = transactionType != .auth
            
            let transactionDetails = Models.TransactionDetailsRequest(merchantTransactionId: merchantTransactionId,
                                                                      merchantOrderId: merchantOrderId,
                                                                      merchantInvoiceNumber: merchantInvoiceNumber,
                                                                      captureFlag: captureFlag,
                                                                      createToken: createPaymentToken)
            
            var referenceTransactionDetails: Models.ReferenceTransactionDetailsRequest?
            // EXPECTS PREVIOUS AUTH
            if transactionType == .capture {
                
                referenceTransactionDetails = Models.ReferenceTransactionDetailsRequest(referenceTransactionId: referenceTransactionId)
            }
            
            // Models.CommerceHubResponse
            let response = try await self.fiservTTPCardReader.charges(amount: bankersAmount(amount: amount),
                                                                      transactionType: transactionType,
                                                                      transactionDetailsRequest: transactionDetails,
                                                                      referenceTransactionDetailsRequest: referenceTransactionDetails,
                                                                      paymentTokenSourceRequest: paymentTokenSource)
            
            await MainActor.run {

                // WARNING
                self.createToken = false
                
                // PAYMENT TYPE CAPTURE, SALE, PAYMENT TOKEN
                if response.gatewayResponse?.transactionState == "CAPTURED" {
                    
                    // Grab the transactionId
                    self.referenceTransactionId = response.gatewayResponse?.transactionProcessingDetails?.transactionId ?? ""
                    // Check for Payments Tokens
                    paymentTokenHelper(from: "charges:CAPTURED",
                                       sourceResponse: response.source,
                                       tokensResponse: response.paymentTokens)
                }
                
                // PAYMENT TYPE AUTH
                if response.gatewayResponse?.transactionState == "AUTHORIZED" {
                    
                    // This will enable the .capture paymentType
                    if let transactionId = response.gatewayResponse?.transactionProcessingDetails?.transactionId {
                        
                        // Auth can be cancelled
                        // Grab the transactionId (and use it as an authorization)
                        self.referenceTransactionId = transactionId
                        self.authTransactionId = transactionId
                        // Check for Payments Tokens
                        paymentTokenHelper(from: "charges:AUTHORIZED",
                                           sourceResponse: response.source,
                                           tokensResponse: response.paymentTokens)
                    }
                }
                
                self.isBusy = false
            }
            
            return response
            
        }  catch {
            await MainActor.run { self.isBusy = false }
            throw error
        }
    }
    
    // ARGS                            MATCHED    UNMATCHED    OPEN
    //
    // READ CARD                        N           Y           Y
    // MERCHANT DETAILS                 Y           Y           Y
    // CAPTURE FLAG                     F           T           T
    // TRANSACTION DETAILS              N           Y           Y
    // REFERENCE TRANSACTION DETAILS    Y           Y           N
    
    // NEW
    public func refunds(amount: Decimal,
                        refundTransactionType: RefundTransactionType,
                        merchantOrderId: String? = nil,
                        merchantTransactionId: String? = nil,
                        merchantInvoiceNumber: String? = nil,
                        referenceTransactionId: String? = nil,
                        referenceMerchantTransactionId: String? = nil,
                        referenceOrderId: String? = nil,
                        referenceMerchantOrderId: String? = nil) async throws -> Models.CommerceHubResponse {
        
        await MainActor.run { self.isBusy = true }
        
        do {
            
            var referenceTransactionDetails: Models.ReferenceTransactionDetailsRequest?
            
            if refundTransactionType != .open {
                
                referenceTransactionDetails = Models.ReferenceTransactionDetailsRequest(referenceTransactionId: referenceTransactionId,
                                                                                        referenceMerchantTransactionId: referenceMerchantTransactionId,
                                                                                        referenceOrderId: referenceOrderId,
                                                                                        referenceMerchantOrderId: referenceMerchantOrderId)
            }
            
            let captureFlag = refundTransactionType != .matched
            
            var transactionDetailsRequest: Models.TransactionDetailsRequest?
            
            if refundTransactionType != .matched {

                transactionDetailsRequest = Models.TransactionDetailsRequest(merchantTransactionId: merchantTransactionId,
                                                                             merchantOrderId: merchantOrderId,
                                                                             merchantInvoiceNumber: merchantInvoiceNumber,
                                                                             captureFlag: captureFlag)
            }
            
            let response = try await self.fiservTTPCardReader.refunds(amount: bankersAmount(amount: amount),
                                                                      refundTransactionType: refundTransactionType,
                                                                      transactionDetails: transactionDetailsRequest,
                                                                      referenceTransactionDetails: referenceTransactionDetails)
            
            await MainActor.run { self.isBusy = false }
            return response
        } catch {
            await MainActor.run { self.isBusy = false }
            throw error
        }
    }
    
    // READ CARD
    public func readCard(amount: Decimal,
                         merchantOrderId: String?,
                         merchantTransactionId: String?,
                         merchantInvoiceNumber: String?) async throws -> FiservTTPChargeResponse {
        
        do {
            await MainActor.run { self.isBusy = true }

            let response = try await self.fiservTTPCardReader.readCard(amount: bankersAmount(amount: amount),
                                                                       merchantOrderId: merchantOrderId,
                                                                       merchantTransactionId: merchantTransactionId,
                                                                       merchantInvoiceNumber: merchantInvoiceNumber)
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
    
    // NEW
    public func cancels(amount: Decimal,
                        referenceTransactionId: String? = nil,
                        referenceOrderId: String? = nil,
                        referenceMerchantTransactionId: String? = nil,
                        referenceMerchantOrderId: String? = nil) async throws -> Models.CommerceHubResponse {
        
        let referenceTransactionDetails = Models.ReferenceTransactionDetailsRequest(referenceTransactionId: referenceTransactionId,
                                                                                    referenceMerchantTransactionId: referenceMerchantTransactionId,
                                                                                    referenceOrderId: referenceOrderId,
                                                                                    referenceMerchantOrderId: referenceMerchantOrderId)
        await MainActor.run { self.isBusy = true }
        
        do {
            
            let response = try await self.fiservTTPCardReader.cancels(amount: bankersAmount(amount: amount),
                                                                      referenceTransactionDetailsRequest: referenceTransactionDetails)
            
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
                           merchantInvoiceNumber: String? = nil,
                           referenceTransactionId: String? = nil,
                           referenceMerchantTransactionId: String? = nil) async throws -> FiservTTPChargeResponse {
            
        do {
            await MainActor.run { self.isBusy = true }
             
            let response = try await self.fiservTTPCardReader.refundCard(amount: bankersAmount(amount: amount),
                                                                         merchantOrderId: merchantOrderId,
                                                                         merchantTransactionId: merchantTransactionId,
                                                                         merchantInvoiceNumber: merchantInvoiceNumber,
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
    
    // DECIMAL NUMBERS ROUNDED TO BANKERS
    private func bankersAmount(amount: Decimal) -> Decimal {
        
        return amount.rounded(2, .bankers)
    }
    
    // SAVE ANY RETURNED PAYMENT TOKENS
    private func paymentTokenHelper(from: String, sourceResponse: Models.SourceResponse?, tokensResponse: [Models.PaymentTokenResponse]?) {
        
        guard let sourceResponse = sourceResponse, let tokensResponse = tokensResponse else {
            return
        }
        
        self.paymentTokens = [Models.PaymentTokenSourceRequest]()
        
        tokensResponse.forEach { token in

            print("** paymentTokenHelper (save token) \(from) ** ")
            let paymentToken = Models.PaymentTokenSourceRequest.init(sourceType: "PaymentToken",
                                                                     tokenData: token.tokenData ?? "",
                                                                     tokenSource: token.tokenSource ?? "",
                                                                     declineDuplicates: true,
                                                                     card: Models.PaymentTokenCardRequest.init(
                                                                     expirationMonth: sourceResponse.card?.expirationMonth ?? "",
                                                                     expirationYear: sourceResponse.card?.expirationYear ?? ""))
            
            print("paymentToken.sourceType: \(paymentToken.sourceType)")
            print("paymentToken.card.expirationMonth: \(paymentToken.card.expirationMonth)")
            print("paymentToken.card.expirationYear: \(paymentToken.card.expirationYear)")
            print("paymentToken.tokenData: \(paymentToken.tokenData)")
            print("paymentToken.tokenSource: \(paymentToken.tokenSource)")
            
            self.paymentTokens?.append(paymentToken)
        }
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
