//
//  RefundsView.swift
//  FiservTTPTestApp
//
//  Created by Tilt, Richard (Alpharetta) on 8/5/24.
//

import SwiftUI
import FiservTTP

struct RefundsView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject var viewModel: FiservTTPViewModel
    
    @State private var amount = 0.00
    
    @State private var merchantOrderId = ""
    
    @State private var merchantTransactionId = "MTID_0000001_"
    
    @State private var merchantInvoiceNumber = ""
    
    // For use in displaying the result of a readCard request
    @State private var reponseWrapper: FiservTTPResponseWrapper?
    
    // Error handling and displaying
    @State private var errorWrapper: FiservTTPErrorWrapper?
    
    var body: some View {
        
        Form {
            
            Section {
                Text("Supported Refund Types")
            }
            
            Section {
                Text("Read Card: false, Ref required")
                
                // ONLY USED FOR REFERENCE
                TextField("Your Trans Id", text: $merchantTransactionId)
                    .keyboardType(.default)
                
                TextField("ReferenceTransactionId", text: $viewModel.referenceTransactionId)
                    .keyboardType(.default)
                TextField("Amount", value: $amount, format: .currency(code: "USD"))
                    .keyboardType(.decimalPad)
                Button("Tagged Matched", action: {
                    taggedRefundMatched()
                }).buttonStyle(BorderlessButtonStyle())
            }
            
            Section {
                Text("Read Card: true, Ref required")
                TextField("ReferenceTransactionId", text: $viewModel.referenceTransactionId)
                    .keyboardType(.default)
                TextField("MerchantTransactionId", text: $merchantTransactionId)
                    .keyboardType(.default)
                TextField("Amount", value: $amount, format: .currency(code: "USD"))
                    .keyboardType(.decimalPad)
                Button("Tagged UnMatched", action: {
                    taggedRefundUnMatched()
                }).buttonStyle(BorderlessButtonStyle())
            }
            
            Section {
                Text("Read Card: true")
                TextField("MerchantOrderId", text: $merchantOrderId)
                    .keyboardType(.default)
                TextField("MerchantTransactionId", text: $merchantTransactionId)
                    .keyboardType(.default)
                TextField("MerchantInvoiceNumber", text: $merchantInvoiceNumber)
                    .keyboardType(.default)
                TextField("Amount", value: $amount, format: .currency(code: "USD"))
                    .keyboardType(.decimalPad)
                Button("Open", action: {
                    openRefund()
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
    
    func taggedRefundMatched() {
        Task {
            do {
                let response = try await viewModel.refunds(amount: Decimal(self.amount),
                                                           refundTransactionType: .matched,
                                                           referenceTransactionId: self.viewModel.referenceTransactionId)
                
                reponseWrapper = FiservTTPResponseWrapper(title: "Refunds [Tagged Matched]",
                                                          responseString: response.prettyJSON)
            } catch let error as FiservTTPCardReaderError {
                errorWrapper = FiservTTPErrorWrapper(error: error, guidance: "Did you use the correct transactionId?")
            }
        }
    }
    
    // ARGS                            MATCHED    UNMATCHED    OPEN
    //
    // READ CARD                        N           Y           Y
    // MERCHANT DETAILS                 Y           Y           Y
    // CAPTURE FLAG                     F           T           T
    // TRANSACTION DETAILS              N           Y           Y
    // REFERENCE TRANSACTION DETAILS    Y           Y           N
    //
    
    func taggedRefundUnMatched() {
        Task {
            do {
                let response = try await viewModel.refunds(amount: Decimal(self.amount),
                                                           refundTransactionType: .unmatched,
                                                           // NA
                                                           // merchantOrderId: (self.merchantOrderId.isEmpty ? nil : self.merchantOrderId),
                                                           merchantTransactionId: (self.merchantTransactionId.isEmpty ? nil : self.merchantTransactionId),
                                                           merchantInvoiceNumber: (self.merchantInvoiceNumber.isEmpty ? nil : self.merchantInvoiceNumber),
                                                           referenceTransactionId: self.viewModel.referenceTransactionId)
                
                reponseWrapper = FiservTTPResponseWrapper(title: "Refunds [Tagged UnMatched]",
                                                          responseString: response.prettyJSON)
            } catch let error as FiservTTPCardReaderError {
                errorWrapper = FiservTTPErrorWrapper(error: error, guidance: "Did you use the correct transactionId?")
            }
        }
    }
    
    func openRefund() {
        Task {
            do {
                let response = try await viewModel.refunds(amount: Decimal(self.amount),
                                                           refundTransactionType: .open,
                                                           merchantOrderId: (self.merchantOrderId.isEmpty ? nil : self.merchantOrderId),
                                                           merchantTransactionId: (self.merchantTransactionId.isEmpty ? nil : self.merchantTransactionId),
                                                           merchantInvoiceNumber: (self.merchantInvoiceNumber.isEmpty ? nil : self.merchantInvoiceNumber))
                
                reponseWrapper = FiservTTPResponseWrapper(title: "Refunds [Open])",
                                                          responseString: response.prettyJSON)
            } catch let error as FiservTTPCardReaderError {
                errorWrapper = FiservTTPErrorWrapper(error: error, guidance: "Did you use the correct transactionId?")
            }
        }
    }
}

#Preview {
    RefundsView()
        .environmentObject(FiservTTPViewModel(configuration: Configuration()))
}
