import SwiftUI


extension Color {
    static let signupButtonColor = Color(red: 0.588, green: 0.306, blue: 0.388)
}


struct SignupResponse: Codable {
    let status: String
    let message: String?
    let user_id: Int?
}


struct NicknameCheckResponse: Codable {
    let status: String
    let message: String?
}


struct SignupView: View {
    let logoImageName = "DuksungLogo"
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    @State private var email: String = ""
    @State private var name: String = ""
    @State private var nickname: String = ""
    @State private var studentID: String = ""
    @State private var password: String = ""
    @State private var passwordConfirm: String = ""
    @State private var isNicknameChecked: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    
    let signupURLString = "http://124.56.5.77/ykt/ykt/SignupView.php"

    var body: some View {
        ZStack {
            Color.white
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, 10)
                .ignoresSafeArea(edges: .bottom)

            VStack(spacing: 0) {
                
                ZStack {
                    Image(logoImageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120)

                    HStack {
                        Button {
                            self.presentationMode.wrappedValue.dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.duksungMaroon)
                                .font(.title2)
                        }
                        Spacer()
                    }
                }
                .frame(height: 50)
                .padding(.horizontal, 40)
                .padding(.top)
                .padding(.bottom, 50)

                
                VStack(spacing: 20) {
                    CustomTextField(placeholder: "email (@duksung.ac.kr)", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)

                    CustomTextField(placeholder: "이름", text: $name)

                    
                    HStack(spacing: 10) {
                        CustomTextField(placeholder: "닉네임", text: $nickname)
                            
                            .onChange(of: nickname) { _ in
                                isNicknameChecked = false
                            }

                        Button {
                            checkNickname()
                        } label: {
                            Text("중복 확인")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .frame(height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color.signupButtonColor)
                                )
                        }
                    }

                    CustomTextField(placeholder: "학번 (8자리)", text: $studentID)
                        .keyboardType(.numberPad)

                    CustomSecureField(placeholder: "비밀번호", text: $password)
                    CustomSecureField(placeholder: "비밀번호 확인", text: $passwordConfirm)

                    Spacer().frame(height: 30)

                    
                    Button {
                        if validateSignup() {
                            registerUser()
                        }
                    } label: {
                        Text("회원가입 완료")
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
                }
                .padding(.horizontal, 40)

                Spacer()
            }
        }
        .navigationBarHidden(true)
        
        .alert(isPresented: $showAlert) {
            if alertMessage.contains("회원가입 성공") {
                return Alert(
                    title: Text("알림"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("확인")) {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                )
            } else {
                return Alert(
                    title: Text("알림"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("확인"))
                )
            }
        }
    }

    
    private func registerUser() {
        guard let url = URL(string: signupURLString) else {
            alertMessage = "잘못된 URL"
            showAlert = true
            return
        }

        
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedNickname = nickname.trimmingCharacters(in: .whitespaces)
        let trimmedStudentID = studentID.trimmingCharacters(in: .whitespaces)

        var request = URLRequest(url: url, timeoutInterval: 15)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded; charset=utf-8",
                         forHTTPHeaderField: "Content-Type")

        var comps = URLComponents()
        comps.queryItems = [
            URLQueryItem(name: "action", value: "signup"),
            URLQueryItem(name: "email", value: trimmedEmail),
            URLQueryItem(name: "name", value: trimmedName),
            URLQueryItem(name: "nickname", value: trimmedNickname),
            URLQueryItem(name: "student_id", value: trimmedStudentID),
            URLQueryItem(name: "password", value: password),
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

            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
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
                let decoded = try JSONDecoder().decode(SignupResponse.self, from: data)

                DispatchQueue.main.async {
                    if decoded.status == "success", let userId = decoded.user_id {
                        UserDefaults.standard.set(userId, forKey: "user_id")
                        UserDefaults.standard.set(trimmedEmail, forKey: "user_email")
                        UserDefaults.standard.set(trimmedNickname, forKey: "user_nickname")

                        alertMessage = "회원가입 성공! 로그인 해주세요."
                        showAlert = true
                    } else {
                        let msg = decoded.message ?? "알 수 없는 오류"
                        alertMessage = "회원가입 실패: \(msg)"
                        showAlert = true
                    }
                }
            } catch {
                let raw = String(data: data, encoding: .utf8) ?? ""
                print("Signup RAW:", raw)
                DispatchQueue.main.async {
                    alertMessage = "응답 파싱 실패: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }.resume()
    }

    
    private func checkNickname() {
        let trimmed = nickname.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            alertMessage = "닉네임을 입력해주세요."
            showAlert = true
            isNicknameChecked = false
            return
        }

        guard let url = URL(string: signupURLString) else {
            alertMessage = "닉네임 확인 URL이 잘못되었습니다."
            showAlert = true
            isNicknameChecked = false
            return
        }

        var request = URLRequest(url: url, timeoutInterval: 15)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded; charset=utf-8",
                         forHTTPHeaderField: "Content-Type")

        var comps = URLComponents()
        comps.queryItems = [
            URLQueryItem(name: "action", value: "check_nickname"),
            URLQueryItem(name: "nickname", value: trimmed)
        ]
        request.httpBody = comps.query?.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    alertMessage = "서버 오류: \(error.localizedDescription)"
                    showAlert = true
                    isNicknameChecked = false
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    alertMessage = "서버 응답이 없습니다."
                    showAlert = true
                    isNicknameChecked = false
                }
                return
            }

            do {
                let decoded = try JSONDecoder().decode(NicknameCheckResponse.self, from: data)
                DispatchQueue.main.async {
                    if decoded.status == "success" {
                        alertMessage = decoded.message ?? "사용 가능한 닉네임입니다."
                        isNicknameChecked = true
                    } else {
                        alertMessage = decoded.message ?? "중복된 닉네임입니다."
                        isNicknameChecked = false
                    }
                    showAlert = true
                }
            } catch {
                let raw = String(data: data, encoding: .utf8) ?? ""
                print("Nickname RAW:", raw)
                DispatchQueue.main.async {
                    alertMessage = "닉네임 확인 응답 파싱 실패: \(error.localizedDescription)"
                    showAlert = true
                    isNicknameChecked = false
                }
            }
        }.resume()
    }

   
    private func validateSignup() -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        guard trimmedEmail.hasSuffix("@duksung.ac.kr") else {
            alertMessage = "덕성 이메일 형식(@duksung.ac.kr)이어야 합니다."
            showAlert = true
            return false
        }
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            alertMessage = "이름을 입력해주세요."
            showAlert = true
            return false
        }
        guard isNicknameChecked else {
            alertMessage = "닉네임 중복확인을 해주세요."
            showAlert = true
            return false
        }
        let trimmedStudentID = studentID.trimmingCharacters(in: .whitespaces)
        guard trimmedStudentID.count == 8,
              CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: trimmedStudentID)) else {
            alertMessage = "학번은 숫자 8자리여야 합니다."
            showAlert = true
            return false
        }
        guard isValidPassword(password) else {
            alertMessage = "비밀번호에는 특수문자 1개와 대문자 1개가 포함되어야 합니다."
            showAlert = true
            return false
        }
        guard password == passwordConfirm else {
            alertMessage = "비밀번호가 일치하지 않습니다."
            showAlert = true
            return false
        }
        return true
    }

    private func isValidPassword(_ password: String) -> Bool {
        let specialCharRegex = ".*[!@#$%^&*(),.?\":{}|<>].*"
        let uppercaseRegex = ".*[A-Z].*"
        return NSPredicate(format: "SELF MATCHES %@", specialCharRegex).evaluate(with: password)
        && NSPredicate(format: "SELF MATCHES %@", uppercaseRegex).evaluate(with: password)
    }
}

struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .padding(.horizontal)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
            )
    }
}

struct CustomSecureField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        SecureField(placeholder, text: $text)
            .padding(.horizontal)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
            )
    }
}
