import SwiftUI

extension Color {
    static let duksungMaroon = Color(red: 0.514, green: 0.161, blue: 0.271)
}

struct StartView: View {
    var body: some View {
        NavigationView {
            ZStack {
                Color.duksungMaroon.ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    VStack(spacing: 15) {
                        Image("DuksungLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 150)
                            .padding(.top, -150)
                        
                        Text("덕 냠!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Image("MoleCloud2")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 270) 
                            .padding(.top, 10)
                        
                        Text("덕성냠냠")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.bottom, 100)
                    
                    Spacer()
                    
                    VStack(spacing: 15) {
                        NavigationLink {
                            SignupView()
                        } label: {
                            Text("회원가입")
                                .font(.headline)
                                .foregroundColor(.duksungMaroon)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(
                                    RoundedRectangle(cornerRadius: 30)
                                        .fill(Color.white)
                                )
                        }
                        .padding(.horizontal, 30)
                        
                        NavigationLink {
                            LoginView()
                        } label: {
                            Text("로그인")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(
                                    RoundedRectangle(cornerRadius: 30)
                                        .stroke(Color.white, lineWidth: 2)
                                )
                        }
                        .padding(.horizontal, 30)
                    }
                    .padding(.bottom, 50)
                }
            }
        }
    }
}

#Preview {
    StartView()
}
