import SwiftUI

struct HamberView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topLeading) {

        
            Color(red: 0.35, green: 0.05, blue: 0.15)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {

            
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding(.top, 16)
                        .padding(.leading, 20)
                }

                Divider()
                    .background(Color.white.opacity(0.6))
                    .padding(.vertical, 12)

            
                VStack(alignment: .leading, spacing: 0) {

                    menuLink(title: "홈", destination: MenuView())
                    menuDivider()

                    menuLink(title: "장바구니", destination: CartView())
                    menuDivider()

                    menuLink(title: "좋아요", destination: LikeView())
                    menuDivider()

                    menuLink(title: "주문/칼로리 순위", destination: RankMenuItemView())
                    menuDivider()

                    menuLink(title: "식사메이트", destination: MateListView())
                    menuDivider()

                    menuLink(title: "주문내역", destination: OrderListView())
                    menuDivider()

                    menuLink(title: "마이페이지", destination: MyInfoView())
                    menuDivider()

                    menuLink(title: "할인정보", destination: SaleInfoView())
                }
                .padding(.horizontal, 20)

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    
    private func menuLink<T: View>(title: String, destination: T) -> some View {
        NavigationLink(destination: destination) {
            Text(title)
                .font(.title3)
                .bold()
                .foregroundColor(.white)
                .padding(.vertical, 14)
        }
    }

    
    private func menuDivider() -> some View {
        Divider()
            .background(Color.white.opacity(0.5))
    }
}

#Preview {
    NavigationView {
        HamberView()
    }
}
