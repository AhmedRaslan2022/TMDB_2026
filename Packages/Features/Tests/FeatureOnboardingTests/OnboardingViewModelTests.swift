//
//  OnboardingViewModelTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 26/07/2026.
//

import Testing
@testable import FeatureOnboarding

@MainActor
@Suite("OnboardingViewModel")
struct OnboardingViewModelTests {
    @MainActor
    private final class CompletionSpy: OnboardingCompletion {
        private(set) var completeCount = 0
        func completeOnboarding() {
            completeCount += 1
        }
    }

    private func pages(_ count: Int) -> [OnboardingPage] {
        (0 ..< count).map { OnboardingPage(id: $0, systemImage: "star", title: "T\($0)", message: "M\($0)") }
    }

    @Test("advance walks the slides, then completes on the last one")
    func advanceThenComplete() {
        let spy = CompletionSpy()
        let viewModel = OnboardingViewModel(pages: pages(3), completion: spy)

        viewModel.advance() // 0 -> 1
        #expect(viewModel.currentIndex == 1)
        #expect(spy.completeCount == 0)

        viewModel.advance() // 1 -> 2 (last)
        #expect(viewModel.currentIndex == 2)
        #expect(viewModel.isOnLastPage)
        #expect(spy.completeCount == 0)

        viewModel.advance() // finish
        #expect(spy.completeCount == 1)
    }

    @Test("skip completes immediately from any slide")
    func skipCompletes() {
        let spy = CompletionSpy()
        let viewModel = OnboardingViewModel(pages: pages(3), completion: spy)

        viewModel.skip()

        #expect(spy.completeCount == 1)
    }

    @Test("completion fires at most once")
    func completesOnce() {
        let spy = CompletionSpy()
        let viewModel = OnboardingViewModel(pages: pages(1), completion: spy)

        viewModel.advance() // single page is already last → finish
        viewModel.advance() // no-op
        viewModel.skip() // no-op

        #expect(spy.completeCount == 1)
    }

    @Test("isOnLastPage reflects the index")
    func lastPageFlag() {
        let viewModel = OnboardingViewModel(pages: pages(3), completion: CompletionSpy())

        #expect(!viewModel.isOnLastPage)
        viewModel.currentIndex = 2
        #expect(viewModel.isOnLastPage)
    }

    @Test("the default walkthrough has multiple slides")
    func defaultPages() {
        let viewModel = OnboardingViewModel(completion: CompletionSpy())
        #expect(viewModel.pages.count >= 2)
    }
}
