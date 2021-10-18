//
//  ModelsScreen.swift
//  ARForge
//
//  Created by ARForgeQA on 8/29/21.
//

import SwiftUI
import SDWebImageSwiftUI

struct ModelsScreen: View {
    @ObservedObject var userModelsState = UserModelsState.shared
    @State var showComposeForm = false
    @State var showCoinsForm = false
    @State var getUserObjectUseCase : UseCase? = nil
    @State var refreshControl: UIRefreshControl? = nil
    @State var listRefreshing = false
    
    init() {
        //Use this if NavigationBarTitle is with Large Font
        UINavigationBar.appearance().largeTitleTextAttributes = [.font : UIFont.monospacedSystemFont(ofSize: 30, weight: .bold)]
        UINavigationBar.appearance().titleTextAttributes = [.font : UIFont.monospacedSystemFont(ofSize: 20, weight: .bold)]
        
        //Use this if NavigationBarTitle is with displayMode = .inline
        //UINavigationBar.appearance().titleTextAttributes = [.font : UIFont(name: "Georgia-Bold", size: 20)!]
    }
    
    var body: some View {
        if (showCoinsForm) {
            BuyCoinsScreen(isShowing: $showCoinsForm)
                .animation(.linear)
        } else  {
            NavigationView{
                ModelsList(refreshing: $listRefreshing, models: $userModelsState.models, onRefresh: {
                    userModelsState.currentState = .refreshing
                    self.getUserObjectUseCase = GetUserObjectUseCase.initializeAndStart()
                })
                .padding(.horizontal)
                .navigationTitle("Your Models")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            FirebaseState.shared.logout()
                        } label: {
                            Image(systemName: "figure.walk")
                        }
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            showCoinsForm.toggle()
                        } label : {
                            Image(systemName: "person")
                        }
                    }
                }
            }
            .animation(.linear)
            .overlay(
                
                Button(action: {
                    self.showComposeForm.toggle()
                }, label: {
                    Image.init(systemName: "plus")
                        .font(Font.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color("darkPurple"))
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.9), radius: 5, x: 5, y: 5)
                })
                .padding()
                , alignment: .bottomTrailing
            )
            .accentColor(Color("ascentColor"))
            .font(.system(.body, design: .monospaced))
            .fullScreenCover(isPresented: $showComposeForm) {
                CreateModelScreen(showComposeForm: $showComposeForm)
            }
            .onAppear {
                self.getUserObjectUseCase = GetUserObjectUseCase.initializeAndStart()
            }.onReceive(userModelsState.$currentState, perform: { val in
                if case .success = val {
                    refreshControl?.endRefreshing()
                    listRefreshing = false
                    refreshControl = nil
                }
            })
        }
    }
}

struct ModelsScreen_Previews: PreviewProvider {

    static var previews: some View {
        ModelsScreen()
            .preferredColorScheme(.light)
    }
}

struct ModelsList: View {
    let columns = 2
    
    @State var startOffset = CGPoint.zero
    @State var offset = CGPoint.zero
    @State var selectedModel : ModelJob? = nil
    @State var showingPreview = false
    @Binding var refreshing: Bool
    @State var rotating = false
    @Binding var models: [ModelJob]
    @Environment(\.openURL) var openURL
    var onRefresh: () -> Void


    // Smooth Hero Effect...
    @Namespace var animation
    
    var body: some View {
        
        ScrollView(.vertical, showsIndicators: false) {
            VStack {
                if (refreshing) {
                    Image(systemName: "arrow.clockwise")
                        .resizable()
                        .frame(width: 50, height: 50, alignment: .center)
                        .rotationEffect(.degrees(rotating ? 360 : 0))
                        .animation(.linear.repeatForever(autoreverses: false))
                        .onDisappear{
                            rotating = false
                        }
                        .onAppear {
                            rotating = true
                        }
                        .padding(.top)
                    Text("Loading ...")

                }
                StaggeredGrid(columns: columns, list: models, content: { model in
                    
                    // Model Card View...
                    ModelCardView(model: model, animation: animation)
                        .matchedGeometryEffect(id: model.id, in: animation)
                        .onTapGesture {
                            self.selectedModel = model
                            self.showingPreview.toggle()
                        }
                })
            }
            .overlay(
                
                // Using Geomtry Reader to get offset...
                
                GeometryReader{proxy -> Color in
                
                    let rect = proxy.frame(in: .global)
                    
                    if startOffset == .zero{
                        DispatchQueue.main.async {
                            startOffset = CGPoint(x: rect.minX, y: rect.minY)
                        }
                    }
                    
                    DispatchQueue.main.async {
                        
                        // Minus From Current...
                        self.offset = CGPoint(x: startOffset.x - rect.minX, y: startOffset.y - rect.minY)
                        if (self.offset.y < -50 && !self.refreshing) {
                            self.refreshing = true
                            self.onRefresh()
                        }
                    }
                    
                    return Color.clear
                }
                // Since were also fetching horizontal offset...
                // so setting width to full so that minX will be Zero...
                .frame(width: UIScreen.main.bounds.width, height: 0)
                
                ,alignment: .top
            )
            .fullScreenCover(isPresented: $showingPreview) {
                ModelCardDetail(modelID: selectedModel?.id ?? "", animation: animation, showing: $showingPreview)
                
            }
        }
    }
}

// since we declared T as Identifiable...
// so we need to pass Idenfiable conform collection/Array...

struct ModelCardView: View{
    
    var model: ModelJob
    var animation: Namespace.ID
    
    var body: some View{
        ZStack {
            LinearGradient(gradient: .init(colors: [Color("lightblue"), Color("lightPurple"), Color("darkPurple")]), startPoint: .top, endPoint: .bottom).edgesIgnoringSafeArea(.all)
            VStack {
                WebImage(url: model.coverImageURL)
                    .resizable()
                    .aspectRatio(contentMode: .fit)

                
                Text(model.status.rawValue)
                    .padding()
            }
        }
        .foregroundColor(Color.white)
        .cornerRadius(10)
    }
}

struct ModelCardDetail: View{
    
    var modelID: String
    var animation: Namespace.ID
    @Binding var showing: Bool
    @Environment(\.openURL) var openURL
    @State var buyModelUseCase: UseCase?
    @State var deleteModelUseCase: UseCase?
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
                
                if !hasSufficientFunds {
                    Button("Insufficient Coins pleease Buy coins") {
                        // Move to Buy Coins Screen
                    }.padding()
                    .background(Color.blue)
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
        }
    }
}
