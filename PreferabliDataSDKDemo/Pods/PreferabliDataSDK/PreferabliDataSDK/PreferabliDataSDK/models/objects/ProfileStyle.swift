//
//  PreferenceStyle.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 12/6/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import CoreData

/// The profile style object links a ``Style`` to a user's ``Profile``. Unique for each customer.
public class ProfileStyle : BaseObject {
    
    /// Indicates if there is any ambiguity in the user's affinity for this style.
    public var conflict: Bool
    
    /// A ranking of 1..n which indicates where this style fits within its ``RatingType`` and ``ProductType`` where 1 indicates the highest level of appeal and n indicates the lowest.
    public var order_profile: NSNumber
    
    /// A ranking of 1..n which indicates where this style fits within its ``ProductType`` where 1 indicates the most recommendable and n indicates the least recommendable. 0 means the style is not recommendable.
    public var order_recommend: NSNumber
    public var style_id: NSNumber
    
    /// True if this style is recommendable for this user.
    public var recommend: Bool
    /// True if we could use some additional data from the user to better understand their affinity for this style.
    public var refine: Bool
    public var style: Style
    public var keywords: String?
    public var created_at: Date
    public var updated_at: Date

    /// The profile of the user where this profile style resides.
    public var profile: Profile
    
    /// Use this to compute ``RatingType``.
    internal var rating: NSNumber
    
    
    internal init(profile_style : CoreData_ProfileStyle, holding_profile : Profile) {
        conflict = profile_style.conflict
        order_profile = profile_style.order_profile
        order_recommend = profile_style.order_recommend
        rating = profile_style.rating
        style_id = profile_style.style_id
        recommend = profile_style.recommend
        refine = profile_style.refine
        style = Style.init(style: profile_style.style)
        keywords = profile_style.keywords
        created_at = profile_style.created_at
        updated_at = profile_style.updated_at
        profile = holding_profile
        super.init(id: profile_style.id)
    }
    
    /// The ``RatingType`` of this profile style.
    var rating_type : RatingType {
        return RatingType.getRatingTypeBasedOffTagValue(value: rating.stringValue)
    }
    
    /// Is a profile style unappealing?
    /// - Returns: true if unappealing.
    public func isUnappealing() -> Bool {
        return rating_type == RatingType.DISLIKE || rating_type == RatingType.SOSO
    }
    
    /// Is a profile style appealing?
    /// - Returns: true if appealing.
    public func isAppealing() -> Bool {
        return rating_type == RatingType.LOVE || rating_type == RatingType.LIKE
    }
    
    /// Sort profile styles by created at date.
    /// - Parameters:
    ///   - profile_styles: an array of profile styles to be sorted.
    ///   - comparison_result: can be ascending or descending. Defaults to *descending*.
    /// - Returns: a sorted array of profile styles.
    static public func sortProfileStylesByDate(profile_styles: [ProfileStyle], comparison_result: ComparisonResult = .orderedDescending) -> Array<ProfileStyle> {
        return profile_styles.sorted {
            return $0.created_at.compare($1.created_at) == comparison_result
            
        }
    }
    
    /// Sort profile styles alphabetically.
    /// - Parameters:
    ///   - profile_styles: an array of profile styles to be sorted.
    ///   - comparison_result: can be ascending or descending. Defaults to *descending*.
    /// - Returns: a sorted array of profile styles.
    static public func sortProfileeStylesAlpha(profile_styles: [ProfileStyle], comparison_result: ComparisonResult) -> Array<ProfileStyle> {
        return profile_styles.sorted {
            return PreferabliTools.alphaSortIgnoreThe(x: $0.style.name, y: $1.style.name, comparisonResult: comparison_result)
        }
    }
    
    /// Filter profile styles by some search term(s).
    /// - Parameters:
    ///   - profile_styles: an array of profile styles to be filtered.
    ///   - search_text: a search term string.
    /// - Returns: a filtered array of profile styles.
    static public func filterPreferenceStyles(profile_styles : Array<ProfileStyle>, search_text : String) -> Array<ProfileStyle> {
        var filteredProfileStyles = Array<ProfileStyle>()
        if (search_text.isEmptyOrWhitespace()) {
            filteredProfileStyles = profile_styles
        } else {
            let searchTerms = search_text.components(separatedBy: " ")
            filteredProfileStyles = profile_styles.filter() {
            innerloop:
                for searchTerm in searchTerms {
                    if ($0.filterPreferenceStyle(search_term: searchTerm)) {
                        continue
                    } else {
                        return false
                    }
                }
                return true
            }
        }
        return filteredProfileStyles
    }
    
    internal func filterPreferenceStyle(search_term : String) -> Bool {
        if (search_term.isEmptyOrWhitespace()) {
            return true
        } else if (style.name.containsIgnoreCase(search_term)) {
            return true
        } else if (keywords?.containsIgnoreCase(search_term) ?? false) {
            return true
        } else {
            return false
        }
    }
}
