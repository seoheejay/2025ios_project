//
//  CartView.swift
//  ykt
//


import SwiftUI
import Combine
import Foundation

struct CartView: View {
    
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel = CartViewModel()
    @State private var selectedItemIDs: Set<Int> = []

    var selectedTotalAmount: Int {
        viewModel.cartItems
            .filter { selectedItemIDs.contains($0.id) }
            .reduce(0) { $0 + ($1.price * $1.quantity) }
    }

    var isOrderButtonEnabled: Bool {
        !selectedItemIDs.isEmpty
    }

    func deleteItem(id: Int) {
        viewModel.deleteItemFromServer(cartItemID: id)
        selectedItemIDs.remove(id)
    }

    func deleteSelectedItems() {
        viewModel.deleteSelectedItemsFromServer(ids: selectedItemIDs)
        selectedItemIDs.removeAll()
    }

    var body: some View {
        VStack(spacing: 0) {

            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                        //Text("뒤로")
                          //  .font(.headline)
                    }
                    .foregroundColor(.black)
                }
                Spacer()
            }
            .padding()
            
            if viewModel.isLoading {
                ProgressView("장바구니 불러오는 중...")
            } else if let error = viewModel.errorMessage {
                Text("오류: \(error)").foregroundColor(.red)
            } else if viewModel.cartItems.isEmpty {
                Spacer()
                Text("장바구니가 비어 있습니다.")
                Spacer()
            } else {

                // 리스트
                List {
                    ForEach(viewModel.cartItems) { item in
                        HStack {
                            Button {
                                if selectedItemIDs.contains(item.id) {
                                    selectedItemIDs.remove(item.id)
                                } else {
                                    selectedItemIDs.insert(item.id)
                                }
                            } label: {
                                Image(systemName: selectedItemIDs.contains(item.id) ? "checkmark.square.fill" : "square")
                            }
                            .buttonStyle(.plain)

                            VStack(alignment: .leading) {
                                HStack {
                                    Text(item.menu_name)
                                        .fontWeight(.medium)

                                    Button {
                                        deleteItem(id: item.id)
                                    } label: {
                                        Text("삭제")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                }

                                HStack {
                                    Text("\(item.category_name)")
                                        .font(.caption)
                                    Text("수량: \(item.quantity)개")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }

                            Spacer()

                            Text("가격: \(item.price * item.quantity)원")
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(PlainListStyle())


                // 하단 결제 영역
                VStack(spacing: 12) {
                    Divider()

                    HStack {
                        Text("결제 예정 금액 (선택 \(selectedItemIDs.count)개)")
                            .font(.headline)
                        Spacer()
                        Text("\(selectedTotalAmount)원")
                            .font(.title2)
                            .fontWeight(.bold)
                    }

                    NavigationLink(isActive: $viewModel.orderCreated) {
                        OrderView(
                            itemsToOrder: viewModel.cartItems.filter { selectedItemIDs.contains($0.id) },
                            orderId: viewModel.createdOrderID ?? -1,
                            receiptNumber: viewModel.createdReceiptNumber ?? -1
                        )
                    } label: {
                        EmptyView()
                    }
                    .opacity(0)





                    Button(action: {
                        let selected = viewModel.cartItems.filter { selectedItemIDs.contains($0.id) }
                        print("선택된 아이템:", selected.map { $0.menu_name })
                        print("orderCreated =", viewModel.orderCreated)
                        print("createdOrderID =", viewModel.createdOrderID ?? -1)
                        print("createdReceiptNumber =", viewModel.createdReceiptNumber ?? -1)

                        viewModel.createOrder(items: selected)
                    }) {

                        Text("주문하기")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isOrderButtonEnabled ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(!isOrderButtonEnabled)

                }
                .padding([.horizontal, .bottom])
                .background(Color(.systemBackground))
            }
        }
        .navigationTitle("장바구니")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.fetchCartItems()
        }
        .navigationBarHidden(true)
    }
}
