//
//  CartData.swift
//  ykt
//
//  Created by mac32 on 11/13/25.
//
import Foundation

struct CartData: Codable, Identifiable {
    var id: Int { cart_id }

    let cart_id: Int
    let user_id: Int
    let status: Int
    let created_at: String
    let updated_at: String?
    let items: [CartItem]
}

