import CoreText
import Foundation

enum AppFontRegistrar {
    static func registerJersey25() {
        guard let fontURL = Bundle.main.url(forResource: "Jersey25-Regular", withExtension: "ttf") else {
            return
        }

        CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
    }
}
