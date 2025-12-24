import SwiftUI

struct MateListResponse: Decodable {
    let status: String
    let data: [RoomInfo]?
    let message: String?
}

struct MateListView: View {
    @State private var rooms: [RoomInfo] = []
    @State private var isLoading: Bool = false
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false

    @State private var selectedFilter: String = "메이트 구하는 방"
    @State private var goToJoin: Bool = false

    private let customDarkColor = Color(red: 97/255, green: 22/255, blue: 37/255)

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                Color.white.ignoresSafeArea()

                VStack(spacing: -61.5) {
                    headerBar()

                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            topNavigationBar()

                            if isLoading {
                                ProgressView("불러오는 중…")
                                    .padding(.top, 20)
                            } else if rooms.isEmpty {
                                Text("등록된 메이트 방이 없습니다.")
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 20)
                            } else {
                                ForEach(rooms) { room in
                                    NavigationLink(
                                        destination: destinationView(for: room)
                                    ) {
                                        MateRoomCard(room: room)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                Spacer(minLength: 80)
                            }
                        }
                    }
                }

                addButton
            }
            .navigationBarHidden(true)
            .background(
                NavigationLink(
                    destination: MateJoinView(),
                    isActive: $goToJoin
                ) {
                    EmptyView()
                }
                .hidden()
            )
            .onAppear {
                loadRooms()
            }
        }
        .navigationBarBackButtonHidden(true)
        .alert(alertMessage, isPresented: $showAlert) {
            Button("확인") {}
        }
    }

    private func currentUserId() -> Int {
        let saved = UserDefaults.standard.integer(forKey: "user_id")
        return saved == 0 ? 1 : saved
    }

    @ViewBuilder
    private func destinationView(for room: RoomInfo) -> some View {
        let me = currentUserId()
        let mine = (room.creator_id ?? 0) == me || (room.isMine ?? 0) == 1
        let joined = (room.isJoined ?? 0) == 1

        if mine || joined {
            MateChatView(roomId: room.room_id)
        } else {
            MateGetView(room: room, currentUserId: me)
        }
    }

    private func headerBar() -> some View {
        HStack {
            NavigationLink(destination: HamberView()) {
                Image(systemName: "line.horizontal.3")
                    .foregroundColor(customDarkColor)
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
                    .foregroundColor(customDarkColor)
            }
            .padding(.trailing, 40)
        }
        .frame(height: 50)
        .padding(.top, UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0)
        .background(Color.white)
        .ignoresSafeArea(edges: .top)
    }

    private func topNavigationBar() -> some View {
        VStack(spacing: 0) {
            HStack {
                NavigationLink(destination: MenuView()) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(customDarkColor)
                }
                .padding(.leading, 15)

                Spacer()

                HStack(spacing: 8) {
                    Text("식사 메이트")
                        .font(.headline)

                    Menu {
                        Button("메이트 구하는 방") {
                            selectedFilter = "메이트 구하는 방"
                        }
                        Button("참석한 식사 메이트") {
                            selectedFilter = "참석한 식사 메이트"
                            goToJoin = true
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(selectedFilter)
                            Image(systemName: "chevron.down")
                        }
                    }
                }

                Spacer()

                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 20)
                    .padding(.trailing, 15)
            }
            .padding(.vertical, 8)
            .background(Color.white)

            Divider()
        }
    }

    private var addButton: some View {
        HStack {
            Spacer()
            NavigationLink(destination: MatePostView()) {
                HStack(spacing: 4) {
                    Text("추가")
                    Image(systemName: "plus.circle")
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(customDarkColor)
                .foregroundColor(.white)
                .cornerRadius(20)
                .padding(.trailing, 20)
                .padding(.bottom, 24)
            }
        }
    }

    private func loadRooms() {
        isLoading = true

        let userId = currentUserId()
        guard let url = URL(string: "http://124.56.5.77/ykt/ykt/MateListView.php?user_id=\(userId)") else {
            alertMessage = "서버 주소 오류"
            showAlert = true
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async { self.isLoading = false }

            if let error = error {
                DispatchQueue.main.async {
                    self.alertMessage = "네트워크 오류: \(error.localizedDescription)"
                    self.showAlert = true
                }
                return
            }

            guard let data = data, !data.isEmpty else {
                DispatchQueue.main.async {
                    self.alertMessage = "서버에서 데이터를 받지 못했습니다."
                    self.showAlert = true
                }
                return
            }

            do {
                let decoded = try JSONDecoder().decode(MateListResponse.self, from: data)
                DispatchQueue.main.async {
                    if decoded.status == "success" {
                        let list = decoded.data ?? []
                        self.rooms = list.sorted { $0.room_id > $1.room_id }
                    } else {
                        self.alertMessage = decoded.message ?? "목록을 불러오지 못했습니다."
                        self.showAlert = true
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.alertMessage = "JSON 오류: \(error.localizedDescription)"
                    self.showAlert = true
                }
            }
        }.resume()
    }
}

struct MateRoomCard: View {
    let room: RoomInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(room.title)
                    .font(.headline)
                Spacer()
                Text("\(room.participant_count)/\(room.participants_max)")
                    .font(.headline)
            }

            Text(room.content)
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineLimit(2)

            HStack {
                Text("장소 | \(room.location_name)")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Text(formattedDateTime)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var formattedDateTime: String {
        let input = DateFormatter()
        input.locale = Locale(identifier: "ko_KR")
        input.timeZone = TimeZone(identifier: "Asia/Seoul")
        input.dateFormat = "yyyy-MM-dd HH:mm:ss"

        let output = DateFormatter()
        output.locale = input.locale
        output.timeZone = input.timeZone
        output.dateFormat = "yyyy.MM.dd HH:mm"

        if let date = input.date(from: room.appointment_datetime) {
            return output.string(from: date)
        } else {
            return room.appointment_datetime
        }
    }
}
