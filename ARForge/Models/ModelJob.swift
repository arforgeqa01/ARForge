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
    case unknown
    
    var isBuyable: Bool {
        return self == .finished
    }
    
    var isDeletable: Bool {
        switch self {
        case .finished, .failed:
            return true
        default:
            return false
        }
    }
}

enum ModelType: String, CaseIterable {
    case preview
    case reduced
    case medium
    case full
    
    var cost: Int {
        switch self {
        case .preview:
            return 4
        case .reduced:
            return 6
        case .medium:
            return 8
        case .full:
            return 10
        }
    }
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
        case status
        case conversionType
    }
    
    init(from decoder:Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        buy = try values.decode(Bool.self, forKey: .buy)
        lut = try values.decode(Double.self, forKey: .lut)
        ts = try values.decode(Double.self, forKey: .ts)
        id = try values.decode(String.self, forKey: .id)
        
        status = Status.initial
        if let st = try? values.decode(String.self, forKey: .st) {
            status = Status(rawValue: st)!
        }
        if let status = try? values.decode(String.self, forKey: .status) {
            self.status = Status(rawValue: status)!
        }
        
        
        modelType = ModelType.medium
        if let mt = try? values.decode(String.self, forKey: .mt) {
            modelType = ModelType(rawValue: mt)!
        }
        if let conversionType = try? values.decode(String.self, forKey: .conversionType) {
            modelType = ModelType(rawValue: conversionType)!
        }

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
    
    var modelThumbnail: URL {
        if self.status == .finished {
            return URL(string: "https://cdn.arforge.app/file/arforge/\(id)_modelThumb.png")!
        }
        return coverImageURL
    }
}

struct UserInfo: Decodable {
    var coins: Int
    var email: String?
    var name: String?
}

struct UserModel: Decodable {
    var coins: Int
    var email: String?
    var name: String?
    
    var docIDs: [String: ModelJob]

    func getModels() -> [ModelJob] {
        var jobs = Array(docIDs.values)
        jobs.sort { $1.ts < $0.ts }
        
        return jobs
    }
    
    func getUserInfo() -> UserInfo {
        UserInfo(coins: coins, email: email, name: name)
    }
}
