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

import SwiftUI

import SwiftUI
import ProximityReader
import FiservTTP

// For pretty-printing JSON
extension Encodable {
    var prettyJSON: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(self),
            let output = String(data: data, encoding: .utf8)
            else { return "Error converting \(self) to JSON string" }
        return output
    }
}

struct BillingAddress {
    var firstName: String = "John"
    var lastName: String = "Jones"
    var houseNumber: String = "123"
    var streetName: String = "Main St"
    var city: String = "Alpharetta"
    var state: String = "GA"
    var postalCode: String = "30004"
    var country: String = "USA"
}

// Main view for our app
struct TTPView: View {
    
    @Binding var isShowingConfig: Bool

    @State private var amount = 0.00
    
    @State private var cardExpirationMonth = ""
    
    @State private var cardExpirationYear = ""
    
    @State private var transactionId = ""
    
    @State private var refundTransactionId = ""
    
    @State private var orderId = ""
        
    @State private var merchantTransactionId = "MTID012345678901"
    
    @State private var merchantOrderId = "MOID012345678901"
    
    @State private var merchantInvoiceNumber = "MINV012345678901"
    
    @State private var billingAddress = BillingAddress()
    
    // For use in displaying the result of a readCard request
    @State private var reponseWrapper: FiservTTPResponseWrapper?
    
    // Error handling and displaying
    @State private var errorWrapper: FiservTTPErrorWrapper?
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var shouldPresentAddressView = false
    
    @State private var shouldPresentPaymentsView = false
    
    @State private var shouldPresentRefundsView = false
    
    @StateObject var viewModel: FiservTTPViewModel
    
    // For detecting app returning from background (need to re-init reader session in this case)
    @Environment(\.scenePhase) var scenePhase
    
    let merchantId: String
    let merchantName: String
    let appleTtpMerchantId: String?
    let currencyCode: String
    
    var body: some View {
        
        NavigationView {
            
            Form {
                
                Group {
                    
                    Section("Configuration") {
                        
                        VStack(alignment:.leading) {
                            
                            Spacer()
                            
                            HStack {
                                
                                Image("Fiserv_logo.svg")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 50, height: 30)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Spacer()
                                
                                Button {
                                    self.isShowingConfig = true
                                } label: {
                                    Image(systemName: "gear")
                                        .scaleEffect(2.0)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                            .frame(maxWidth: .infinity)
                            
                            Spacer()
                            
                            Text("Apple TTP Test Tool")
                                .font(Font.title.weight(.bold))
                            
                        }
                    }
                    
                    Section("Merchant Info") {
                        
                        Text(self.merchantId)
                        
                        Text(self.merchantName)
                        
                        Text(self.appleTtpMerchantId == nil ? "Apple MID Optional" : self.appleTtpMerchantId ?? "")
                    }
                    
                    if (viewModel.isBusy == true ) {
                        TTPProgressView()
                    }
                    
                    // You must always obtain a session token before any other operation
                    Section("1. Obtain session token") {
                        HStack() {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(viewModel.hasToken ? Color.green : Color.gray)
                            
                            Button("Create Session Token", action: {
                                Task {
                                    do {
                                        try await viewModel.requestSessionToken()
                                    } catch let error as FiservTTPCardReaderError {
                                        errorWrapper = FiservTTPErrorWrapper(error: error, guidance: "Check the configuration settings and try again.")
                                    }
                                }
                            }).buttonStyle(BorderlessButtonStyle())
                        }
                    }
                }
                
                Group {
                    
                    Section("2a. (Optional) Is Apple Account Linked to MID") {
                        HStack() {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(viewModel.accountLinked ? Color.green : Color.gray)
                            Button("Is Apple Account Linked?", action: {
                                
                                Task {
                                    do {
                                        try await viewModel.isAccountLinked()
                                    } catch let error as FiservTTPCardReaderError {
                                        errorWrapper = FiservTTPErrorWrapper(error: error, guidance: "Did you obtain a session token?")
                                    }
                                }
                            }).buttonStyle(BorderlessButtonStyle())
                        }
                    }
                    
                    Section("2b. (Optional) Link Apple Account to MID") {
                        HStack() {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(viewModel.accountLinked ? Color.green : Color.gray)
                            Button("Link Apple Account", action: {
                                
                                Task {
                                    do {
                                        try await viewModel.linkAccount()
                                    } catch let error as FiservTTPCardReaderError {
                                        errorWrapper = FiservTTPErrorWrapper(error: error, guidance: "Did you obtain a session token?")
                                    }
                                }
                            }).buttonStyle(BorderlessButtonStyle())
                        }
                    }
                }
                
                Group {
                    
                    Section("3. Start Accepting TTP Payments") {
                        HStack() {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(viewModel.cardReaderActive ? Color.green : Color.gray)
                            Button("Start TTP Session", action: {
                                
                                Task {
                                    do {
                                        try await viewModel.initializeSession()
                                    } catch let error as FiservTTPCardReaderError {
                                        errorWrapper = FiservTTPErrorWrapper(error: error, guidance: "Did you obtain a session token?")
                                    }
                                }
                            }).buttonStyle(BorderlessButtonStyle())
                        }
                    }
                    
                    Section("4. (Optional) Validate Card") {
                        HStack() {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(viewModel.cardValid ? Color.green : Color.gray)
                            Button("Validate Card", action: {
                                
                                Task {
                                    do {
                                        let _ = try await viewModel.validateCard()
                                    } catch let error as FiservTTPCardReaderError {
                                        errorWrapper = FiservTTPErrorWrapper(error: error, guidance: "Did you initialize the reader?")
                                    }
                                }
                            }).buttonStyle(BorderlessButtonStyle())
                        }
                    }
                    
                    Section("X. Account Verification") {
                        
                        // Payment Token not yet created
                        if self.viewModel.paymentTokens == nil {
                            
                            Text("No Payment Token available")
                            
                            Text("Read Card: true")
                            
                            Toggle(isOn: $viewModel.createToken) {
                                Text("Create Payment Token")
                            }
                        }
                        
                        // Payment Token available
                        if self.viewModel.paymentTokens != nil {
                            
                            Text("Payment Token available")
                            
                            Button ("Clear Payment Token", action: {
                                
                                viewModel.paymentTokens = nil
                                
                            }).buttonStyle(BorderlessButtonStyle())
                            
                            Toggle(isOn: $viewModel.expectsToken) {
                                Text("Use Payment Token")
                            }
                            
                            if self.viewModel.expectsToken {
                                Text("Read Card: false")
                            } else {
                                Text("Read Card: true")
                            }
                            
                            
                        }
                        
                        Button ("Account Verification", action: {
                            
                            // Collect Address Information using BillingAddressView
                            shouldPresentAddressView.toggle()
                            
                        }).buttonStyle(BorderlessButtonStyle())
                    }
                    
                    Section("X. Tokenize Card") {
                        Text("Read Card: true")
                        Button ("Tokenize Card", action: {
                            
                            Task {
                                
                                do {
                                    
                                    let response = try await viewModel.tokenizeCard(merchantTransactionId: self.merchantTransactionId,
                                                                                    merchantOrderId: self.merchantOrderId,
                                                                                    merchantInvoiceNumber: self.merchantInvoiceNumber)
                                    
                                    reponseWrapper = FiservTTPResponseWrapper(title: "Tokenize Card",
                                                                              responseString: response.prettyJSON)
                                
                                } catch let error as FiservTTPCardReaderError {
                                    errorWrapper = FiservTTPErrorWrapper(error: error, guidance: "Did you use the correct transactionId?")
                                }
                            }
                            
                        }).buttonStyle(BorderlessButtonStyle())
                    }
                    
                    Section("X. Charges") {
                        Button ("Payment Types", action: {
                            
                            shouldPresentPaymentsView.toggle()
                            
                        }).buttonStyle(BorderlessButtonStyle())
                    }
                    
                    Section("X. Inquire") {
                        Text("Read Card: false")
                        Text("Expects a previous Ref Trans Id \nSessionless")
                        TextField("ReferenceTransactionId", text: $viewModel.referenceTransactionId)
                            .keyboardType(.default)
                        Button ("[Inquire]", action: {
                            
                            Task {
                                
                                do {
                                    
                                    let response = try await viewModel.transactionInquiry(referenceTransactionId: viewModel.referenceTransactionId.isEmpty ? nil : viewModel.referenceTransactionId)
                                    
                                    reponseWrapper = FiservTTPResponseWrapper(title: "Inquire",
                                                                              responseString: response.prettyJSON)
                                    
                                } catch let error as FiservTTPCardReaderError {
                                    
                                    errorWrapper = FiservTTPErrorWrapper(error: error, guidance: "Did you use the correct transactionId?")
                                }
                            }
                            
                        }).buttonStyle(BorderlessButtonStyle())
                    }
                    
                    Section("X. Refunds") {
                        Button ("Refund Types", action: {
                            
                            shouldPresentRefundsView.toggle()
                            
                        }).buttonStyle(BorderlessButtonStyle())
                    }
                    
                    Section("X. Cancels") {
                        Text("Read Card: false")
                        Text("Expects a previous Ref Trans Id \nSessionless")
                        TextField("ReferenceTransactionId", text: $viewModel.referenceTransactionId)
                            .keyboardType(.default)
                        TextField("Amount", value: $amount, format: .currency(code: self.currencyCode))
                            .keyboardType(.decimalPad)
                        Button ("Cancels", action: {
                            
                            Task {
                                
                                do {
                                    
                                    let response = try await viewModel.cancels(amount: Decimal(self.amount),
                                                                               referenceTransactionId: viewModel.referenceTransactionId.isEmpty ? nil : viewModel.referenceTransactionId)
                                    
                                    reponseWrapper = FiservTTPResponseWrapper(title: "Cancels",
                                                                              responseString: response.prettyJSON)
                                    
                                } catch let error as FiservTTPCardReaderError {
                                    
                                    errorWrapper = FiservTTPErrorWrapper(error: error, guidance: "Did you use the correct transactionId?")
                                }
                            }
                            
                        }).buttonStyle(BorderlessButtonStyle())
                    }
                    
                    Section("5. Accept a TTP Payment") {
                        
                        TextField("Amount", value: $amount, format: .currency(code: self.currencyCode))
                            .keyboardType(.decimalPad)
                        
                        TextField("Your Order Id (Optional)", text: $merchantOrderId)
                            .keyboardType(.default)
                        
                        TextField("Your Trans Id (Optional)", text: $merchantTransactionId)
                            .keyboardType(.default)
                        
                        TextField("Your Invoice Number (Optional)", text: $merchantInvoiceNumber)
                            .keyboardType(.default)
                        
                        Button("Accept Payment",action: {
                            
                            Task {
                                
                                do {
                                    
                                    let chargeResponse = try await viewModel.readCard(amount: Decimal(self.amount),
                                                                                      merchantOrderId: (self.merchantOrderId.isEmpty ? nil : self.merchantOrderId),
                                                                                      merchantTransactionId: (self.merchantTransactionId.isEmpty ? nil : self.merchantTransactionId),
                                                                                      merchantInvoiceNumber: (self.merchantInvoiceNumber.isEmpty ? nil : self.merchantInvoiceNumber))
                                    
                                    reponseWrapper = FiservTTPResponseWrapper(title: "Charge Response",
                                                                              responseString: chargeResponse.prettyJSON)
                                    
                                    self.transactionId = chargeResponse.gatewayResponse?.transactionProcessingDetails?.transactionId ?? ""
                                    
                                    self.merchantTransactionId = chargeResponse.transactionDetails?.merchantTransactionId ?? ""
                                    
                                    self.merchantOrderId = chargeResponse.transactionDetails?.merchantOrderId ?? ""
                                    
                                    self.orderId = chargeResponse.gatewayResponse?.transactionProcessingDetails?.orderId ?? ""
                                    
                                } catch let error as FiservTTPCardReaderError {
                                    errorWrapper = FiservTTPErrorWrapper(error: error, guidance: "Did you initialize the reader?")
                                }
                                
                                self.amount = 0.00
                            }
                        }).buttonStyle(BorderlessButtonStyle())
                    }
                }
                
                Group {
                    
                    Section("6. Inquire a TTP Payment") {
                        
                        TextField("Ref TransactionId", text: $transactionId)
                            .keyboardType(.default)
                        
                        TextField("Ref OrderId", text: $orderId)
                            .keyboardType(.default)
                        
                        TextField("Your Trans Id", text: $merchantTransactionId)
                            .keyboardType(.default)
                        
                        TextField("Your Order Id", text: $merchantOrderId)
                            .keyboardType(.default)
                        
                        Button("Inquire Transaction", action: {
                            
                            Task {
                                
                                do {
                                    
                                    let response = try await viewModel.inquiryTransaction(referenceTransactionId: (self.transactionId.isEmpty ? nil : self.transactionId),
                                                                referenceOrderId: (self.orderId.isEmpty ? nil : self.orderId),
                                                                referenceMerchantTransactionId: (self.merchantTransactionId.isEmpty ? nil : self.merchantTransactionId),
                                                                referenceMerchantOrderId: (self.merchantOrderId.isEmpty ? nil : self.merchantOrderId))
                                    
                                    reponseWrapper = FiservTTPResponseWrapper(title: "Inquire Response(s)",
                                                                              responseString: response.prettyJSON)
                                    
                                } catch let error as FiservTTPCardReaderError {
                                    
                                    errorWrapper = FiservTTPErrorWrapper(error: error, guidance: "Did you use the correct transactionId?")
                                }
                            }
                            
                        }).buttonStyle(BorderlessButtonStyle())
                    }
                    
                    Section("7. Void a TTP Payment") {
                        
                        TextField("Amount", value: $amount, format: .currency(code: self.currencyCode))
                            .keyboardType(.decimalPad)
                        
                        TextField("Ref TransactionId", text: $transactionId)
                            .keyboardType(.default)
                        
                        TextField("Your Trans Id", text: $merchantTransactionId)
                            .keyboardType(.default)
                        
                        Button("Void Transaction", action: {
                            
                            Task {
                                
                                do {
                                    
                                    let response = try await viewModel.voidTransaction(amount: Decimal(self.amount),
                                                                    referenceTransactionId: (self.transactionId.isEmpty ? nil : self.transactionId),
                                                                    referenceMerchantTransactionId: (self.merchantTransactionId.isEmpty ? nil : self.merchantTransactionId))
                                    
                                    reponseWrapper = FiservTTPResponseWrapper(title: "Void Response",
                                                                              responseString: response.prettyJSON)
                                    
                                } catch let error as FiservTTPCardReaderError {
                                    
                                    errorWrapper = FiservTTPErrorWrapper(error: error, guidance: "Did you use the correct transactionId?")
                                }
                                
                                self.amount = 0.00
                            }
                            
                        }).buttonStyle(BorderlessButtonStyle())
                    }
                }

                Group {
                    
                    Section("8a. Tagged Refund Matched [Trans ID + NO TAP, Original Card]") {
                        
                        TextField("Amount", value: $amount, format: .currency(code: self.currencyCode))
                            .keyboardType(.decimalPad)
                        
                        TextField("Ref TransactionId", text: $transactionId)
                            .keyboardType(.default)
                        
                        // ONLY USED FOR REFERENCE
                        TextField("Your Trans Id", text: $merchantTransactionId)
                            .keyboardType(.default)
                        
                        Button("Refund Transaction", action: {
                            
                            Task {
                                
                                do {
                                    
                                    let response = try await viewModel.refundTransaction(amount: Decimal(self.amount),
                                                                    referenceTransactionId: (self.transactionId.isEmpty ? nil : self.transactionId),
                                                                    referenceMerchantTransactionId: (self.merchantTransactionId.isEmpty ? nil : self.merchantTransactionId))
                                    
                                    reponseWrapper = FiservTTPResponseWrapper(title: "Refund Response",
                                                                              responseString: response.prettyJSON)
                                    
                                    self.refundTransactionId = response.gatewayResponse?.transactionProcessingDetails?.transactionId ?? ""
                                    
                                } catch let error as FiservTTPCardReaderError {
                                    
                                    errorWrapper = FiservTTPErrorWrapper(error: error, guidance: "Did you use the correct transactionId?")
                                }
                                
                                self.amount = 0.00
                            }
                            
                        }).buttonStyle(BorderlessButtonStyle())
                    }
                    
                    Section("8b. Debit Refund [Trans ID + TAP, Same Card]") {
                        
                        TextField("Amount", value: $amount, format: .currency(code: self.currencyCode))
                            .keyboardType(.decimalPad)
                        
                        TextField("Ref TransactionId", text: $transactionId)
                            .keyboardType(.default)
                        
                        TextField("Your Trans Id (Optional)", text: $merchantTransactionId)
                            .keyboardType(.default)
                        
                        TextField("Your Order Id (Optional)", text: $merchantOrderId)
                            .keyboardType(.default)
                        
                        TextField("Your Order Id (Optional)", text: $merchantInvoiceNumber)
                            .keyboardType(.default)
                    
                        Button("Refund Card Transaction", action: {
                            
                            Task {
                                
                                do {
                                    
                                    let response = try await viewModel.refundCard(amount: Decimal(self.amount),
                                                                                  merchantOrderId: (self.merchantOrderId.isEmpty ? nil : self.merchantOrderId),
                                                                                  merchantTransactionId: (self.merchantTransactionId.isEmpty ? nil : self.merchantTransactionId),
                                                                                  merchantInvoiceNumber: (self.merchantInvoiceNumber.isEmpty ? nil : self.merchantInvoiceNumber),
                                                                                  referenceTransactionId: (self.transactionId.isEmpty ? nil : self.transactionId))
                                    
                                    reponseWrapper = FiservTTPResponseWrapper(title: "Refund Card Response",
                                                                              responseString: response.prettyJSON)
                                    
                                    self.refundTransactionId = response.gatewayResponse?.transactionProcessingDetails?.transactionId ?? ""
                                    
                                } catch let error as FiservTTPCardReaderError {
                                    
                                    errorWrapper = FiservTTPErrorWrapper(error: error, guidance: "Did you use the correct transactionId?")
                                }
                                
                                self.amount = 0.00
                            }
                            
                        }).buttonStyle(BorderlessButtonStyle())
                    }
                    
                    Section("8c. Tagged Refund Unmatched [Trans ID + TAP, Different Card]") {
                        
                        TextField("Amount", value: $amount, format: .currency(code: self.currencyCode))
                            .keyboardType(.decimalPad)
                        
                        TextField("Ref TransactionId", text: $transactionId)
                            .keyboardType(.default)
                        // CAN BE OTHER THAN ORIGINAL VALUE
                        TextField("Your Trans Id (Optional)", text: $merchantTransactionId)
                            .keyboardType(.default)
                        
                        Button("Refund Card Transaction", action: {
                            
                            Task {
                                
                                do {
                                    
                                    let response = try await viewModel.refundCard(amount: Decimal(self.amount),
                                                                                  merchantOrderId: (self.merchantOrderId.isEmpty ? nil : self.merchantOrderId),
                                                                                  merchantTransactionId: (self.merchantTransactionId.isEmpty ? nil : self.merchantTransactionId),
                                                                                  merchantInvoiceNumber: (self.merchantInvoiceNumber.isEmpty ? nil : self.merchantInvoiceNumber),
                                                                                  referenceTransactionId: (self.transactionId.isEmpty ? nil : self.transactionId))
                                    
                                    reponseWrapper = FiservTTPResponseWrapper(title: "Refund Card Response",
                                                                              responseString: response.prettyJSON)
                                    
                                    self.refundTransactionId = response.gatewayResponse?.transactionProcessingDetails?.transactionId ?? ""
                                    
                                } catch let error as FiservTTPCardReaderError {
                                    
                                    errorWrapper = FiservTTPErrorWrapper(error: error, guidance: "Did you use the correct transactionId?")
                                }
                                
                                self.amount = 0.00
                            }
                            
                        }).buttonStyle(BorderlessButtonStyle())
                    }
                    
                    Section("8d. Open Refund [No Trans ID + TAP, Any Card]") {
                        
                        TextField("Amount", value: $amount, format: .currency(code: self.currencyCode))
                            .keyboardType(.decimalPad)
                        // FOR REFERENCE
                        TextField("Your Trans Id (Optional)", text: $merchantTransactionId)
                            .keyboardType(.default)
                        // FOR REFERENCE
                        TextField("Your Order Id (Optional)", text: $merchantOrderId)
                            .keyboardType(.default)
                        // FOR REFERENCE
                        TextField("Your Invoice Number (Optional)", text: $merchantInvoiceNumber)
                            .keyboardType(.default)
                        
                        Button("Refund Card Transaction", action: {
                            
                            Task {
                                
                                do {
                                    
                                    let response = try await viewModel.refundCard(amount: Decimal(self.amount),
                                                                                  merchantOrderId: (self.merchantOrderId.isEmpty ? nil : self.merchantOrderId),
                                                                                  merchantTransactionId: (self.merchantTransactionId.isEmpty ? nil : self.merchantTransactionId),
                                                                                  merchantInvoiceNumber: (self.merchantInvoiceNumber.isEmpty ? nil : self.merchantInvoiceNumber),
                                                                                  referenceTransactionId: (self.transactionId.isEmpty ? nil : self.transactionId))
                                    
                                    reponseWrapper = FiservTTPResponseWrapper(title: "Refund Card Response",
                                                                              responseString: response.prettyJSON)
                                    
                                    self.refundTransactionId = response.gatewayResponse?.transactionProcessingDetails?.transactionId ?? ""
                                    
                                } catch let error as FiservTTPCardReaderError {
                                    
                                    errorWrapper = FiservTTPErrorWrapper(error: error, guidance: "Did you use the correct transactionId?")
                                }
                                
                                self.amount = 0.00
                            }
                            
                        }).buttonStyle(BorderlessButtonStyle())
                    }
                }
            }
            // You need to check whether the device supports Apple TapToPay
            .onAppear {
                if !self.viewModel.readerIsSupported() {
                    
                    let error = FiservTTPCardReaderError(title: "Reader not supported.",
                                                         localizedDescription: NSLocalizedString("This device does not support Apple Tap to Pay.", comment: ""))
                    
                    errorWrapper = FiservTTPErrorWrapper(error: error, guidance: "You will need to use a newer device.")
                }
            }
            // You need to reinitialize the card reader session when returning from the background
            .onChange(of: scenePhase) {
                if scenePhase == .active {
                    Task {
                        do {
                            try await viewModel.reinitializeSession()
                        } catch let error as FiservTTPCardReaderError {
                            errorWrapper = FiservTTPErrorWrapper(error: error, guidance: "Check the configuration settings and try again.")
                        }
                    }
                }
            }
            .sheet(isPresented: $shouldPresentRefundsView, content: {
                RefundsView()
                    .environmentObject(viewModel)
            })
            .sheet(isPresented: $shouldPresentPaymentsView, content: {
                PaymentsView()
                    .environmentObject(viewModel)
            })
            .sheet(isPresented: $shouldPresentAddressView, content: {
                BillingAddressView(billingAddress: $billingAddress)
                    .environmentObject(viewModel)
            })
            .sheet(item: $reponseWrapper) { wrapper in
                FiservResponseWrapperView(responseWrapper: wrapper)
            }
            .sheet(item: $errorWrapper) { wrapper in
                FiservTTPErrorView(errorWrapper: wrapper)
            }
        }
    }
}

// RESPONSE VIEW
struct FiservResponseWrapperView: View {
    
    let responseWrapper: FiservTTPResponseWrapper?
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        
        NavigationView {
            
            VStack {
                
                Text(responseWrapper?.title ?? "Server Response")
                    .font(.title)
                    .padding(.bottom)
                
                if let response = responseWrapper?.responseString {
                    
                    ScrollView {
                        
                        VStack {
                            
                            Text(response)
                            
                        }.frame(maxWidth: .infinity)
                    }
                    
                } else {
                    
                    VStack {
                        
                        Text("None")
                        
                    }.frame(maxWidth: .infinity)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Dismiss") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// ERROR VIEW
struct FiservTTPErrorView: View {
    
    let errorWrapper: FiservTTPErrorWrapper?
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        
        NavigationView {
            
            VStack {
                
                if let error_wrapper = errorWrapper {
                    Text("An error has occurred!")
                        .font(.title)
                        .padding(.bottom)
                    Text(error_wrapper.error.title)
                        .font(.headline)
                    Text(error_wrapper.error.localizedDescription)
                        .font(.headline)
                    Text(error_wrapper.guidance)
                        .font(.caption)
                    Text(error_wrapper.error.failureReason ?? "")
                        .font(.headline)
                        .padding(.top)
                    Spacer()
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Dismiss") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TTPView_Previews: PreviewProvider {
    
    static var previews: some View {
        
        TTPView(isShowingConfig: .constant(true),
                viewModel: FiservTTPViewModel(configuration: Configuration()),
                merchantId: "190009000000700",
                merchantName: "Tom's Tacos",
                appleTtpMerchantId: String(),
                currencyCode: "USD")
    }
}
