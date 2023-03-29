//
//  PreferenceStyle.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 12/6/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import CoreData

/// The preference style object links a ``Style`` to a user's ``Profile``. Unique for each customer.
public class PreferenceStyle : BaseObject {
    
    public var conflict: Bool
    public var order_profile: NSNumber
    public var order_recommend: NSNumber
    public var rating: NSNumber
    public var strength: NSNumber
    public var style_id: NSNumber
    public var recommend: Bool
    public var refine: Bool
    public var style: Style
    public var keywords: String?
    public var created_at: Date
    public var profile: Profile
    
    internal init(preference_style : CoreData_PreferenceStyle, holding_profile : Profile) {
        conflict = preference_style.conflict
        order_profile = preference_style.order_profile
        order_recommend = preference_style.order_recommend
        rating = preference_style.rating
        strength = preference_style.strength
        style_id = preference_style.style_id
        recommend = preference_style.recommend
        refine = preference_style.refine
        style = Style.init(style: preference_style.style)
        keywords = preference_style.keywords
        created_at = preference_style.created_at
        profile = holding_profile
        super.init(id: preference_style.id)
    }
    
    /// Get the level of appeal of a preference style.
    /// - Returns: ``RatingType`` of the preference.
    public func getRatingType() -> RatingType {
        return RatingType.getRatingTypeBasedOffTagValue(value: rating.stringValue)
    }
    
    /// Is a preference style unappealing?
    /// - Returns: true if unappealing.
    public func isUnappealing() -> Bool {
        return getRatingType() == RatingType.DISLIKE || getRatingType() == RatingType.SOSO
    }
    
    /// Is a preference style appealing?
    /// - Returns: true if appealing.
    public func isAppealing() -> Bool {
        return getRatingType() == RatingType.LOVE || getRatingType() == RatingType.LIKE
    }
    
    /// Sort preference styles by created at date.
    /// - Parameters:
    ///   - preference_styles: an array of preference styles to be sorted.
    ///   - comparison_result: can be ascending or descending. Defaults to *descending*.
    /// - Returns: a sorted array of preference styles.
    static public func sortPreferenceStylesByDate(preference_styles: [PreferenceStyle], comparison_result: ComparisonResult = .orderedDescending) -> Array<PreferenceStyle> {
        return preference_styles.sorted {
            return $0.created_at.compare($1.created_at) == comparison_result
            
        }
    }
    
    /// Sort preference styles alphabetically.
    /// - Parameters:
    ///   - preference_styles: an array of preference styles to be sorted.
    ///   - comparison_result: can be ascending or descending. Defaults to *descending*.
    /// - Returns: a sorted array of preference styles.
    static public func sortPreferenceStylesAlpha(preference_styles: [PreferenceStyle], comparison_result: ComparisonResult) -> Array<PreferenceStyle> {
        return preference_styles.sorted {
            return PreferabliTools.alphaSortIgnoreThe(x: $0.style.name, y: $1.style.name, comparisonResult: comparison_result)
        }
    }
    
    /// Filter preference styles by some search term(s).
    /// - Parameters:
    ///   - preference_styles: an array of preference styles to be filtered.
    ///   - search_text: a search term string.
    /// - Returns: a filtered array of preference styles.
    static public func filterPreferenceStyles(preference_styles : Array<PreferenceStyle>, search_text : String) -> Array<PreferenceStyle> {
        var filteredPreferenceStyles = Array<PreferenceStyle>()
        if (search_text.isEmptyOrWhitespace()) {
            filteredPreferenceStyles = preference_styles
        } else {
            let searchTerms = search_text.components(separatedBy: " ")
            filteredPreferenceStyles = preference_styles.filter() {
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
        return filteredPreferenceStyles
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
