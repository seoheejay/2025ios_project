import SwiftUI

struct LoginResponse: Codable {
    let status: String
    let message: String?
    let user_id: Int?
    let name: String?
    let email: String?
    let studentID: String?
}

struct LoginView: View {
    let logoImageName = "DuksungLogo"
    
    @State private var studentID: String = ""
    @State private var password: String = ""
    @State private var isLoginSuccess: Bool = false
    @State private var showSignupView: Bool = false
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    let loginURLString = "http://124.56.5.77/ykt/ykt/LoginView.php"
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Image(logoImageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 140)
                        .padding(.top)
                        .padding(.bottom, 50)
                    
                    VStack(spacing: 20) {
                        CustomTextField(placeholder: "학번", text: $studentID)
                            .keyboardType(.numberPad)
                        CustomSecureField(placeholder: "비밀번호", text: $password)
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer().frame(height: 40)
                    
                    Button {
                        loginUser()
                    } label: {
                        Text("로그인")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.signupButtonColor)
                                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
                            )
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer().frame(height: 20)
                    
                    Button {
                        showSignupView = true
                    } label: {
                        Text("회원가입")
                            .font(.subheadline)
                            .foregroundColor(.signupButtonColor)
                    }
                    .padding(.bottom, 40)
                    
                    Spacer()
                }
                
                NavigationLink(
                    destination: SignupView(),
                    isActive: $showSignupView
                ) {
                    EmptyView()
                }
                .hidden()
                
                NavigationLink(
                    destination: MenuView(),
                    isActive: $isLoginSuccess
                ) {
                    EmptyView()
                }
                .hidden()
            }
            .navigationBarHidden(true)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("알림"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("확인"))
                )
            }
            .onAppear {
                if let saved = UserDefaults.standard.string(forKey: "user_studentID") {
                    studentID = saved
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private func loginUser() {
        let trimmedStudentID = studentID.trimmingCharacters(in: .whitespaces)
        let trimmedPassword  = password.trimmingCharacters(in: .whitespaces)
        
        guard !trimmedStudentID.isEmpty, !trimmedPassword.isEmpty else {
            alertMessage = "학번과 비밀번호를 모두 입력해주세요."
            showAlert = true
            return
        }
        
        guard let url = URL(string: loginURLString) else {
            alertMessage = "잘못된 URL입니다."
            showAlert = true
            return
        }
        
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded; charset=utf-8",
                         forHTTPHeaderField: "Content-Type")
        
        var comps = URLComponents()
        comps.queryItems = [
            URLQueryItem(name: "studentID", value: trimmedStudentID),
            URLQueryItem(name: "password",  value: trimmedPassword)
        ]
        request.httpBody = comps.query?.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    alertMessage = "서버 오류: \(error.localizedDescription)"
                    showAlert = true
                }
                return
            }
            
            if let http = response as? HTTPURLResponse,
               !(200...299).contains(http.statusCode) {
                DispatchQueue.main.async {
                    alertMessage = "서버 응답 코드: \(http.statusCode)"
                    showAlert = true
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    alertMessage = "서버 응답이 없습니다."
                    showAlert = true
                }
                return      
            }
            
            do {
                let decoded = try JSONDecoder().decode(LoginResponse.self, from: data)
                
                DispatchQueue.main.async {
                    if decoded.status == "success", let userId = decoded.user_id {
                        UserDefaults.standard.set(userId, forKey: "user_id")
                        if let email = decoded.email {
                            UserDefaults.standard.set(email, forKey: "user_email")
                        }
                        if let name = decoded.name {
                            UserDefaults.standard.set(name, forKey: "user_name")
                        }
                        if let sid = decoded.studentID {
                            UserDefaults.standard.set(sid, forKey: "user_studentID")
                        }
                        
                        isLoginSuccess = true
                    } else {
                        let msg = decoded.message ?? "로그인에 실패했습니다."
                        alertMessage = msg
                        showAlert = true
                    }
                }
            } catch {
                let raw = String(data: data, encoding: .utf8) ?? ""
                print("RAW:", raw)
                DispatchQueue.main.async {
                    alertMessage = "응답 파싱 실패: \(error.localizedDescription)\n\(raw)"
                    showAlert = true
                }
            }
        }.resume()
    }
}

#Preview {
    LoginView()
}
