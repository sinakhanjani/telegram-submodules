//
//  Multipart.swift.swift
//  Telegram
//
//  Created by Sina Khanjani on 10/14/25.
//

import Foundation

public struct MultipartPart {
    public enum Value {
        case text(String)
        case data(Data, filename: String?, mimeType: String?)
    }

    public let name: String
    public let value: Value

    public init(name: String, value: Value) {
        self.name = name
        self.value = value
    }
}

public struct MultipartBody {
    public let data: Data
    public let contentType: String
}

public enum MultipartBuilder {
    public static func build(parts: [MultipartPart], boundary: String = "Boundary-\(UUID().uuidString)") throws -> MultipartBody {
        var body = Data()
        let lineBreak = "\r\n"

        func append(_ string: String) {
            if let d = string.data(using: .utf8) { body.append(d) }
        }

        for part in parts {
            append("--\(boundary)\(lineBreak)")
            switch part.value {
            case .text(let text):
                append("Content-Disposition: form-data; name=\"\(part.name)\"\(lineBreak)\(lineBreak)")
                append(text)
                append(lineBreak)
            case .data(let data, let filename, let mimeType):
                let fn = filename ?? "blob"
                let mt = mimeType ?? "application/octet-stream"
                append("Content-Disposition: form-data; name=\"\(part.name)\"; filename=\"\(fn)\"\(lineBreak)")
                append("Content-Type: \(mt)\(lineBreak)\(lineBreak)")
                body.append(data)
                append(lineBreak)
            }
        }
        append("--\(boundary)--\(lineBreak)")

        return MultipartBody(
            data: body,
            contentType: "multipart/form-data; boundary=\(boundary)"
        )
    }
}
