//
//  ContentView.swift
//  ARForge
//
//  Created by ARForgeQA on 8/28/21.
//

import SwiftUI

struct LoginScreen: View {
    
    var body: some View {
        
        ZStack{

            LinearGradient(gradient: .init(colors: [Color.black]), startPoint: .top, endPoint: .bottom).edgesIgnoringSafeArea(.all)

            if UIScreen.main.bounds.height > 800{

                LoginContentView()
            }
            else{

                ScrollView(.vertical, showsIndicators: false) {

                    LoginContentView()
                }
            }
        }
    }
}

struct LoginScreen_Previews: PreviewProvider {
    static var previews: some View {
        LoginScreen()
    }
}

struct LoginContentView : View {
    @State var index = 0
    
    var body : some View{
        
        VStack{
            
            Image("logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
            
            Text("Convert your videos or photos to 3D Assets")
                .font(.system(size: 30, weight: .bold, design:  .monospaced))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            HStack(spacing: 15){
                
                Color.white.opacity(0.7)
                .frame(width: 35, height: 1)
                
                Text("Sign In")
                    .font(.system(size: 30, weight: .bold, design:  .monospaced))
                    .foregroundColor(.white)
                
                Color.white.opacity(0.7)
                .frame(width: 35, height: 1)
                
            }
            .padding(.top, 10)
            
            HStack{
                
                Button(action: {
                    //TODO hook up apple singin
                    AppleLoginManager.shared.startSignInWithAppleFlowWith(hostViewController: (UIApplication.shared.windows.first?.rootViewController)!)
                }) {
                    
                    Image("logoApple")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .padding()
                    
                    
                }.background(Color.white)
                .clipShape(Circle())
                
                Button(action: {
                    GoogleLoginManager.shared.startSignInWithGoogleFlowWith(hostViewController: (UIApplication.shared.windows.first?.rootViewController)!)
                }) {
                    
                    Image("logoGoogle")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .padding()
                    
                }.background(Color.white)
                .clipShape(Circle())
                .padding(.leading, 25)
            }
            .padding(.top, 10)
            
            Spacer()

        }
        .padding()
    }
}
