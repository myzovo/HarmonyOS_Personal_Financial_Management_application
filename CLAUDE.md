# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

HarmonyOS personal finance/bookkeeping app (记账本) built with ArkTS using the Stage model. Targets HarmonyOS SDK 5.1.0 (API 18) for phone devices.

**Bundle:** `com.example.myapplication`

## Build & Run

**Build tool:** Hvigor (HarmonyOS build system)  
**Package manager:** OHPM (OpenHarmony Package Manager)  
**IDE:** DevEco Studio

```bash
# Build HAP package
hvigor assembleHap

# Run tests (device-side)
hvigor assembleHap --target ohosTest

# Install dependencies
ohpm install
```

Deploy to device/emulator via DevEco Studio.

## Architecture

### Source Layout (`entry/src/main/ets/`)

```
entryability/     App entry point (EntryAbility.ets - UIAbility lifecycle)
model/            Data models (Bill.ets - interfaces, enums, category constants)
pages/            5 page components (screens)
components/       11 reusable UI components
utils/            Utilities (database, dates, file export, theme, constants)
```

### Pages

| Page | Route | Purpose |
|------|-------|---------|
| Index | `pages/Index` | Home dashboard: today/month summaries, recent bills, "+" FAB |
| AddBill | `pages/AddBill` | Add/edit bill form with category picker |
| BillList | `pages/BillList` | Bill list with month/week filtering, date-grouped |
| Statistics | `pages/Statistics` | Charts: pie, line (7-day trend), bar (monthly daily) |
| Export | `pages/Export` | JSON/CSV export with range selection |

### Navigation

- Bottom TabBar (4 tabs: Home, Bills, Statistics, Export)
- `router.pushUrl()` for forward nav, `router.replaceUrl()` for tab switches (avoids page stack buildup)

### Data Layer

- **Database:** HarmonyOS RDB (`@ohos.data.relationalStore`), singleton `DatabaseHelper`
- **DB name:** `ledger.db` (version 1)
- **Table:** `bills` with index `idx_bill_date` on `date` column
- **Schema:** id (TEXT PK), type (INTEGER: 0=expense/1=income), amount (REAL), category (TEXT), remark (TEXT), date (TEXT), createTime (TEXT), updateTime (TEXT)
- **Export:** Uses `@kit.CoreFileKit` (fileIo) to write to `/data/storage/el2/base/downloads`

### Key Patterns

- **Singleton database:** `DatabaseHelper.getInstance()` for all DB operations
- **Theme:** Centralized in `ThemeColors.ets` with color constants for light/dark modes
- **Categories:** Predefined lists in `Constants.ets` (9 expense, 5 income categories)
- **Charts:** Canvas-based PieChart, LineChart, BarChart with touch interaction and animations

## Testing

**Framework:** `@ohos/hypium` (unit), `@ohos/hamock` (mocking)

```bash
# Run device-side tests
hvigor assembleHap --target ohosTest
```

- Local tests: `entry/src/test/`
- Device tests: `entry/src/ohosTest/`
- Tests aggregated via `List.test.ets` files

## Linting

Config: `code-linter.json5`  
Applies to: `*.ets` files  
Rule sets: `@performance/recommended`, `@typescript-eslint/recommended`, `@security/no-unsafe-*`

## SDK APIs

- `@kit.AbilityKit` — UIAbility lifecycle, Want
- `@kit.ArkUI` — UI framework (router, promptAction, window)
- `@kit.PerformanceAnalysisKit` — hilog logging
- `@ohos.data.relationalStore` — RDB database
- `@kit.CoreFileKit` — File I/O, BackupExtensionAbility
