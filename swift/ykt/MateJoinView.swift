import SwiftUI

struct MateRoomItem: Identifiable, Decodable {
    let id: Int
    let title: String
    let content: String
    let location_name: String
    let appointment: String
    let current_participants: Int
    let max_participants: Int
    let isMine: Int
    let status: Int
}

struct MateRoomListResponse: Decodable {
    let status: String
    let rooms: [MateRoomItem]
}

struct MateJoinView: View {

    private let baseURL = "http://124.56.5.77/ykt/bk"
    private let customDarkColor = Color(red: 97/255, green: 22/255, blue: 37/255)

    @State private var roomsMine: [MateRoomItem] = []
    @State private var roomsJoined: [MateRoomItem] = []
    @State private var goToRecruitList = false
    @State private var loading = true
    @State private var showAlert = false
    @State private var resultMessage = ""

    private func currentUserId() -> Int {
        let saved = UserDefaults.standard.integer(forKey: "user_id")
        return saved == 0 ? 1 : saved
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {

                Color.white.ignoresSafeArea()

                VStack(spacing: -61.5) {
                    headerBar()

                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {

                            topNavigationBar()

                            if loading {
                                ProgressView("불러오는 중…")
                                    .padding(.top, 20)
                            } else {
                                Text("내가 만든 식사 메이트")
                                    .font(.headline)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 12)

                                ForEach(roomsMine) { r in
                                    NavigationLink(destination: MateFixView(roomID: r.id)) {
                                        roomCard(r)
                                    }
                                    .buttonStyle(.plain)
                                }

                                Text("참석한 식사 메이트")
                                    .font(.headline)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 12)

                                ForEach(roomsJoined) { r in
                                    NavigationLink(destination: MateChatView(roomId: r.id)) {
                                        roomCard(r, showOwnerMark: true)
                                    }
                                    .buttonStyle(.plain)
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
                NavigationLink(destination: MateListView(),
                               isActive: $goToRecruitList) {
                    EmptyView()
                }
                .hidden()
            )
            .onAppear {
                loadRooms()
            }
        }
        .navigationBarBackButtonHidden(true)
        .alert(resultMessage, isPresented: $showAlert) {
            Button("확인") {}
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
                        Button("참석한 식사 메이트") { }
                        Button("메이트 모집 방") { goToRecruitList = true }
                    } label: {
                        HStack(spacing: 4) {
                            Text("참석한 식사 메이트")
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

    private func roomCard(_ r: MateRoomItem, showOwnerMark: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {

            HStack {
                if showOwnerMark && r.isMine == 1 {
                    Image(systemName: "star.fill")
                        .foregroundColor(customDarkColor)
                        .font(.system(size: 14))
                }

                Text(r.title)
                    .font(.headline)

                Spacer()

                Text("\(r.current_participants)/\(r.max_participants)")
                    .font(.headline)
            }

            Text(r.content)
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineLimit(2)

            HStack {
                Text("장소 | \(r.location_name)")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Text(r.appointment)
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
        loading = true
        roomsMine = []
        roomsJoined = []

        let uid = currentUserId()
        let group = DispatchGroup()

        group.enter()
        load(from: "\(baseURL)/get_my_created_rooms.php", userId: uid) { list in
            self.roomsMine = list
            group.leave()
        }

        group.enter()
        load(from: "\(baseURL)/get_my_joined_rooms.php", userId: uid) { list in
            self.roomsJoined = list
            group.leave()
        }

        group.notify(queue: .main) {
            self.loading = false
        }
    }

    private func load(from urlString: String,
                      userId: Int,
                      completion: @escaping ([MateRoomItem]) -> Void) {
        guard let url = URL(string: urlString) else { return }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.httpBody = "user_id=\(userId)".data(using: .utf8)

        URLSession.shared.dataTask(with: req) { data, _, _ in
            guard let data = data else { return }

            print(String(data: data, encoding: .utf8) ?? "nil")

            if let decoded = try? JSONDecoder().decode(MateRoomListResponse.self, from: data),
               decoded.status == "success" {
                DispatchQueue.main.async {
                    completion(decoded.rooms)
                }
            } else {
                DispatchQueue.main.async {
                    self.resultMessage = "방 목록 불러오기 실패"
                    self.showAlert = true
                }
            }
        }.resume()
    }
}

#Preview {
    MateJoinView()
}
