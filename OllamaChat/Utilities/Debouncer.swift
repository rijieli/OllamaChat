//
//  Debouncer.swift
//  OllamaChat
//
//  Created by Roger on 2025/3/2.
//  Copyright © 2025 IdeasForm. All rights reserved.
//


import Combine
import Foundation

public class Debouncer {
    private let subject = PassthroughSubject<Void, Never>()
    private var cancellable: AnyCancellable?

    public init(delay: TimeInterval) {
        cancellable =
            subject
            .debounce(for: .seconds(delay), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.action?()
            }
    }

    private var action: (() -> Void)?

    public func call(_ callback: @escaping () -> Void) {
        action = callback
        subject.send()
    }

    deinit {
        cancellable?.cancel()
    }
}
