//
//  MateRoomListView.swift
//  ykt
//
//  Created by mac32 on 12/1/25.
//

import SwiftUI

struct MateRoomListView: View {
    @StateObject var vm = MateRoomListViewModel()

    var body: some View {
        NavigationView {
            List {
                ForEach(vm.rooms) { room in
                    NavigationLink(destination: MateChatView(roomId: room.room_id)) {
                        VStack(alignment: .leading) {
                            Text(room.title)
                                .font(.headline)
                            Text("약속: \(room.appointment_datetime)")
                                .font(.subheadline)
                        }
                        .onAppear{
                            print("셀 렌더링 — \(room.room_id) / \(room.title)")
                        }
                    }
                }
            }
            .onAppear {
                print("MateRoomListView onAppear-fetch")
                vm.fetchMyRooms()
            }
            .navigationTitle("참여 중인 방")
            .navigationBarBackButtonHidden(true)
        }
    }
}
