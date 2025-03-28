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

struct BillingAddressView: View {
    
    @Binding var billingAddress: BillingAddress
    
    @EnvironmentObject var viewModel: FiservTTPViewModel
    
    @Environment(\.dismiss) private var dismiss
    
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
                TextField("First Name", text: $billingAddress.firstName)
                TextField("Last Name", text: $billingAddress.lastName)
                TextField("House Number", text: $billingAddress.houseNumber)
                TextField("Street Name", text: $billingAddress.streetName)
                TextField("City", text: $billingAddress.city)
                TextField("State", text: $billingAddress.state)
                TextField("Postal Code", text: $billingAddress.postalCode)
                TextField("Country", text: $billingAddress.country)
                TextField("MerchantOrderId", text: $merchantOrderId)
                TextField("MerchantTransactionId", text: $merchantTransactionId)
                TextField("MerchantInvoiceNumber", text: $merchantInvoiceNumber)
                Toggle(isOn: $viewModel.useAddress) {
                    Text("Use Address Info")
                }
                Button("Account Verification", action: {
                    accountVerification()
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
    
    func accountVerification() {
        
        Task {
            
            do {
                
                let response = try await viewModel.accountVerification(billingAddress: self.billingAddress,
                                                                       createPaymentToken: self.viewModel.createToken,
                                    merchantTransactionId: self.merchantTransactionId.isEmpty ? nil : self.merchantTransactionId,
                                    merchantOrderId: self.merchantOrderId.isEmpty ? nil : self.merchantOrderId,
                                    merchantInvoiceNumber: self.merchantInvoiceNumber.isEmpty ? nil : self.merchantInvoiceNumber)
                
                reponseWrapper = FiservTTPResponseWrapper(title: "Account Verification",
                                                          responseString: response.prettyJSON)

            } catch let error as FiservTTPCardReaderError {
                
                errorWrapper = FiservTTPErrorWrapper(error: error, guidance: "Did you use the correct transactionId?")
            }
        }
    }
}

#Preview {
    BillingAddressView(billingAddress: .constant(BillingAddress()))
        .environmentObject(FiservTTPViewModel(configuration: Configuration()))
}
