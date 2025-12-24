import SwiftUI
import Combine

private let ORDER_BASE_URL = "http://124.56.5.77/ykt/sec"

// MARK: - Models

struct OLMenuItem: Identifiable {
    let id: Int         // order_item_id
    let menuId: Int
    let name: String
    let price: Int
    let quantity: Int
    let isReviewed: Bool
}

struct OLOrderSummary: Identifiable {
    let id: Int
    let orderDate: String
    let receiptNumber: String
    let title: String
    let totalPrice: Int
    let items: [OLMenuItem]
}

struct OrderItemDTO: Codable {
    let orderItemId: Int
    let menuId: Int?
    let menuName: String
    let price: Int
    let quantity: Int
    let isReviewed: Int
    
    enum CodingKeys: String, CodingKey {
        case orderItemId, menuId, menuName, price, quantity, isReviewed
    }
}

struct OrderDTO: Codable {
    let orderId: Int
    let orderDate: String
    let receiptNumber: String
    let totalPrice: Int
    let items: [OrderItemDTO]
}

struct OrderListServerError: Decodable {
    let error: String?
}

struct ReviewTarget: Identifiable {
    let id = UUID()
    let order: OLOrderSummary
    let menu: OLMenuItem
}

// MARK: - ViewModel

@MainActor
final class OLOrderListViewModel: ObservableObject {
    @Published var orders: [OLOrderSummary] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private func currentUserId() -> Int {
        let saved = UserDefaults.standard.integer(forKey: "user_id")
        return saved == 0 ? 1 : saved
    }

  
    func markItemAsReviewed(orderId: Int, menuId: Int) {
       
        guard let orderIndex = orders.firstIndex(where: { $0.id == orderId }) else { return }
        
        
        guard let itemIndex = orders[orderIndex].items.firstIndex(where: { $0.menuId == menuId }) else { return }
        
        
        let oldItem = orders[orderIndex].items[itemIndex]
        let newItem = OLMenuItem(
            id: oldItem.id,
            menuId: oldItem.menuId,
            name: oldItem.name,
            price: oldItem.price,
            quantity: oldItem.quantity,
            isReviewed: true
        )
        
        var newItems = orders[orderIndex].items
        newItems[itemIndex] = newItem
        
        let newOrder = OLOrderSummary(
            id: orders[orderIndex].id,
            orderDate: orders[orderIndex].orderDate,
            receiptNumber: orders[orderIndex].receiptNumber,
            title: orders[orderIndex].title,
            totalPrice: orders[orderIndex].totalPrice,
            items: newItems
        )
        
        orders[orderIndex] = newOrder
    }

    func loadFromServer() {
        isLoading = true
        errorMessage = nil

        let userId = currentUserId()
        guard let url = URL(string: "\(ORDER_BASE_URL)/order_list.php?user_id=\(userId)") else {
            isLoading = false
            errorMessage = "잘못된 URL"
            return
        }

        Task {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    isLoading = false
                    errorMessage = "서버 에러 (Status: \(httpResponse.statusCode))"
                    return
                }

                let rawData = String(data: data, encoding: .utf8) ?? "데이터 없음"
                print("[DEBUG] 서버 응답 데이터: \(rawData)")

                let decoder = JSONDecoder()

                if let dtoList = try? decoder.decode([OrderDTO].self, from: data) {
                    self.orders = dtoList.map { dto in
                        let title: String
                        if let first = dto.items.first {
                            if dto.items.count == 1 {
                                title = first.menuName
                            } else {
                                title = "\(first.menuName) 외 \(dto.items.count - 1)건"
                            }
                        } else {
                            title = "주문 \(dto.orderId)"
                        }

                        let items = dto.items.map { itemDto in
                            OLMenuItem(
                                id: itemDto.orderItemId,
                                menuId: itemDto.menuId ?? 0,
                                name: itemDto.menuName,
                                price: itemDto.price,
                                quantity: itemDto.quantity,
                                isReviewed: itemDto.isReviewed == 1
                            )
                        }

                        return OLOrderSummary(
                            id: dto.orderId,
                            orderDate: "주문 일자: \(dto.orderDate)",
                            receiptNumber: dto.receiptNumber,
                            title: title,
                            totalPrice: dto.totalPrice,
                            items: items
                        )
                    }
                    isLoading = false
                    return
                }

                if let serverError = try? decoder.decode(OrderListServerError.self, from: data) {
                    isLoading = false
                    self.errorMessage = serverError.error ?? "서버 오류 발생"
                    return
                }
                
                do {
                    _ = try decoder.decode([OrderDTO].self, from: data)
                } catch {
                    print("[JSON ERROR] 디코딩 실패: \(error)")
                    isLoading = false
                    self.errorMessage = "데이터 불러오기 실패 (형식 오류)"
                }

            } catch {
                isLoading = false
                errorMessage = "네트워크 오류: \(error.localizedDescription)"
            }
        }
    }

    func addOrderToCart(_ order: OLOrderSummary) {
        let userId = currentUserId()
        guard let url = URL(string: "\(ORDER_BASE_URL)/order_reorder.php") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyString = "user_id=\(userId)&order_id=\(order.id)"
        request.httpBody = bodyString.data(using: .utf8)

        Task {
            _ = try? await URLSession.shared.data(for: request)
        }
    }

    func deleteOrder(_ order: OLOrderSummary) {
        if let idx = orders.firstIndex(where: { $0.id == order.id }) {
            orders.remove(at: idx)
        }
    }
}

// MARK: - Main View

struct OrderListView: View {
    @StateObject private var viewModel = OLOrderListViewModel()

    @State private var selectedOrderForDetail: OLOrderSummary? = nil
    @State private var goToOrderDetail: Bool = false
    @State private var orderForMenuSelect: OLOrderSummary? = nil
    @State private var reviewTarget: ReviewTarget? = nil
    @State private var showCartToast: Bool = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                OLOrderListTopBar()

                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if let error = viewModel.errorMessage {
                    Spacer()
                    Text(error)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                    Spacer()
                } else if viewModel.orders.isEmpty {
                    Spacer()
                    Text("주문 내역이 없습니다!")
                        .foregroundColor(.gray)
                        .padding()
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(viewModel.orders) { order in
                                OLOderCardView(
                                    order: order,
                                    onTapCard: {
                                        selectedOrderForDetail = order
                                        goToOrderDetail = true
                                    },
                                    onTapReview: {
                                        DispatchQueue.main.async {
                                            orderForMenuSelect = order
                                        }
                                    },
                                    onTapAddToCart: {
                                        viewModel.addOrderToCart(order)
                                        showCartToast = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                            showCartToast = false
                                        }
                                    },
                                    onTapDelete: {
                                        viewModel.deleteOrder(order)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                }

                NavigationLink(
                    destination: Group {
                        if let order = selectedOrderForDetail {
                            OrderHistoryView(order: order)
                        } else {
                            EmptyView()
                        }
                    },
                    isActive: $goToOrderDetail
                ) {
                    EmptyView()
                }
            }
            .background(Color(red: 0.5, green: 0.0, blue: 0.15).opacity(0.9))

            if showCartToast {
                VStack(spacing: 8) {
                    Image(systemName: "cart.badge.plus")
                        .font(.system(size: 32))
                    Text("선택하신 상품이")
                    Text("장바구니에 담겼습니다.")
                        .underline()
                }
                .font(.caption)
                .padding(16)
                .background(Color.black.opacity(0.7))
                .foregroundColor(.white)
                .cornerRadius(12)
                .frame(maxWidth: 240)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showCartToast)
        .navigationBarBackButtonHidden(true)
        
        .sheet(item: $orderForMenuSelect) { order in
            OLReviewMenuSelectSheet(order: order) { menu in
                orderForMenuSelect = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    reviewTarget = ReviewTarget(order: order, menu: menu)
                }
            }
        }
        .background(
            EmptyView()
                .sheet(item: $reviewTarget) { target in
                    ReviewPostView(
                        orderId: target.order.id,
                        orderItemId: target.menu.id,
                        menuId: target.menu.menuId,
                        price: target.menu.price,
                        menuName: target.menu.name,
                        orderDate: target.order.orderDate,
                    
                        onSuccess: {
                            viewModel.markItemAsReviewed(orderId: target.order.id, menuId: target.menu.menuId)
                        }
                    )
                }
        )
        .onAppear {
            viewModel.loadFromServer()
        }
    }
}

// MARK: - Subviews

struct OLOrderListTopBar: View {
    var body: some View {
        HStack(spacing: 12) {
            NavigationLink(destination: HamberView()) {
                Image(systemName: "line.3.horizontal")
                    .font(.title2)
                    .foregroundColor(.black)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("덕성여자대학교").font(.headline).bold()
                Text("DUKSUNG WOMEN'S UNIVERSITY")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            NavigationLink(destination: CartView()) {
                Image(systemName: "cart")
                    .font(.title2)
                    .foregroundColor(.black)
            }
        }
        .padding()
        .background(Color.white)
        .overlay(Divider(), alignment: .bottom)
    }
}

struct OLOderCardView: View {
    let order: OLOrderSummary
    let onTapCard: () -> Void
    let onTapReview: () -> Void
    let onTapAddToCart: () -> Void
    let onTapDelete: () -> Void

    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(order.orderDate)
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(order.title)
                            .font(.headline)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("주문 번호: \(order.receiptNumber)")
                            .font(.caption)
                            .foregroundColor(.gray)

                        Button(action: onTapDelete) {
                            Text("삭제")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }

                let allReviewed = order.items.allSatisfy { $0.isReviewed }

                HStack {
                    Button(action: onTapReview) {
                        HStack {
                            Text(allReviewed ? "리뷰 완료" : "리뷰 쓰기")
                            Image(systemName: "pencil")
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(allReviewed ? Color.gray : Color.blue)
                        .cornerRadius(14)
                    }
                    .disabled(allReviewed)
                    .buttonStyle(BorderlessButtonStyle())

                    Spacer()

                    Button(action: onTapAddToCart) {
                        HStack {
                            Text("장바구니 담기")
                            Text("· \(order.totalPrice)원")
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.pink)
                        .cornerRadius(18)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
                .padding(.top, 6)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
            .onTapGesture {
                onTapCard()
            }
        }
    }
}

struct OLReviewMenuSelectSheet: View {
    let order: OLOrderSummary
    let onSelectMenu: (OLMenuItem) -> Void

    var body: some View {
        NavigationView {
            List(order.items) { item in
                Button {
                    if !item.isReviewed {
                        onSelectMenu(item)
                    }
                } label: {
                    HStack {
                        Text(item.name)
                        Spacer()
                        if item.quantity > 1 {
                            Text("x\(item.quantity)")
                                .foregroundColor(.gray)
                        }
                        if item.isReviewed {
                            Text("이미 리뷰 작성")
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                    }
                }
                .disabled(item.isReviewed)
                .opacity(item.isReviewed ? 0.4 : 1.0)
            }
            .navigationTitle("어떤 메뉴 리뷰 쓸까?")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct OrderHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    let order: OLOrderSummary

    var body: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 20)

            Text("주문 완료")
                .font(.headline)
            Text("주문이 접수되었습니다.")
                .font(.title3)

            VStack {
                Text("접수 번호")
                    .font(.subheadline)
                    .padding(.top, 12)
                Text(order.receiptNumber)
                    .font(.system(size: 48, weight: .bold))
                    .padding(.vertical, 16)
            }
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(radius: 4)
            .padding(.horizontal, 24)

            Divider().padding(.horizontal, 24)

            HStack {
                Text("주문 목록")
                Spacer()
            }
            .padding(.horizontal, 24)

            VStack(spacing: 4) {
                ForEach(order.items) { item in
                    HStack {
                        Text(item.name)
                        Spacer()
                        Text("x\(item.quantity)")
                    }
                }
            }
            .padding(.horizontal, 24)

            Divider().padding(.horizontal, 24)

            HStack {
                Text("결제 금액")
                Spacer()
                Text("\(order.totalPrice)원")
                    .font(.headline)
            }
            .padding(.horizontal, 24)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("확인")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(white: 0.95))
                    .cornerRadius(10)
            }
            .padding(.horizontal, 80)
            .padding(.bottom, 24)
        }
        .background(Color.white.ignoresSafeArea())
    }
}
