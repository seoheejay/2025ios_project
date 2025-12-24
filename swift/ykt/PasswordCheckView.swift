//
//  PasswordCheckView.swift
//  ykt
//
//  Created by mac32 on 11/17/25.
//

import SwiftUI
import Combine

struct PasswordCheckView: View {
    @State private var currentPassword = ""
    @State private var errorMessage = ""
    @State private var navigate = false
    @StateObject var vm = ProfileEditViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                        //Text("뒤로")
                          //  .font(.headline)
                    }
                    .foregroundColor(.black)
                }
                Spacer()
            }
            .padding()
            
            Text("현재 비밀번호를 입력하세요.")
                .font(.headline)

            SecureField("현재 비밀번호", text: $currentPassword)
                .padding()
                .background(Color(.systemGray6))
               
                .cornerRadius(10)
                .padding(.horizontal)

            if !errorMessage.isEmpty {
                Text(errorMessage).foregroundColor(.red)
            }

            Button("확인") {
                vm.checkPassword(current: currentPassword) { success in
                    if success {
                        navigate = true
                    } else {
                        errorMessage = "비밀번호가 일치하지 않습니다."
                        print("입력 패스워드:",currentPassword)
                        print("입력 패스워드 길이:", currentPassword.count)

                    }
                }
            }
            .buttonStyle(.borderedProminent)

            NavigationLink("", destination: PasswordEditView(), isActive: $navigate)
                .hidden()
        }
        .navigationTitle("회원 정보 수정")
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    NavigationStack {
        PasswordCheckView()
    }
}
