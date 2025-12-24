//
//  ProfileEditViewModel.swift
//  ykt
//
//  Created by mac32 on 11/17/25.
//
import Foundation
import Combine

class ProfileEditViewModel: ObservableObject {

    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var saveSuccess = false



    private let baseURL = "http://124.56.5.77/ykt"
  
    var userId: Int?

    init() {
        let saved = UserDefaults.standard.integer(forKey: "user_id")
        self.userId = (saved == 0) ? nil : saved
    }


    // 비밀번호 확인
    func checkPassword(current: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/check_password.php") else { return }
        guard let userId = userId else {
            print("userId 없음")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = "user_id=\(userId)&password=\(current)"
        print(body)
        request.httpBody = body.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, response, error in
            
            print(String(data?.count ?? 0))
            
            guard let data = data,
                  let result = try? JSONDecoder().decode(Response.self, from: data) else {
                completion(false)
                return
            }
            DispatchQueue.main.async {
                completion(result.success)
            }
        }.resume()
    }

    // 비밀번호 변경
    func updatePassword(newPassword: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/update_password.php") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = "user_id=\(userId)&new_password=\(newPassword)"
        request.httpBody = body.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let result = try? JSONDecoder().decode(Response.self, from: data) else {
                completion(false)
                return
            }
            DispatchQueue.main.async {
                //completion(result.success)
                self.saveSuccess = true
                completion(true)
            }
        }.resume()
    }

    // 회원 탈퇴
    func deleteUser(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/delete_user.php") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = "user_id=\(userId)"
        request.httpBody = body.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let result = try? JSONDecoder().decode(Response.self, from: data) else {
                completion(false)
                return
            }
            DispatchQueue.main.async {
                completion(result.success)
            }
        }.resume()
    }
}

struct Response: Decodable {
    let success: Bool
}
