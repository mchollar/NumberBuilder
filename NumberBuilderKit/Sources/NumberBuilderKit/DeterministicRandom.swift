/// A seeded, deterministic `RandomNumberGenerator` (the standard SplitMix64 algorithm) — used
/// wherever the same "random" sequence must reproduce identically across processes and devices,
/// which Swift's default generator and `String.hashValue` (randomized per process) cannot do.
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

enum StableHash {
    /// FNV-1a (64-bit) over the string's UTF-8 bytes. Deliberately not `String.hashValue`,
    /// which Swift randomizes per process for hash-DoS resistance and so is unsuitable for
    /// anything that must reproduce the same value across launches, devices, or years.
    static func fnv1a(_ string: String) -> UInt64 {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        let prime: UInt64 = 0x0000_0100_0000_01B3
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* prime
        }
        return hash
    }
}
