;; Group Class Scheduling Contract
;; Manages fitness session bookings

;; Constants
(define-constant ERR-NOT-AUTHORIZED (err u400))
(define-constant ERR-CLASS-NOT-FOUND (err u401))
(define-constant ERR-CLASS-FULL (err u402))
(define-constant ERR-ALREADY-BOOKED (err u403))
(define-constant ERR-BOOKING-NOT-FOUND (err u404))
(define-constant ERR-CLASS-STARTED (err u405))
(define-constant ERR-INVALID-INPUT (err u406))
(define-constant ERR-INVALID-RATING (err u407))

;; Data Variables
(define-data-var next-class-id uint u1)
(define-data-var next-booking-id uint u1)

;; Data Maps
(define-map fitness-classes
  { class-id: uint }
  {
    instructor: principal,
    name: (string-ascii 50),
    description: (string-ascii 200),
    start-time: uint,
    duration-minutes: uint,
    max-capacity: uint,
    current-bookings: uint,
    price: uint,
    total-rating: uint,
    rating-count: uint,
    is-cancelled: bool,
    created-at: uint
  }
)

(define-map class-bookings
  { booking-id: uint }
  {
    class-id: uint,
    user: principal,
    booking-time: uint,
    attended: bool,
    rating-given: bool
  }
)

(define-map user-class-bookings
  { user: principal, class-id: uint }
  { booking-id: uint }
)

(define-map class-ratings
  { class-id: uint, user: principal }
  { rating: uint }
)

(define-map instructor-stats
  { instructor: principal }
  {
    total-classes: uint,
    total-students: uint,
    total-rating: uint,
    rating-count: uint
  }
)

;; Public Functions

;; Schedule a new fitness class
(define-public (schedule-class (name (string-ascii 50)) (description (string-ascii 200)) (start-time uint) (duration-minutes uint) (max-capacity uint) (price uint))
  (let
    (
      (class-id (var-get next-class-id))
    )
    (asserts! (> start-time block-height) ERR-INVALID-INPUT)
    (asserts! (> duration-minutes u0) ERR-INVALID-INPUT)
    (asserts! (> max-capacity u0) ERR-INVALID-INPUT)

    (map-set fitness-classes
      { class-id: class-id }
      {
        instructor: tx-sender,
        name: name,
        description: description,
        start-time: start-time,
        duration-minutes: duration-minutes,
        max-capacity: max-capacity,
        current-bookings: u0,
        price: price,
        total-rating: u0,
        rating-count: u0,
        is-cancelled: false,
        created-at: block-height
      }
    )

    ;; Update instructor stats
    (let
      (
        (instructor-stat (default-to
          { total-classes: u0, total-students: u0, total-rating: u0, rating-count: u0 }
          (map-get? instructor-stats { instructor: tx-sender })
        ))
      )
      (map-set instructor-stats
        { instructor: tx-sender }
        (merge instructor-stat { total-classes: (+ (get total-classes instructor-stat) u1) })
      )
    )

    (var-set next-class-id (+ class-id u1))
    (ok class-id)
  )
)

;; Book a class
(define-public (book-class (class-id uint))
  (let
    (
      (class-info (unwrap! (map-get? fitness-classes { class-id: class-id }) ERR-CLASS-NOT-FOUND))
      (booking-id (var-get next-booking-id))
      (existing-booking (map-get? user-class-bookings { user: tx-sender, class-id: class-id }))
    )
    (asserts! (is-none existing-booking) ERR-ALREADY-BOOKED)
    (asserts! (< (get current-bookings class-info) (get max-capacity class-info)) ERR-CLASS-FULL)
    (asserts! (> (get start-time class-info) block-height) ERR-CLASS-STARTED)
    (asserts! (not (get is-cancelled class-info)) ERR-CLASS-NOT-FOUND)
    (asserts! (not (is-eq tx-sender (get instructor class-info))) ERR-NOT-AUTHORIZED)

    ;; Create booking
    (map-set class-bookings
      { booking-id: booking-id }
      {
        class-id: class-id,
        user: tx-sender,
        booking-time: block-height,
        attended: false,
        rating-given: false
      }
    )

    ;; Link user to booking
    (map-set user-class-bookings
      { user: tx-sender, class-id: class-id }
      { booking-id: booking-id }
    )

    ;; Update class booking count
    (map-set fitness-classes
      { class-id: class-id }
      (merge class-info { current-bookings: (+ (get current-bookings class-info) u1) })
    )

    (var-set next-booking-id (+ booking-id u1))
    (ok booking-id)
  )
)

;; Cancel booking
(define-public (cancel-booking (class-id uint))
  (let
    (
      (class-info (unwrap! (map-get? fitness-classes { class-id: class-id }) ERR-CLASS-NOT-FOUND))
      (user-booking (unwrap! (map-get? user-class-bookings { user: tx-sender, class-id: class-id }) ERR-BOOKING-NOT-FOUND))
      (booking-id (get booking-id user-booking))
    )
    (asserts! (> (get start-time class-info) block-height) ERR-CLASS-STARTED)

    ;; Remove booking
    (map-delete class-bookings { booking-id: booking-id })
    (map-delete user-class-bookings { user: tx-sender, class-id: class-id })

    ;; Update class booking count
    (map-set fitness-classes
      { class-id: class-id }
      (merge class-info { current-bookings: (- (get current-bookings class-info) u1) })
    )

    (ok true)
  )
)

;; Mark attendance (instructor only)
(define-public (mark-attendance (class-id uint) (user principal) (attended bool))
  (let
    (
      (class-info (unwrap! (map-get? fitness-classes { class-id: class-id }) ERR-CLASS-NOT-FOUND))
      (user-booking (unwrap! (map-get? user-class-bookings { user: user, class-id: class-id }) ERR-BOOKING-NOT-FOUND))
      (booking-id (get booking-id user-booking))
      (booking (unwrap! (map-get? class-bookings { booking-id: booking-id }) ERR-BOOKING-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender (get instructor class-info)) ERR-NOT-AUTHORIZED)

    (map-set class-bookings
      { booking-id: booking-id }
      (merge booking { attended: attended })
    )

    ;; Update instructor stats if attended
    (if attended
      (let
        (
          (instructor-stat (default-to
            { total-classes: u0, total-students: u0, total-rating: u0, rating-count: u0 }
            (map-get? instructor-stats { instructor: (get instructor class-info) })
          ))
        )
        (map-set instructor-stats
          { instructor: (get instructor class-info) }
          (merge instructor-stat { total-students: (+ (get total-students instructor-stat) u1) })
        )
      )
      true
    )

    (ok true)
  )
)

;; Rate a class
(define-public (rate-class (class-id uint) (rating uint))
  (let
    (
      (class-info (unwrap! (map-get? fitness-classes { class-id: class-id }) ERR-CLASS-NOT-FOUND))
      (user-booking (unwrap! (map-get? user-class-bookings { user: tx-sender, class-id: class-id }) ERR-BOOKING-NOT-FOUND))
      (booking-id (get booking-id user-booking))
      (booking (unwrap! (map-get? class-bookings { booking-id: booking-id }) ERR-BOOKING-NOT-FOUND))
      (existing-rating (map-get? class-ratings { class-id: class-id, user: tx-sender }))
    )
    (asserts! (and (>= rating u1) (<= rating u5)) ERR-INVALID-RATING)
    (asserts! (get attended booking) ERR-NOT-AUTHORIZED)
    (asserts! (< (get start-time class-info) block-height) ERR-INVALID-INPUT)

    (if (is-some existing-rating)
      ;; Update existing rating
      (let
        (
          (old-rating (get rating (unwrap-panic existing-rating)))
          (new-total (+ (- (get total-rating class-info) old-rating) rating))
        )
        (map-set class-ratings
          { class-id: class-id, user: tx-sender }
          { rating: rating }
        )
        (map-set fitness-classes
          { class-id: class-id }
          (merge class-info { total-rating: new-total })
        )
      )
      ;; Add new rating
      (let
        (
          (new-total (+ (get total-rating class-info) rating))
          (new-count (+ (get rating-count class-info) u1))
        )
        (map-set class-ratings
          { class-id: class-id, user: tx-sender }
          { rating: rating }
        )
        (map-set fitness-classes
          { class-id: class-id }
          (merge class-info {
            total-rating: new-total,
            rating-count: new-count
          })
        )
        (map-set class-bookings
          { booking-id: booking-id }
          (merge booking { rating-given: true })
        )
      )
    )

    (ok true)
  )
)

;; Cancel class (instructor only)
(define-public (cancel-class (class-id uint))
  (let
    (
      (class-info (unwrap! (map-get? fitness-classes { class-id: class-id }) ERR-CLASS-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender (get instructor class-info)) ERR-NOT-AUTHORIZED)
    (asserts! (> (get start-time class-info) block-height) ERR-CLASS-STARTED)

    (map-set fitness-classes
      { class-id: class-id }
      (merge class-info { is-cancelled: true })
    )
    (ok true)
  )
)

;; Read-only Functions

;; Get class details
(define-read-only (get-class (class-id uint))
  (map-get? fitness-classes { class-id: class-id })
)

;; Get booking details
(define-read-only (get-booking (booking-id uint))
  (map-get? class-bookings { booking-id: booking-id })
)

;; Get user's booking for a class
(define-read-only (get-user-class-booking (user principal) (class-id uint))
  (match (map-get? user-class-bookings { user: user, class-id: class-id })
    booking-ref (map-get? class-bookings { booking-id: (get booking-id booking-ref) })
    none
  )
)

;; Get class average rating
(define-read-only (get-class-average-rating (class-id uint))
  (match (map-get? fitness-classes { class-id: class-id })
    class-info (if (> (get rating-count class-info) u0)
                 (some (/ (get total-rating class-info) (get rating-count class-info)))
                 none)
    none
  )
)

;; Get instructor stats
(define-read-only (get-instructor-stats (instructor principal))
  (map-get? instructor-stats { instructor: instructor })
)

;; Check if class is available for booking
(define-read-only (is-class-available (class-id uint))
  (match (map-get? fitness-classes { class-id: class-id })
    class-info (and (< (get current-bookings class-info) (get max-capacity class-info))
                 (> (get start-time class-info) block-height)
                 (not (get is-cancelled class-info)))
    false
  )
)

;; Get next class ID
(define-read-only (get-next-class-id)
  (var-get next-class-id)
)

;; Get next booking ID
(define-read-only (get-next-booking-id)
  (var-get next-booking-id)
)
