import SwiftUI

struct ContentView: View {
    init() {
        AppFontRegistrar.registerJersey25()
    }
    
    var body: some View {
        RootView()
    }
}
