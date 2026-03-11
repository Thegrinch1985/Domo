import SwiftUI

struct ItemsView: View {
    @State private var segment = 0

    var body: some View {
        if segment == 0 {
            AssetsView(segment: $segment)
        } else {
            DocumentsView(segment: $segment)
        }
    }
}

#Preview {
    ItemsView()
        .environmentObject(DomoStore())
}
