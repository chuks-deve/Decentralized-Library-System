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
     
;; Get publication size
(define-private (get-byte-count (publication-id uint))
    (default-to u0 
        (get byte-count 
            (map-get? publication-registry { publication-id: publication-id })
        )
    )
)

;; Validate tag format
(define-private (valid-tag? (tag (string-ascii 32)))
    (and 
        (> (len tag) u0)
        (< (len tag) TAG-MAX-CHARS)
    )
)

;; Validate all tags in list
(define-private (validate-tag-list? (tags (list 8 (string-ascii 32))))
    (and
        (> (len tags) u0)
        (<= (len tags) MAX-TAG-COUNT)
        (is-eq (len (filter valid-tag? tags)) (len tags))
    )
)

;; Update usage counter
(define-private (record-access (publication-id uint))
    (let
        (
            (current-accesses (default-to u0 (get access-count (map-get? usage-statistics { publication-id: publication-id }))))
        )
        (map-set usage-statistics
            { publication-id: publication-id }
            { access-count: (+ current-accesses u1) }
        )
    )
)

;;-----------------------------------------------------------------------------
;; Public Interface
;;-----------------------------------------------------------------------------

;; Retrieve complete publication details
(define-read-only (get-publication-details (publication-id uint))
    (match (map-get? publication-registry { publication-id: publication-id })
        pub-data 
        (ok {
            title: (get title pub-data),
            creator: (get creator pub-data),
            byte-count: (get byte-count pub-data),
            creation-block: (get creation-block pub-data),
            description: (get description pub-data),
            tags: (get tags pub-data),
            access-count: (default-to u0 (get access-count (map-get? usage-statistics { publication-id: publication-id })))
        })
        ERROR-ITEM-MISSING
    )
)

;; Change publication ownership
(define-public (change-creator (publication-id uint) (new-creator principal))
    (let
        ((pub-data (unwrap! (map-get? publication-registry { publication-id: publication-id }) ERROR-ITEM-MISSING)))
        
        ;; Security validations
        (asserts! (publication-registered? publication-id) ERROR-ITEM-MISSING)
        (asserts! (is-eq (get creator pub-data) tx-sender) ERROR-UNAUTHORIZED)

        ;; Update creator field
        (map-set publication-registry
            { publication-id: publication-id }
            (merge pub-data { creator: new-creator })
        )
        (ok true)
    )
)


;; Register new publication
(define-public (register-publication 
    (title (string-ascii 64)) 
    (byte-count uint) 
    (description (string-ascii 256)) 
    (tags (list 8 (string-ascii 32))))
    (let
        ((next-id (+ (var-get publication-count) u1)))
        
        ;; Input validation checks
        (asserts! (and (> (len title) u0) (< (len title) TITLE-MAX-CHARS)) ERROR-INVALID-TITLE)
        (asserts! (and (> byte-count u0) (< byte-count FILE-SIZE-LIMIT)) ERROR-INVALID-SIZE)
        (asserts! (and (> (len description) u0) (< (len description) DESCRIPTION-MAX-CHARS)) ERROR-INVALID-TITLE)
        (asserts! (validate-tag-list? tags) ERROR-INVALID-TITLE)

        ;; Store publication data
        (map-insert publication-registry
            { publication-id: next-id }
            {
                title: title,
                creator: tx-sender,
                byte-count: byte-count,
                creation-block: block-height,
                description: description,
                tags: tags
            }
        )

        ;; Grant creator access by default
        (map-insert user-permissions
            { publication-id: next-id, user: tx-sender }
            { permitted: true }
        )

        ;; Update system counter
        (var-set publication-count next-id)
        (ok next-id)
    )
)

;; Record publication access
(define-public (access-publication (publication-id uint))
    (begin
        ;; Verify publication exists
        (asserts! (publication-registered? publication-id) ERROR-ITEM-MISSING)

        ;; Verify user has permission
        (let
            ((permission (default-to { permitted: false }
                            (map-get? user-permissions { publication-id: publication-id, user: tx-sender }))))
            (asserts! (get permitted permission) ERROR-PERMISSION)
        )

        ;; Update access statistics
        (record-access publication-id)
        (ok true)
    )
)

;; Modify publication details
(define-public (modify-publication 
    (publication-id uint) 
    (updated-title (string-ascii 64)) 
    (updated-size uint) 
    (updated-description (string-ascii 256)) 
    (updated-tags (list 8 (string-ascii 32))))
    (let
        ((pub-data (unwrap! (map-get? publication-registry { publication-id: publication-id }) ERROR-ITEM-MISSING)))
        
        ;; Validate existing record and permissions
        (asserts! (publication-registered? publication-id) ERROR-ITEM-MISSING)
        (asserts! (is-eq (get creator pub-data) tx-sender) ERROR-UNAUTHORIZED)
        
        ;; Validate new data
        (asserts! (and (> (len updated-title) u0) (< (len updated-title) TITLE-MAX-CHARS)) ERROR-INVALID-TITLE)
        (asserts! (and (> updated-size u0) (< updated-size FILE-SIZE-LIMIT)) ERROR-INVALID-SIZE)
        (asserts! (and (> (len updated-description) u0) (< (len updated-description) DESCRIPTION-MAX-CHARS)) ERROR-INVALID-TITLE)
        (asserts! (validate-tag-list? updated-tags) ERROR-INVALID-TITLE)

        ;; Update publication record
        (map-set publication-registry
            { publication-id: publication-id }
            (merge pub-data { 
                title: updated-title, 
                byte-count: updated-size, 
                description: updated-description, 
                tags: updated-tags 
            })
        )
        (ok true)
    )
)

;; Remove publication from system
(define-public (remove-publication (publication-id uint))
    (let
        ((pub-data (unwrap! (map-get? publication-registry { publication-id: publication-id }) ERROR-ITEM-MISSING)))
        
        ;; Verify record exists and user has permission
        (asserts! (publication-registered? publication-id) ERROR-ITEM-MISSING)
        (asserts! (is-eq (get creator pub-data) tx-sender) ERROR-UNAUTHORIZED)

        ;; Delete publication record
        (map-delete publication-registry { publication-id: publication-id })
        (ok true)
    )
)
