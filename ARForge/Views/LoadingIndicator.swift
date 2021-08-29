//
//  LoadingIndicator.swift
//  ARForge
//
//  Created by ARForgeQA on 9/1/21.
//

import SwiftUI


struct LoadingIndicator : UIViewRepresentable {
    
    var color = UIColor.black
    
    func makeUIView(context: Context) -> UIActivityIndicatorView  {
        
        let view = UIActivityIndicatorView(style: .large)
        view.color = self.color
        view.startAnimating()
        return view
    }
    
    func updateUIView(_ uiView:  UIActivityIndicatorView, context: Context) {
        
        
    }
}
