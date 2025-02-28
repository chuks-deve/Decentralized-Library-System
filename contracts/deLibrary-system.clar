;;-----------------------------------------------------------------------------
;; Digital Library Management System
;; A decentralized platform for managing and distributing digital publications
;;-----------------------------------------------------------------------------

;;-----------------------------------------------------------------------------
;; System Parameters & Error Handling
;;-----------------------------------------------------------------------------

;; System administrator (defaults to contract deployer)
(define-constant CONTRACT-OWNER tx-sender)

;; System Limits for Content Validation
(define-constant TITLE-MAX-CHARS u64)         ;; Maximum characters in publication title
(define-constant DESCRIPTION-MAX-CHARS u256)  ;; Maximum characters in publication description
(define-constant TAG-MAX-CHARS u32)           ;; Maximum characters per category tag
(define-constant MAX-TAG-COUNT u8)            ;; Maximum number of tags per publication
(define-constant FILE-SIZE-LIMIT u1000000000) ;; Maximum file size in bytes

;; Error Response Codes
(define-constant ERROR-ITEM-MISSING (err u301))      ;; Publication not in database
(define-constant ERROR-DUPLICATE-ENTRY (err u302))   ;; Publication already registered
(define-constant ERROR-INVALID-TITLE (err u303))     ;; Title format/length invalid
(define-constant ERROR-INVALID-SIZE (err u304))      ;; File size exceeds limits
(define-constant ERROR-UNAUTHORIZED (err u305))      ;; Permission denied for operation
(define-constant ERROR-INVALID-USER (err u306))      ;; Target user is invalid
(define-constant ERROR-ADMIN-ONLY (err u307))        ;; Operation restricted to admin
(define-constant ERROR-PERMISSION (err u308))        ;; User lacks required permissions
(define-constant ERROR-ACCESS-FORBIDDEN (err u309))  ;; Access explicitly forbidden

;;-----------------------------------------------------------------------------
;; Data Storage Structures
;;-----------------------------------------------------------------------------

;; System publication counter
(define-data-var publication-count uint u0)

;; Publication metadata storage
(define-map publication-registry
    { publication-id: uint }
    {
        title: (string-ascii 64),                  ;; Publication title
        creator: principal,                        ;; Creator's blockchain identity
        byte-count: uint,                          ;; File size in bytes
        creation-block: uint,                      ;; Block height at creation time
        description: (string-ascii 256),           ;; Publication description
        tags: (list 8 (string-ascii 32))           ;; Classification tags
    }
)

;; User permission tracking
(define-map user-permissions
    { publication-id: uint, user: principal }
    { permitted: bool }                            ;; Permission status flag
)

;; Usage statistics tracking
(define-map usage-statistics
    { publication-id: uint }
    { access-count: uint }                         ;; Number of accesses recorded
)

;;-----------------------------------------------------------------------------
;; Internal Helper Functions
;;-----------------------------------------------------------------------------

;; Check if publication exists
(define-private (publication-registered? (publication-id uint))
    (is-some (map-get? publication-registry { publication-id: publication-id }))
)

;; Verify publication ownership
(define-private (is-creator? (publication-id uint) (user principal))
    (match (map-get? publication-registry { publication-id: publication-id })
        pub-data (is-eq (get creator pub-data) user)
        false
    )
)
     
