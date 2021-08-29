//
//  WalkThroughScreen.swift
//  ARForge
//
//  Created by ARForgeQA on 8/30/21.
//

import SwiftUI

struct WalkthroughScreen: View {
    @State var currentPage: Int = 0
    
    var body: some View{
        
        // For Slide Animation...
        let walkThroughModels = WalkThroughModel.getWalkThroughModels()
        let totalPages = WalkThroughModel.getWalkThroughModels().count

        ZStack{
            ForEach(0..<totalPages) {i in // <- use ForEach() here for transition to work smoothly
                if currentPage == i{
                    ScreenView(image: walkThroughModels[i].imageName, title: walkThroughModels[i].title, detail: walkThroughModels[i].detail, bgColor: Color("darkPurple"))
                        .foregroundColor(.white)
                        .transition(.asymmetric(insertion: .move(edge: .leading), removal: .slide))
                }
            }
        }
        .overlay(
            HStack {
            
            // Showing it only for first Page...
                Text("Capture Guide")
                    .font(.system(.title, design: .monospaced))
                    .fontWeight(.semibold)
                    // Letter Spacing...
                    .kerning(1.4)
            
            
            Spacer()
            
            Button(action: {
                withAnimation(.easeInOut){
                    OnboardingState.shared.markOnboardingFinished()
                }
            }, label: {
                Text("Skip")
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.semibold)
                    .kerning(1.2)
            })
        }
        .foregroundColor(.white)
        .padding(), alignment: .top)
        .overlay(
        
            // Button...
            Button(action: {
                // changing views...
                withAnimation(.easeInOut){
                    
                    // checking....
                    if currentPage < totalPages-1{
                        currentPage += 1
                    } else {
                        OnboardingState.shared.markOnboardingFinished()
                    }
                }
            }, label: {
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(width: 60, height: 60)
                    .background(Color.white)
                    .clipShape(Circle())
                // Circlular Slider...
                    .overlay(
                    
                        ZStack{
                            
                            Circle()
                                .stroke(Color.black.opacity(0.04),lineWidth: 4)
                                
                            Circle()
                                .trim(from: 0, to: CGFloat(currentPage + 1) / CGFloat(totalPages))
                                .stroke(Color.white,lineWidth: 4)
                                .rotationEffect(.init(degrees: -90))
                        }
                        .padding(-15)
                    )
            })
            .padding(.bottom,20)
            
            ,alignment: .bottom
        )
    }
}

struct ScreenView: View {
    
    var image: String
    var title: String
    var detail: String?
    var bgColor: Color
        
    var body: some View {
        ZStack {
            LinearGradient(gradient: .init(colors: [Color.black, Color("darkPurple")]), startPoint: .top, endPoint: .bottom).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20){
                
                Spacer(minLength: 0)
                
                Image(image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                
                Text(title)
                    .font(.system(.title2, design: .monospaced))
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(EdgeInsets(top: 10.0, leading: 10.0, bottom: 0, trailing: 10.0))
                
                if let detail = detail {
                    Text(detail)
                        .font(.system(.footnote, design: .monospaced))
                        .kerning(1.3)
                        .multilineTextAlignment(.center)
                        .padding(EdgeInsets(top: 10.0, leading: 10.0, bottom: 0, trailing: 10.0))
                }
                
                // Minimum Spacing When Phone is reducing...
                
                Spacer(minLength: 120)
            }
        }
    }
}
