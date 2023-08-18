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

struct ConfigurationView: View {
    
    @Binding var isPresented: Bool
    
    @EnvironmentObject var configuration: Configuration
    
    var body: some View {
        
        NavigationView {
            
            List {
                
                Section(header: Text("API Security")) {
                    
                    VStack(alignment: .leading) {
                        Text("API Key")
                        TextField("API Key:", text: $configuration.apiKey)
                            .foregroundColor(.blue)
                        
                        Divider()
                        
                        Text("Secret Key")
                        TextField("Secret Key:", text: $configuration.secretKey)
                            .foregroundColor(.blue)
                    }
                    .autocorrectionDisabled()
                }
                
                Section(header: Text("Processing Details")) {
                    
                    VStack(alignment: .leading) {
                        
                        Group {
                            
                            Text("Merchant Name")
                            TextField("Merchant Name", text: $configuration.merchantName)
                                .foregroundColor(.blue)
                            Divider()
                            
                            Text("Merchant ID")
                            TextField("Merchant ID", text: $configuration.merchantId)
                                .foregroundColor(.blue)
                                .keyboardType(.numberPad)
                            
                            Divider()
                            
                            Text("Terminal ID")
                            TextField("Terminal ID", text: $configuration.terminalId)
                                .foregroundColor(.blue)
                                .keyboardType(.numberPad)
                        }
                        .autocorrectionDisabled()
                        
                        
                        Group {
                            Divider()
                            
                            Text("Merchant Category Code")
                            
                            TextField("Merchant Category Code", text: $configuration.merchantCategoryCode)
                                .foregroundColor(.blue)
                                .keyboardType(.numberPad)
                            
                            Divider()
                            
                            Text("Terminal Profile ID")
                            TextField("", text: $configuration.terminalProfileId)
                                .foregroundColor(.blue)
                        }
                        .autocorrectionDisabled()
                    }
                }
                
                HStack {
                
                    Spacer()
                    
                    Button {
                        isPresented = false
                    } label: {
                        
                        Text("Application v0.0.9")
                        
                        Text("Done")
                    }
                    Spacer()
                }
            }
        }
    }
}

struct ConfigurationView_Previews: PreviewProvider {
    static var previews: some View {
        ConfigurationView(isPresented: .constant(true))
            .environmentObject(Configuration())
    }
}
