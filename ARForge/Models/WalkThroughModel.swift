//
//  WalkThroughModel.swift
//  ARForge
//
//  Created by ARForgeQA on 8/30/21.
//

import Foundation

struct WalkThroughModel {
    var imageName: String
    var title: String
    var detail: String?
    
    static func getWalkThroughModels() -> [WalkThroughModel] {
        return [
            WalkThroughModel(imageName: "wt1", title: "Let's share you some simple guidelines for taking photos or videos"),
            WalkThroughModel(imageName: "wt2", title: "Capture photos or videos from all sides", detail: "We need atleast 20 photos with more than 70% overlap or a 10 sec turntable video"),
            WalkThroughModel(imageName: "wt3", title: "Keep your backgroud clear", detail: "Have a static and ideally clear backgroud. Feel free to crop your videos or photos to just focus on the object"),
            WalkThroughModel(imageName: "wt1", title: "Ensure sufficient and consistent lighting", detail: "Avoid shadows and bright lights"),
            WalkThroughModel(imageName: "wt2", title: "Avoid traslucent and reflective objects"),
            WalkThroughModel(imageName: "wt3", title: "You are all set !")
        ]
    }
}
