//  TTPProgressView
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

struct TTPProgressView: View {
    
    @State var degress = 0.0
    
    var body: some View {
        HStack() {
            Circle()
                .trim(from: 0.0, to: 0.6)
                .stroke(.blue, lineWidth: 5.0)
                .frame(width: 120, height: 120)
                .rotationEffect(Angle(degrees: degress))
                .onAppear(perform: {self.start()})
            
            Spacer()
            
            Text("Working...")
            
            Spacer()
        }
    }
    
    func start() {
        _ = Timer.scheduledTimer(withTimeInterval: 0.06, repeats: true) { timer in
            withAnimation {
                self.degress += 10.0
            }
        }
    }
}

struct TTPProgressView_Previews: PreviewProvider {
    static var previews: some View {
        TTPProgressView()
    }
}
