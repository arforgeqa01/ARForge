//
//  ModelJob.swift
//  ARForge
//
//  Created by ARForgeQA on 8/29/21.
//

import SwiftUI

enum Status: String {
    case finished
    case inputUploaded
    case inProgress
    case failed
    case initial
}

struct ModelJob: Identifiable, Hashable {
    var id: String
    var name: String
    var status: Status
    
    var coverImageURL: URL {
        URL(string: "https://cdn.arforge.app/file/arforge/\(id)_cover")!
    }
    
    var usdzURL: URL {
        URL(string: "https://cdn.arforge.app/file/arforge/\(id).usdz")!
    }
    
    static func convertToModels(dict: [String: String]) -> [ModelJob] {
        var retVal: [ModelJob] = []
        
        var counter = 1
        
        dict.forEach { (key: String, value: String) in
            retVal.append(ModelJob(id: key, name: "Model \(counter)", status: Status.init(rawValue: value)!))
            counter += 1
        }
        
        return retVal
    }
}
