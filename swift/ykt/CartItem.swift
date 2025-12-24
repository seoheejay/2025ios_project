//
//  CartItem.swift
//  ykt
//

import Foundation

struct CartItem: Identifiable, Codable {

    // SwiftUI에서 id로 사용할 값 = cart_item_id
    var id: Int { cart_item_id }

    let cart_item_id: Int
    let menu_id: Int
    let menu_name: String
    let category: Int
    let category_name: String
    let promotion: Int
    let price: Int
    let quantity: Int
    let created_at: String?
    let updated_at: String?

    enum CodingKeys: String, CodingKey {
        case cart_item_id, menu_id, menu_name, category, category_name, promotion, price, quantity, created_at, updated_at
    }
}

//dumy data
extension CartItem {
    static let preview = CartItem(
        cart_item_id: 1,
        menu_id: 1,
        menu_name: "마라상궈",
        category: 1,
        category_name: "중식",
        promotion: 0,
        price: 7000,
        quantity: 1,
        created_at: "2025-10-27",
        updated_at: nil
    )
    
    static let previews = [CartItem.preview]
}

