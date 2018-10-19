//
//  Purchase.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 10/19/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct Purchase: Codable {

    enum ModelType: String {
        case unknown = ""
        case track = "record"
    }

    let id: Int
    let parentId: Int?
    let orderId: Int
    let quantity: Int
    let price: Money?
    let createdAt: Date?
//    "attributes":null
//    "item_piece_id":13,
    let modelId: Int
    let modelType: ModelType
    let name: String
//    "images":[{"links":{"thumb":{"path":"https://d3k4p0lviij6pz.cloudfront.net/website/b557d080-c465-4392-bb59-2f088361e70e/image/thumb_brOvc2UXZmBIQ2T1kC0T.jpg","width":250,"height":215},"big":{"path":"https://d3k4p0lviij6pz.cloudfront.net/website/b557d080-c465-4392-bb59-2f088361e70e/image/big_YFaA2Rn4hffu2iXqkHkq.jpg","width":1324,"height":1142}}}],
//    "artist":{"name":"One local Artist2"},
//    "order_status":3,
//    "download_link":"https://d12jw7apbd2ayu.cloudfront.net/website/b557d080-c465-4392-bb59-2f088361e70e/audio_file/WOAsShYg0obHPE0kFruS.mp3"}

    enum CodingKeys: String, CodingKey {
        case id
        case parentId = "parent_id"
        case orderId = "order_id"
        case quantity
        case price
        case createdAt = "created_at"
        case modelId = "model_id"
        case modelType = "model_type"
        case name
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.parentId = try container.decodeIfPresent(Int.self, forKey: .parentId)
        self.orderId = try container.decode(Int.self, forKey: .orderId)
        self.quantity = try container.decode(Int.self, forKey: .quantity)

        let priceStringValue = try container.decode(String.self, forKey: .price)
        if let priceValue = Decimal(string: priceStringValue) {
            self.price = Money(value: priceValue, currency: .USD)
        } else {
            self.price = nil
        }

        let dateTimeFormatter = ModelSupport.sharedInstance.dateTimeFormattre
        self.createdAt = try container.decodeAsDate(String.self, forKey: .createdAt, dateFormatter: dateTimeFormatter)

        self.modelId = try container.decode(Int.self, forKey: .modelId)

        let modelTypeRawValue = try container.decode(String.self, forKey: .modelType)
        if let modelType = ModelType(rawValue: modelTypeRawValue) {
            self.modelType = modelType
        } else {
            self.modelType = .unknown
        }

        self.name = try container.decode(String.self, forKey: .name)
    }

    func encode(to encoder: Encoder) throws {
        
    }
}
