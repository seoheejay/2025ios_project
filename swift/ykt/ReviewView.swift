import SwiftUI

struct ReviewListResponse: Decodable {
    let status: String
    let data: ReviewListData?
}

struct ReviewListData: Decodable {
    let average_rating: Double
    let review_count: Int
    let reviews: [ReviewDTO]
}

struct ReviewDTO: Identifiable, Decodable {
    let review_id: Int
    let user_id: Int
    let menu_id: Int
    let order_item_id: Int?
    let rating: Double
    let title: String?
    let content: String?
    let price: Int?
    let status: Int
    let created_at: String?
    let updated_at: String?
    
    var id: Int { review_id }
}

struct ReviewView: View {
    @Environment(\.presentationMode) var presentationMode
    
    let logoImageName = "DuksungLogo"
    let menuId: Int
    
    private let baseURL = "http://124.56.5.77/ykt/ykt/ReviewView.php"
    
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    @State private var averageRating: Double = 0.0
    @State private var reviewCount: Int = 0
    @State private var reviews: [ReviewDTO] = []
    
    enum SortType {
        case ratingDesc
        case ratingAsc
    }
    @State private var sortType: SortType = .ratingDesc
    
    var sortTitle: String {
        switch sortType {
        case .ratingDesc: return "별점 높은순"
        case .ratingAsc:  return "별점 낮은순"
        }
    }
    
    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()
            
            VStack(spacing: 0) {
                DuksungHeaderView(
                    logoImageName: logoImageName,
                    onBack: { presentationMode.wrappedValue.dismiss() },
                    bottomPadding: 0,
                    showCartButton: false
                )
                
                Text("리뷰")
                    .font(.system(size: 18, weight: .semibold))
                    .padding(.vertical, 8)
                
                Divider()
                
                ratingSummarySection
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                
                Divider()
                
                if reviews.isEmpty && !isLoading {
                    VStack(spacing: 8) {
                        Text("아직 리뷰가 없어요")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.gray)
                        Text("첫 리뷰를 남겨보세요!")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 40)
                    Spacer()
                    
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            ForEach(reviews) { review in
                                ReviewRowView(review: review)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 20)
                    }
                }
            }
            
            if isLoading {
                Color.black.opacity(0.2).ignoresSafeArea()
                ProgressView()
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            fetchReviews()
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

extension ReviewView {
    
    var ratingSummarySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 8) {
                StarRatingView(rating: averageRating, starSize: 18)
                
                Text(String(format: "%.1f", averageRating))
                    .font(.system(size: 22, weight: .bold))
                
                Spacer()
                
                Button(action: toggleSort) {
                    HStack(spacing: 4) {
                        Text(sortTitle)
                            .font(.system(size: 14))
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                    )
                }
            }
            
            Text("(\(reviewCount)건 리뷰)")
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
    }
    
    private func toggleSort() {
        switch sortType {
        case .ratingDesc:
            sortType = .ratingAsc
        case .ratingAsc:
            sortType = .ratingDesc
        }
        applyCurrentSort()
    }
    
    private func applyCurrentSort() {
        switch sortType {
        case .ratingDesc:
            reviews.sort {
                if $0.rating == $1.rating {
                    return ($0.created_at ?? "") > ($1.created_at ?? "")
                }
                return $0.rating > $1.rating
            }
        case .ratingAsc:
            reviews.sort {
                if $0.rating == $1.rating {
                    return ($0.created_at ?? "") > ($1.created_at ?? "")
                }
                return $0.rating < $1.rating
            }
        }
    }
}

struct StarRatingView: View {
    let rating: Double
    var starSize: CGFloat = 12
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5) { i in
                let starValue = rating - Double(i)
                
                if starValue >= 1 {
                    Image(systemName: "star.fill")
                } else if starValue >= 0.5 {
                    Image(systemName: "star.leadinghalf.filled")
                } else {
                    Image(systemName: "star")
                }
            }
        }
        .foregroundColor(.yellow)
        .font(.system(size: starSize))
    }
}

struct ReviewRowView: View {
    let review: ReviewDTO
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text(review.title ?? "제목 없음")
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
                
                HStack(spacing: 4) {
                    StarRatingView(rating: review.rating, starSize: 12)
                    Text(String(format: "%.1f", review.rating))
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            
            Text(review.content ?? "")
                .font(.system(size: 13))
                .foregroundColor(.black)
                .lineLimit(3)
            
            HStack {
                Text("주문 일자: \(formattedDate(review.created_at))")
                Spacer()
                Text("결제 금액 \(review.price ?? 0)원")
            }
            .font(.system(size: 11))
            .foregroundColor(.gray)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
    private func formattedDate(_ raw: String?) -> String {
        guard let raw = raw, raw.count >= 10 else { return "-" }
        return String(raw.prefix(10))
    }
}

extension ReviewView {
    
    private func fetchReviews() {
        guard var components = URLComponents(string: baseURL) else { return }
        components.queryItems = [
            URLQueryItem(name: "action", value: "list"),
            URLQueryItem(name: "menu_id", value: "\(menuId)")
        ]
        guard let url = components.url else { return }
        
        isLoading = true
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async { isLoading = false }
            
            if let error = error {
                DispatchQueue.main.async {
                    alertMessage = "리뷰를 불러올 수 없습니다.\n\(error.localizedDescription)"
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
                let decoded = try JSONDecoder().decode(ReviewListResponse.self, from: data)
                guard decoded.status == "success",
                      let dataObj = decoded.data
                else {
                    DispatchQueue.main.async {
                        alertMessage = "리뷰 정보를 불러오지 못했습니다."
                        showAlert = true
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    self.averageRating = dataObj.average_rating
                    self.reviewCount   = dataObj.review_count
                    self.reviews       = dataObj.reviews
                    self.applyCurrentSort()
                }
            } catch {
                let raw = String(data: data, encoding: .utf8) ?? "nil"
                print("RAW JSON:", raw)
                
                DispatchQueue.main.async {
                    alertMessage = "응답 파싱 오류: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }.resume()
    }
}
