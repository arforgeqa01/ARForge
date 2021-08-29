//
//  CreateModelJobUseCase.swift
//  ARForge
//
//  Created by ARForgeQA on 9/2/21.
//

import Foundation
import Combine

class CreateModelJobUseCase: UseCase {
    var jobState: CreateJobState
    var assets: [Asset]
    var conversionType: String
    var inputType: String
    
    var jobID: String?
    var subscriptions = Set<AnyCancellable>()
    
    func start() {
        FirebaseState.shared.firebaseUser?.getIDToken(completion: { [weak self] token, _ in
            guard let self = self,
                  let token = token else {
                return
            }
            
            self.startPublishers(token: token)
        });
    }
    
    func startPublishers(token: String) {
        self.jobState.res = .success(.uploading("Getting upload URLS"))
        
        let pub1 = self.getCreateJobPublisher(token: token)
            .receive(on: DispatchQueue.main)
            .tryMap { [weak self] res -> [UploadAsset]  in
                guard let self = self else {
                    throw NetworkError.unknown
                }
                
                switch res {
                case .failure(let error):
                    throw error
                case .success(let jobRes):
                    self.jobState.res = .success(.uploading("Uploading files"))
                    self.jobID = jobRes.newJob.id
                    return CreateModelJobUseCase.getUploadAssets(assets: self.assets, uploadData: jobRes.uploadUrls)
                }
            }
            .map { return $0.publisher }
            .flatMap { return $0 }
            .eraseToAnyPublisher()
            .map {
                self.getUploadFilePublisher(uploadAsset: $0)
            }
            .flatMap { $0 }
            .collect(self.assets.count + 1)
            .eraseToAnyPublisher()
        
        
        let pub2 = pub1.tryMap { results -> String in
            var passed = true
            results.forEach { res in
                if case .failure(_) = res {
                    passed = false
                }
            }
            guard passed,
                  let jobID = self.jobID
            else {
                throw NetworkError.unknown
            }
            
            self.jobState.res = .success(.uploading("Uploading Done! Adding the Job to the Queue"))
            return jobID
        }.map {
            return self.getUpdateJobPublisher(jobId: $0, token: token)
        }.flatMap {
            $0
        }.eraseToAnyPublisher()
        
        
        
        pub2.tryMap { result -> Result<CreateJobStateValue, NetworkError> in
            if case .failure(_) = result {
                throw NetworkError.unknown
            }
            return Result<CreateJobStateValue, NetworkError>.success(.success)
        }
        .replaceError(with: .failure(.unknown))
        .assign(to: \.res, on: self.jobState)
        .store(in: &self.subscriptions)
    }
    
    init(jobState: CreateJobState, assets: [Asset], conversionType: String, inputType: String) {
        self.jobState = jobState
        self.assets = assets
        self.conversionType = conversionType
        self.inputType = inputType
    }
}

extension CreateModelJobUseCase {
    struct UploadAsset {
        var asset: Asset
        var isThumbnail = false
        var uploadData: CreateJobResponse.UploadURLs
    }
    
    static func getUploadAssets(assets: [Asset], uploadData: [CreateJobResponse.UploadURLs]) -> [UploadAsset] {
        var newAssets: [UploadAsset] = []
        for i in 0..<uploadData.count {
            let asset = i == 0 ? assets[0]: assets[i-1]
            newAssets.append(UploadAsset(asset: asset, isThumbnail: i==0, uploadData: uploadData[i]))
        }
        return newAssets
    }
}

extension CreateModelJobUseCase {
    func getMockUploadFilePublisher(uploadAsset: UploadAsset) -> AnyPublisher<Result<String, NetworkError>, Never> {
        return Just(Result<String, NetworkError>.success("success")).eraseToAnyPublisher()
    }
    
    func getUploadFilePublisher(uploadAsset: UploadAsset) -> AnyPublisher<Result<String, NetworkError>, Never>  {
        return DeviceImageFetcher.exportDataPublisher(asset: uploadAsset.asset, isThumbnail: uploadAsset.isThumbnail)
            .map { (data, contentType, sha1hash) -> AnyPublisher<Data?, Error> in
                let url = URL(string: uploadAsset.uploadData.uploadUrl)!
                let uploadAuthorizationToken = uploadAsset.uploadData.authorizationToken
                let fileName = uploadAsset.uploadData.name
                let contentType = contentType
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.addValue(uploadAuthorizationToken, forHTTPHeaderField: "Authorization")
                request.addValue(fileName, forHTTPHeaderField: "X-Bz-File-Name")
                request.addValue(contentType, forHTTPHeaderField: "Content-Type")
                request.addValue(sha1hash, forHTTPHeaderField: "X-Bz-Content-Sha1")
                request.addValue("unknown", forHTTPHeaderField: "X-Bz-Info-Author")

                return FileUploader.uploadPulisher(request: request, fileData: data)
            }
            .flatMap {
                $0
            }
            .map { _ -> Result<String, NetworkError> in
                return .success("Done")
            }
            .replaceError(with: .failure(.unknown))
            .eraseToAnyPublisher()
    }
}

extension CreateModelJobUseCase {
    struct UpdateJobReq: Codable {
        let jobID: String
        let jobStatus: String
    }
    
    func getMockUpdateJobPublisher(jobId: String, token: String) -> AnyPublisher<Result<String, NetworkError>, Never> {
        return Just(Result<String, NetworkError>.success("success")).eraseToAnyPublisher()
    }
    
    func getUpdateJobPublisher(jobId: String, token: String) -> AnyPublisher<Result<String, NetworkError>, Never> {
        
        let updateJobReq = UpdateJobReq(jobID: jobId, jobStatus: "inputUploaded")
        
        
        guard let data = try? JSONEncoder().encode(updateJobReq),
              let req = FirebaseEndpoint.updateJobRequest(data).urlRequest(token: token) else {
            return Just(Result<String, NetworkError>.failure(.unknown)).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: req)
            .receive(on: DispatchQueue.main)
            .map { _ in
                return Result<String, NetworkError>.success("success")
            }
            .replaceError(with: Result<String, NetworkError>.failure(.unknown))
            .eraseToAnyPublisher()
    }
}

extension CreateModelJobUseCase {
    struct CreateJobReq: Codable {
        let count: Int
        let jobType: String
        let conversionType: String
    }
    
    struct CreateJobResponse: Codable {
        let newJob: Job
        let uploadUrls: [UploadURLs]
        
        struct Job : Codable {
            let id: String
        }
        
        struct UploadURLs: Codable {
            let authorizationToken: String
            let uploadUrl: String
            let name: String
            let bucketId: String
        }
        
        static func getMockData() -> CreateJobResponse {
            let str = """
                {"newJob":{"id":"mmEiVoCOSXLrrwkVAP2g","lut":1630618162341,"ts":1630618162341,"count":2,"status":"initial","conversionType":"medium","userID":"nMn4EuJoafUynn3BPXyMdaSFuBD3","jobType":"video"},"uploadUrls":[{"authorizationToken":"4_002e643010c93ac0000000001_019eb5a9_019269_upld_P9DR79BbrfT4-iqivu5IV-B6bBM=","uploadUrl":"https://pod-000-1141-05.backblaze.com/b2api/v2/b2_upload_file/0ed664b3206160ac79b30a1c/c002_v0001141_t0008","name":"mmEiVoCOSXLrrwkVAP2g_cover","bucketId":"0ed664b3206160ac79b30a1c"},{"authorizationToken":"4_002e643010c93ac0000000001_019eb5a9_031faf_upld_hsGG2hfuX-ND9pxB9eMEF6Tnq8k=","uploadUrl":"https://pod-000-1164-04.backblaze.com/b2api/v2/b2_upload_file/0ed664b3206160ac79b30a1c/c002_v0001164_t0035","name":"mmEiVoCOSXLrrwkVAP2g_input_1","bucketId":"0ed664b3206160ac79b30a1c"}]}
                """
            let data = str.data(using: .utf8)!
            return try! JSONDecoder().decode(CreateJobResponse.self, from: data)
        }
    }
    
    func getMockCreateJobPublisher(token: String) -> AnyPublisher<Result<CreateJobResponse, NetworkError>, Never> {
        return Just(Result<CreateJobResponse, NetworkError>.success(CreateJobResponse.getMockData()))
            .eraseToAnyPublisher()
    }
    
    func getCreateJobPublisher(token: String) -> AnyPublisher<Result<CreateJobResponse, NetworkError>, Never> {
        let createJobReq = CreateJobReq(count: assets.count, jobType: inputType, conversionType: conversionType)
        
        
        guard let data = try? JSONEncoder().encode(createJobReq),
              let req = FirebaseEndpoint.createJobRequest(data).urlRequest(token: token) else {
            return Just(Result<CreateJobResponse, NetworkError>.failure(.unknown)).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: req)
            .map(\.data)
            .handleEvents(receiveOutput: { data in
                print("ARForgeQADEBUG got the data \(String.init(data: data, encoding: .utf8))")
            })
            .decode(type: CreateJobResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .map {
                return Result<CreateJobResponse, NetworkError>.success($0)
            }
            .replaceError(with: Result<CreateJobResponse, NetworkError>.failure(.unknown))
            .eraseToAnyPublisher()
    }
}
