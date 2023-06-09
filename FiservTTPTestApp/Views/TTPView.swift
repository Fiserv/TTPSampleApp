//  ContentView
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
#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

// Main view for our app
struct TTPView: View {
    
    @Binding var isShowingConfig: Bool

    // Default value for charging a card
    // @State private var amount: String = "0.00"
    @State private var amount = 0.00
    
    @State private var transactionId = ""
    
    // For ease in displaying the result of a readCard request
    @State private var reponseWrapper: FiservTTPResponseWrapper?
    
    // Error handling and displaying
    @State private var errorWrapper: FiservTTPErrorWrapper?
    
    @Environment(\.dismiss) private var dismiss
    
    @StateObject var viewModel: FiservTTPViewModel
    
    // For detecting app returning from background (need to re-init reader session in this case)
    @Environment(\.scenePhase) var scenePhase
    
    let merchantId: String
    let merchantName: String
    
    var body: some View {
        
        NavigationView {
                
            Form {
                
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
                }

                if( viewModel.isBusy == true ) {
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

                Section("2. (Optional) Link Apple Account to MID") {
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

                Section("5. Accept a TTP Payment") {
                    
                    TextField("Amount", value: $amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                        .keyboardType(.decimalPad)
                    
                    Button("Accept Payment",action: {
                        
                        Task {

                            do {
                                let chargeResponse = try await viewModel.readCard(amount: Decimal(self.amount), merchantOrderId: "oid123", merchantTransactionId: "tid987")
                                
                                reponseWrapper = FiservTTPResponseWrapper(title: "Charge Response", response: chargeResponse)
                                
                                self.transactionId = chargeResponse.gatewayResponse?.transactionProcessingDetails?.transactionId ?? ""
                                
                            } catch let error as FiservTTPCardReaderError {
                                errorWrapper = FiservTTPErrorWrapper(error: error, guidance: "Did you initialize the reader?")
                            }
                            
                            self.amount = 0.00
                        }
                    }).buttonStyle(BorderlessButtonStyle())
                }
                
                Section("6. Void a TTP Payment") {
                    
                    TextField("Amount", value: $amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                        .keyboardType(.decimalPad)
                    
                    TextField("TransactionId", text: $transactionId)
                        .keyboardType(.default)
                    
                    Button("Void Transaction", action: {
                        
                        Task {
                            
                            do {
                                
                                let response = try await viewModel.voidTransaction(amount: Decimal(self.amount),
                                                                                   referenceTransactionId: self.transactionId)
                                
                                reponseWrapper = FiservTTPResponseWrapper(title: "Void Response", response: response)
                                
                            } catch let error as FiservTTPCardReaderError {
                                
                                errorWrapper = FiservTTPErrorWrapper(error: error, guidance: "Did you use the correct transactionId?")
                            }
                            
                            self.amount = 0.00
                            
                            self.transactionId = ""
                        }
                    }).buttonStyle(BorderlessButtonStyle())
                }
                
                Section("7. Refund a TTP Payment") {
                    
                    TextField("Amount", value: $amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                        .keyboardType(.decimalPad)
                    
                    TextField("TransactionId", text: $transactionId)
                        .keyboardType(.default)
                    
                    Button("Refund Transaction", action: {
                        
                        Task {
                            
                            do {
                                
                                let response = try await viewModel.refundTransaction(amount: Decimal(self.amount),
                                                                                     referenceTransactionId: self.transactionId)
                                
                                reponseWrapper = FiservTTPResponseWrapper(title: "Refund Response", response: response)
                                
                            } catch let error as FiservTTPCardReaderError {
                                
                                errorWrapper = FiservTTPErrorWrapper(error: error, guidance: "Did you use the correct transactionId?")
                            }
                            
                            self.amount = 0.00
                            
                            self.transactionId = ""
                        }
                        
                    }).buttonStyle(BorderlessButtonStyle())
                }
            }
            .onTapGesture {
                hideKeyboard()
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
            .onChange(of: scenePhase) { phase in
                if phase == .active {
                    Task {
                        do {
                            try await viewModel.reinitializeSession()
                        } catch let error as FiservTTPCardReaderError {
                            errorWrapper = FiservTTPErrorWrapper(error: error, guidance: "Check the configuration settings and try again.")
                        }
                    }
                }
            }
            .sheet(item: $reponseWrapper) { wrapper in

                FiservTTPChargeResponseView(responseWrapper: wrapper)
            }
            .sheet(item: $errorWrapper) { wrapper in
                FiservTTPErrorView(errorWrapper: wrapper)
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
    }
}

// CHARGE RESPONSE VIEW
struct FiservTTPChargeResponseView: View {

    let responseWrapper: FiservTTPResponseWrapper?

    @Environment(\.dismiss) private var dismiss

    var body: some View {

        NavigationView {

            VStack {
                
                if let response = responseWrapper?.response {
                    
                    Text(responseWrapper?.title ?? "Server Response")
                        .font(.title)
                        .padding(.bottom)
                    
                    ScrollView {
                        
                        VStack {
                            
                            Text(response.prettyJSON)

                        }.frame(maxWidth: .infinity)
                    }
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
                merchantName: "Tom's Tacos")
    }
}
