//
//  CustomImagePicker.swift
//  ARForge
//
//  Created by ARForgeQA on 9/1/21.
//

import SwiftUI
import Photos

enum InputAssetType: String, CaseIterable {
    case photo
    case video
    
    func mediaType() -> PHAssetMediaType {
        switch self {
        case .photo:
            return .image
        case .video:
            return .video
        }
    }
}

struct CustomPicker : View {
    var inputType : InputAssetType
    @Binding var selected : [Asset]
    @State var allAssets: [Asset] = []
    @Binding var show : Bool
    @ObservedObject var deviceImageFetcher = DeviceImageFetcher.shared
    
    var body: some View{
        ZStack {
            Color.black.opacity(0.5).edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    self.show = false
                    selected = []
                }
            VStack{
                if deviceImageFetcher.setupState != .finished {
                        LoadingIndicator()
                } else if deviceImageFetcher.library_status == .denied || allAssets.isEmpty {
                    VStack(spacing: 15){

                        Text( "Allow Access For Photos")
                            .foregroundColor(.gray)

                        Button(action: {
                            // Go to Settings
                            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
                        }, label: {

                            Text("Allow Access")
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                                .padding(.vertical,10)
                                .padding(.horizontal)
                                .background(Color.blue)
                                .cornerRadius(5)
                        })
                    }
                } else if !allAssets.isEmpty{
                    HStack{

                        Text("Pick a Image")
                            .fontWeight(.bold)

                        Spacer()
                    }
                    .padding(.leading)
                    .padding(.top)

                    StaggeredGrid(columns: 2, spacing:5, list: allAssets, content: { asset in
                        ImagePickerCard(data: PhotoPickerAssetViewModel(asset), selected: self.$selected)
                    }).padding()

                    Button(action: {

                        self.show.toggle()

                    }) {

                        Text("Select")
                            .foregroundColor(.white)
                            .padding(.vertical,10)
                            .frame(width: UIScreen.main.bounds.width / 2)
                    }
                    .background(Color.red.opacity((self.selected.count != 0) ? 1 : 0.5))
                    .clipShape(Capsule())
                    .padding(.bottom)
                    .disabled((self.selected.count != 0) ? false : true)

                }

            }
            .frame(width: UIScreen.main.bounds.width - 40, height: UIScreen.main.bounds.height / 1.5)
            .background(Color.white)
            .cornerRadius(12)
        }
        .background(Color.black.opacity(0.5).edgesIgnoringSafeArea(.all))
        .onAppear {
            DeviceImageFetcher.shared.setupIfNeeded()
        }.onReceive(deviceImageFetcher.$fetchedAssets, perform: { fetchedAssets in
            allAssets = fetchedAssets.filter {
                $0.asset.mediaType == inputType.mediaType()
            }
        })
        
    }
}
