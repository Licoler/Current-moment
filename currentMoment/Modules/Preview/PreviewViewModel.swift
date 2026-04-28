import Combine
import Foundation
import UIKit

@MainActor
final class PreviewViewModel {
    @Published private(set) var recipients: [User] = []
    @Published private(set) var selectedRecipientIDs: Set<String> = []
    @Published private(set) var isSending = false
    @Published private(set) var errorMessage: String?
    @Published var caption: String = ""

    let asset: CapturedMomentAsset

    private let repository: CurrentMomentRepositoryProtocol
    private let imagePipeline: ImagePipeline
    private var cancellables: Set<AnyCancellable> = []

    init(repository: CurrentMomentRepositoryProtocol, imagePipeline: ImagePipeline, asset: CapturedMomentAsset) {
        self.repository = repository
        self.imagePipeline = imagePipeline
        self.asset = asset

        repository.friendsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] friends in
                guard let self else { return }
                self.recipients = friends
                if self.selectedRecipientIDs.isEmpty {
                    self.selectedRecipientIDs = Set(friends.prefix(2).map(\.id))
                }
            }
            .store(in: &cancellables)
    }

    func isSelected(_ user: User) -> Bool {
        selectedRecipientIDs.contains(user.id)
    }

    func toggleRecipient(_ user: User) {
        if selectedRecipientIDs.contains(user.id) {
            selectedRecipientIDs.remove(user.id)
        } else {
            selectedRecipientIDs.insert(user.id)
        }
    }

    func send(completion: @escaping (Result<Moment, Error>) -> Void) {
        guard !isSending else { return }
        isSending = true
        errorMessage = nil

        let draft = MomentDraft(
            imageData: asset.imageData,
            thumbnailData: asset.thumbnailData,
            caption: caption.trimmingCharacters(in: .whitespacesAndNewlines),
            recipientIds: Array(selectedRecipientIDs),
            isLivePhoto: false
        )

        Task {
            do {
                let moment = try await repository.sendMoment(draft)
                isSending = false
                completion(.success(moment))
            } catch {
                isSending = false
                errorMessage = error.localizedDescription
                completion(.failure(error))
            }
        }
    }
}
