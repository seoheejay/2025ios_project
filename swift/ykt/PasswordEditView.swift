//
//  PasswordEditView.swift
//  ykt
//
//  Created by mac32 on 11/17/25.
//

import SwiftUI

struct PasswordEditView: View {
    @State private var newPassword = ""
    @State private var newPasswordCheck = ""
    @State private var message = ""
    @State private var showDeleteAlert = false
    @State private var goToStart = false
    @State private var goToMyInfo = false
    @Environment(\.dismiss) var dismiss
    @StateObject var vm = ProfileEditViewModel()

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
            Text("새 비밀번호를 입력해주세요.")
                .font(.headline)

            SecureField("새 비밀번호 입력", text: $newPassword)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)

            SecureField("비밀번호 확인", text: $newPasswordCheck)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)

            if !message.isEmpty {
                Text(message).foregroundColor(.red)
            }

            Button("저장") {
                guard newPassword == newPasswordCheck else {
                    message = "비밀번호가 일치하지 않습니다."
                    return
                }

                vm.updatePassword(newPassword: newPassword) { success in
                    if success {
                        message = "비밀번호가 변경되었습니다."
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                             goToMyInfo = true
                         }
                    } else {
                        message = "변경 실패"
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 10)
            Spacer().frame(height: 30)
            NavigationLink(
                "",
                destination: MyInfoView(),
                isActive: $goToMyInfo
            )
            .hidden()


            Button("회원 탈퇴") {
                showDeleteAlert = true
            }
            .foregroundColor(.red)

            NavigationLink("", destination: StartView(), isActive: $goToStart)
                .hidden()
        }
        .alert("정말 탈퇴하시겠습니까?\n이 작업은 되돌릴 수 없습니다.", isPresented: $showDeleteAlert) {
            Button("취소", role: .cancel) {}

            Button("예", role: .destructive) {
                vm.deleteUser { success in
                    if success {
                        goToStart = true
                    }
                }
            }
        }
        .navigationTitle("회원 정보 수정")
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    NavigationStack {
        PasswordEditView()
    }
}
