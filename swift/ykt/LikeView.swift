//
//  LikeView.swift
//  ykt
//
//  Created by mac17 on 10/27/25.
//

import SwiftUI

struct LikeView: View {
    var body: some View {
        VStack{
            NavigationLink {
                HamberView()
            } label: {
                Text("내가 좋아요 한 메뉴")
            }
        }
    }
}

#Preview {
    LikeView()
}
