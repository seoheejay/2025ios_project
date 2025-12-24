//
//  ChatMessage.swift
//  ykt
//
//  Created by mac32 on 12/1/25.
//

import Foundation

struct ChatMessage: Identifiable, Codable {
    var id: Int { message_id }

    let message_id: Int
    let content: String
    let room_id: Int
    let sender_id: Int
    let is_read: Int
    let created_at: String

    // 서버에서 sender nickname을 받아오면 UI에 표시 가능
    let sender_nickname: String
}
