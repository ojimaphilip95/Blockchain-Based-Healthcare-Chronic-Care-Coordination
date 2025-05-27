;; Care Plan Optimization Contract
;; Manages and optimizes treatment protocols for chronic care

(define-constant ERR_UNAUTHORIZED (err u400))
(define-constant ERR_PLAN_NOT_FOUND (err u401))
(define-constant ERR_INVALID_PARAMETERS (err u402))

;; Care plan structure
(define-map care-plans
  { plan-id: uint }
  {
    patient-id: principal,
    provider-id: principal,
    condition: (string-ascii 100),
    created-date: uint,
    last-updated: uint,
    active: bool,
    effectiveness-score: uint
  }
)

;; Treatment protocols
(define-map treatment-protocols
  { plan-id: uint, protocol-id: uint }
  {
    treatment-type: (string-ascii 100),
    frequency: uint,
    duration: uint,
    adherence-rate: uint,
    effectiveness: uint
  }
)

;; Plan optimization metrics
(define-map optimization-metrics
  { plan-id: uint }
  {
    total-protocols: uint,
    successful-protocols: uint,
    patient-satisfaction: uint,
    clinical-outcomes: uint,
    cost-effectiveness: uint
  }
)

;; Plan counter
(define-data-var plan-counter uint u0)

;; Create new care plan
(define-public (create-care-plan
  (patient-id principal)
  (condition (string-ascii 100)))
  (let ((plan-id (+ (var-get plan-counter) u1)))

    (map-set care-plans
      { plan-id: plan-id }
      {
        patient-id: patient-id,
        provider-id: tx-sender,
        condition: condition,
        created-date: block-height,
        last-updated: block-height,
        active: true,
        effectiveness-score: u0
      }
    )

    (map-set optimization-metrics
      { plan-id: plan-id }
      {
        total-protocols: u0,
        successful-protocols: u0,
        patient-satisfaction: u0,
        clinical-outcomes: u0,
        cost-effectiveness: u0
      }
    )

    (var-set plan-counter plan-id)
    (ok plan-id)
  )
)

;; Add treatment protocol to care plan
(define-public (add-treatment-protocol
  (plan-id uint)
  (treatment-type (string-ascii 100))
  (frequency uint)
  (duration uint))
  (let ((plan (unwrap! (map-get? care-plans { plan-id: plan-id }) ERR_PLAN_NOT_FOUND))
        (metrics (unwrap! (map-get? optimization-metrics { plan-id: plan-id }) ERR_PLAN_NOT_FOUND))
        (protocol-id (+ (get total-protocols metrics) u1)))

    (asserts! (is-eq tx-sender (get provider-id plan)) ERR_UNAUTHORIZED)

    (map-set treatment-protocols
      { plan-id: plan-id, protocol-id: protocol-id }
      {
        treatment-type: treatment-type,
        frequency: frequency,
        duration: duration,
        adherence-rate: u0,
        effectiveness: u0
      }
    )

    (map-set optimization-metrics
      { plan-id: plan-id }
      (merge metrics { total-protocols: protocol-id })
    )

    (ok protocol-id)
  )
)

;; Update protocol effectiveness
(define-public (update-protocol-effectiveness
  (plan-id uint)
  (protocol-id uint)
  (adherence-rate uint)
  (effectiveness uint))
  (let ((plan (unwrap! (map-get? care-plans { plan-id: plan-id }) ERR_PLAN_NOT_FOUND))
        (protocol (unwrap! (map-get? treatment-protocols { plan-id: plan-id, protocol-id: protocol-id }) ERR_PLAN_NOT_FOUND)))

    (asserts! (is-eq tx-sender (get provider-id plan)) ERR_UNAUTHORIZED)
    (asserts! (and (<= adherence-rate u100) (<= effectiveness u100)) ERR_INVALID_PARAMETERS)

    (map-set treatment-protocols
      { plan-id: plan-id, protocol-id: protocol-id }
      (merge protocol {
        adherence-rate: adherence-rate,
        effectiveness: effectiveness
      })
    )

    ;; Update plan effectiveness score
    (let ((updated-score (calculate-plan-effectiveness plan-id)))
      (map-set care-plans
        { plan-id: plan-id }
        (merge plan {
          effectiveness-score: updated-score,
          last-updated: block-height
        })
      )
    )

    (ok true)
  )
)

;; Calculate overall plan effectiveness
(define-private (calculate-plan-effectiveness (plan-id uint))
  ;; Simplified calculation - in practice would be more sophisticated
  u75 ;; Placeholder return value
)

;; Get care plan
(define-read-only (get-care-plan (plan-id uint))
  (map-get? care-plans { plan-id: plan-id })
)

;; Get treatment protocol
(define-read-only (get-treatment-protocol (plan-id uint) (protocol-id uint))
  (map-get? treatment-protocols { plan-id: plan-id, protocol-id: protocol-id })
)
