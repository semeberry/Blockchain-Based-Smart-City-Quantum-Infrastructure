;; Infrastructure Verification Contract
;; Validates quantum city systems and infrastructure components

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INVALID_INFRASTRUCTURE (err u101))
(define-constant ERR_ALREADY_VERIFIED (err u102))

;; Data structures
(define-map infrastructure-registry
  { infrastructure-id: (string-ascii 64) }
  {
    verified: bool,
    verification-timestamp: uint,
    verifier: principal,
    quantum-compatibility: bool,
    security-level: uint
  }
)

(define-map authorized-verifiers principal bool)

;; Initialize contract owner as authorized verifier
(map-set authorized-verifiers CONTRACT_OWNER true)

;; Public functions
(define-public (add-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (ok (map-set authorized-verifiers verifier true))
  )
)

(define-public (verify-infrastructure
  (infrastructure-id (string-ascii 64))
  (quantum-compatibility bool)
  (security-level uint))
  (let ((existing-record (map-get? infrastructure-registry { infrastructure-id: infrastructure-id })))
    (asserts! (default-to false (map-get? authorized-verifiers tx-sender)) ERR_UNAUTHORIZED)
    (asserts! (is-none existing-record) ERR_ALREADY_VERIFIED)
    (asserts! (and (>= security-level u1) (<= security-level u10)) ERR_INVALID_INFRASTRUCTURE)
    (ok (map-set infrastructure-registry
      { infrastructure-id: infrastructure-id }
      {
        verified: true,
        verification-timestamp: block-height,
        verifier: tx-sender,
        quantum-compatibility: quantum-compatibility,
        security-level: security-level
      }
    ))
  )
)

;; Read-only functions
(define-read-only (get-infrastructure-status (infrastructure-id (string-ascii 64)))
  (map-get? infrastructure-registry { infrastructure-id: infrastructure-id })
)

(define-read-only (is-infrastructure-verified (infrastructure-id (string-ascii 64)))
  (match (map-get? infrastructure-registry { infrastructure-id: infrastructure-id })
    record (get verified record)
    false
  )
)
