//
//  CartViewModel.swift
//  ykt
//
//  Created by mac32 on 11/3/25.
//

import Foundation
import Combine

final class CartViewModel: ObservableObject {
    @Published var cartItems: [CartItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var createdReceiptNumber: Int?
    

    //private let baseURL = "http://localhost:8000"
    private let baseURL = "http://124.56.5.77/ykt"

    @Published var orderCreated = false
    @Published var createdOrderID: Int?
    
    var userId: Int?

    init() {
        let saved = UserDefaults.standard.integer(forKey: "user_id")
        self.userId = (saved == 0) ? nil : saved
    }

    func createOrder(items: [CartItem]) {
        guard let userId = userId else {
            print("userId 없음")
            return
        }

        guard let url = URL(string: "\(baseURL)/create_order.php") else { return }
        print(" createOrder 실행됨, 아이템 개수:", items.count)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let itemsData = items.map {
            ["menu_id": $0.menu_id, "price": $0.price, "quantity": $0.quantity]
        }

        
        let itemsJson = String(data: try! JSONSerialization.data(withJSONObject: itemsData), encoding: .utf8)!

       
        let encodedItems = itemsJson.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!

        
        let body = "user_id=\(userId)&items=\(encodedItems)"
        print("보내는 body:", body)
        request.httpBody = body.data(using: .utf8)

        // 서버 호출
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in

            print("createOrder 서버 응답 raw:", String(data: data ?? Data(), encoding: .utf8) ?? "no data")

            guard let data = data else { return }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                DispatchQueue.main.async {
                    if let success = json["success"] as? Bool,
                       success == true,
                       let orderID = json["order_id"] as? Int,
                       let receiptNumber = json["receipt_number"] as? Int {

                        print("주문 성공! order_id =", orderID, " receipt =", receiptNumber)
                        self?.createdOrderID = orderID
                        self?.createdReceiptNumber = receiptNumber
                        self?.orderCreated = true
                    }
                }
            }
        }.resume()
    }


    func fetchCartItems() {
        guard let userId = userId else {
            print("userId 없음")
            return
        }

        isLoading = true
        errorMessage = nil

        guard let url = URL(string: "\(baseURL)/get_cart.php?user_id=\(userId)") else {
            errorMessage = "잘못된 URL"
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            print(" 서버 응답 raw:", String(data: data ?? Data(), encoding: .utf8) ?? "no data")

            DispatchQueue.main.async {
                self?.isLoading = false
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    self?.errorMessage = "서버 응답 없음"
                }
                return
            }

            do {
                let decoded = try JSONDecoder().decode([CartData].self, from: data)
                DispatchQueue.main.async {
                    self?.cartItems = decoded.first?.items ?? []
                }
            } catch {
                DispatchQueue.main.async {
                    self?.errorMessage = "데이터 파싱 실패: \(error.localizedDescription)"
                }
            }

        }.resume()
    }
    
    func deleteItemFromServer(cartItemID: Int) {
        guard let url = URL(string: "\(baseURL)/delete_cart_item.php") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = "cart_item_id=\(cartItemID)"
        request.httpBody = body.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            print(" createOrder 서버 응답 raw:", String(data: data ?? Data(), encoding: .utf8) ?? "no data")
            DispatchQueue.main.async {
                self?.cartItems.removeAll { $0.cart_item_id == cartItemID }
            }
            
        }.resume()
    }

    func deleteSelectedItemsFromServer(ids: Set<Int>) {
        for id in ids {
            deleteItemFromServer(cartItemID: id)
        }
    }
}
