//
//  ScrollView+.swift
//  OllamaChat
//
//  Created by Roger on 2025/10/20.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import SwiftUI
import SwiftUIIntrospect

extension View {
    public func introspectScrollView(scope: IntrospectionScope? = nil, customize: @escaping (NSScrollView) -> ()) -> some View {
        introspect(.scrollView, on: .macOS(.v13, .v14, .v15, .v26), scope: scope, customize: customize)
    }
}

extension ScrollView {
    @ViewBuilder
    func scrollViewClipsToBounds(_ bool: Bool) -> some View {
        if #available(macOS 14, *) {
            self.scrollClipDisabled(!bool)
        } else {
            self.introspectScrollView { v in
                v.clipsToBounds = bool
            }
        }
    }
}
