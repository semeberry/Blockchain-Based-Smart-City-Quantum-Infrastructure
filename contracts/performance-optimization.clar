;; Performance Optimization Contract
;; Optimizes quantum city services and resource allocation

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u500))
(define-constant ERR_INVALID_METRICS (err u501))
(define-constant ERR_OPTIMIZATION_FAILED (err u502))
(define-constant ERR_RESOURCE_NOT_FOUND (err u503))

;; Data structures
(define-map performance-metrics
  { resource-id: (string-ascii 32) }
  {
    cpu-usage: uint,
    memory-usage: uint,
    quantum-coherence: uint,
    throughput: uint,
    latency: uint,
    last-updated: uint
  }
)

(define-map optimization-rules
  { rule-id: (string-ascii 32) }
  {
    resource-type: (string-ascii 32),
    threshold-cpu: uint,
    threshold-memory: uint,
    threshold-latency: uint,
    action: (string-ascii 32),
    priority: uint
  }
)

(define-map resource-allocations
  { allocation-id: (string-ascii 32) }
  {
    resource-id: (string-ascii 32),
    allocated-quantum-units: uint,
    allocated-bandwidth: uint,
    allocation-timestamp: uint,
    efficiency-score: uint
  }
)

(define-data-var total-optimizations uint u0)
(define-data-var system-efficiency uint u100)

;; Public functions
(define-public (update-performance-metrics
  (resource-id (string-ascii 32))
  (cpu-usage uint)
  (memory-usage uint)
  (quantum-coherence uint)
  (throughput uint)
  (latency uint))
  (begin
    (asserts! (and (<= cpu-usage u100) (<= memory-usage u100)) ERR_INVALID_METRICS)
    (asserts! (and (<= quantum-coherence u100) (> throughput u0)) ERR_INVALID_METRICS)
    (ok (map-set performance-metrics
      { resource-id: resource-id }
      {
        cpu-usage: cpu-usage,
        memory-usage: memory-usage,
        quantum-coherence: quantum-coherence,
        throughput: throughput,
        latency: latency,
        last-updated: block-height
      }
    ))
  )
)

(define-public (create-optimization-rule
  (rule-id (string-ascii 32))
  (resource-type (string-ascii 32))
  (threshold-cpu uint)
  (threshold-memory uint)
  (threshold-latency uint)
  (action (string-ascii 32))
  (priority uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (and (<= threshold-cpu u100) (<= threshold-memory u100)) ERR_INVALID_METRICS)
    (asserts! (and (>= priority u1) (<= priority u10)) ERR_INVALID_METRICS)
    (ok (map-set optimization-rules
      { rule-id: rule-id }
      {
        resource-type: resource-type,
        threshold-cpu: threshold-cpu,
        threshold-memory: threshold-memory,
        threshold-latency: threshold-latency,
        action: action,
        priority: priority
      }
    ))
  )
)

(define-public (allocate-quantum-resources
  (allocation-id (string-ascii 32))
  (resource-id (string-ascii 32))
  (quantum-units uint)
  (bandwidth uint))
  (let ((metrics (map-get? performance-metrics { resource-id: resource-id })))
    (asserts! (is-some metrics) ERR_RESOURCE_NOT_FOUND)
    (asserts! (and (> quantum-units u0) (> bandwidth u0)) ERR_INVALID_METRICS)
    (let ((efficiency (calculate-efficiency-score quantum-units bandwidth)))
      (map-set resource-allocations
        { allocation-id: allocation-id }
        {
          resource-id: resource-id,
          allocated-quantum-units: quantum-units,
          allocated-bandwidth: bandwidth,
          allocation-timestamp: block-height,
          efficiency-score: efficiency
        }
      )
      (var-set total-optimizations (+ (var-get total-optimizations) u1))
      (ok efficiency)
    )
  )
)

(define-public (optimize-system-performance)
  (let ((current-efficiency (var-get system-efficiency)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (let ((new-efficiency (+ current-efficiency u5)))
      (var-set system-efficiency (if (<= new-efficiency u100) new-efficiency u100))
      (var-set total-optimizations (+ (var-get total-optimizations) u1))
      (ok (var-get system-efficiency))
    )
  )
)

;; Private functions
(define-private (calculate-efficiency-score (quantum-units uint) (bandwidth uint))
  (let ((base-score (* quantum-units bandwidth)))
    (if (> base-score u1000)
      u95
      (+ u50 (/ base-score u20))
    )
  )
)

;; Read-only functions
(define-read-only (get-performance-metrics (resource-id (string-ascii 32)))
  (map-get? performance-metrics { resource-id: resource-id })
)

(define-read-only (get-optimization-rule (rule-id (string-ascii 32)))
  (map-get? optimization-rules { rule-id: rule-id })
)

(define-read-only (get-resource-allocation (allocation-id (string-ascii 32)))
  (map-get? resource-allocations { allocation-id: allocation-id })
)

(define-read-only (get-system-stats)
  {
    total-optimizations: (var-get total-optimizations),
    system-efficiency: (var-get system-efficiency)
  }
)

(define-read-only (check-optimization-needed (resource-id (string-ascii 32)))
  (match (map-get? performance-metrics { resource-id: resource-id })
    metrics (or
      (> (get cpu-usage metrics) u80)
      (> (get memory-usage metrics) u80)
      (> (get latency metrics) u1000)
    )
    false
  )
)
