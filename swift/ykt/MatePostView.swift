import SwiftUI
import Combine

struct CreateMateResponse: Decodable {
    let status: String
    let data: CreateMateData?
    let message: String?
    let room_id: Int?
    
    var resolvedRoomId: Int? {
        if let d = data?.room_id { return d }
        return room_id
    }
}

struct CreateMateData: Decodable {
    let room_id: Int
}

struct MateLocationP: Identifiable, Codable {
    let id: Int
    let buildingName: String
    let detailed: String
    
    var displayName: String {
        "\(buildingName) \(detailed)"
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "location_id"
        case buildingName = "building_name"
        case detailed
    }
}

struct MatePostView: View {
    @State private var roomTitle: String = ""
    @State private var content: String = ""
    @State private var date: Date = Date()
    @State private var maxPeople: Int = 1
    
    @State private var isLoading: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var goToList: Bool = false
    
    @State private var locations: [MateLocationP] = []
    @State private var isLoadingLocations: Bool = false
    @State private var locationError: String? = nil
    @State private var showLocationSheet: Bool = false
    @State private var selectedLocation: MateLocationP? = nil
    
    private let customDarkColor = Color(red: 97/255, green: 22/255, blue: 37/255)
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerArea()
                    Divider()
                    
                    VStack {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("방 이름")
                                    .font(.headline)
                                TextField("", text: $roomTitle)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                
                                Text("글 작성")
                                    .font(.headline)
                                TextEditor(text: $content)
                                    .frame(minHeight: 150)
                                    .padding(4)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color(.systemGray4))
                                    )
                                
                                Text("장소")
                                    .font(.headline)
                                
                                Button {
                                    showLocationSheet = true
                                } label: {
                                    HStack {
                                        Text(selectedLocation?.displayName ?? "장소를 선택해 주세요.")
                                            .foregroundColor(selectedLocation == nil ? .gray : .primary)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(.gray)
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                                
                                Text("일시")
                                    .font(.headline)
                                DatePicker(
                                    "",
                                    selection: $date,
                                    displayedComponents: [.date, .hourAndMinute]
                                )
                                .labelsHidden()
                                .datePickerStyle(.compact)
                                
                                Text("인원수")
                                    .font(.headline)
                                Stepper(value: $maxPeople, in: 1...10) {
                                    Text("\(maxPeople) 명")
                                }
                            }
                            .padding(16)
                        }
                        
                        Button(action: submitRoom) {
                            Text(isLoading ? "게시 중..." : "게시하기")
                                .foregroundColor(.white)
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(customDarkColor)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                        .disabled(isLoading)
                    }
                }
            }
            .sheet(isPresented: $showLocationSheet) {
                NavigationStack {
                    Group {
                        if isLoadingLocations {
                            ProgressView("장소 불러오는 중...")
                                .padding()
                        } else if let error = locationError {
                            Text(error)
                                .foregroundColor(.red)
                                .padding()
                        } else {
                            List(locations) { loc in
                                Button {
                                    selectedLocation = loc
                                    showLocationSheet = false
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(loc.buildingName)
                                                .font(.headline)
                                            Text(loc.detailed)
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                        Spacer()
                                        if selectedLocation?.id == loc.id {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .navigationTitle("장소 선택")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("닫기") {
                                showLocationSheet = false
                            }
                        }
                    }
                }
            }
            .background(
                NavigationLink(
                    destination: MateListView(),
                    isActive: $goToList
                ) {
                    EmptyView()
                }
                .hidden()
            )
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("알림"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("확인"))
                )
            }
            .onAppear {
                if locations.isEmpty {
                    loadLocations()
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private func headerArea() -> some View {
        VStack(spacing: 4) {
            HStack {
                Spacer()
                Image("DuksungLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 50)
                Spacer()
            }
            Text("식사 메이트 방 만들기")
                .font(.headline)
        }
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(Color.white)
    }
    
    private func submitRoom() {
        let savedUserId = UserDefaults.standard.integer(forKey: "user_id")
        guard savedUserId != 0 else {
            alertMessage = "로그인 정보가 없습니다. 다시 로그인해주세요."
            showAlert = true
            return
        }
        
        guard !roomTitle.isEmpty,
              !content.isEmpty,
              let selectedLocation = selectedLocation else {
            alertMessage = "모든 항목을 입력하고, 장소를 선택해 주세요."
            showAlert = true
            return
        }
        
        isLoading = true
        
        let df = DateFormatter()
        df.locale = Locale(identifier: "ko_KR")
        df.timeZone = TimeZone(identifier: "Asia/Seoul")
        
        df.dateFormat = "yyyy-MM-dd"
        let dateString = df.string(from: date)
        
        df.dateFormat = "HH:mm"
        let timeString = df.string(from: date)
        
        guard let url = URL(string: "http://124.56.5.77/ykt/ykt/MatePostView.php") else {
            alertMessage = "서버 주소 오류"
            showAlert = true
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded; charset=utf-8",
                         forHTTPHeaderField: "Content-Type")
        
        let params: [String: String] = [
            "room_title": roomTitle,
            "content": content,
            "date": dateString,
            "time": timeString,
            "max_people": "\(maxPeople)",
            "user_id": "\(savedUserId)",
            "location_id": "\(selectedLocation.id)"
        ]
        
        let bodyString = params
            .map { "\($0.key)=\(percentEscape($0.value))" }
            .joined(separator: "&")
        
        request.httpBody = bodyString.data(using: .utf8)
        
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
                    self.alertMessage = "서버에서 데이터가 오지 않았습니다."
                    self.showAlert = true
                }
                return
            }
            
            let rawString = String(data: data, encoding: .utf8) ?? ""
            print("MatePostView response:", rawString)
            
            do {
                let decoded = try JSONDecoder().decode(CreateMateResponse.self, from: data)
                
                DispatchQueue.main.async {
                    if decoded.status == "success" {
                        self.goToList = true
                    } else {
                        self.alertMessage = decoded.message ?? "방 생성 실패"
                        self.showAlert = true
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.alertMessage = "JSON 파싱 오류: \(error.localizedDescription)"
                    self.showAlert = true
                }
            }
        }.resume()
    }
    
    private func loadLocations() {
        guard let url = URL(string: "http://124.56.5.77/ykt/ykt/MateLocations.php") else {
            locationError = "장소 목록 URL 오류"
            return
        }
        
        isLoadingLocations = true
        locationError = nil
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoadingLocations = false
            }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.locationError = "네트워크 오류: \(error.localizedDescription)"
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.locationError = "서버에서 데이터가 오지 않았습니다."
                }
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode([MateLocationP].self, from: data)
                DispatchQueue.main.async {
                    self.locations = decoded
                }
            } catch {
                DispatchQueue.main.async {
                    self.locationError = "JSON 파싱 오류: \(error.localizedDescription)"
                    print("MateLocations response:", String(data: data, encoding: .utf8) ?? "nil")
                }
            }
        }.resume()
    }
    
    private func percentEscape(_ text: String) -> String {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "+&=?")
        return text.addingPercentEncoding(withAllowedCharacters: allowed) ?? text
    }
}

#Preview {
    MatePostView()
}
