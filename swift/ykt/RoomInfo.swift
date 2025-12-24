//
//  RoomInfo.swift
//  ykt
//
//  Created by mac17 on 12/3/25.
//

import Foundation


struct RoomInfo: Codable, Identifiable {
    var id: Int { room_id }
    
    let room_id: Int
    let title: String
    let content: String
    let created_at: String
    let location_name: String
    let appointment_datetime: String
    let participant_count: Int
    let participants_max: Int
    let creator_id: Int?
    let isMine: Int?
    let isJoined: Int?
}

