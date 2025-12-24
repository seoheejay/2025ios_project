import SwiftUI
import Combine

private let BASE_URL = "http://124.56.5.77/ykt/sec"

enum MenuCategory: String, CaseIterable, Identifiable {
    case today   = "오늘의 메뉴"
    case pohanki = "포한끼"
    case miguel  = "미구엘의 돈까스가게"
    case mara    = "한우사골 마라탕"
    case viva    = "비바쿡"
    case cafe    = "카페"
    
    var id: String { rawValue }
}

struct TodayMenuItem: Identifiable, Codable {
    let id: Int
    let menuId: Int
    let name: String
    let isSoldOut: Bool
    let hasAllergy: Bool
}

struct CategoryMenuItem: Identifiable, Codable {
    let id: Int
    let name: String
    let imageURL: String
    let rating: Double
    let isSoldOut: Bool
    let hasAllergy: Bool
}

struct TodayMenuResponse: Codable {
    let menuAItems: [TodayMenuItem]
    let menuBItems: [TodayMenuItem]
    let menuARating: Double
    let menuBRating: Double
    let menuASoldOut: Bool
    let menuBSoldOut: Bool
}

@MainActor
class MenuViewModel: ObservableObject {
    
    private let userId: Int?
    
    init() {
        let saved = UserDefaults.standard.integer(forKey: "user_id")
        self.userId = saved == 0 ? nil : saved
    }
    
    @Published var todayMenuA: [TodayMenuItem] = []
    @Published var todayMenuB: [TodayMenuItem] = []
    @Published var todayMenuARating: Double = 0.0
    @Published var todayMenuBRating: Double = 0.0
    @Published var todayMenuASoldOut: Bool = false
    @Published var todayMenuBSoldOut: Bool = false
    
    @Published var categoryMenus: [CategoryMenuItem] = []
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private func serverCategoryName(_ category: MenuCategory) -> String {
        switch category {
        case .today:   return "오늘의메뉴"
        case .pohanki: return "포한끼"
        case .miguel:  return "미구엘의돈까스가게"
        case .mara:    return "한우사골마라탕"
        case .viva:    return "비바쿡"
        case .cafe:    return "카페"
        }
    }
    
    func load(for category: MenuCategory) {
        isLoading = true
        errorMessage = nil
        
        switch category {
        case .today:
            fetchTodayMenuFromServer()
        default:
            let serverName = serverCategoryName(category)
            fetchCategoryMenuFromServer(restaurant: serverName)
        }
    }
    
    private func fetchTodayMenuFromServer() {
        var components = URLComponents(string: "\(BASE_URL)/today_menu.php")
        if let userId = userId {
            components?.queryItems = [
                URLQueryItem(name: "user_id", value: String(userId))
            ]
        }
        
        guard let url = components?.url else {
            isLoading = false
            errorMessage = "잘못된 URL"
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "통신 오류: \(error.localizedDescription)"
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "데이터가 없습니다."
                }
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(TodayMenuResponse.self, from: data)
                
                DispatchQueue.main.async {
                    self.todayMenuA        = result.menuAItems
                    self.todayMenuB        = result.menuBItems
                    self.todayMenuARating  = result.menuARating
                    self.todayMenuBRating  = result.menuBRating
                    self.todayMenuASoldOut = result.menuASoldOut
                    self.todayMenuBSoldOut = result.menuBSoldOut
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "파싱 오류: \(error.localizedDescription)"
                    print("DEBUG today_menu JSON:", String(data: data, encoding: .utf8) ?? "nil")
                }
            }
        }
        
        task.resume()
    }
    
    private func fetchCategoryMenuFromServer(restaurant: String) {
        var components = URLComponents(string: "\(BASE_URL)/category_menu.php")
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "restaurant", value: restaurant)
        ]
        if let userId = userId {
            queryItems.append(URLQueryItem(name: "user_id", value: String(userId)))
        }
        components?.queryItems = queryItems
        
        guard let url = components?.url else {
            isLoading = false
            errorMessage = "잘못된 URL"
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "통신 오류: \(error.localizedDescription)"
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "데이터가 없습니다."
                }
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let items = try decoder.decode([CategoryMenuItem].self, from: data)
                
                DispatchQueue.main.async {
                    self.categoryMenus = items
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "파싱 오류: \(error.localizedDescription)"
                    print("DEBUG category_menu JSON:", String(data: data, encoding: .utf8) ?? "nil")
                }
            }
        }
        
        task.resume()
    }
}

struct MenuView: View {
    
    @State private var selectedCategory: MenuCategory = .today
    @StateObject private var viewModel = MenuViewModel()
    
    @State private var selectedMenuId: Int? = nil
    @State private var selectedTodayText: String? = nil
    @State private var isDetailActive: Bool = false
    
    @State private var showSoldOutAlert: Bool = false
    
    @State private var isHamberActive: Bool = false
    @State private var isCartActive: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            
            HomeTopBar(
                onTapMenu: { isHamberActive = true },
                onTapCart: { isCartActive = true }
            )
            
            ScrollView {
                CategoryChips(selectedCategory: $selectedCategory)
                    .padding(.horizontal, 16)
                
                if viewModel.isLoading {
                    ProgressView()
                        .padding(.top, 40)
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding(.top, 40)
                } else {
                    CategoryContentView(
                        category: selectedCategory,
                        todayMenuA: viewModel.todayMenuA,
                        todayMenuB: viewModel.todayMenuB,
                        todayMenuARating: viewModel.todayMenuARating,
                        todayMenuBRating: viewModel.todayMenuBRating,
                        categoryItems: viewModel.categoryMenus,
                        todayMenuASoldOut: viewModel.todayMenuASoldOut,
                        todayMenuBSoldOut: viewModel.todayMenuBSoldOut,
                        onTapTodayMenu: { item in
                            let isA = viewModel.todayMenuA.contains { $0.id == item.id }
                            let group = isA ? viewModel.todayMenuA : viewModel.todayMenuB
                            let text = group.map { $0.name }.joined(separator: "\n")
                            selectedMenuId = item.menuId
                            selectedTodayText = text
                            isDetailActive = true
                        },
                        onTapTodaySoldOut: { _ in
                            showSoldOutAlert = true
                        },
                        onTapCategoryMenu: { item in
                            selectedMenuId = item.id
                            selectedTodayText = nil
                            isDetailActive = true
                        },
                        onTapCategorySoldOut: { _ in
                            showSoldOutAlert = true
                        }
                    )
                    .padding(.horizontal, 16)
                }
            }
            
            NavigationLink(
                destination: Group {
                    if let id = selectedMenuId {
                        MenuDetailView(menuId: id, todayMenuText: selectedTodayText)
                    } else {
                        EmptyView()
                    }
                },
                isActive: $isDetailActive
            ) {
                EmptyView()
            }
            
            NavigationLink(
                destination: HamberView(),
                isActive: $isHamberActive
            ) {
                EmptyView()
            }
            
            NavigationLink(
                destination: CartView(),
                isActive: $isCartActive
            ) {
                EmptyView()
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.load(for: selectedCategory)
        }
        .onChange(of: selectedCategory) { newValue in
            viewModel.load(for: newValue)
        }
        .alert("품절된 메뉴입니다.", isPresented: $showSoldOutAlert) {
            Button("확인", role: .cancel) { }
        }
    }
}

private struct HomeTopBar: View {
    let onTapMenu: () -> Void
    let onTapCart: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button { onTapMenu() } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.title2)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("덕성여자대학교").font(.headline).bold()
                Text("DUKSUNG WOMEN'S UNIVERSITY")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Button { onTapCart() } label: {
                Image(systemName: "cart")
                    .font(.title2)
            }
        }
        .padding()
        .background(.white)
        .overlay(Divider(), alignment: .bottom)
    }
}

private struct CategoryChips: View {
    @Binding var selectedCategory: MenuCategory
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10)
        ], spacing: 10) {
            ForEach(MenuCategory.allCases) { category in
                Button { selectedCategory = category } label: {
                    Text(category.rawValue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .chipStyle(selected: selectedCategory == category)
            }
        }
        .padding(.top, 12)
    }
}

private struct Chip: ViewModifier {
    let selected: Bool
    
    func body(content: Content) -> some View {
        content
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(selected ? .white : Color.blue)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(selected ? Color.pink.opacity(0.9) : Color.white)
                    .shadow(color: .gray.opacity(0.2), radius: 3)
            )
    }
}

extension View {
    func chipStyle(selected: Bool = false) -> some View {
        modifier(Chip(selected: selected))
    }
}

private struct CategoryContentView: View {
    let category: MenuCategory
    let todayMenuA: [TodayMenuItem]
    let todayMenuB: [TodayMenuItem]
    let todayMenuARating: Double
    let todayMenuBRating: Double
    let categoryItems: [CategoryMenuItem]
    let todayMenuASoldOut: Bool
    let todayMenuBSoldOut: Bool
    
    let onTapTodayMenu: (TodayMenuItem) -> Void
    let onTapTodaySoldOut: (TodayMenuItem) -> Void
    let onTapCategoryMenu: (CategoryMenuItem) -> Void
    let onTapCategorySoldOut: (CategoryMenuItem) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(category.rawValue)
                .font(.title3).bold()
                .padding(.top, 12)
            
            if category == .today {
                TodayMenuSection(
                    menuA: todayMenuA,
                    menuB: todayMenuB,
                    menuARating: todayMenuARating,
                    menuBRating: todayMenuBRating,
                    menuASoldOut: todayMenuASoldOut,
                    menuBSoldOut: todayMenuBSoldOut,
                    onTapMenu: onTapTodayMenu,
                    onTapSoldOut: onTapTodaySoldOut
                )
            } else {
                CategoryMenuSection(
                    items: categoryItems,
                    onTapMenu: onTapCategoryMenu,
                    onTapSoldOut: onTapCategorySoldOut
                )
            }
        }
        .padding(.top, 20)
    }
}

private struct TodayMenuSection: View {
    let menuA: [TodayMenuItem]
    let menuB: [TodayMenuItem]
    let menuARating: Double
    let menuBRating: Double
    let menuASoldOut: Bool
    let menuBSoldOut: Bool
    let onTapMenu: (TodayMenuItem) -> Void
    let onTapSoldOut: (TodayMenuItem) -> Void
    
    var body: some View {
        VStack(spacing: 28) {
            VStack(alignment: .leading, spacing: 8) {
                Text("오늘의 메뉴 A").font(.headline)
                PinkMenuCard(
                    items: menuA,
                    isSoldOut: menuASoldOut,
                    onTapMenu: onTapMenu,
                    onTapSoldOut: onTapSoldOut
                )
                HStack(spacing: 4) {
                    StarRatingView2(rating: menuARating)
                    Text(String(format: "%.1f", menuARating))
                        .font(.subheadline)
                }
                .padding(.top, 4)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("오늘의 메뉴 B").font(.headline)
                PinkMenuCard(
                    items: menuB,
                    isSoldOut: menuBSoldOut,
                    onTapMenu: onTapMenu,
                    onTapSoldOut: onTapSoldOut
                )
                HStack(spacing: 4) {
                    StarRatingView2(rating: menuBRating)
                    Text(String(format: "%.1f", menuBRating))
                        .font(.subheadline)
                }
                .padding(.top, 4)
            }
        }
    }
}

private struct PinkMenuCard: View {
    let items: [TodayMenuItem]
    let isSoldOut: Bool
    let onTapMenu: (TodayMenuItem) -> Void
    let onTapSoldOut: (TodayMenuItem) -> Void
    
    var body: some View {
        ZStack {
            VStack(spacing: 6) {
                ForEach(items) { item in
                    Button {
                        if isSoldOut {
                            onTapSoldOut(item)
                        } else {
                            onTapMenu(item)
                        }
                    } label: {
                        HStack {
                            Text(item.name)
                                .foregroundColor(.black)
                            Spacer()
                            if isSoldOut {
                                Text("품절")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemPink).opacity(0.15))
            .cornerRadius(12)
            
            if isSoldOut {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.4))
                Text("오늘의 메뉴 품절")
                    .font(.headline)
                    .foregroundColor(.red)
            }
        }
    }
}

private struct StarRatingView2: View {
    let rating: Double
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5) { index in
                let filled = Double(index) < floor(rating)
                let half   = !filled && Double(index) + 0.5 <= rating
                Image(systemName:
                        filled ? "star.fill" :
                        (half ? "star.leadinghalf.filled" : "star")
                )
                .font(.caption)
            }
        }
        .foregroundColor(.yellow)
    }
}

private struct CategoryMenuSection: View {
    let items: [CategoryMenuItem]
    let onTapMenu: (CategoryMenuItem) -> Void
    let onTapSoldOut: (CategoryMenuItem) -> Void
    
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        if items.isEmpty {
            Text("메뉴가 없습니다.")
                .foregroundColor(.secondary)
        } else {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(items) { item in
                    Button {
                        if item.isSoldOut {
                            onTapSoldOut(item)
                        } else {
                            onTapMenu(item)
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.name)
                                .font(.headline)
                                .foregroundColor(.black)
                            
                            ZStack(alignment: .topTrailing) {
                                if let url = URL(string: item.imageURL),
                                   !item.imageURL.isEmpty {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .empty:
                                            ProgressView()
                                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                                .clipped()
                                        case .failure:
                                            Image(systemName: "photo")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                                .foregroundColor(.gray)
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                } else {
                                    Image(systemName: "photo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .foregroundColor(.gray)
                                }
                                
                                if item.isSoldOut {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.black.opacity(0.4))
                                    
                                    Text("품절")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(4)
                                        .background(Color.red.opacity(0.8))
                                        .cornerRadius(6)
                                        .padding(6)
                                }
                            }
                            .frame(height: 130)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            
                            HStack(spacing: 4) {
                                StarRatingView2(rating: item.rating)
                                Text(String(format: "%.1f", item.rating))
                                    .font(.subheadline)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 8)
        }
    }
}
