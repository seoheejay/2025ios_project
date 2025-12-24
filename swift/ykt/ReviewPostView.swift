import SwiftUI

private let REVIEW_BASE_URL = "http://124.56.5.77/ykt/sec"

struct ReviewPostView: View {
    @Environment(\.dismiss) private var dismiss

    // 받아온 데이터
    let orderId: Int
    let orderItemId: Int
    let menuId: Int
    let price: Int
    let menuName: String // 화면 표시용 (서버 전송 X)
    let orderDate: String
    
    var onSuccess: (() -> Void)? = nil

    @State private var rating: Double = 5.0
    @State private var titleText: String = ""
    @State private var contentText: String = ""

    @State private var isSubmitting: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    var body: some View {
        VStack(spacing: 0) {
            headerBar()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 화면에는 받아온 이름 표시
                    Text(menuName)
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 12)

                    StarRatingHalfStep(rating: $rating)
                        .padding(.horizontal, 24)

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("제목:")
                                .font(.subheadline).bold()
                            TextField("제목을 입력하세요", text: $titleText)
                                .textFieldStyle(.plain)
                        }

                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $contentText)
                                .frame(height: 170)
                                .padding(4)

                            if contentText.isEmpty {
                                Text("내용을 입력해주세요.")
                                    .foregroundColor(.gray.opacity(0.5))
                                    .padding(.top, 12)
                                    .padding(.leading, 10)
                            }
                        }
                        .background(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3)))
                    }
                    .padding(.horizontal, 24)

                    HStack {
                        Text(orderDate)
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        Button("게시", action: submitReview)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 8)
                            .background(Color.pink)
                            .cornerRadius(18)
                            .disabled(isSubmitting)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 6)
                }
                .padding(.top, 8)
            }
        }
        .background(Color.white.ignoresSafeArea())
        .alert(alertMessage, isPresented: $showAlert) {
            Button("확인") {
                if alertMessage == "리뷰가 등록되었습니다." {
                    onSuccess?()
                    dismiss()
                }
            }
        }
    }

    private func headerBar() -> some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18))
                    .foregroundColor(.black)
                    .padding(.leading, 16)
            }
            Spacer()
            Text("리뷰 작성")
                .font(.headline)
            Spacer()
            Rectangle()
                .fill(Color.clear)
                .frame(width: 30)
                .padding(.trailing, 16)
        }
        .frame(height: 50)
        .padding(.top, UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0)
        .background(Color.white)
        .ignoresSafeArea(edges: .top)
    }

    private func currentUserId() -> Int {
        let saved = UserDefaults.standard.integer(forKey: "user_id")
        return saved == 0 ? 1 : saved
    }

    private func submitReview() {
        guard rating > 0 else { alertMessage = "별점을 선택해주세요."; showAlert = true; return }
        guard !titleText.trimmingCharacters(in: .whitespaces).isEmpty else { alertMessage = "제목을 입력해주세요."; showAlert = true; return }
        guard !contentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { alertMessage = "내용을 입력해주세요."; showAlert = true; return }

        isSubmitting = true

        let userId = currentUserId()
        guard let url = URL(string: "\(REVIEW_BASE_URL)/ReviewPost.php") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        // menu_name 제외, menu_id만 전송
        let params: [String: String] = [
            "user_id": "\(userId)",
            "order_id": "\(orderId)",
            "order_item_id": "\(orderItemId)",
            "menu_id": "\(menuId)",
            "price": "\(price)",
            "rating": String(format: "%.1f", rating),
            "title": titleText,
            "content": contentText
        ]

        let body = params
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
        request.httpBody = body.data(using: .utf8)

        Task {
            defer { isSubmitting = false }
            do {
                let (data, _) = try await URLSession.shared.data(for: request)
                
                struct Resp: Decodable { let status: String; let message: String? }
                
                if let decoded = try? JSONDecoder().decode(Resp.self, from: data), decoded.status == "success" {
                    alertMessage = "리뷰가 등록되었습니다."
                } else {
                    if let decoded = try? JSONDecoder().decode(Resp.self, from: data) {
                        alertMessage = decoded.message ?? "리뷰 저장 실패"
                    } else {
                        alertMessage = "서버 응답 오류"
                    }
                }
                showAlert = true
            } catch {
                alertMessage = "오류: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
}

struct StarRatingHalfStep: View {
    @Binding var rating: Double
    private let starSize: CGFloat = 36
    private let spacing: CGFloat = 8
    
    var body: some View {
        HStack(spacing: spacing) {
            ForEach(1...5, id: \.self) { index in
                StarView(index: index, rating: $rating, size: starSize)
            }
            Text(String(format: "%.1f", rating))
                .font(.subheadline)
                .frame(minWidth: 44, alignment: .leading)
        }
        .gesture(
            DragGesture()
                .onChanged { value in calculateRating(location: value.location) }
        )
    }
    
    private func calculateRating(location: CGPoint) {
        let stepWidth = starSize + spacing
        let rawRating = location.x / stepWidth
        let roundedRating = (rawRating * 2).rounded() / 2
        rating = min(max(roundedRating + 0.5, 0.5), 5.0)
    }
    
    struct StarView: View {
        let index: Int
        @Binding var rating: Double
        let size: CGFloat
        var body: some View {
            Image(systemName: symbolName())
                .resizable().scaledToFit().frame(width: size, height: size).foregroundColor(.yellow)
                .onTapGesture { handleTap() }
        }
        private func handleTap() {
            let full = Double(index); let half = full - 0.5
            if rating >= full { rating = half } else if rating >= half { rating = full } else { rating = half }
        }
        private func symbolName() -> String {
            let full = Double(index)
            if rating >= full { return "star.fill" } else if rating >= full - 0.5 { return "star.leadinghalf.filled" } else { return "star" }
        }
    }
}
