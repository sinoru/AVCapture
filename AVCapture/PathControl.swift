//
//  PathControl.swift
//  AVCapture
//
//  Created by Jaehong Kang on 2022/11/26.
//

#if os(macOS)

import SwiftUI
import AppKit
import Combine

struct PathControl: View {
    enum Style: Equatable, Hashable, Sendable {
        case standard
        case popUp
    }

    @Environment(\.isEnabled)
    private var isEnabled

    let allowedTypes: [String]?

    let style: Style
    @Binding var url: URL?

    init(allowedTypes: [String]? = nil, style: Style, url: Binding<URL?>) {
        self.allowedTypes = allowedTypes
        self.style = style
        self._url = url
    }
}

extension PathControl: NSViewRepresentable {
    typealias NSViewType = NSPathControl

    class Coordinator: NSObject {
        var anyCancellables: Set<AnyCancellable> = []
    }

    func makeCoordinator() -> Coordinator {
        .init()
    }

    func makeNSView(context: Context) -> NSViewType {
        let nsView = NSViewType(frame: .zero)

        nsView
            .publisher(for: \.url)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: \.url, on: self)
            .store(in: &context.coordinator.anyCancellables)

        return nsView
    }

    func updateNSView(_ nsView: NSViewType, context: Context) {
        nsView.isEditable = isEnabled
        nsView.pathStyle = style.nsPathControlStyle
        nsView.url = url
    }
}

extension PathControl.Style {
    fileprivate var nsPathControlStyle: NSPathControl.Style {
        switch self {
        case .standard:
            return .standard
        case .popUp:
            return .popUp
        }
    }
}

struct PathControl_Previews: PreviewProvider {
    static var previews: some View {
        PathControl(style: .standard, url: .constant(nil))

        PathControl(style: .popUp, url: .constant(nil))
    }
}

#endif
