//
//  ModelCardDetailScreen.swift
//  ARForge
//
//  Created by ARForgeQA on 10/17/21.
//

import SwiftUI
import SDWebImageSwiftUI

struct ModelCardDetail: View{
    
    var modelID: String
    var animation: Namespace.ID
    @Binding var showing: Bool
    @Environment(\.openURL) var openURL
    @State var buyModelUseCase: UseCase?
    @State var deleteModelUseCase: UseCase?
    @State var showBuyScreen: Bool = false
    @ObservedObject var userModelState = UserModelsState.shared
        
    var body: some View{
        
        VStack {
            if let model = userModelState.model(from: modelID) {
                
                HStack(spacing: 25){
                    
                    Button(action: {
                        // closing view...
                        withAnimation(.spring()){showing.toggle()}
                    }) {
                        
                        Image(systemName: "chevron.left")
                            .font(.title)
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                }
                .padding()
                
                Spacer()
                WebImage(url: model.modelThumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                
                Text(model.status.rawValue)
                    .padding()
                
                Spacer()
                
                if model.buy{
                    HStack {
                        Button("Show USDZ") {
                            openURL(model.usdzURL)
                        }.padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding()
                        
                        
                        Button("Open GLB") {
                            openURL(model.glbURL)
                        }.padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }.padding()
                }
                
                let hasSufficientFunds = model.modelType.cost <= userModelState.userInfo!.coins
                
                if !model.buy && model.status.isBuyable && hasSufficientFunds {
                    Button("Buy for \(model.modelType.cost) coins") {
                        self.buyModelUseCase = BuyModelUseCase.initializeAndStart(jobID: model.id)
                    }.padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding()
                }
                
                if !hasSufficientFunds && !model.buy {
                    Button("Insufficient Coins !!! \n Please Buy coins") {
                        showBuyScreen.toggle()
                    }.padding()
                    .multilineTextAlignment(.center)
                    .background(Color.yellow)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding()
                }
                
                if model.status.isDeletable {
                    Button("Delete") {
                        self.deleteModelUseCase = DeleteModelUseCase.initializeAndStart(jobID: model.id)
                    }.padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding()
                }
                
                Spacer()
            } else {
                Text("Model deleted").onAppear {
                    showing.toggle()
                }
            }
        }.fullScreenCover(isPresented: $showBuyScreen) {
            BuyCoinsScreen(isShowing: $showBuyScreen)
        }
    }
}
