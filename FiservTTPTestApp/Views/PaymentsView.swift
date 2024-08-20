//
//  PaymentsView.swift
//  FiservTTPTestApp
//
//  Created by Tilt, Richard (Alpharetta) on 8/2/24.
//

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
    
    var body: some View {
        Form {
            Section {
                Text("Supported Payments Types")
            }
            
            Section {
                Text("Read Card: true, captureFlage: true")
                TextField("Amount", value: $amount, format: .currency(code: "USD"))
                    .keyboardType(.decimalPad)
                Button("Sale", action: {
                    sale()
                }).buttonStyle(BorderlessButtonStyle())
            }
            
            Section {
                Text("Read Card: true, captureFlag: false")
                TextField("Amount", value: $amount, format: .currency(code: "USD"))
                    .keyboardType(.decimalPad)
                Button("Auth", action: {
                    auth()
                }).buttonStyle(BorderlessButtonStyle())
            }
            
            Section {
                Text("Read Card: false, captureFlage: true \nExpects previous authorization\nSessionless")
                TextField("Amount", value: $amount, format: .currency(code: "USD"))
                    .keyboardType(.decimalPad)
                Button("Capture", action: {
                    capture()
                }).buttonStyle(BorderlessButtonStyle())
            }
            
            Section {
                Text("Read Card: false, captureFlage: true \nExpects previous payment token\nSessionless")
                TextField("Amount", value: $amount, format: .currency(code: "USD"))
                    .keyboardType(.decimalPad)
                Button("Payment Token", action: {
                    paymentToken()
                }).buttonStyle(BorderlessButtonStyle())
            }
            
            Button("Done", action: {
                dismiss()
            }).buttonStyle(BorderlessButtonStyle())
        }
        .onTapGesture {
            hideKeyboard()
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
    
    func sale() {

        Task {
            do {
                let response =  try await viewModel.charges(amount: Decimal(self.amount),
                                                            transactionType: PaymentTransactionType.sale,
                                                            merchantOrderId: "MOID_0000001_SALE",
                                                            merchantTransactionId: "MTID_0000001_SALE")
                
                reponseWrapper = FiservTTPResponseWrapper(title: "Sale",
                                                          responseString: response.prettyJSON)
                
            } catch let error as FiservTTPCardReaderError {
                errorWrapper = FiservTTPErrorWrapper(error: error, guidance: "Did you use the correct transactionId?")
            }
        }
    }
    
    func auth() {
        
        Task {
            do {
                let response =  try await viewModel.charges(amount: Decimal(self.amount),
                                                            transactionType: PaymentTransactionType.auth,
                                                            merchantOrderId: "MOID000000_AUTH",
                                                            merchantTransactionId: "MTID000000_AUTH")
                
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
                                                           merchantOrderId: "MOID_0000001_CAP",
                                                           merchantTransactionId: "MTID_0000001_CAP",
                                                           referenceTransactionId: viewModel.authTransactionId)
                
                reponseWrapper = FiservTTPResponseWrapper(title: "Capture",
                                                          responseString: response.prettyJSON)
                
            } catch let error as FiservTTPCardReaderError {
                errorWrapper = FiservTTPErrorWrapper(error: error, guidance: "Did you use the correct transactionId?")
            }
        }
    }
    
    func paymentToken() {
        
        Task {
            do {
                let response = try await viewModel.charges(amount: Decimal(self.amount),
                                                           transactionType: PaymentTransactionType.paymentToken,
                                                           paymentTokenSource: viewModel.paymentTokenSourceRequest,
                                                           merchantOrderId: "MOID000000_TOKEN",
                                                           merchantTransactionId: "MTID000000_TOKEN")
                
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
