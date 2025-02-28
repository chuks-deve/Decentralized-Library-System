# **Decentralized Library Management System**  
A blockchain-powered platform for managing and distributing digital publications using Clarity smart contracts.

## **Table of Contents**
- [Introduction](#introduction)  
- [Features](#features)  
- [Smart Contract Overview](#smart-contract-overview)  
- [System Components](#system-components)  
- [Error Handling](#error-handling)  
- [Contract Functions](#contract-functions)  
- [Deployment](#deployment)  
- [Usage Guide](#usage-guide)  
- [Security Considerations](#security-considerations)  
- [License](#license)  

---

## **Introduction**  
The **Decentralized Library Management System** is a blockchain-based solution that enables secure management and distribution of digital publications. It leverages **Clarity smart contracts** to register publications, enforce access control, and track usage statistics in an immutable, decentralized manner.

---

## **Features**  
✔ **Decentralized Publication Storage** – Users can register and manage publications without reliance on a central authority.  
✔ **Access Control** – Publication creators can grant or revoke permissions for specific users.  
✔ **Immutable Record Keeping** – All transactions are recorded on the blockchain, ensuring transparency.  
✔ **Usage Tracking** – Keeps count of publication accesses for analytics.  
✔ **Permission-Based Access** – Prevents unauthorized users from viewing content.  

---

## **Smart Contract Overview**  
The contract is built using **Clarity**, a predictable and secure smart contract language for the Stacks blockchain. It maintains a **publication registry** along with **user permissions** and **access statistics**.

---

## **System Components**  

### 1. **Publication Registry**  
- Stores metadata about digital publications, including title, creator, file size, description, and tags.

### 2. **User Permissions**  
- Maps users to specific publications they have access to.

### 3. **Usage Statistics**  
- Keeps a count of how many times each publication has been accessed.

### 4. **System Constants & Limits**  
- `TITLE-MAX-CHARS` – Maximum title length.  
- `DESCRIPTION-MAX-CHARS` – Maximum description length.  
- `FILE-SIZE-LIMIT` – Maximum allowed file size in bytes.  
- `MAX-TAG-COUNT` – Maximum number of classification tags per publication.  

---

## **Error Handling**  
The contract defines specific error codes for better debugging and security:  

- **301** – Publication not found  
- **302** – Duplicate publication entry  
- **303** – Invalid title format or length  
- **304** – File size exceeds allowed limit  
- **305** – Unauthorized access attempt  
- **306** – Invalid user  
- **307** – Operation restricted to admin  
- **308** – User lacks necessary permissions  
- **309** – Explicit access restriction  

---

## **Contract Functions**  

### **1. `register-publication`**  
Registers a new publication with metadata and access permissions.  
```clarity
(define-public (register-publication 
    (title (string-ascii 64)) 
    (byte-count uint) 
    (description (string-ascii 256)) 
    (tags (list 8 (string-ascii 32))))
)
```
📌 **Requires:**  
✔ Title, description, and tags must meet character limits.  
✔ File size must not exceed system limits.  
✔ Automatically assigns ownership to the `tx-sender`.  

---

### **2. `get-publication-details`**  
Retrieves metadata and statistics for a publication.  
```clarity
(define-read-only (get-publication-details (publication-id uint)))
```
📌 **Returns:**  
✔ Title, creator, file size, creation block, description, tags, and access count.  

---

### **3. `change-creator`**  
Transfers ownership of a publication to another user.  
```clarity
(define-public (change-creator (publication-id uint) (new-creator principal)))
```
📌 **Requires:**  
✔ Caller must be the current creator.  
✔ New owner must be a valid principal.  

---

### **4. `access-publication`**  
Records access to a publication if the user has permission.  
```clarity
(define-public (access-publication (publication-id uint)))
```
📌 **Requires:**  
✔ Publication must exist.  
✔ User must have permission.  
✔ Increments access count.  

---

### **5. `modify-publication`**  
Updates the metadata of an existing publication.  
```clarity
(define-public (modify-publication 
    (publication-id uint) 
    (updated-title (string-ascii 64)) 
    (updated-size uint) 
    (updated-description (string-ascii 256)) 
    (updated-tags (list 8 (string-ascii 32))))
)
```
📌 **Requires:**  
✔ Caller must be the creator.  
✔ New data must meet validation rules.  

---

### **6. `remove-publication`**  
Deletes a publication from the system.  
```clarity
(define-public (remove-publication (publication-id uint)))
```
📌 **Requires:**  
✔ Caller must be the creator.  
✔ Publication must exist.  

---

## **Deployment**  

### **Prerequisites:**  
- Install [Clarity Developer Tools](https://docs.stacks.co/clarity)  
- Set up a Stacks blockchain testnet or mainnet environment  

### **Deploying the Contract**  
1. Compile the contract:  
   ```bash
   clarity check digital-library.clar
   ```  
2. Deploy using the Stacks CLI:  
   ```bash
   clarity deploy digital-library.clar
   ```  

---

## **Usage Guide**  

### **Registering a New Publication**  
```clarity
(contract-call? .digital-library register-publication "Blockchain Essentials" u500000 "A guide to blockchain technology." ["tech" "education"])
```

### **Accessing Publication Details**  
```clarity
(contract-call? .digital-library get-publication-details u1)
```

### **Granting Access to a User**  
```clarity
(contract-call? .digital-library access-publication u1)
```

---

## **Security Considerations**  
🔒 **Immutability:** Data stored on the blockchain is permanent.  
🔒 **Access Control:** Only authorized users can modify or access publications.  
🔒 **Validation Rules:** Prevents invalid entries and unauthorized actions.  

---

## **License**  
This project is licensed under the **MIT License** – feel free to use, modify, and distribute.  

---

