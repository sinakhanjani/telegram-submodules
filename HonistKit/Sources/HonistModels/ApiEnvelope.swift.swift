//
//  ApiEnvelope.swift.swift
//  Telegram
//
//  Created by Sina Khanjani on 10/14/25.
//

import Foundation
import HonistFoundation

/// { "success": Bool, "data": T?, "message": String? }
public struct ApiEnvelope<T: Decodable>: Decodable {
    public let success: Bool
    public let data: T?
    public let message: String?
    
    public init(success: Bool, data: T?, message: String?) {
        self.success = success
        self.data = data
        self.message = message
    }
}

public struct Pagination: Decodable {
    public let page: Int
    public let limit: Int
    public let total: Int
    public let totalPages: Int
}

public struct ListPayload<Item: Decodable>: Decodable {
    public let items: [Item]
    public let pagination: Pagination?

    private struct Wrapped<I: Decodable>: Decodable {
        let pagination: Pagination?
        let items: [I]
    }

    private enum CodingKeys: String, CodingKey {
        case success, message, data, pagination
    }

    public init(items: [Item], pagination: Pagination?) {
        self.items = items
        self.pagination = pagination
    }

    public init(from decoder: Decoder) throws {
        // Attempt 1: { success, data: { pagination, items } }
        if let env = try? ApiEnvelope<Wrapped<Item>>.init(from: decoder), env.success {
            if let d = env.data {
                self.items = d.items
                self.pagination = d.pagination
                return
            } else {
                throw DecodingError.dataCorrupted(.init(codingPath: [],
                    debugDescription: "Envelope.success=true but data=nil"))
            }
        }

        // Attempt 2: { success, data: [Item], pagination: ? } (pagination at root level)
        if let container = try? decoder.container(keyedBy: CodingKeys.self),
           (try? container.decode(Bool.self, forKey: .success)) == true,
           let arr = try? container.decode([Item].self, forKey: .data) {
            let pag = try? container.decode(Pagination.self, forKey: .pagination)
            self.items = arr
            self.pagination = pag
            return
        }

        // Attempt 3: { success, data: [Item] } (no pagination)
        if let envArr = try? ApiEnvelope<[Item]>.init(from: decoder), envArr.success {
            self.items = envArr.data ?? []
            self.pagination = nil
            return
        }

        throw DecodingError.dataCorrupted(.init(codingPath: [],
            debugDescription: "Unsupported list payload shape"))
    }
}

    /*
     // Example:
     GET /api/v1/shop/offers
     {
       "success": true,
       "data": [
         {
           "id": "6bd2d226-4773-4a00-bf24-13ac21e7d91c",
           "type": "subscription_quota",
           "title": "Weekly Starter Pack",
           "base_price_cents": 499
         }
       ],
       "pagination": {
         "page": 1,
         "limit": 100,
         "total": 1,
         "totalPages": 1
       }
     }
     
     public struct OfferDTO: Decodable {
         public let id: String
         public let type: String
         public let title: String
         public let basePriceCents: Int
     }
     
     let api = HonistApiClient(tokenProvider: myTokenProvider)

     do {
         let response: ListPayload<OfferDTO> = try await api.getList(
             "/api/v1/shop/offers",
             query: ["page": 1, "limit": 20]
         )
         
         print("✅ Total items:", response.items.count)
         print("📄 Page:", response.pagination?.page ?? 1)
         
         for offer in response.items {
             print("🛍️ \(offer.title) – \(offer.basePriceCents)¢")
         }

     } catch {
         print("❌ Error:", error.localizedDescription)
     }
     */
