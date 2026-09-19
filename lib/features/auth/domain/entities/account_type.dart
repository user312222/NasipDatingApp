/// FR-8.1: chosen right after the invite-code gate, permanent for the
/// life of the account. Everything downstream (profile creation,
/// matching, messaging) is only ever reachable by [single] accounts —
/// [guardian] accounts are routed into the read-only family-link flow
/// instead (see `features/family/`).
enum AccountType { single, guardian }
