//
//  View+.swift
//  OllamaChat
//
//  Created by Roger on 2024/2/15.
//

import Foundation
import SwiftUI

extension View {

    public func asAnyView() -> AnyView {
        AnyView(self)
    }

    public func maxFrame(alignment: Alignment = .center) -> some View {
        frame(
            minWidth: 0,
            maxWidth: .infinity,
            minHeight: 0,
            maxHeight: .infinity,
            alignment: alignment
        )
    }

    public func maxWidth(alignment: Alignment = .center) -> some View {
        frame(minWidth: 0, maxWidth: .infinity, alignment: alignment)
    }

    public func maxHeight(alignment: Alignment = .center) -> some View {
        frame(minHeight: 0, maxHeight: .infinity, alignment: alignment)
    }

    public func fixedHeight() -> some View {
        fixedSize(horizontal: false, vertical: true)
    }

    public func fixedWidth() -> some View {
        fixedSize(horizontal: true, vertical: false)
    }

    public func disableAnimation() -> some View {
        transaction { transaction in
            transaction.animation = nil
        }
    }

    @ViewBuilder
    public func widgetLink(enabled: Bool, _ url: URL?) -> some View {
        if enabled, let url = url {
            Link(destination: url) {
                self
            }
            .buttonStyle(.plain)
        } else {
            self
        }
    }

    public func continusCornerRadius(_ radius: CGFloat) -> some View {
        clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }

    public func continusCornerRadius(_ radius: CGFloat, strokeWidth: CGFloat, strokeColor: Color)
        -> some View
    {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        return clipShape(shape)
            .overlay(shape.stroke(strokeColor, lineWidth: strokeWidth))
    }

    @ViewBuilder
    public func isHidden(_ hidden: Bool) -> some View {
        if hidden {
            self.hidden()
        } else {
            self
        }
    }

}

// https://stackoverflow.com/a/64495887
struct ViewDidLoadModifier: ViewModifier {

    @State private var didLoad = false
    private let action: (() -> Void)?

    init(perform action: (() -> Void)? = nil) {
        self.action = action
    }

    func body(content: Content) -> some View {
        content.onAppear {
            if didLoad == false {
                didLoad = true
                action?()
            }
        }
    }

}

extension View {

    public func onLoad(perform action: (() -> Void)? = nil) -> some View {
        modifier(ViewDidLoadModifier(perform: action))
    }

}

extension View {

    public func ifGeometryGroup() -> some View {
        if #available(macOS 14, iOS 17.0, *) {
            return self.geometryGroup()
        } else {
            return self
        }
    }

}

extension View {

    public func ifTranslationPresentation(
        isPresented: Binding<Bool>,
        text: String,
        arrowEdge: Edge = .top
    ) -> some View {
        if #available(macOS 14.4, iOS 17.4, *) {
            return self.translationPresentation(
                isPresented: isPresented,
                text: text,
                arrowEdge: arrowEdge
            )
        } else {
            return self
        }
    }

}
