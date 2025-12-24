import Foundation
import Combine

struct ChatRoomInfo: Codable {
    let room_id: Int
    let title: String
    let content: String
    let created_at: String
    let location_name: String
    let appointment_datetime: String
    let participant_count: Int
}

class MateChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var newMessage = ""

    @Published var roomTitle = ""
    @Published var roomContent = ""
    @Published var postDate = ""
    @Published var locationName = ""
    @Published var appointmentTime = ""
    @Published var participantCount = 0

    let baseURL = "http://124.56.5.77/ykt"
    let roomId: Int

    var userId: Int {
        let saved = UserDefaults.standard.integer(forKey: "user_id")
        return saved == 0 ? -1 : saved
    }

    var timer: Timer?

    init(roomId: Int = -1) {
        self.roomId = roomId
        if roomId != -1 {
            fetchRoomInfo()
            startAutoRefresh()
        }
    }

    func fetchRoomInfo() {
        let urlString = "\(baseURL)/get_room_info.php?room_id=\(roomId)"
        print("[DEBUG] fetchRoomInfo 요청 URL:", urlString)

        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("네트워크 오류:", error)
                return
            }

            guard let data = data else {
                print("데이터 없음(fetchRoomInfo)")
                return
            }

            print("fetchRoomInfo 응답 JSON:", String(data: data, encoding: .utf8) ?? "nil")

            do {
                let result = try JSONDecoder().decode(ChatRoomInfo.self, from: data)
                DispatchQueue.main.async {
                    self.roomTitle = result.title
                    self.roomContent = result.content
                    self.postDate = result.created_at
                    self.locationName = result.location_name
                    self.appointmentTime = result.appointment_datetime
                    self.participantCount = result.participant_count
                }
            } catch {
                print("JSON 디코딩 실패(fetchRoomInfo):", error)
            }

        }.resume()
    }

    func startAutoRefresh() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            self.fetchMessages()
        }
    }

    func stopAutoRefresh() {
        timer?.invalidate()
        timer = nil
    }

    func fetchMessages() {
        guard let url = URL(string: "\(baseURL)/get_chat_messages.php?room_id=\(roomId)") else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data,
                  let result = try? JSONDecoder().decode([ChatMessage].self, from: data) else {
                return
            }

            DispatchQueue.main.async {
                self.messages = result
            }
        }.resume()
    }

    func sendMessage() {
        guard !newMessage.isEmpty else { return }
        guard let url = URL(string: "\(baseURL)/send_chat_message.php") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = "room_id=\(roomId)&user_id=\(userId)&content=\(newMessage)"
        request.httpBody = body.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { _, _, _ in
            DispatchQueue.main.async {
                self.newMessage = ""
                self.fetchMessages()
            }
        }.resume()
    }

    func leaveRoom(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/leave_room.php") else {
            completion(false)
            return
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = "room_id=\(roomId)&user_id=\(userId)"
        req.httpBody = body.data(using: .utf8)

        URLSession.shared.dataTask(with: req) { data, res, err in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  json["success"] as? Bool == true else {
                DispatchQueue.main.async { completion(false) }
                return
            }

            DispatchQueue.main.async {
                completion(true)
            }
        }.resume()
    }
}
