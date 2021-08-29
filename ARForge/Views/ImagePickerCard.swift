//
//  ImagePickerCard.swift
//  ARForge
//
//  Created by ARForgeQA on 9/1/21.
//


import SwiftUI
import Photos



struct PhotoPickerAssetViewModel: Hashable {
    
    var image : UIImage
    var selected : Bool
    var asset : PHAsset
    
    init(_ asset: Asset) {
        self.image = asset.image
        self.asset = asset.asset
        self.selected = false
    }
}

struct ImagePickerCard : View {
    
    @State var data : PhotoPickerAssetViewModel
    @Binding var selected : [Asset]
    
    var body: some View{
        
        ZStack{
            
            Image(uiImage: self.data.image)
                .resizable()
                .aspectRatio(contentMode: .fit)
            
            if self.data.selected{
                
                ZStack{
                    
                    Color.black.opacity(0.5)
                    
                    Image(systemName: "checkmark")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.white)
                }
            }
            
        }
        .onTapGesture {
            
            
            if !self.data.selected{
                
                
                self.data.selected = true
                
                self.selected.append(Asset(asset: self.data.asset, image: self.data.image))
                
            }
            else{
                
                for i in 0..<self.selected.count{
                    
                    if self.selected[i].asset == self.data.asset{
                        
                        self.selected.remove(at: i)
                        self.data.selected = false
                        return
                    }
                    
                }
            }
        }
        
    }
}
