//
//  ReviewMyView.swift
//  ykt
//

import SwiftUI

struct ReviewListResponse2: Decodable {
    let review: [MyReview]
}

struct MyReview: Decodable, Identifiable {
    var review_id: Int
    var user_id: Int
    var menu_id: Int
    var order_item_id: Int
    var rating: Float
    var title: String
    var content: String
    var price: Int
    var status: Int
    var created_at: String
    var updated_at: String?
    var order_date: String
    var menu_name: String

    var id: Int { review_id }

    enum CodingKeys: String, CodingKey {
        case review_id, user_id, menu_id, order_item_id, rating, title, content, price, status, created_at, updated_at
        case order_date, menu_name
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        func decodeInt(_ key: CodingKeys) -> Int {
            if let intVal = try? c.decode(Int.self, forKey: key) {
                return intVal
            }
            if let str = try? c.decode(String.self, forKey: key),
               let intVal = Int(str) {
                return intVal
            }
            return 0
        }

        func decodeFloat(_ key: CodingKeys) -> Float {
            if let f = try? c.decode(Float.self, forKey: key) {
                return f
            }
            if let d = try? c.decode(Double.self, forKey: key) {
                return Float(d)
            }
            if let s = try? c.decode(String.self, forKey: key),
               let d = Double(s) {
                return Float(d)
            }
            return 0
        }

        review_id     = decodeInt(.review_id)
        user_id       = decodeInt(.user_id)
        menu_id       = decodeInt(.menu_id)
        order_item_id = decodeInt(.order_item_id)
        rating        = decodeFloat(.rating)
        price         = decodeInt(.price)
        status        = decodeInt(.status)

        title      = (try? c.decode(String.self, forKey: .title)) ?? ""
        content    = (try? c.decode(String.self, forKey: .content)) ?? ""
        created_at = (try? c.decode(String.self, forKey: .created_at)) ?? ""
        updated_at = try? c.decode(String.self, forKey: .updated_at)

        order_date = (try? c.decode(String.self, forKey: .order_date)) ?? ""
        menu_name  = (try? c.decode(String.self, forKey: .menu_name)) ?? ""
    }

    var formattedOrderDate: String {
        order_date.count >= 10 ? String(order_date.prefix(10)) : order_date
    }

    var formattedPrice: String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return (f.string(from: NSNumber(value: price)) ?? "") + "원"
    }
}

struct ReviewMyView: View {

    private let baseURL = "http://124.56.5.77/ykt/bk"
    private let customDarkColor = Color(red: 97/255, green: 22/255, blue: 37/255)

    @State private var reviews: [MyReview] = []
    @State private var loading = true
    @State private var resultMessage = ""
    @State private var showAlert = false
    @State private var showDeleteConfirm = false
    @State private var deleteTargetId: Int? = nil

    var body: some View {

        NavigationView {
            ZStack {
                Color(red: 245/255, green: 245/255, blue: 245/255)
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: -61.5) {
                    customHeaderView()

                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {

                            customNavigationBar()

                            contentSection()

                            Spacer(minLength: 0)
                        }
                    }
                    .background(Color.white)
                }
            }
            .navigationBarHidden(true)

        }
        .onAppear(perform: loadReviews)
        .alert("삭제하시겠습니까?", isPresented: $showDeleteConfirm) {
            Button("예", role: .destructive) {
                if let id = deleteTargetId {
                    deleteReview(id)
                }
            }
            Button("아니오", role: .cancel) {}
        }
        .alert(resultMessage, isPresented: $showAlert) {
            Button("확인") {}
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

    private func customNavigationBar() -> some View {
        HStack {
            NavigationLink(destination: MyInfoView()) {
                Image(systemName: "chevron.left")
                    .foregroundColor(customDarkColor)
            }
            .padding(.leading, 15)

            Spacer()

            Text("내가 쓴 리뷰")
                .font(.headline)
                .bold()
                .foregroundColor(.black)

            Spacer()

            Rectangle()
                .fill(Color.clear)
                .frame(width: 20)
                .padding(.trailing, 15)
        }
        .padding(.vertical, 8)
        .background(Color.white)
    }

    @ViewBuilder
    private func contentSection() -> some View {
        if loading {
            VStack {
                ProgressView("리뷰 불러오는 중...")
                    .padding(.top, 12)
            }
        } else if reviews.isEmpty {
            Text("작성하신 리뷰가 없습니다.")
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity)
                .padding(.top, 24)
        } else {
            LazyVStack(spacing: 18) {
                ForEach(reviews) { r in
                    NavigationLink(destination: ReviewMyDetailView(reviewId: r.review_id)) {
                        reviewCard(r)
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                }
            }
            .padding(.top, 12)
        }
    }

    private func reviewCard(_ r: MyReview) -> some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Text("주문 항목: \(r.menu_name)")
                    .font(.headline)

                Spacer()

                Button {
                    deleteTargetId = r.review_id
                    showDeleteConfirm = true
                } label: {
                    Text("삭제")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .background(Color.red)
                        .cornerRadius(10)
                }
            }

            HStack(spacing: 6) {
                StarRating(rating: r.rating)
                    .frame(height: 16)

                Text("\(r.rating, specifier: "%.1f")")
                    .font(.subheadline)
                    .foregroundColor(.orange)
            }

            Text(r.content)
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineLimit(2)

            HStack {
                Text("주문 일자: \(r.formattedOrderDate)")
                Spacer()
                Text("결제 금액: \(r.formattedPrice)")
            }
            .font(.caption)
            .foregroundColor(.gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.15), radius: 3, y: 2)
        )
    }

    private func loadReviews() {
        guard let url = URL(string: "\(baseURL)/get_my_reviews.php") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

    
        let uid = UserDefaults.standard.integer(forKey: "user_id")
        request.httpBody = "user_id=\(uid)".data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, _, error in

            guard let data = data, error == nil else { return }

            do {
                let decoded = try JSONDecoder().decode(ReviewListResponse2.self, from: data)
                DispatchQueue.main.async {
                    self.reviews = decoded.review
                    self.loading = false
                }
            } catch {
                DispatchQueue.main.async {
                    print("RAW JSON:", String(data: data, encoding: .utf8) ?? "없음")
                    self.loading = false
                    self.resultMessage = "리뷰 목록 디코딩 실패"
                    self.showAlert = true
                }
            }

        }.resume()
    }


    private func deleteReview(_ id: Int) {
        guard let url = URL(string: "\(baseURL)/delete_review.php") else { return }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.httpBody = "review_id=\(id)".data(using: .utf8)

        URLSession.shared.dataTask(with: req) { data, _, error in

            guard let data = data, error == nil else { return }

            if let str = String(data: data, encoding: .utf8) {
                print("삭제 응답:", str)
            }

            DispatchQueue.main.async {
                self.resultMessage = "삭제되었습니다."
                self.showAlert = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.loadReviews()
            }

        }.resume()
    }
}

struct StarRating: View {
    let rating: Float
    let max = 5

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<max, id: \.self) { i in
                let half = Float(i) + 0.5
                Image(systemName:
                        rating >= Float(i + 1) ? "star.fill" :
                        (rating >= half ? "star.leadinghalf.filled" : "star")
                )
                .foregroundColor(.yellow)
            }
        }
    }
}

#Preview {
    ReviewMyView()
}
