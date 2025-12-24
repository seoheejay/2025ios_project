//
//  SaleInfoView.swift
//  ykt
//
//  Created by mac17 on 10/27/25.
//

import SwiftUI

struct SaleInfoView: View {
    var body: some View {
        VStack{
            NavigationLink {
                HamberView()
            } label: {
                Text("햄버거탭")
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    SaleInfoView()
}
