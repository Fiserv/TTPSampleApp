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
import FiservTTP

struct PaymentsView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject var viewModel: FiservTTPViewModel
    
    @State private var amount = 0.00
    
    // For use in displaying the result of a readCard request
    @State private var reponseWrapper: FiservTTPResponseWrapper?
    
    // Error handling and displaying
    @State private var errorWrapper: FiservTTPErrorWrapper?
    
    @State private var merchantOrderId: String = ""
    @State private var merchantTransactionId: String = ""
    @State private var merchantInvoiceNumber: String = ""
    
    var body: some View {
        Form {
            Section {
                Text("Supported Payments Types")
            }
            
            Section {
                Button("Clear paymentToken", action: {
                    clearPaymentToken()
                }).buttonStyle(BorderlessButtonStyle())
            }
            
            Section {
                TextField("MerchantOrderId", text: $merchantOrderId)
                TextField("MerchantTransactionId", text: $merchantTransactionId)
                TextField("MerchantInvoiceNumber", text: $merchantInvoiceNumber)
            }
            
            Section {
                Text("Read Card: true, captureFlag: false")
                TextField("Amount", value: $amount, format: .currency(code: "USD"))
                    .keyboardType(.decimalPad)
                Toggle(isOn: $viewModel.createToken) {
                    Text("Create Payment Token")
                }
                Button("Auth using Card", action: {
                    auth(fromToken: false)
                }).buttonStyle(BorderlessButtonStyle())
            }
            
            Section {
                Text("Read Card: false, captureFlag: false \nExpects previous payment token")
                TextField("Amount", value: $amount, format: .currency(code: "USD"))
                    .keyboardType(.decimalPad)
                
                Button("Auth using Payment Token", action: {
                    auth(fromToken: true)
                }).buttonStyle(BorderlessButtonStyle())
            }
            
            Section {
                Text("Read Card: false, captureFlage: true \nExpects previous authorization\nSessionless")
                TextField("Amount", value: $amount, format: .currency(code: "USD"))
                    .keyboardType(.decimalPad)
                Button("Sale (Capture from Auth)", action: {
                    capture()
                }).buttonStyle(BorderlessButtonStyle())
            }
            
            Section {
                Text("Read Card: false, captureFlage: true \nExpects previous payment token\nSessionless")
                TextField("Amount", value: $amount, format: .currency(code: "USD"))
                    .keyboardType(.decimalPad)
                Button("Sale (Payment Token)", action: {
                    paymentToken()
                }).buttonStyle(BorderlessButtonStyle())
            }
            
            Section {
                Text("Read Card: true, captureFlage: true")
                TextField("Amount", value: $amount, format: .currency(code: "USD"))
                    .keyboardType(.decimalPad)
                Toggle(isOn: $viewModel.createToken) {
                    Text("Create Payment Token")
                }
                Button("Sale (Read Card)", action: {
                    sale()
                }).buttonStyle(BorderlessButtonStyle())
            }
            
            Button("Done", action: {
                dismiss()
            }).buttonStyle(BorderlessButtonStyle())
        }
        .sheet(item: $reponseWrapper) { wrapper in
            FiservResponseWrapperView(responseWrapper: wrapper)
        }
        .sheet(item: $errorWrapper) { wrapper in
            FiservTTPErrorView(errorWrapper: wrapper)
        }
        .navigationTitle(Text("Billing Address"))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func clearPaymentToken() {
        viewModel.paymentTokens = nil
    }
    
    func sale() {
    
        Task {
            do {
                let response =  try await viewModel.charges(amount: Decimal(self.amount),
                                                            createPaymentToken: viewModel.createToken,
                                                            transactionType: PaymentTransactionType.sale,
                                                            merchantOrderId: self.merchantOrderId.isEmpty ? nil : self.merchantOrderId,
                                                            merchantTransactionId: self.merchantTransactionId.isEmpty ? nil : self.merchantTransactionId,
                                                            merchantInvoiceNumber: self.merchantInvoiceNumber.isEmpty ? nil : self.merchantInvoiceNumber)
                
                reponseWrapper = FiservTTPResponseWrapper(title: "Sale",
                                                          responseString: response.prettyJSON)
                
            } catch let error as FiservTTPCardReaderError {
                errorWrapper = FiservTTPErrorWrapper(error: error, guidance: "Did you use the correct transactionId?")
            }
        }
    }
    
    func auth(fromToken: Bool) {
        
        if fromToken == true && viewModel.paymentTokens == nil {
            
            let error = FiservTTPCardReaderError(title: "Authorization", localizedDescription: String(localized: "Expected a pre-existing payment token."))
            errorWrapper = FiservTTPErrorWrapper(error: error, guidance: "")
            return
        }
        
        Task {
            do {
                let response =  try await viewModel.charges(amount: Decimal(self.amount),
                                                            createPaymentToken: fromToken ? false : viewModel.createToken,
                                                            transactionType: PaymentTransactionType.auth,
                                                            paymentTokenSource: fromToken ? viewModel.paymentTokens?.first : nil,
                                                            merchantOrderId: self.merchantOrderId.isEmpty ? nil : self.merchantOrderId,
                                                            merchantTransactionId: self.merchantTransactionId.isEmpty ? nil : self.merchantTransactionId,
                                                            merchantInvoiceNumber: self.merchantInvoiceNumber.isEmpty ? nil : self.merchantInvoiceNumber)
                
                reponseWrapper = FiservTTPResponseWrapper(title: "Auth",
                                                          responseString: response.prettyJSON)
                
            } catch let error as FiservTTPCardReaderError {
                errorWrapper = FiservTTPErrorWrapper(error: error, guidance: "Did you use the correct transactionId?")
            }
        }
    }
    
    func capture() {
        
        Task {
            do {
                let response = try await viewModel.charges(amount: Decimal(self.amount),
                                                           transactionType: PaymentTransactionType.capture,
                                                           merchantOrderId: self.merchantOrderId.isEmpty ? nil : self.merchantOrderId,
                                                           merchantTransactionId: self.merchantTransactionId.isEmpty ? nil : self.merchantTransactionId,
                                                           merchantInvoiceNumber: self.merchantInvoiceNumber.isEmpty ? nil : self.merchantInvoiceNumber,
                                                           referenceTransactionId: viewModel.authTransactionId)
                
                reponseWrapper = FiservTTPResponseWrapper(title: "Capture",
                                                          responseString: response.prettyJSON)
                
            } catch let error as FiservTTPCardReaderError {
                errorWrapper = FiservTTPErrorWrapper(error: error, guidance: "Did you use the correct transactionId?")
            }
        }
    }
    
    func paymentToken() {
        
        if viewModel.paymentTokens == nil {
            
            let error = FiservTTPCardReaderError(title: "Sale from Token", localizedDescription: String(localized: "Expected a pre-existing payment token."))
            errorWrapper = FiservTTPErrorWrapper(error: error, guidance: "")
            return
        }
        
        Task {
            do {
                let response = try await viewModel.charges(amount: Decimal(self.amount),
                                                           transactionType: PaymentTransactionType.paymentToken,
                                                           paymentTokenSource: viewModel.paymentTokens?.first,
                                                           merchantOrderId: self.merchantOrderId.isEmpty ? nil : self.merchantOrderId,
                                                           merchantTransactionId: self.merchantTransactionId.isEmpty ? nil : self.merchantTransactionId,
                                                           merchantInvoiceNumber: self.merchantInvoiceNumber.isEmpty ? nil : self.merchantInvoiceNumber)
                
                reponseWrapper = FiservTTPResponseWrapper(title: "Payment Token",
                                                          responseString: response.prettyJSON)
                
            } catch let error as FiservTTPCardReaderError {
                errorWrapper = FiservTTPErrorWrapper(error: error, guidance: "Did you use the correct transactionId?")
            }
        }
    }
}

#Preview {
    PaymentsView()
        .environmentObject(FiservTTPViewModel(configuration: Configuration()))
}
