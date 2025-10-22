# SkillFi

## Overview

**SkillFi** is a **decentralized freelancing and task management smart contract** designed to streamline client–contractor collaborations using on-chain verification and milestone-based payments.
It enables clients to create tasks, assign contractors, validate submitted work in phases, and release payments securely and transparently.

---

## Features

### 1. **Task Creation**

Clients can create tasks with detailed descriptions, total payments, and the number of project phases.

**Function:**

```clarity
(create-task (name (string-utf8 100)) (details (string-utf8 500)) (payment uint) (total-phases uint))
```

* Restricted to the **contract administrator**.
* Each task is assigned a unique `task-id`.
* Initializes with zero completed phases and an unset contractor.

---

### 2. **Contractor Assignment**

Clients can assign contractors to specific tasks.

**Function:**

```clarity
(assign-contractor (tid uint) (contractor principal))
```

* Only the task’s creator (client) can assign a contractor.
* Updates the task record with the contractor’s principal address.

---

### 3. **Phase Submission**

Contractors can submit work for a particular phase of the task.

**Function:**

```clarity
(submit-phase (tid uint) (phase-id uint) (details (string-utf8 200)))
```

* Restricted to the assigned contractor.
* Creates a new phase record marked as unvalidated and uncompensated.

---

### 4. **Phase Approval**

Clients review and approve submitted phases before payment release.

**Function:**

```clarity
(approve-phase (tid uint) (phase-id uint))
```

* Only the client who owns the task can approve a phase.
* Marks the phase as validated and increments the count of finished phases.

---

### 5. **Payment Release**

Clients release payment for validated phases.

**Function:**

```clarity
(release-payment (tid uint) (phase-id uint))
```

* Only the client can trigger payment.
* Ensures the phase is validated and not yet compensated.
* Updates the phase status to `is-compensated: true`.

---

### 6. **Task Completion**

When all phases are completed, the task can be finalized.

**Function:**

```clarity
(complete-task (tid uint))
```

* Restricted to the task’s client.
* Ensures all phases are validated before marking the task as finalized.

---

### 7. **Read-Only Functions**

Retrieve stored data without modifying the blockchain state.

* **Get Task Details:**

  ```clarity
  (get-task-details (tid uint))
  ```

  Returns full task metadata including client, contractor, payment, and completion status.

* **Get Phase Details:**

  ```clarity
  (get-phase-details (tid uint) (phase-id uint))
  ```

  Returns specific phase details such as submission notes, validation, and compensation status.

---

## Data Structures

### Map: `tasks`

Stores high-level information about each registered task.

```clarity
uint => {
  client: principal,
  contractor: (optional principal),
  name: (string-utf8 100),
  details: (string-utf8 500),
  payment: uint,
  phase-count: uint,
  finished-phases: uint,
  is-finalized: bool
}
```

### Map: `phase-info`

Tracks progress and approval details for each phase of a task.

```clarity
{ task-id: uint, phase-id: uint } => {
  details: (string-utf8 200),
  is-validated: bool,
  is-compensated: bool
}
```

---

## Error Codes

| Code   | Constant                        | Description                         |
| ------ | ------------------------------- | ----------------------------------- |
| `u100` | `err-access-denied`             | Unauthorized caller                 |
| `u101` | `err-task-not-found`            | Task does not exist                 |
| `u102` | `err-phase-not-found`           | Phase not found                     |
| `u103` | `err-invalid-contractor`        | Only assigned contractor can submit |
| `u104` | `err-phase-already-validated`   | Phase already approved              |
| `u105` | `err-phase-already-compensated` | Phase already paid                  |
| `u106` | `err-task-already-finalized`    | Task already completed              |

---

## Workflow Summary

1. **Admin creates** a task via `create-task`.
2. **Client assigns** a contractor using `assign-contractor`.
3. **Contractor submits** phase work using `submit-phase`.
4. **Client approves** the phase via `approve-phase`.
5. **Client releases** payment with `release-payment`.
6. **Client finalizes** task after all phases are approved via `complete-task`.

---

## Summary

**SkillFi** provides a **trustless, transparent freelancing framework** where each project phase is validated and compensated independently.
It enforces accountability, eliminates disputes, and automates milestone tracking, ensuring smooth client–contractor collaboration in a decentralized environment.
