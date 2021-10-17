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

enum ModelType: String, CaseIterable {
    case preview
    case reduced
    case medium
    case full
}

struct ModelJob: Identifiable, Hashable, Decodable {
    var buy: Bool
    var lut: Double
    var id: String
    var ts: Double
    var modelType: ModelType
    var status: Status
    
    private enum CodingKeys: String, CodingKey {
        case buy
        case lut
        case id
        case st
        case mt
        case ts
    }
    
    init(from decoder:Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        buy = try values.decode(Bool.self, forKey: .buy)
        lut = try values.decode(Double.self, forKey: .lut)
        ts = try values.decode(Double.self, forKey: .ts)
        id = try values.decode(String.self, forKey: .id)
        let st = try values.decode(String.self, forKey: .st)
        status = Status(rawValue: st)!
        let mt = try values.decode(String.self, forKey: .mt)
        modelType = ModelType(rawValue: mt)!
    }
    
    
    var coverImageURL: URL {
        URL(string: "https://cdn.arforge.app/file/arforge/\(id)_cover")!
    }
    
    var usdzURL: URL {
        URL(string: "https://cdn.arforge.app/file/arforge/\(id).usdz")!
    }
    
    var glbURL: URL {
        URL(string: "https://cdn.arforge.app/file/arforge/\(id).glb")!
    }
    
}

struct UserInfo: Decodable {
    var coins: Int
    var email: String
    var name: String
}

struct UserModel: Decodable {
    var coins: Int
    var email: String
    var name: String
    
    var docIDs: [String: ModelJob]

    func getModels() -> [ModelJob] {
        var jobs = Array(docIDs.values)
        jobs.sort { $1.ts > $0.ts }
        
        return jobs
    }
    
    func getUserInfo() -> UserInfo {
        UserInfo(coins: coins, email: email, name: name)
    }
}
