struct FeatureAUseCase {
    // Intentional leak for self-test:
    func mirror(_ other: FeatureBEntity) -> String { other.id }
}
