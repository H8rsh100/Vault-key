# VaultKey — Full Project Specification

> **Naming Note:** All references to `SmartWallet` in older docs/code refer to **VaultKey**. The project was renamed early on. Use `VaultKey` everywhere going forward.

---

## Table of Contents

1. [Problem Statement](#problem-statement)
2. [Solution](#solution)
3. [Tech Stack](#tech-stack)
4. [What Makes This Senior-Caliber](#what-makes-this-senior-caliber)
5. [Folder Structure](#folder-structure)
6. [16-Day Build Plan](#16-day-build-plan)
7. [Agent Ground Rules](#agent-ground-rules)

---

## Problem Statement

Web3 adoption remains bottlenecked by **wallet UX**, not blockchain capability.

- Users must safeguard a 12-word seed phrase with **zero recovery options** if lost.
- Users must hold **native gas tokens** before performing any action — even a first-time signup.

Industry leaders (Coinbase, Alchemy) have converged on **ERC-4337 account abstraction** as the fix. Account abstraction is expected to become the standard UX layer for consumer-facing Web3 apps by 2026, eliminating seed phrases and manual gas management in favor of smart contract wallets with social recovery and sponsored transactions.

---

## Solution

**VaultKey** is a smart contract wallet implementing ERC-4337 that:

1. **Sponsors gas** via a paymaster so users never need native tokens to transact.
2. **Replaces seed phrases** with N-of-M guardian-based social recovery, so losing a device doesn't mean losing funds permanently.

> This mirrors exactly what Coinbase's Smart Wallet and similar production systems solve today — this isn't a toy problem, it's the current frontier of Web3 UX.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Smart Contracts | Foundry / Solidity, ERC-4337 (LightAccount-based) |
| Bundler | Pimlico or Alchemy (hosted, free tier) |
| Backend | FastAPI + PostgreSQL |
| Frontend | React + Vite + Tailwind + viem |
| Network | Base Sepolia (testnet) |
| Deployment | Render (backend) + Netlify (frontend) |

---

## What Makes This Senior-Caliber

### 1. Testing Rigor

- **Coverage target:** 90%+ on all contracts (`forge coverage`)
- **Fuzz tests** on `SocialRecoveryModule`:
  - 0 guardians edge case
  - 1-of-1 threshold edge case
  - Malicious guardian trying to self-approve twice
- **Invariant tests:**
  - Wallet balance never goes negative
  - Only valid EntryPoint can call `validateUserOp`

### 2. Security Posture

- Reentrancy guards on all fund-moving functions
- Explicit access control modifiers:
  - `onlyEntryPoint`
  - `onlyOwnerOrEntryPoint`
  - `onlyGuardian`
- **`SECURITY.md`** documenting the threat model:
  - What happens if a guardian key is compromised
  - What happens if the paymaster runs out of funds
  - What happens on bundler downtime
- **Run Slither** (static analyzer) before final submission
- Document all findings and fixes in `docs/audit-notes.md`

### 3. CI/CD

- **GitHub Actions** workflow (`.github/workflows/ci.yml`)
- On every push, run:
  - `forge test`
  - `forge coverage`
  - `backend pytest`
  - `frontend lint/build`

> CI alone signals "professional practice" more than almost anything else in a student project.

### 4. API Design Discipline

- **OpenAPI docs** auto-generated via FastAPI (`/docs`) — don't skip this
- **Typed error handling** — no bare 500s
- **Rate limiting** on the paymaster sponsorship endpoint (prevent abuse/gas drain attacks)

### 5. Documentation

- **`README.md`** with:
  - Problem statement
  - Architecture diagram
  - Setup instructions
  - Demo GIF
  - Tech decisions ("why ERC-4337 over EOA", "why Base over Ethereum mainnet")
- **`docs/architecture.md`** — diagram showing:
  ```
  User → Frontend → Backend (paymaster/relay) → Bundler → EntryPoint → VaultKey contract
  ```
- **Inline NatSpec comments** on all Solidity functions (`/// @notice`, `/// @param`)

---

## Folder Structure

```
vaultkey/
├── .github/
│   └── workflows/
│       └── ci.yml
├── contracts/
│   ├── src/
│   │   ├── VaultKey.sol                  (renamed from SmartAccount.sol)
│   │   ├── VaultKeyFactory.sol           (renamed from SmartAccountFactory.sol)
│   │   └── SocialRecoveryModule.sol
│   ├── test/
│   │   ├── VaultKey.t.sol
│   │   ├── VaultKeyFactory.t.sol
│   │   └── SocialRecoveryModule.t.sol    (unit + fuzz + invariant)
│   ├── script/
│   │   └── Deploy.s.sol
│   └── foundry.toml
├── backend/
│   ├── app/
│   │   ├── routers/
│   │   │   ├── wallet.py
│   │   │   └── guardians.py
│   │   ├── models/
│   │   ├── services/
│   │   │   ├── bundler_client.py
│   │   │   └── paymaster.py
│   │   ├── auth.py
│   │   └── db.py
│   ├── tests/
│   ├── requirements.txt
│   └── Dockerfile
├── frontend/
│   └── src/
│       ├── components/
│       │   ├── WalletCreate.jsx
│       │   ├── SendTx.jsx
│       │   ├── RecoveryFlow.jsx
│       │   └── TxHistory.jsx
│       ├── hooks/
│       └── lib/
├── docs/
│   ├── problem-statement.md
│   ├── architecture.md
│   └── audit-notes.md
├── SECURITY.md
├── .gitignore
└── README.md
```

---

## 16-Day Build Plan

### Day 1 — Setup & Solidity Refresher
- Install Foundry (via WSL or Git Bash — **not raw PowerShell**)
- `forge init` inside `contracts/`
- Write a plain (non-abstracted) wallet contract: holds ETH, lets owner send funds
- Deploy to Base Sepolia testnet manually
- **Goal:** Get comfortable with Foundry + testnet deploys before ERC-4337 complexity

### Day 2 — Understand ERC-4337 Deeply *(No coding)*
- Read the EIP
- Read Alchemy's account abstraction docs
- Watch one good YouTube walkthrough
- Understand: `UserOperation`, `EntryPoint`, bundler, paymaster roles
- Write a one-page notes doc — needed to explain the project in interviews/write-up

### Days 3–4 — VaultKey.sol (SmartAccount)
- Fork/adapt Alchemy's LightAccount as base `VaultKey.sol`
- Implement `validateUserOp`, `execute`
- NatSpec comments on every function
- Write `VaultKey.t.sol` covering:
  - Owner can execute ✓
  - Non-owner cannot execute ✓
  - Signature validation ✓

### Day 5 — VaultKeyFactory.sol
- Implement factory pattern with **CREATE2** (deterministic addresses before deployment)
- Test: factory creates accounts correctly

### Days 6–7 — SocialRecoveryModule.sol
- `Guardian` struct + mapping
- Functions: `addGuardian`, `removeGuardian`, `initiateRecovery`, `approveRecovery`, `executeRecovery` (N-of-M)
- Full test suite including:
  - Fuzz tests (0 guardians, 1-of-1, self-approve twice)
  - Invariant tests
- **This is the most interesting contract — spend real time here**

### Day 8 — Deploy Contracts to Base Sepolia
- Write `Deploy.s.sol` script
- Deploy Factory + implementation
- Verify on Basescan
- Save deployed addresses in `docs/` (public addresses only — no secrets)

### Days 9–10 — Backend: Paymaster + Bundler Integration
- FastAPI project setup
- Sign up for Pimlico or Alchemy bundler (free tier)
- Build:
  - `bundler_client.py` — submits UserOps to hosted bundler
  - `paymaster.py` — sponsorship logic (e.g., first N txs free)
- Build `wallet.py` router: `create wallet`, `get wallet by user`
- Rate limiting on sponsorship endpoint

### Day 11 — Backend: Guardians + Auth
- `guardians.py` router: `add`, `list`, `approve`
- JWT auth (bcrypt + JWT — same pattern as PromptVault)
- PostgreSQL models: `User`, `Wallet`, `Guardian`, `Transaction`

### Days 12–13 — Frontend
- Vite + React + Tailwind scaffold
- Components:
  - `WalletCreate.jsx` — **no seed phrase shown** (this is the whole point)
  - `SendTx.jsx` — gas fee invisible, paymaster covers it
  - `RecoveryFlow.jsx` — guardian approval UI
  - `TxHistory.jsx`
- Wire up to backend APIs + `viem` for on-chain state reads

### Day 14 — Security Pass
- Run **Slither** static analysis on all contracts
- Add reentrancy guards where missing
- Write `SECURITY.md` (threat model)
- Fix all findings, document everything in `docs/audit-notes.md`

### Day 15 — CI Setup
- Write `.github/workflows/ci.yml`
- Get all tests green in the pipeline:
  - `forge test` + `forge coverage`
  - `pytest` (backend)
  - Frontend lint + build

### Day 16 — Docs + Polish + Deploy
- Dockerize backend, deploy to **Render**
- Deploy frontend to **Netlify**
- Write/finalize `docs/architecture.md` with flow diagram
- Finalize `README.md` (problem, diagram, setup, demo GIF, tech decisions)
- Record demo video/GIF for submission

---

## Agent Ground Rules

| Rule | Detail |
|---|---|
| **Environment** | Windows/PowerShell — Foundry needs WSL or Git Bash, not raw PowerShell |
| **Git** | No CLI git. All commits go through **GitHub Desktop**. Agent modifies files only — user commits manually |
| **Secrets** | All `.env` files must be gitignored from Day 1. Never commit RPC URLs, private keys, bundler API keys, or JWT secrets |
| **File creation** | On Windows, use `New-Item -ItemType File` where `touch`/`echo` fail |
| **Naming** | Everywhere you see `SmartWallet`, treat it as `VaultKey` |
| **Commits** | **Make commits and push immediately after each meaningful change** — this is the primary development workflow rule |
| **Repo** | `H8rsh100/Vaultkey` on GitHub |

---

*Spec locked. Awaiting green signal to begin Day 1.*
