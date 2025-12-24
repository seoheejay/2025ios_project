//
//  OrderView.swift
//  ykt
//

import SwiftUI
import Foundation

struct OrderView: View {
    let itemsToOrder: [CartItem]
    let orderId: Int
    let receiptNumber: Int
    @State private var goToMenu = false
    
    // 최종 금액 계산
    var finalPaymentAmount: Int {
        itemsToOrder.reduce(0) { $0 + ($1.price * $1.quantity) }
    }

    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 30) {
            
            
            Text("주문이 접수되었습니다.")
                .font(.title2)
                .fontWeight(.regular)
            
            VStack(spacing: 15) {
                Text("접수 번호")
                    .font(.headline)
                
                Text("\(receiptNumber)")
                    .font(.system(size: 80, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white)
                    .shadow(color: .gray.opacity(0.3), radius: 10)
            )
            .padding(.horizontal, 30)
            
            VStack(alignment: .leading, spacing: 15) {
                Divider()
                Text("주문 목록")
                    .font(.headline)
                
                ForEach(itemsToOrder) { item in
                    Text("\(item.menu_name) x\(item.quantity)")
                        .foregroundColor(.gray)
                }
                
                Divider()
                HStack {
                    Text("결제 금액")
                        .font(.headline)
                    Spacer()
                    Text("\(finalPaymentAmount)원")
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
            .padding(.horizontal, 30)
            
            Spacer()
            
        }
        NavigationLink("", destination: MenuView(), isActive: $goToMenu)
            .hidden()

        Button("확인") {
            goToMenu = true
        }
        .font(.headline)
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
        .navigationTitle("주문 완료")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    NavigationStack {
        OrderView(itemsToOrder: CartItem.previews, orderId: 5, receiptNumber: 216)
    }
}
