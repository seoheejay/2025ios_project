import SwiftUI

struct UserProfile: Decodable {
    let status: String
    let name: String?
    let studentId: String?
    let nickname: String?
    let message: String?
}

struct UpdateResponse2: Decodable {
    let status: String
    let message: String
}

struct NicknameCheckResponse2: Decodable {
    let status: String
    let message: String
}

struct MyInfoView: View {
    let logoImageName = "DuksungLogo"
    private let baseURL = "http://124.56.5.77/ykt/bk"
    
    @State private var currentPKey: Int? = UserDefaults.standard.integer(forKey: "user_id")
    
    @State private var userName: String = "로딩 중..."
    @State private var userStudentId: String = "로딩 중..."
    @State private var userNickname: String = "로딩 중..."
    
    @State private var isEditingNicknameAlert = false
    @State private var newNickname: String = ""
    @State private var showResultAlert = false
    @State private var resultMessage: String = ""
    
    let customDarkColor = Color(red: 97/255, green: 22/255, blue: 37/255)
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 50/255, green: 50/255, blue: 50/255)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: -61.5) {
                    customHeaderView()
                        
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            customNavigationBar()
                            profileSectionView(name: userName, studentId: userStudentId, nickname: userNickname)
                            activitySectionView()
                            infoSectionView()
                            Spacer()
                        }
                    }
                    .background(Color.white)
                    .edgesIgnoringSafeArea(.bottom)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {

            currentPKey = UserDefaults.standard.integer(forKey: "user_id")
            loadUserProfile(for: currentPKey)
        }
        .alert("닉네임 수정", isPresented: $isEditingNicknameAlert) {
            TextField("새 닉네임", text: $newNickname).textInputAutocapitalization(.never)
            Button("수정", action: {
                if newNickname.isEmpty || newNickname == userNickname {
                    resultMessage = "새로운 닉네임을 입력하거나 변경해주세요."
                    showResultAlert = true
                    return
                }
                validateAndEditNickname(newNickname: newNickname)
            })
            Button("취소", role: .cancel) { }
        } message: {
            Text("새로운 닉네임을 입력하세요. 중복 확인 후 적용됩니다.")
        }
        .alert(resultMessage, isPresented: $showResultAlert) {
            Button("확인", role: .cancel) {
                if resultMessage.contains("성공") {
                    loadUserProfile(for: currentPKey)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private func customHeaderView() -> some View {
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

    private func loadUserProfile(for pkey: Int?) {
        guard let id = pkey, id > 0, let url = URL(string: "\(baseURL)/select_profile.php") else { return }
        let postString = "pkey=\(id)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = postString.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else { return }
            do {
                let decodedResponse = try JSONDecoder().decode(UserProfile.self, from: data)
                DispatchQueue.main.async {
                    if decodedResponse.status == "success",
                       let name = decodedResponse.name,
                       let studentId = decodedResponse.studentId,
                       let nickname = decodedResponse.nickname {
                        self.userName = name
                        self.userStudentId = studentId
                        self.userNickname = nickname
                    } else {
                        self.resultMessage = decodedResponse.message ?? "서버 오류"
                        self.showResultAlert = true
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.resultMessage = "데이터 디코딩 실패"
                    self.showResultAlert = true
                }
            }
        }.resume()
    }

    private func validateAndEditNickname(newNickname: String) {
        guard let url = URL(string: "\(baseURL)/check_nickname.php") else { return }
        let postString = "nickname=\(newNickname.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? newNickname)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = postString.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else { return }
            do {
                let decodedResponse = try JSONDecoder().decode(NicknameCheckResponse2.self, from: data)
                DispatchQueue.main.async {
                    if decodedResponse.status == "available" {
                        self.editNick(newNickname: newNickname)
                    } else {
                        self.resultMessage = decodedResponse.message ?? ""
                        self.showResultAlert = true
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.resultMessage = "데이터 디코딩 실패"
                    self.showResultAlert = true
                }
            }
        }.resume()
    }
    
    private func editNick(newNickname: String) {
        guard let id = currentPKey, id > 0, let url = URL(string: "\(baseURL)/update_nickname.php") else { return }
        let postString = "pkey=\(id)&new_nickname=\(newNickname.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? newNickname)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = postString.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else { return }
            do {
                let decodedResponse = try JSONDecoder().decode(UpdateResponse2.self, from: data)
                DispatchQueue.main.async {
                    self.resultMessage = decodedResponse.message
                    self.showResultAlert = true
                }
            } catch {
                DispatchQueue.main.async {
                    self.resultMessage = "데이터 디코딩 실패"
                    self.showResultAlert = true
                }
            }
        }.resume()
    }

    private func customNavigationBar() -> some View {
        HStack {
            NavigationLink(destination: MenuView()) {
                Image(systemName: "chevron.left")
                    .foregroundColor(customDarkColor)
            }
            .padding(.leading, 15)
            
            Spacer()
            
            Text("마이페이지")
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
    }

    private func profileSectionView(name: String, studentId: String, nickname: String) -> some View {
        VStack(alignment: .leading) {
            Text("내 프로필").font(.headline).padding(.bottom, 5)
            VStack(spacing: 15) {
                Circle()
                    .fill(Color(red: 230/255, green: 210/255, blue: 210/255))
                    .frame(width: 90, height: 90)
                    .overlay(
                        Text(String((name.isEmpty ? " " : name).prefix(1)))
                            .font(.largeTitle)
                            .foregroundColor(.black)
                            .fontWeight(.bold)
                    )
                Text("이름: \(name)").foregroundColor(.black)
                Text("학번: \(studentId)").foregroundColor(.black)
                HStack {
                    Text("닉네임:").foregroundColor(.black)
                    Text(nickname)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                        .background(Color(red: 240/255, green: 240/255, blue: 240/255))
                        .cornerRadius(5)
                        .fontWeight(.bold)
                    Button(action: { self.newNickname = self.userNickname; self.isEditingNicknameAlert = true }) {
                        Image(systemName: "pencil").foregroundColor(.gray)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 1)
        }
        .padding(.horizontal)
    }

    private func activitySectionView() -> some View {
        VStack(alignment: .leading) {
            Text("내 활동").font(.headline).padding(.bottom, 5)
            VStack(spacing: 0) {
                customNavigationRow(title: "내가 좋아요 한 메뉴", destination: LikeView())
                Divider().padding(.leading)
                customNavigationRow(title: "장바구니", destination: CartView())
                Divider().padding(.leading)
                customNavigationRow(title: "주문 내역", destination: OrderListView())
                Divider().padding(.leading)
                customNavigationRow(title: "내가 쓴 리뷰", destination: ReviewMyView())
            }
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 1)
        }
        .padding(.horizontal)
    }

    private func infoSectionView() -> some View {
        VStack(alignment: .leading) {
            Text("내 정보").font(.headline).padding(.bottom, 5)
            VStack(spacing: 0) {
                customNavigationRow(title: "알레르기 정보 수정", destination: MyAllergyView())
                Divider().padding(.leading)
                customNavigationRow(title: "회원 정보 수정", destination:PasswordCheckView())
                Divider().padding(.leading)
                Button(action: { print("로그아웃 액션 실행") }) {
                    HStack {
                        Text("로그아웃").foregroundColor(.black)
                        Spacer()
                    }.padding()
                }
            }
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 1)
        }
        .padding(.horizontal)
    }

    private func customNavigationRow<Destination: View>(title: String, destination: Destination) -> some View {
        NavigationLink(destination: destination) {
            HStack {
                Text(title).foregroundColor(.black)
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.gray)
            }.padding()
        }
    }
}

#Preview {
    MyInfoView()
}
