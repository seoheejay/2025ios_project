import SwiftUI

struct MateLocation: Identifiable, Decodable {
    let id: Int
    let name: String
}

struct MateFixRoomDetail: Decodable {
    let room_id: Int
    let title: String
    let content: String
    let location_id: Int
    let location_name: String
    let appointment_datetime: String
    let max_participants: Int
}

struct MateFixRoomDetailResponse: Decodable {
    let status: String
    let room: MateFixRoomDetail?
    let message: String?
}

struct MateFixSimpleResponse: Decodable {
    let status: String
    let message: String?
}

struct MateFixView: View {

    let roomID: Int   // ← MateJoinView에서 전달되는 **진짜** room_id

    private let baseURL = "http://124.56.5.77/ykt/bk"
    private let customDark = Color(red: 97/255, green: 22/255, blue: 37/255)

    @Environment(\.dismiss) private var dismiss

    @State private var loading = true

    @State private var titleText = ""
    @State private var contentText = ""
    @State private var selectedLocationID: Int = 0
    @State private var selectedLocationName: String = ""
    @State private var appointmentText = ""
    @State private var maxCount = 2

    @State private var locations: [MateLocation] = []
    @State private var showLocationMenu = false

    @State private var showAlert = false
    @State private var alertMessage = ""

    @State private var goToChat = false

    var body: some View {

        ZStack {
            Color(red: 245/255, green: 245/255, blue: 245/255)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: -61.5) {

                headerBar()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {

                        topBar()

                        if loading {
                            VStack {
                                ProgressView("방 정보 불러오는 중…")
                                    .padding(.top, 20)
                                Spacer(minLength: 40)
                            }
                        } else {
                            formSection()
                        }

                        Spacer(minLength: 40)
                    }
                    .background(Color.white)
                }
            }

            NavigationLink(
                destination: MateChatView(roomId: roomID),
                isActive: $goToChat
            ) { EmptyView() }
            .hidden()
        }
        .onAppear {
            loadLocations()
            loadDetail()
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .alert(alertMessage, isPresented: $showAlert) {
            Button("확인", role: .cancel) {

                if alertMessage.contains("수정이 완료되었습니다.") {
                    dismiss()
                }

                if alertMessage.contains("삭제") {
                    dismiss()
                }
            }
        }
    }

    private func headerBar() -> some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(customDark)
                    .font(.system(size: 20))
            }
            .padding(.leading, 20)

            Spacer()

            Image("DuksungLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200, height: 70)

            Spacer()

            NavigationLink(destination: CartView()) {
                Image(systemName: "cart")
                    .font(.system(size: 22))
                    .foregroundColor(customDark)
            }
            .padding(.trailing, 40)
        }
        .frame(height: 50)
        .padding(.top, UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0)
        .background(Color.white)
        .ignoresSafeArea(edges: .top)
    }

    private func topBar() -> some View {
        HStack {
            Text("식사 메이트 수정")
                .font(.headline)
                .bold()
                .foregroundColor(.black)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.white)
    }

    private func formSection() -> some View {
        VStack(alignment: .leading, spacing: 18) {

            VStack(alignment: .leading, spacing: 6) {
                Text("방 이름")
                    .font(.subheadline)
                TextField("방 이름 입력", text: $titleText)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            VStack(alignment: .leading, spacing: 6) {
                Text("글 작성")
                    .font(.subheadline)
                TextEditor(text: $contentText)
                    .frame(height: 150)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            .padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 6) {
                Text("장소")
                    .font(.subheadline)

                Menu {
                    ForEach(locations) { loc in
                        Button(loc.name) {
                            selectedLocationID = loc.id
                            selectedLocationName = loc.name
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedLocationName.isEmpty ? "장소 선택" : selectedLocationName)
                            .foregroundColor(.black)
                        Spacer()
                        Image(systemName: "chevron.down")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 6) {
                Text("약속 시간")
                    .font(.subheadline)
                TextField("YYYY-MM-DD hh:mm:ss", text: $appointmentText)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            .padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 6) {
                Text("인원수")
                    .font(.subheadline)

                Stepper(value: $maxCount, in: 1...10) {
                    Text("\(maxCount) 명")
                        .font(.headline)
                }
            }
            .padding(.horizontal, 20)

            VStack(spacing: 10) {

                Button(action: updateRoom) {
                    Text("수정하기")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(customDark)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                Button(action: {
                    goToChat = true
                }) {
                    Text("참여하기")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.85))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                Button(action: deleteRoom) {
                    Text("글 삭제하기")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }

    private func loadLocations() {
        guard let url = URL(string: "\(baseURL)/get_locations.php") else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { return }

            if let decoded = try? JSONDecoder().decode([String: [MateLocation]].self, from: data),
               let list = decoded["locations"] {

                DispatchQueue.main.async {
                    self.locations = list
                }
            }
        }.resume()
    }

    private func loadDetail() {
        guard let url = URL(string: "\(baseURL)/get_room_detail.php") else { return }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.httpBody = "room_id=\(roomID)".data(using: .utf8)

        URLSession.shared.dataTask(with: req) { data, _, _ in
            guard let data = data else { return }

            do {
                let decoded = try JSONDecoder().decode(MateFixRoomDetailResponse.self, from: data)

                DispatchQueue.main.async {
                    if decoded.status == "success", let r = decoded.room {

                        titleText = r.title
                        contentText = r.content
                        appointmentText = r.appointment_datetime
                        maxCount = r.max_participants

                        selectedLocationID = r.location_id
                        selectedLocationName = r.location_name

                        loading = false

                    } else {
                        alertMessage = decoded.message ?? "방 정보를 불러오지 못했습니다."
                        showAlert = true
                        loading = false
                    }
                }

            } catch {
                DispatchQueue.main.async {
                    alertMessage = "방 정보를 불러오는 중 오류가 발생했습니다."
                    showAlert = true
                    loading = false
                }
            }

        }.resume()
    }

    private func updateRoom() {
        guard let url = URL(string: "\(baseURL)/update_room.php") else { return }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"

        let bodyDict: [String: String] = [
            "room_id": "\(roomID)",
            "title": titleText,
            "content": contentText,
            "location_id": "\(selectedLocationID)",
            "appointment": appointmentText,
            "max_participants": "\(maxCount)"
        ]

        req.httpBody = formURLEncoded(bodyDict)

        URLSession.shared.dataTask(with: req) { data, _, _ in
            guard let data = data else { return }

            do {
                let res = try JSONDecoder().decode(MateFixSimpleResponse.self, from: data)

                DispatchQueue.main.async {
                    alertMessage = res.status == "success" ? "수정이 완료되었습니다." : (res.message ?? "수정 실패")
                    showAlert = true
                }

            } catch {
                DispatchQueue.main.async {
                    alertMessage = "수정 중 오류가 발생했습니다."
                    showAlert = true
                }
            }

        }.resume()
    }

    private func deleteRoom() {
        guard let url = URL(string: "\(baseURL)/delete_room.php") else { return }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.httpBody = "room_id=\(roomID)".data(using: .utf8)

        URLSession.shared.dataTask(with: req) { data, _, _ in
            guard let data = data else { return }

            do {
                let res = try JSONDecoder().decode(MateFixSimpleResponse.self, from: data)

                DispatchQueue.main.async {
                    alertMessage = res.status == "success" ? "삭제되었습니다." : (res.message ?? "삭제 실패")
                    showAlert = true
                }

            } catch {
                DispatchQueue.main.async {
                    alertMessage = "삭제 중 오류가 발생했습니다."
                    showAlert = true
                }
            }
        }.resume()
    }
}

private func formURLEncoded(_ dict: [String: String]) -> Data? {
    let s = dict.map {
        "\($0.key)=\(($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value))"
    }.joined(separator: "&")

    return s.data(using: .utf8)
}

#Preview {
    MateFixView(roomID: 1)
}
