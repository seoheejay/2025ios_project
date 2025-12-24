import SwiftUI

// MARK: - Models
struct AllergyItem: Identifiable, Decodable {
    let id: Int
    let allergy_name: String
    var checked: Bool

    enum CodingKeys: String, CodingKey {
        case id, allergy_name, checked
    }

    // id: "1" 또는 1, checked: "0"/0/false/true 모두 처리
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        // id 처리 (문자열/숫자 모두 허용)
        if let intId = try? c.decode(Int.self, forKey: .id) {
            id = intId
        } else if let strId = try? c.decode(String.self, forKey: .id),
                  let intId = Int(strId) {
            id = intId
        } else {
            id = 0
        }

        allergy_name = (try? c.decode(String.self, forKey: .allergy_name)) ?? ""

        // checked 처리
        if let boolVal = try? c.decode(Bool.self, forKey: .checked) {
            checked = boolVal
        } else if let intVal = try? c.decode(Int.self, forKey: .checked) {
            checked = (intVal != 0)
        } else if let strVal = try? c.decode(String.self, forKey: .checked) {
            checked = (strVal == "1" || strVal.lowercased() == "true")
        } else {
            checked = false
        }
    }
}

struct AllergyListResponse: Decodable {
    let status: String
    let allergy: [AllergyItem]?
}

struct SaveResponse: Decodable {
    let status: String
    let message: String
}

// MARK: - 공통 헤더
struct CommonHeaderView: View {
    let customDarkColor = Color(red: 97/255, green: 22/255, blue: 37/255)

    var body: some View {
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

            Rectangle()
                .fill(Color.clear)
                .frame(width: 24)
                .padding(.trailing, 40)
        }
        .frame(height: 50)
        .padding(.top, UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0)
        .background(Color.white)
        .ignoresSafeArea(edges: .top)
    }
}

// MARK: - 공통 네비게이션 바
struct CommonNavigationBar: View {
    let title: String
    let customDarkColor = Color(red: 97/255, green: 22/255, blue: 37/255)

    var body: some View {
        HStack {
            NavigationLink(destination: MenuView()) {
                Image(systemName: "chevron.left")
                    .foregroundColor(customDarkColor)
            }
            .padding(.leading, 15)

            Spacer()

            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.black)

            Spacer()

            Rectangle()
                .fill(Color.clear)
                .frame(width: 20)
                .padding(.trailing, 15)
        }
        .padding(.vertical, 8)
        .background(Color.white)
    }
}

// MARK: - MAIN VIEW
struct MyAllergyView: View {

   
    private let baseURL = "http://124.56.5.77/ykt/bk"
    private let customDarkColor = Color(red: 97/255, green: 22/255, blue: 37/255)

    private func currentUserId() -> Int? {
        let saved = UserDefaults.standard.integer(forKey: "user_id")
        return saved == 0 ? nil : saved
    }

    @State private var allergyList: [AllergyItem] = []
    @State private var loading = true
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {

        NavigationView {
            ZStack(alignment: .bottom) {

                Color(red: 50/255, green: 50/255, blue: 50/255)
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: -61.5) {

                    CommonHeaderView()

                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {

                            CommonNavigationBar(title: "알레르기 정보 수정")

                            if loading {
                                ProgressView("불러오는 중…")
                                    .padding(.top, 40)
                                    .frame(maxWidth: .infinity)
                            } else {
                                ForEach($allergyList) { $item in
                                    HStack(spacing: 12) {
                                        Button {
                                            item.checked.toggle()
                                        } label: {
                                            Image(systemName: item.checked ? "checkmark.square.fill" : "square")
                                                .foregroundColor(customDarkColor)
                                                .font(.title3)
                                        }

                                        Text(item.allergy_name)
                                            .foregroundColor(.black)
                                            .font(.system(size: 17))

                                        Spacer()
                                    }
                                    .padding(.horizontal, 10)
                                }
                            }

                        }
                        .padding(.horizontal, 25)
                        .padding(.top, 10)
                        .padding(.bottom, 160)
                        .background(Color.white)
                    }
                    .background(Color.white)
                }

                bottomButtonsSection()
                    .ignoresSafeArea(edges: .bottom)
            }
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
        }
        .navigationBarHidden(true)             
        .navigationBarBackButtonHidden(true)        .onAppear(perform: loadAllergyData)
        .alert(alertMessage, isPresented: $showAlert) {
            Button("확인") {}
        }
    }
}

// MARK: - Bottom Buttons
extension MyAllergyView {

    private func bottomButtonsSection() -> some View {
        HStack(spacing: 18) {

            Button(action: resetSelections) {
                Text("초기화")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.black)
                    .cornerRadius(14)
            }

            Button(action: saveSelections) {
                Text("저장")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 212/255, green: 121/255, blue: 140/255))
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 15)
        .padding(.bottom, 5)
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.07), radius: 4, y: -3)
    }
}

// MARK: - Networking
extension MyAllergyView {

    private func loadAllergyData() {
        guard let userId = currentUserId() else {
            self.loading = false
            self.alertMessage = "로그인 후 이용해주세요."
            self.showAlert = true
            return
        }

        guard let url = URL(string: "\(baseURL)/get_allergy_list.php") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data else {
                DispatchQueue.main.async { self.loading = false }
                return
            }

            do {
                let decoded = try JSONDecoder().decode(AllergyListResponse.self, from: data)
                var fullList = decoded.allergy ?? []

                // 유저 알레르기 가져와서 merge
                fetchUserAllergy(userId: userId) { userIds in
                    DispatchQueue.main.async {
                        for i in fullList.indices {
                            if userIds.contains(fullList[i].id) {
                                fullList[i].checked = true
                            }
                        }
                        self.allergyList = fullList
                        self.loading = false
                    }
                }

            } catch {
                print("JSON Parse ERR:", String(data: data, encoding: .utf8) ?? "")
                DispatchQueue.main.async { self.loading = false }
            }

        }.resume()
    }

    private func fetchUserAllergy(userId: Int, completion: @escaping ([Int]) -> Void) {
        guard let url = URL(string: "\(baseURL)/get_user_allergy.php") else {
            completion([])
            return
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.httpBody = "user_id=\(userId)".data(using: .utf8)

        URLSession.shared.dataTask(with: req) { data, _, _ in
            guard let data = data else {
                completion([])
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let list = json["list"] as? [[String: Any]] {

                    // allergy_id가 "1" 문자열일 수도 있어서 Int로 변환
                    let ids: [Int] = list.compactMap { dict in
                        if let intVal = dict["allergy_id"] as? Int {
                            return intVal
                        } else if let strVal = dict["allergy_id"] as? String,
                                  let intVal = Int(strVal) {
                            return intVal
                        } else {
                            return nil
                        }
                    }
                    completion(ids)

                } else {
                    completion([])
                }
            } catch {
                print("USER Allergy Parse ERR:", error)
                completion([])
            }

        }.resume()
    }

    private func resetSelections() {
        for i in allergyList.indices { allergyList[i].checked = false }
    }

    private func saveSelections() {
        guard let userId = currentUserId() else {
            self.alertMessage = "로그인 후 이용해주세요."
            self.showAlert = true
            return
        }

        guard let url = URL(string: "\(baseURL)/save_user_allergy.php") else { return }

        let selected = allergyList
            .filter { $0.checked }
            .map { "\($0.id)" }
            .joined(separator: ",")

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.httpBody = "user_id=\(userId)&allergy_ids=\(selected)"
            .data(using: .utf8)

        URLSession.shared.dataTask(with: req) { data, _, _ in
            if let data = data,
               let decoded = try? JSONDecoder().decode(SaveResponse.self, from: data) {

                DispatchQueue.main.async {
                    alertMessage = decoded.message
                    showAlert = true
                }
            }

        }.resume()
    }
}

#Preview {
    MyAllergyView()
}

