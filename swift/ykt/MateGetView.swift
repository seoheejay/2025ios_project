import SwiftUI

struct MateGetView: View {

    let room: RoomInfo
    let currentUserId: Int

    @State private var currentParticipants: Int = 0
    @State private var isJoining: Bool = false
    @State private var goToChat: Bool = false
    @State private var errorMessage: String?

    @Environment(\.presentationMode) var presentationMode

    private let serverURL = "http://124.56.5.77/ykt/sec/mate.php"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            VStack(alignment: .leading, spacing: 8) {
                Text("방 이름")
                    .font(.caption)
                    .foregroundStyle(.gray)

                Text(room.title)
                    .font(.title3)
                    .bold()

                Text(room.content)
                    .font(.body)
                    .padding(.top, 8)
            }
            .padding()

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                infoRow(title: "글쓴 시간", value: room.created_at)
                infoRow(title: "장소", value: room.location_name)
                infoRow(title: "약속 일시", value: room.appointment_datetime)
                infoRow(title: "현재 인원", value: "\(currentParticipants)/\(room.participants_max)")
            }
            .padding(.horizontal)

            Spacer()

            NavigationLink(
                destination: MateChatView(roomId: room.room_id),
                isActive: $goToChat
            ) {
                EmptyView()
            }
            .hidden()

            Button {
                joinRoom()
            } label: {
                Text("참여하기")
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
            .disabled(isJoining)
        }
        .navigationTitle("방 정보")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        
                    }
                }
            }
        }
        .onAppear {
            currentParticipants = room.participant_count
        }
        .alert("오류", isPresented: .constant(errorMessage != nil)) {
            Button("확인") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func joinRoom() {
        guard let url = URL(string: serverURL) else { return }

        isJoining = true

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let bodyString = "type=join_room&room_id=\(room.room_id)&user_id=\(currentUserId)"
        request.httpBody = bodyString.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {

                isJoining = false

                if let error = error {
                    errorMessage = error.localizedDescription
                    return
                }

                guard let data = data else {
                    errorMessage = "서버 응답 없음"
                    return
                }

                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {

                    if let result = json["result"] as? Bool, result == true {

                        if let count = json["current_participants"] as? Int {
                            currentParticipants = count
                        } else {
                            currentParticipants += 1
                        }

                        goToChat = true
                        return
                    }

                    errorMessage = json["message"] as? String ?? "참여 실패"
                    return
                }

                errorMessage = "JSON 파싱 오류"
            }
        }.resume()
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text("\(title):")
                .foregroundStyle(.gray)
            Spacer()
            Text(value)
        }
        .font(.subheadline)
    }
}
