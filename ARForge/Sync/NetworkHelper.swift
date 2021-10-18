//
//  NetworkHelper.swift
//  ARForge
//
//  Created by ARForgeQA on 9/2/21.
//

import Foundation
import Combine

enum NetworkError: Error {
    case failure(String)
    case encodingError
    case serverConnectionError
    case unknown
    
    var localizedDescription: String {
        return self.description
    }
    
    var description: String {
        switch self {
        case .serverConnectionError:
            return "Server Connection Error"
        case .unknown:
            return "Unknown"
        case .encodingError:
            return "EncodingError"
        case .failure(let res):
            return res
        }
    }
}

enum FirebaseEndpoint {
    case getUserObj
    case createJobRequest(Data)
    case updateJobRequest(Data)
    case addCoinsWithAppleReceipt(Data)
    case buyModelRequest(Data)
    case deleteJobRequest(Data)
    
    func urlRequest(token:String?) -> URLRequest? {
        let baseUrl = "https://us-central1-doc-6d1fc.cloudfunctions.net/"
        
        var finalUrlReq: URLRequest? = nil
        switch self {
        case .getUserObj:
            finalUrlReq = URLRequest(url: URL(string: baseUrl+"getUserObj")!)
        case .createJobRequest(let jsonData):
            finalUrlReq = URLRequest(url: URL(string: baseUrl+"createJobRequest")!)
            finalUrlReq?.httpBody = jsonData
            finalUrlReq?.httpMethod = "POST"
            finalUrlReq?.setValue("application/json", forHTTPHeaderField: "content-type")
        case .addCoinsWithAppleReceipt(let jsonData):
            finalUrlReq = URLRequest(url: URL(string: baseUrl+"addCoinsWithAppleReceipt")!)
            finalUrlReq?.httpBody = jsonData
            finalUrlReq?.httpMethod = "POST"
            finalUrlReq?.setValue("application/json", forHTTPHeaderField: "content-type")
        case .updateJobRequest(let jsonData):
            finalUrlReq = URLRequest(url: URL(string: baseUrl+"updateJobRequest")!)
            finalUrlReq?.httpBody = jsonData
            finalUrlReq?.httpMethod = "POST"
            finalUrlReq?.setValue("application/json", forHTTPHeaderField: "content-type")
        case .buyModelRequest(let jsonData):
            finalUrlReq = URLRequest(url: URL(string: baseUrl+"buyModelRequest")!)
            finalUrlReq?.httpBody = jsonData
            finalUrlReq?.httpMethod = "POST"
            finalUrlReq?.setValue("application/json", forHTTPHeaderField: "content-type")
        case .deleteJobRequest(let jsonData):
            finalUrlReq = URLRequest(url: URL(string: baseUrl+"deleteJobRequest")!)
            finalUrlReq?.httpBody = jsonData
            finalUrlReq?.httpMethod = "POST"
            finalUrlReq?.setValue("application/json", forHTTPHeaderField: "content-type")
        }
        
        guard var finalUrlReq = finalUrlReq,
              let token = token else {
            return nil
        }
        
        finalUrlReq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return finalUrlReq
    }
}


protocol UseCase {
    func start()
}

class FileUploader: NSObject {
    
    static func uploadPulisher(
        request: URLRequest,
        fileData: Data
    ) -> AnyPublisher<Data?, Error> {
        let subject: PassthroughSubject<Data?, Error> = .init()
        let task: URLSessionUploadTask = URLSession.shared.uploadTask(with: request, from: fileData){ data, response, error in
            if let error = error {
                subject.send(completion: .failure(error))
                return
            }
            if (response as? HTTPURLResponse)?.statusCode == 200 {
                subject.send(data)
                return
            }
            subject.send(nil)
        }
        task.resume()
        return subject
            .eraseToAnyPublisher()
    }
    
}

/*
curl 'https://us-central1-doc-6d1fc.cloudfunctions.net/createJobRequest' \
  -H 'authority: us-central1-doc-6d1fc.cloudfunctions.net' \
  -H 'pragma: no-cache' \
  -H 'cache-control: no-cache' \
  -H 'sec-ch-ua: "Chromium";v="92", " Not A;Brand";v="99", "Google Chrome";v="92"' \
  -H 'authorization: Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6IjJjZGFiZDIwNzVjODQxNDI0NDY3MTNlM2U0NGU5ZDcxOGU3YzJkYjQiLCJ0eXAiOiJKV1QifQ.eyJuYW1lIjoiS2V2aW4gUGF0ZWwiLCJwaWN0dXJlIjoiaHR0cHM6Ly9saDMuZ29vZ2xldXNlcmNvbnRlbnQuY29tL2EtL0FPaDE0R2diQlFfbm9CVWUzaldSc0dyMGFUZG9Wb29Ec05vZ25uZVJNaGhpPXM5Ni1jIiwiaXNzIjoiaHR0cHM6Ly9zZWN1cmV0b2tlbi5nb29nbGUuY29tL2RvYy02ZDFmYyIsImF1ZCI6ImRvYy02ZDFmYyIsImF1dGhfdGltZSI6MTYzMDI3NDAxMSwidXNlcl9pZCI6Im5NbjRFdUpvYWZVeW5uM0JQWHlNZGFTRnVCRDMiLCJzdWIiOiJuTW40RXVKb2FmVXlubjNCUFh5TWRhU0Z1QkQzIiwiaWF0IjoxNjMwNjE3MTU0LCJleHAiOjE2MzA2MjA3NTQsImVtYWlsIjoia2V2aW5Ad2hlZWFwcC1pbmMuY29tIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsImZpcmViYXNlIjp7ImlkZW50aXRpZXMiOnsiZ29vZ2xlLmNvbSI6WyIxMDg2NTk1Njg5NzgzMTUxNjgwODciXSwiZW1haWwiOlsia2V2aW5Ad2hlZWFwcC1pbmMuY29tIl19LCJzaWduX2luX3Byb3ZpZGVyIjoiZ29vZ2xlLmNvbSJ9fQ.IdKlQuniK-ARXbey4OD-8H44EKwSCqWB86isC144VpXq6wDiHU052tPOU5Mi3ufc_oM67_zwc0HyhzKCMQagA6aDmSpojEvHBraotrtQzXouPDW32_SQvha1kwWswvgsuEXW6OiMjG1Nt5U4iEGcvp_m-kYhxCV0VtVG2TDzhoUT7QphcDD56ON0YdXJF0Wb2xNcky57sLdh9j-eU25kysizd311XK-S4nA4PeESgNidFED-KqFx_eRHvpJtFoeA-_mu9iqNz0UpIkIC9d-miJucuGTJU1HEfoq494BBWhg8BCnbWy2GoVLE0WDQSjzgbwKjMdNO8Y57fKPyT9GlDA' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.159 Safari/537.36' \
  -H 'content-type: application/json;charset=UTF-8' \
  -H 'origin: https://arforge.app' \
  -H 'sec-fetch-site: cross-site' \
  -H 'sec-fetch-mode: cors' \
  -H 'sec-fetch-dest: empty' \
  -H 'referer: https://arforge.app/' \
  -H 'accept-language: en-US,en;q=0.9' \
  --data-raw '{"count":2,"jobType":"video","conversionType":"medium"}' \
  --compressed
 {"newJob":{"id":"mmEiVoCOSXLrrwkVAP2g","lut":1630618162341,"ts":1630618162341,"count":2,"status":"initial","conversionType":"medium","userID":"nMn4EuJoafUynn3BPXyMdaSFuBD3","jobType":"video"},"uploadUrls":[{"authorizationToken":"4_002e643010c93ac0000000001_019eb5a9_019269_upld_P9DR79BbrfT4-iqivu5IV-B6bBM=","uploadUrl":"https://pod-000-1141-05.backblaze.com/b2api/v2/b2_upload_file/0ed664b3206160ac79b30a1c/c002_v0001141_t0008","name":"mmEiVoCOSXLrrwkVAP2g_cover","bucketId":"0ed664b3206160ac79b30a1c"},{"authorizationToken":"4_002e643010c93ac0000000001_019eb5a9_031faf_upld_hsGG2hfuX-ND9pxB9eMEF6Tnq8k=","uploadUrl":"https://pod-000-1164-04.backblaze.com/b2api/v2/b2_upload_file/0ed664b3206160ac79b30a1c/c002_v0001164_t0035","name":"mmEiVoCOSXLrrwkVAP2g_input_1","bucketId":"0ed664b3206160ac79b30a1c"},{"authorizationToken":"4_002e643010c93ac0000000001_019eb5a9_e8cbbc_upld_5wH9suFNLM7nVQ2XTqGEskRAYNM=","uploadUrl":"https://pod-000-1163-12.backblaze.com/b2api/v2/b2_upload_file/0ed664b3206160ac79b30a1c/c002_v0001163_t0039","name":"mmEiVoCOSXLrrwkVAP2g_input_2","bucketId":"0ed664b3206160ac79b30a1c"}]}
 
 
curl 'https://us-central1-doc-6d1fc.cloudfunctions.net/updateJobRequest' \
  -H 'authority: us-central1-doc-6d1fc.cloudfunctions.net' \
  -H 'pragma: no-cache' \
  -H 'cache-control: no-cache' \
  -H 'sec-ch-ua: "Chromium";v="92", " Not A;Brand";v="99", "Google Chrome";v="92"' \
  -H 'authorization: Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6IjJjZGFiZDIwNzVjODQxNDI0NDY3MTNlM2U0NGU5ZDcxOGU3YzJkYjQiLCJ0eXAiOiJKV1QifQ.eyJuYW1lIjoiS2V2aW4gUGF0ZWwiLCJwaWN0dXJlIjoiaHR0cHM6Ly9saDMuZ29vZ2xldXNlcmNvbnRlbnQuY29tL2EtL0FPaDE0R2diQlFfbm9CVWUzaldSc0dyMGFUZG9Wb29Ec05vZ25uZVJNaGhpPXM5Ni1jIiwiaXNzIjoiaHR0cHM6Ly9zZWN1cmV0b2tlbi5nb29nbGUuY29tL2RvYy02ZDFmYyIsImF1ZCI6ImRvYy02ZDFmYyIsImF1dGhfdGltZSI6MTYzMDI3NDAxMSwidXNlcl9pZCI6Im5NbjRFdUpvYWZVeW5uM0JQWHlNZGFTRnVCRDMiLCJzdWIiOiJuTW40RXVKb2FmVXlubjNCUFh5TWRhU0Z1QkQzIiwiaWF0IjoxNjMwNjE3MTU0LCJleHAiOjE2MzA2MjA3NTQsImVtYWlsIjoia2V2aW5Ad2hlZWFwcC1pbmMuY29tIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsImZpcmViYXNlIjp7ImlkZW50aXRpZXMiOnsiZ29vZ2xlLmNvbSI6WyIxMDg2NTk1Njg5NzgzMTUxNjgwODciXSwiZW1haWwiOlsia2V2aW5Ad2hlZWFwcC1pbmMuY29tIl19LCJzaWduX2luX3Byb3ZpZGVyIjoiZ29vZ2xlLmNvbSJ9fQ.IdKlQuniK-ARXbey4OD-8H44EKwSCqWB86isC144VpXq6wDiHU052tPOU5Mi3ufc_oM67_zwc0HyhzKCMQagA6aDmSpojEvHBraotrtQzXouPDW32_SQvha1kwWswvgsuEXW6OiMjG1Nt5U4iEGcvp_m-kYhxCV0VtVG2TDzhoUT7QphcDD56ON0YdXJF0Wb2xNcky57sLdh9j-eU25kysizd311XK-S4nA4PeESgNidFED-KqFx_eRHvpJtFoeA-_mu9iqNz0UpIkIC9d-miJucuGTJU1HEfoq494BBWhg8BCnbWy2GoVLE0WDQSjzgbwKjMdNO8Y57fKPyT9GlDA' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.159 Safari/537.36' \
  -H 'content-type: application/json;charset=UTF-8' \
  -H 'origin: https://arforge.app' \
  -H 'sec-fetch-site: cross-site' \
  -H 'sec-fetch-mode: cors' \
  -H 'sec-fetch-dest: empty' \
  -H 'referer: https://arforge.app/' \
  -H 'accept-language: en-US,en;q=0.9' \
  --data-raw '{"jobID":"mmEiVoCOSXLrrwkVAP2g","jobStatus":"inputUploaded"}' \
  --compressed

 {"job":{"id":"mmEiVoCOSXLrrwkVAP2g","lut":1630618180069,"ts":1630618162341,"count":2,"status":"inputUploaded","conversionType":"medium","userID":"nMn4EuJoafUynn3BPXyMdaSFuBD3","jobType":"video"}}
 
curl 'https://us-central1-doc-6d1fc.cloudfunctions.net/getUserObj' \
  -H 'authority: us-central1-doc-6d1fc.cloudfunctions.net' \
  -H 'pragma: no-cache' \
  -H 'cache-control: no-cache' \
  -H 'sec-ch-ua: "Chromium";v="92", " Not A;Brand";v="99", "Google Chrome";v="92"' \
  -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.159 Safari/537.36' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'authorization: Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6IjJjZGFiZDIwNzVjODQxNDI0NDY3MTNlM2U0NGU5ZDcxOGU3YzJkYjQiLCJ0eXAiOiJKV1QifQ.eyJuYW1lIjoiS2V2aW4gUGF0ZWwiLCJwaWN0dXJlIjoiaHR0cHM6Ly9saDMuZ29vZ2xldXNlcmNvbnRlbnQuY29tL2EtL0FPaDE0R2diQlFfbm9CVWUzaldSc0dyMGFUZG9Wb29Ec05vZ25uZVJNaGhpPXM5Ni1jIiwiaXNzIjoiaHR0cHM6Ly9zZWN1cmV0b2tlbi5nb29nbGUuY29tL2RvYy02ZDFmYyIsImF1ZCI6ImRvYy02ZDFmYyIsImF1dGhfdGltZSI6MTYzMDI3NDAxMSwidXNlcl9pZCI6Im5NbjRFdUpvYWZVeW5uM0JQWHlNZGFTRnVCRDMiLCJzdWIiOiJuTW40RXVKb2FmVXlubjNCUFh5TWRhU0Z1QkQzIiwiaWF0IjoxNjMwNjE3MTU0LCJleHAiOjE2MzA2MjA3NTQsImVtYWlsIjoia2V2aW5Ad2hlZWFwcC1pbmMuY29tIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsImZpcmViYXNlIjp7ImlkZW50aXRpZXMiOnsiZ29vZ2xlLmNvbSI6WyIxMDg2NTk1Njg5NzgzMTUxNjgwODciXSwiZW1haWwiOlsia2V2aW5Ad2hlZWFwcC1pbmMuY29tIl19LCJzaWduX2luX3Byb3ZpZGVyIjoiZ29vZ2xlLmNvbSJ9fQ.IdKlQuniK-ARXbey4OD-8H44EKwSCqWB86isC144VpXq6wDiHU052tPOU5Mi3ufc_oM67_zwc0HyhzKCMQagA6aDmSpojEvHBraotrtQzXouPDW32_SQvha1kwWswvgsuEXW6OiMjG1Nt5U4iEGcvp_m-kYhxCV0VtVG2TDzhoUT7QphcDD56ON0YdXJF0Wb2xNcky57sLdh9j-eU25kysizd311XK-S4nA4PeESgNidFED-KqFx_eRHvpJtFoeA-_mu9iqNz0UpIkIC9d-miJucuGTJU1HEfoq494BBWhg8BCnbWy2GoVLE0WDQSjzgbwKjMdNO8Y57fKPyT9GlDA' \
  -H 'origin: https://arforge.app' \
  -H 'sec-fetch-site: cross-site' \
  -H 'sec-fetch-mode: cors' \
  -H 'sec-fetch-dest: empty' \
  -H 'referer: https://arforge.app/' \
  -H 'accept-language: en-US,en;q=0.9' \
  --compressed
 {"id":"nMn4EuJoafUynn3BPXyMdaSFuBD3","lut":1630618666108,"ts":1629501252533,"profileImageUrl":null,"fcmTokens":{},"docIDs":{"rK0nbXSRS9ENTkiPakC5":"finished","Bbyx3AY1HVEkfG7cFM5s":"finished","lcenDdIMwEbR0YpsgNwP":"finished","mCYcBPHlSaiMMRyshlzE":"finished","czHbm7LnUo2Wt2cHPpvT":"inProgress","ONhzcbYwTlw5ZSLwEOHx":"finished","lQSdAdSYCyZya2W2SGro":"finished","YYwRI0FnRYx0fVslFEJE":"finished","wEJcjhPcnlPvRa4arYxZ":"finished","TDsXV5Is7JTWNyhxsffX":"finished","XHkiMKe28PjybPlzITcB":"finished","jFCZ3Gs3yxSceSjyorpa":"finished","KA6jTrHSZhAn0K8r4Fhd":"finished","mmEiVoCOSXLrrwkVAP2g":"finished","rOrwx5cJxNpfWgYjNMQn":"finished"},"email":"ARForgeQA@wheeapp-inc.com","name":"ARForge QA"}
*/
