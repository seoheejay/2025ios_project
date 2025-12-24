//
//  MateRoomListViewModel.swift
//  ykt
//
//  Created by mac32 on 12/1/25.
//
import Foundation
import Combine


class MateRoomListViewModel: ObservableObject {
    @Published var rooms: [RoomInfo] = []

    //let baseURL = "http://localhost"
    private let baseURL = "http://124.56.5.77/ykt"
    //let userId = 1
    var userId: Int?

    init() {
        let saved = UserDefaults.standard.integer(forKey: "user_id")
        self.userId = (saved == 0) ? nil : saved
    }

    func fetchMyRooms() {
        print("fetchMyRooms 호출됨")
        //guard let url = URL(string: "\(baseURL)/get_my_rooms.php?user_id=\(userId)") else {
            //print("url 생성 실패")
          //  return }
        guard let uid = userId else {
            print("userId 없음. 로그인 안된 상태")
            return
        }

        let urlString = "\(baseURL)/get_my_rooms.php?user_id=\(uid)"
        print("청 URL:", urlString)

        guard let url = URL(string: urlString) else {
            print("URL 변환 실패")
            return
        }
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("network error:", error)
                return
            }

            guard let data = data else {
                print("no data returned")
                return
            }

            print(" JSON:", String(data: data, encoding: .utf8)!)

            do {
                let result = try JSONDecoder().decode([RoomInfo].self, from: data)
                DispatchQueue.main.async {
                    self.rooms = result
                    print("rooms updated:", result.count)
                }
            } catch {
                print("JSON decoding error:", error)
            }

        }.resume()
    }
}
