import SwiftUI

struct MenuDetailResponse: Decodable {
    let status: String
    let data: MenuDetailData?
}

struct MenuDetailData: Decodable {
    let menu: MenuDTO
    let allergies: [AllergyDTO]?
}

struct MenuDTO: Decodable {
    let menu_id: Int
    let menu_name: String
    let menu_details: String?
    let price: Int?
    let image_url: String?
    let rating: Double?
    let review_count: Int?
    let promotion: Int?
    let like_count: Int?
    let is_liked: Bool?
}

struct AllergyDTO: Decodable {
    let allergy_id: Int
    let allergy_name: String
    let status: Int?
    let is_user_allergic: Int?
}

struct ToggleLikeResponse: Decodable {
    let status: String
    let data: ToggleLikeData?
}

struct ToggleLikeData: Decodable {
    let is_liked: Bool
    let like_count: Int
}

struct AddToCartResponse: Decodable {
    let status: String
    let message: String?
}

struct DuksungHeaderView: View {
    let logoImageName: String
    let onBack: () -> Void
    var bottomPadding: CGFloat = 10
    var showCartButton: Bool = false
    
    var body: some View {
        ZStack {
            Image(logoImageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120)

            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.duksungMaroon)
                        .font(.title2)
                }
                Spacer()
                
                if showCartButton {
                    NavigationLink(destination: CartView()) {
                        Image(systemName: "cart")
                            .font(.title2)
                            .foregroundColor(.duksungMaroon)
                    }
                }
            }
        }
        .frame(height: 50)
        .padding(.horizontal, 40)
        .padding(.top)
        .padding(.bottom, bottomPadding)
    }
}

struct MenuDetailView: View {
    let logoImageName = "DuksungLogo"
    
    let menuId: Int
    let todayMenuText: String?
    
    private var userId: Int? {
        let saved = UserDefaults.standard.integer(forKey: "user_id")
        return saved == 0 ? nil : saved
    }
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    @State private var isLiked = false
    @State private var likeCount: Int = 0
    @State private var price: Int = 0
    @State private var descriptionText: String = ""
    @State private var menuName: String = ""
    @State private var menuRating: Double = 0.0
    @State private var menuReviewCount: Int = 0
    @State private var isLoading: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var allergies: [AllergyDTO] = []
    @State private var menuImageURL: String? = nil
    
    private let baseURL = "http://124.56.5.77/ykt/ykt/MenuDetailView.php"
    
    var body: some View {
            ZStack {
                Color.white.ignoresSafeArea()

                VStack(spacing: 0) {
                    DuksungHeaderView(
                        logoImageName: logoImageName,
                        onBack: { self.presentationMode.wrappedValue.dismiss() },
                        bottomPadding: 0,
                        showCartButton: true
                    )
                    .background(Color.white.ignoresSafeArea(edges: .top))

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            menuCard
                                .padding(.top, 8)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 32)
                    }
                }
                
                if isLoading {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    ProgressView()
                }
            }
            .navigationBarBackButtonHidden(true)
            .onAppear {
                fetchMenuDetail()
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("알림"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("확인"))
                )
            }
        }
    }

extension MenuDetailView {
    var menuCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(Color(red: 1.0, green: 0.89, blue: 0.93))

            VStack(spacing: 50) {
                topNameLikeRow
                    .padding(.top, 30)

                if todayMenuText == nil {
                    if let urlString = menuImageURL,
                       let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(height: 180)
                                    .frame(maxWidth: .infinity)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 180)
                                    .frame(maxWidth: .infinity)
                                    .clipped()
                                    .cornerRadius(16)
                            case .failure:
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 180)
                                    .frame(maxWidth: .infinity)
                                    .foregroundColor(.gray)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .padding(.horizontal, 18)
                    } else {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 180)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 18)
                    }
                }

                VStack(spacing: 20) {
                    HStack {
                        Text(price == 0 ? "₩-" : "₩\(price)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)

                        Spacer()
                        
                        Button {
                            addToCart()
                        } label: {
                            Image(systemName: "cart")
                                .font(.system(size: 30))
                                .foregroundColor(.black)
                        }
                    }
                    
                    let displayText: String = {
                        if let t = todayMenuText, !t.isEmpty {
                            return t
                        } else if descriptionText.isEmpty {
                            return "메뉴 설명이 없습니다."
                        } else {
                            return descriptionText
                        }
                    }()

                    Text(displayText)
                        .font(.system(size: 15))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 40)
                        .fill(Color.white)
                )
                .padding(.horizontal, 30)

                allergyAndReviewRow
                    .padding(.horizontal, 10)

                allergyTagsRow
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
            }
        }
        .padding(.top, 10)
    }
}

extension MenuDetailView {
    var topNameLikeRow: some View {
        ZStack {
            HStack {
                Spacer()
                VStack(spacing: 2) {
                    Text(menuName.isEmpty ? "메뉴" : menuName)
                        .font(.system(size: 20, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color(red: 0.75, green: 0.34, blue: 0.48))
                )
                Spacer()
            }

            HStack {
                Spacer()
                Button {
                    toggleLike()
                } label: {
                    HStack(spacing: 4) {
                        Text("\(likeCount)")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.black)

                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 40))
                            .foregroundColor(.pink)
                    }
                }
                .padding(.trailing, 20)
            }
        }
        .frame(height: 32)
    }
}

extension MenuDetailView {
    var allergyAndReviewRow: some View {
        HStack {
            Button { } label: {
                Text("알레르기 유발물질")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.9))
                    )
            }

            StarRatingView(rating: menuRating, starSize: 14)
            
            HStack(spacing: 2) {
                Text(String(format: "%.1f", menuRating))
                
                NavigationLink(destination: ReviewView(menuId: menuId)) {
                    Text(">")
                }
            }
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(.black)
        }
    }
}

extension MenuDetailView {
    var allergyTagsRow: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            alignment: .center,
            spacing: 12
        ) {
            ForEach(allergies, id: \.allergy_id) { allergy in
                let highlighted = (allergy.is_user_allergic ?? 0) == 1
                AllergyTagView(
                    mainText: allergy.allergy_name,
                    isActive: highlighted
                )
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct AllergyTagView: View {
    let mainText: String
    let isActive: Bool

    var body: some View {
        Text(mainText)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(isActive ? .white : .black)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isActive ? Color.red : Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
    }
}

extension MenuDetailView {
    private func fetchMenuDetail() {
        guard var components = URLComponents(string: baseURL) else { return }
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "action", value: "detail"),
            URLQueryItem(name: "menu_id", value: "\(menuId)")
        ]
        
        if let uid = userId {
            queryItems.append(URLQueryItem(name: "user_id", value: "\(uid)"))
        }
        components.queryItems = queryItems
        
        guard let url = components.url else { return }
        
        isLoading = true
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let http = response as? HTTPURLResponse,
               !(200...299).contains(http.statusCode) {
                DispatchQueue.main.async {
                    isLoading = false
                    alertMessage = "서버 응답 코드: \(http.statusCode)"
                    showAlert = true
                }
                return
            }
            
            DispatchQueue.main.async { isLoading = false }
            
            if let error = error {
                DispatchQueue.main.async {
                    alertMessage = "메뉴 정보를 불러올 수 없습니다.\n\(error.localizedDescription)"
                    showAlert = true
                }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async {
                    alertMessage = "데이터가 비어 있습니다."
                    showAlert = true
                }
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(MenuDetailResponse.self, from: data)
                guard decoded.status == "success",
                      let dataObj = decoded.data
                else {
                    DispatchQueue.main.async {
                        alertMessage = "메뉴 정보를 불러오지 못했습니다."
                        showAlert = true
                    }
                    return
                }
                
                let menuData = dataObj.menu
                let allergyList = dataObj.allergies ?? []
                
                DispatchQueue.main.async {
                    price = menuData.price ?? 0
                    descriptionText = menuData.menu_details ?? ""
                    isLiked = menuData.is_liked ?? false
                    likeCount = menuData.like_count ?? 0
                    allergies = allergyList
                    menuImageURL = menuData.image_url
                    menuName = menuData.menu_name
                    menuRating = menuData.rating ?? 0.0
                    menuReviewCount = menuData.review_count ?? 0
                }
            } catch {
                DispatchQueue.main.async {
                    alertMessage = "응답 파싱 오류: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }.resume()
    }
    
    private func toggleLike() {
        guard let uid = userId else { return }
        guard let url = URL(string: baseURL + "?action=toggle_like") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let bodyString = "menu_id=\(menuId)&user_id=\(uid)"
        request.httpBody = bodyString.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[toggle_like] 네트워크 에러: \(error.localizedDescription)")
                return
            }
            
            if let http = response as? HTTPURLResponse,
               !(200...299).contains(http.statusCode) {
                print("[toggle_like] HTTP 상태코드: \(http.statusCode)")
                return
            }
            
            guard let data = data else {
                print("[toggle_like] data = nil")
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(ToggleLikeResponse.self, from: data)
                guard decoded.status == "success", let d = decoded.data else {
                    print("status != success")
                    return
                }

                DispatchQueue.main.async {
                    isLiked = d.is_liked
                    likeCount = d.like_count
                }
            } catch {
                print("[toggle_like] JSON 디코딩 실패: \(error)")
            }
        }.resume()
    }

    private func addToCart() {
        guard let uid = userId else {
            DispatchQueue.main.async {
                alertMessage = "로그인 후 이용해 주세요."
                showAlert = true
            }
            return
        }
        
        guard let url = URL(string: baseURL + "?action=add_to_cart") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let bodyString = "menu_id=\(menuId)&user_id=\(uid)&quantity=1"
        request.httpBody = bodyString.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    alertMessage = "장바구니 추가 실패: \(error.localizedDescription)"
                    showAlert = true
                }
                return
            }
            
            if let http = response as? HTTPURLResponse,
               !(200...299).contains(http.statusCode) {
                DispatchQueue.main.async {
                    alertMessage = "장바구니 응답 코드: \(http.statusCode)"
                    showAlert = true
                }
                return
            }
            
            guard let data = data else { return }
            
            do {
                let decoded = try JSONDecoder().decode(AddToCartResponse.self, from: data)
                DispatchQueue.main.async {
                    alertMessage = decoded.message ?? "장바구니 처리 결과를 확인하세요."
                    showAlert = true
                }
            } catch {
                DispatchQueue.main.async {
                    alertMessage = "장바구니 응답 파싱 오류: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }.resume()
    }
}
