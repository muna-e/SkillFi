;; Define the contract
(define-constant admin tx-sender)

;; Data structures
(define-data-var task-counter uint u0)

(define-map tasks
  uint ;; tid
  {
    owner: principal,
    worker: (optional principal),
    title: (string-utf8 100),
    desc: (string-utf8 500),
    amt: uint,
    num-phases: uint,
    completed-phases: uint,
    finalized: bool
  }
)

(define-map phase-info
  { tid: uint, pid: uint }
  {
    desc: (string-utf8 200),
    validated: bool,
    paid: bool
  }
)

;; Errors
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-TASK-MISSING (err u101))
(define-constant ERR-PHASE-MISSING (err u102))
(define-constant ERR-INVALID-WORKER (err u103))
(define-constant ERR-PHASE-VALIDATED (err u104))
(define-constant ERR-PHASE-PAID (err u105))
(define-constant ERR-TASK-FINALIZED (err u106))

;; Create a new task
(define-public (create-task (title (string-utf8 100)) (desc (string-utf8 500)) (amt uint) (num-phases uint))
  (let ((new-tid (+ (var-get task-counter) u1)))
    (asserts! (is-eq tx-sender admin) ERR-UNAUTHORIZED)
    (map-set tasks new-tid
      {
        owner: tx-sender,
        worker: none,
        title: title,
        desc: desc,
        amt: amt,
        num-phases: num-phases,
        completed-phases: u0,
        finalized: false
      }
    )
    (var-set task-counter new-tid)
    (ok new-tid)
  )
)

;; Assign a contractor to a task
(define-public (assign-contractor (tid uint) (worker principal))
  (let ((t (map-get? tasks tid)))
    (asserts! (is-some t) ERR-TASK-MISSING)
    (asserts! (is-eq (get owner (unwrap-panic t)) tx-sender) ERR-UNAUTHORIZED)
    (map-set tasks tid
      (merge (unwrap-panic t)
        {
          worker: (some worker)
        }
      )
    )
    (ok true)
  )
)

;; Submit a phase
(define-public (submit-phase (tid uint) (pid uint) (desc (string-utf8 200)))
  (let ((t (map-get? tasks tid)))
    (asserts! (is-some t) ERR-TASK-MISSING)
    (asserts! (is-eq (get worker (unwrap-panic t)) (some tx-sender)) ERR-INVALID-WORKER)
    (map-set phase-info { tid: tid, pid: pid }
      {
        desc: desc,
        validated: false,
        paid: false
      }
    )
    (ok true)
  )
)

;; Approve a phase
(define-public (approve-phase (tid uint) (pid uint))
  (let ((t (map-get? tasks tid))
        (p (map-get? phase-info { tid: tid, pid: pid })))
    (asserts! (is-some t) ERR-TASK-MISSING)
    (asserts! (is-some p) ERR-PHASE-MISSING)
    (asserts! (is-eq (get owner (unwrap-panic t)) tx-sender) ERR-UNAUTHORIZED)
    (asserts! (not (get validated (unwrap-panic p))) ERR-PHASE-VALIDATED)
    (map-set phase-info { tid: tid, pid: pid }
      (merge (unwrap-panic p)
        {
          validated: true
        }
      )
    )
    (map-set tasks tid
      (merge (unwrap-panic t)
        {
          completed-phases: (+ (get completed-phases (unwrap-panic t)) u1)
        }
      )
    )
    (ok true)
  )
)

;; Release payment for a phase
(define-public (release-payment (tid uint) (pid uint))
  (let ((t (map-get? tasks tid))
        (p (map-get? phase-info { tid: tid, pid: pid })))
    (asserts! (is-some t) ERR-TASK-MISSING)
    (asserts! (is-some p) ERR-PHASE-MISSING)
    (asserts! (is-eq (get owner (unwrap-panic t)) tx-sender) ERR-UNAUTHORIZED)
    (asserts! (get validated (unwrap-panic p)) ERR-PHASE-MISSING)
    (asserts! (not (get paid (unwrap-panic p))) ERR-PHASE-PAID)
    (map-set phase-info { tid: tid, pid: pid }
      (merge (unwrap-panic p)
        {
          paid: true
        }
      )
    )
    (ok true)
  )
)

;; Mark task as completed
(define-public (complete-task (tid uint))
  (let ((t (map-get? tasks tid)))
    (asserts! (is-some t) ERR-TASK-MISSING)
    (asserts! (is-eq (get owner (unwrap-panic t)) tx-sender) ERR-UNAUTHORIZED)
    (asserts! (not (get finalized (unwrap-panic t))) ERR-TASK-FINALIZED)
    (asserts! (is-eq (get completed-phases (unwrap-panic t)) (get num-phases (unwrap-panic t))) ERR-UNAUTHORIZED)
    (map-set tasks tid
      (merge (unwrap-panic t)
        {
          finalized: true
        }
      )
    )
    (ok true)
  )
)

;; Helper function to get task details
(define-read-only (get-task-details (tid uint))
  (map-get? tasks tid)
)

;; Helper function to get phase details
(define-read-only (get-phase-details (tid uint) (pid uint))
  (map-get? phase-info { tid: tid, pid: pid })
)