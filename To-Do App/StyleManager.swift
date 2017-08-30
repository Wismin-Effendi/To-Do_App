//
//  StyleManager.swift
//  To-Do App
//
//  Created by Wismin Effendi on 8/29/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation
import ChameleonFramework

typealias Style = StyleManager

//MARK: - StyleManager 

final class StyleManager {
    
    // MARK: - StyleManager
    
    static func setUpTheme() {
        Chameleon.setGlobalThemeUsingPrimaryColor(primaryTheme(), withSecondaryColor: theme(), usingFontName: font(), andContentStyle: content())
    }
    
    // MARK: - Theme
    
    static func primaryTheme() -> UIColor {
        return FlatOrange()
    }
    
    static func theme() -> UIColor {
        return FlatWhite()
    }
    
    static func toolBarTheme() -> UIColor {
        return FlatOrange()
    }
    
    static func tintTheme() -> UIColor {
        return FlatOrange()
    }
    
    static func titleTextTheme() -> UIColor {
        return FlatWhite()
    }
    
    static func titleTheme() -> UIColor {
        return FlatCoffeeDark()
    }
    
    static func textTheme() -> UIColor {
        return FlatOrange()
    }
    
    static func backgroudTheme() -> UIColor {
        return FlatWhite()
    }
    
    static func positiveTheme() -> UIColor {
        return FlatWhite()
    }
    
    static func negativeTheme() -> UIColor {
        return FlatRed()
    }
    
    static func clearTheme() -> UIColor {
        return UIColor.clear
    }
    
    // MARK: - Content
    
    static func content() -> UIContentStyle {
        return UIContentStyle.contrast
    }
    
    // MARK: - Font
    
    static func font() -> String {
        return UIFont(name: FontType.Primary.fontName, size: FontType.Primary.fontSize)!.fontName
    }
}

//MARK: - FontType

enum FontType {
    case Primary
}

extension FontType {
    var fontName: String {
        switch self {
        case .Primary:
            return "OpenSans-Regular"
        }
    }
    
    var fontSize: CGFloat {
        switch self {
        case .Primary:
            return 16
        }
    }
}
