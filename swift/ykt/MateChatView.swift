import SwiftUI

struct MateChatView: View {
    @StateObject var vm: MateChatViewModel
    @State private var goToJoin = false

    init(roomId: Int = -1) {
        _vm = StateObject(wrappedValue: MateChatViewModel(roomId: roomId))
    }

    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Button(action: { goToJoin = true }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.black)
                    }
                    .padding(.trailing, 8)

                    Text(vm.roomTitle)
                        .font(.headline)

                    Spacer()

                    Button("나가기") {
                        vm.leaveRoom { success in
                            if success {
                                goToJoin = true
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(red: 122/255, green: 32/255, blue: 32/255))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }

                Text(vm.roomContent)
                    .font(.subheadline)
                    .padding(.top, 4)

                Text("글쓴 시간: \(vm.postDate)")
                Text("장소: \(vm.locationName)")
                Text("약속 일시: \(vm.appointmentTime)")
                Text("현재 인원: \(vm.participantCount)명")
            }
            .padding()

            Divider()

            ScrollViewReader { scrollProxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(vm.messages) { msg in
                            HStack {
                                if msg.sender_id == vm.userId {
                                    Spacer()
                                    Text(msg.content)
                                        .padding()
                                        .background(Color.pink.opacity(0.3))
                                        .cornerRadius(10)
                                } else {
                                    Text(msg.content)
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(10)
                                    Spacer()
                                }
                            }
                            .id(msg.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: vm.messages.count) { _ in
                    if let last = vm.messages.last {
                        withAnimation {
                            scrollProxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            HStack {
                TextField("메시지를 입력하세요", text: $vm.newMessage)
                    .textFieldStyle(.roundedBorder)
                    .frame(height: 40)

                Button("전송") {
                    vm.sendMessage()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(red: 122/255, green: 32/255, blue: 32/255))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding()
        }
        .onDisappear { vm.stopAutoRefresh() }
        .navigationBarBackButtonHidden(true)   // ← 이게 정답 위치!!!

        NavigationLink(destination: MateJoinView(),
                       isActive: $goToJoin) {
            EmptyView()
        }
        .hidden()
    }
}
