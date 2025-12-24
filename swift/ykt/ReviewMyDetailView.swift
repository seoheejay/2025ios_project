import SwiftUI

struct ReviewDetailResponse: Decodable {
    let status: String
    let data: MyReview?
    let message: String?
}

struct SimpleResponse: Decodable {
    let status: String
    let message: String
}

struct ReviewMyDetailView: View {

    private let baseURL = "http://124.56.5.77/ykt/bk"
    private let customDarkColor = Color(red: 97/255, green: 22/255, blue: 37/255)

    let reviewId: Int

    @Environment(\.dismiss) private var dismiss

    @State private var review: MyReview?
    @State private var editing = false
    @State private var newContent = ""
    @State private var newRating: Float = 0
    @State private var showAlert = false
    @State private var resultMessage = ""

    var body: some View {

        ZStack {
            Color(red: 245/255, green: 245/255, blue: 245/255)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: -61.5) {

                headerBar()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {

                        topNavigationBar()

                        contentSection()

                        Spacer(minLength: 40)
                    }
                }
                .background(Color.white)
            }
        }
        .onAppear(perform: loadDetail)
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .alert(resultMessage, isPresented: $showAlert) {
            Button("확인", role: .cancel) {
                if resultMessage.contains("삭제") {
                    dismiss()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private func headerBar() -> some View {
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

    private func topNavigationBar() -> some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(customDarkColor)
            }
            .padding(.leading, 15)

            Spacer()

            Text("리뷰 상세")
                .font(.headline)
                .bold()
                .foregroundColor(.black)

            Spacer()

            Rectangle().fill(Color.clear)
                .frame(width: 20)
                .padding(.trailing, 15)
        }
        .padding(.vertical, 8)
        .background(Color.white)
    }

    @ViewBuilder
    private func contentSection() -> some View {
        if let r = review {

            VStack(alignment: .leading, spacing: 16) {

                HStack {
                    Text("주문 항목: \(r.menu_name)")
                        .font(.headline)

                    Spacer()

                    Text("주문 일자: \(r.formattedOrderDate)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                HStack(spacing: 6) {

                    if editing {
                        EditableStarRating(rating: $newRating)
                            .frame(height: 26)
                    } else {
                        StarRating(rating: r.rating)
                            .frame(height: 26)
                    }

                    Text("\(editing ? newRating : r.rating, specifier: "%.1f")")
                        .font(.title3)
                        .bold()
                        .foregroundColor(.orange)

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 6) {

                    Text("제목 : \(r.title)")
                        .font(.headline)

                    if editing {
                        TextEditor(text: $newContent)
                            .frame(height: 160)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    } else {
                        Text(r.content)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                }

                HStack(spacing: 12) {

                    if editing {

                        Button("완료") { saveEdit() }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(customDarkColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)

                        Button("취소") { editing = false }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .cornerRadius(12)

                    } else {

                        Button("삭제", role: .destructive) {
                            deleteReview()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(12)

                        Button("수정") {
                            newContent = r.content
                            newRating = r.rating
                            editing = true
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 255/255, green: 170/255, blue: 185/255))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding(.top, 12)
            }
            .padding(20)

        } else {

            VStack {
                ProgressView("불러오는 중...")
                Spacer()
            }
            .padding()
        }
    }

    private func loadDetail() {
        guard let url = URL(string: "\(baseURL)/get_review_detail.php") else { return }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.httpBody = "review_id=\(reviewId)".data(using: .utf8)

        URLSession.shared.dataTask(with: req) { data, _, _ in
            guard let data = data else { return }

            do {
                let dto = try JSONDecoder().decode(ReviewDetailResponse.self, from: data)

                DispatchQueue.main.async {
                    if dto.status == "success", let item = dto.data {
                        self.review = item
                        self.newContent = item.content
                        self.newRating = item.rating
                    } else {
                        self.resultMessage = dto.message ?? "불러오기 실패"
                        self.showAlert = true
                    }
                }

            } catch {
                DispatchQueue.main.async {
                    self.resultMessage = "디코딩 실패"
                    self.showAlert = true
                }
            }

        }.resume()
    }

    private func saveEdit() {
        guard let r = review,
              let url = URL(string: "\(baseURL)/update_review.php")
        else { return }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.httpBody = formURLEncoded([
            "review_id": "\(r.id)",
            "title": r.title,
            "content": newContent,
            "rating": "\(newRating)"
        ])

        URLSession.shared.dataTask(with: req) { data, _, _ in
            guard let data = data else { return }

            do {
                let res = try JSONDecoder().decode(SimpleResponse.self, from: data)

                DispatchQueue.main.async {
                    if res.status == "success" {
                        review?.content = newContent
                        review?.rating = newRating
                    }
                    resultMessage = res.message
                    editing = false
                    showAlert = true
                }

            } catch {
                DispatchQueue.main.async {
                    resultMessage = "수정 실패"
                    showAlert = true
                }
            }

        }.resume()
    }

    private func deleteReview() {
        guard let url = URL(string: "\(baseURL)/delete_review.php") else { return }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.httpBody = "review_id=\(reviewId)".data(using: .utf8)

        URLSession.shared.dataTask(with: req) { data, _, _ in
            guard let data = data else { return }

            do {
                let res = try JSONDecoder().decode(SimpleResponse.self, from: data)
                DispatchQueue.main.async {
                    resultMessage = res.message
                    showAlert = true
                }
            } catch {
                DispatchQueue.main.async {
                    resultMessage = "삭제 실패"
                    showAlert = true
                }
            }

        }.resume()
    }
}

private func formURLEncoded(_ dict: [String:String]) -> Data? {
    let s = dict.map {
        "\($0.key)=\(($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value))"
    }.joined(separator: "&")

    return s.data(using: .utf8)
}

struct EditableStarRating: View {
    @Binding var rating: Float
    let max = 5

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<max*2, id: \.self) { i in
                let v = Float(i+1)/2

                Image(systemName:
                        rating >= v
                        ? (v.truncatingRemainder(dividingBy: 1) == 0
                           ? "star.fill"
                           : "star.leadinghalf.filled")
                        : "star")
                    .foregroundColor(.orange)
                    .onTapGesture { rating = v }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ReviewMyDetailView(reviewId: 1)
    }
}
