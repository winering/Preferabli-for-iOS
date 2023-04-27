//
//  Media.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 11/14/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import CoreData
import UIKit

/// An image or video.
public class Media : BaseObject {
    
    public var created_at: Date?
    public var path: String
    public var type: String?
    
    internal init(map : [String : Any]) {
        created_at = map["created_at"] as? Date
        path = map["path"] as! String
        type = map["type"] as? String
        super.init(id: map["id"] as? NSNumber ?? NSNumber.init(value: 0))
    }
    
    internal init(media : CoreData_Media) {
        created_at = media.created_at
        path = media.path
        type = media.type
        super.init(id: media.id)
    }
    
    /// Get the media's path for display as an image. Only use if the media is an image.
    /// - Parameters:
    ///   - width: returns an image with the specified width in pixels.
    ///   - height: returns an image with the specified height in pixels.
    ///   - quality: returns an image with the specified quality. Scales from 0 - 100.
    /// - Returns: the URL of the requested image.
    public func getImage(width : CGFloat, height : CGFloat, quality : Int = 80) -> URL? {
        return PreferabliTools.getImageUrl(image: path, width: width, height: height, quality: quality)
    }
}
