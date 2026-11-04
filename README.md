# Mere Paise (मेरे पैसे)

> **A fast, offline-first personal finance ledger for everyday Indian money, built like an honest account book and not like a toy.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore%20Offline-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)](https://android.com)

---

## 🏛️ Philosophy & Design: *Ledger of the Night*

**Mere Paise** was designed around a simple conviction: **logging an expense must be faster than forgetting it.** When standing at a tea stall, getting off a bus, or paying via UPI in a crowded market, recording transactions should take fewer than 3 taps and under 5 seconds.

Instead of playful, gamified, or bloated finance apps, Mere Paise embraces a gothic, disciplined aesthetic dubbed **"Ledger of the Night"**:

* **Numbers are sacred:** Amounts are always the most prominent, legible element on screen.
* **Zero floating-point rounding errors:** All monetary amounts are stored strictly as integer **paise** (`₹ 249.50` is stored as `24950`).
* **Indian numeral formatting:** Native grouping system (`₹ 1,25,000` rather than `₹ 125,000`).
* **Consistent color coding:** 
  * **Oxblood (`#8E1B2B` / `#C2394B`):** Money Out (Expenses, preceded by `−`).
  * **Verdigris (`#4E7A63` / `#7FB08F`):** Money In (Income, preceded by `+`).
  * **Brass (`#B4915A`):** Net balance and primary accents.
* **Quiet, ordered surfaces:** Dense dark layouts, hairline 1px borders, subtle haptics, and zero decorative distractions.

---

## ✨ Key Features

### ⚡ Quick Entry (Under 5 Seconds)
* **Immediate numeric keypad:** Opens directly with the keypad raised; no redundant screens.
* **Segmented Out / In toggle:** Instantly re-themes the entire sheet between Oxblood (expense) and Verdigris (income).
* **Smart defaults:** Remembers your last-used category, defaults to current time, and offers single-tap buttons for "Yesterday" or custom dates.
* **Inline tags & notes:** Create `#tags` inline with automatic tag completion.
* **Duplicate protection:** Prevents accidental double-taps by verifying identical amount, category, and minute.

### 📜 Bahi (Home) & Chronological Ledger
* **Bahi Overview:** Monthly net balance, side-by-side Out/In summary cards, and a 7-day compact spending bar strip.
* **Grouped Ledger:** Transactions organized by day with day-level subtotals.
* **Swipe-to-delete with Undo:** 6-second grace period with undo snackbar.
* **Advanced Multi-Facet Filtering:** Filter by date range, transaction type (Out / In), category, tag, or amount range, with full-text search across notes and tags.

### 📊 Comprehensive Insights & Visualizations
* **5 Reporting Horizons:** Seamlessly switch between **Day**, **Week**, **Month**, **Year**, and **All-Time** views with previous/next period navigation.
* **Custom-Themed Charts (`fl_chart`):**
  * *Day:* Hourly timeline with time-of-day distribution (Morning, Afternoon, Evening, Night).
  * *Week:* 7-day comparative bars (Out vs. In).
  * *Month:* Daily spending bars with a cumulative spend progression line.
  * *Year:* 12 monthly bars with a net trendline.
  * *All-Time:* Long-term historical trend graph.
* **Category Breakdown & Drill-Down:** Ranked category expenditure bars. Tapping any category or chart slice immediately filters and opens the matching transactions in the Ledger.

### 🏷️ Flexible Category & Tag Management
* **Custom Categories:** Add, edit, recolor, choose custom line-icons, reorder, or archive categories.
* **Safe Deletion with Reassignment:** Deleting a category prompts reassigning its existing transactions to another category or archiving it, ensuring historic records are never orphaned.
* **Tag Control:** View usage frequency, rename, merge, or delete tags across all entries.

### 🛡️ Offline-First Architecture & Cloud Sync
* **Immediate local responsiveness:** Powered by persistent local cache and reactive Riverpod state.
* **Background synchronization:** Automatic synchronization with Cloud Firestore when network connectivity is available.
* **Precomputed monthly summaries:** Maintains lightweight summary documents updated via batched writes (`FieldValue.increment`), keeping dashboard lookups and graph computations near-instantaneous while minimizing Firestore reads.

### 🎨 Themes & Preferences
* **Gothic Dark ("Obsidian"):** High-contrast dark theme with `#0C0B0D` background.
* **Parchment Light ("Vellum"):** High-readability parchment theme with `#EFE8D8` background and `#1A171C` ink text.
* **Custom Calendars:** Configurable first day of the week (Monday default) and custom month start day (1 to 28) to match monthly salary cycles.
* **CSV Export:** Export transaction history to CSV anytime.

---

## 🎨 Color Palette & Typography

### Design Tokens

| Token | Hex | Role |
| :--- | :--- | :--- |
| `obsidian` | `#0C0B0D` | Deep background |
| `crypt` | `#151317` | Cards, bottom sheets, navigation bar |
| `slab` | `#1E1B21` | Elevated surfaces, input containers, keypad keys |
| `iron-line` | `#34303A` | Hairline borders and section dividers (1px) |
| `bone` | `#E9E1D1` | Primary text and headings |
| `ash` | `#9A9285` | Secondary text, placeholders, metadata |
| `brass` | `#B4915A` | Primary accent, selected states, Net balance |
| `oxblood` / `lit` | `#8E1B2B` / `#C2394B` | Money Out (Expenses), warnings |
| `verdigris` / `lit` | `#4E7A63` / `#7FB08F` | Money In (Income), positive metrics |
| `tallow` | `#C9A23F` | Budget warnings and alerts |

### Typography

* **Wordmark:** Blackletter display font (*UnifrakturCook*) used exclusively on the splash screen and app branding.
* **Headings:** High-contrast serif (*Cormorant Garamond* / *Cinzel*).
* **Body & UI:** Crisp humanist sans (*Source Sans 3*).
* **Numbers:** High-legibility serif with tabular figures (*Spectral* / *IBM Plex Mono*), ensuring all financial columns align.

---

## 🏗️ Architecture & Project Structure

The project adopts a modular, **feature-first** architecture with strict separation between data, presentation, and domain layers.

```
lib/
├── core/
│   ├── constants/        # Category icons, constants
│   ├── theme/            # AppColors, AppTheme (Obsidian & Vellum), AppTypography
│   ├── utils/            # CurrencyFormatter (paise logic), DateUtils, Haptics
│   └── widgets/          # GothicCard, GothicDivider, GothicEmptyState
├── features/
│   ├── auth/             # Firebase Authentication & Google Sign-In
│   ├── data/             # StorageService, LedgerRepository, FirestoreSyncService
│   ├── entries/          # QuickAddSheet, Keypad, transaction form components
│   ├── home/             # HomeScreen (Bahi), summary cards, 7-day strip
│   ├── insights/         # InsightsScreen, Day/Week/Month/Year/All graphs
│   ├── ledger/           # LedgerScreen, search & filter bars, entry rows
│   ├── manage/           # CategoriesScreen, Tag management, Settings, Export
│   ├── models/           # TransactionEntry, CategoryItem, TagItem, MonthSummary
│   └── providers/        # Riverpod StateNotifiers & computed providers
├── firebase_options.dart # Generated Firebase configuration
└── main.dart             # App entry point & bottom navigation scaffold
```

### Data Storage & Sync Model

```
users/{uid}/
├── profile/              # Currency, week start, salary start day
├── categories/{catId}    # Category name, kind (expense/income), icon, color
├── tags/{tagId}          # Tag definitions and creation metadata
├── transactions/{txnId}  # Integer amountPaise, categoryId, dayKey, monthKey, etc.
└── summaries/{monthKey}  # Precomputed outPaise, inPaise, and category breakdowns
```

---

## 🚀 Getting Started

### Prerequisites

* [Flutter SDK](https://docs.flutter.dev/get-started/install) (version `>= 3.13.4` or Flutter 3.24+)
* [Dart SDK](https://dart.dev/get-dart) (`^3.13.4`)
* Android SDK / Android Studio configured with API level 26+ (Android 8.0+)
* A configured [Firebase project](https://console.firebase.google.com/) with Cloud Firestore and Authentication enabled

### Installation & Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/mere-paise.git
   cd mere-paise
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase:**
   Ensure `google-services.json` is placed in `android/app/` (or run `flutterfire configure`).

4. **Deploy Firestore Security Rules:**
   ```bash
   firebase deploy --only firestore:rules
   ```

5. **Run on an Android device or emulator:**
   ```bash
   flutter run
   ```

6. **Build release APK:**
   ```bash
   flutter build apk --release
   ```

---

## 🧪 Testing

Run unit and widget tests:

```bash
flutter test
```

Test coverage includes:
* **CurrencyFormatter:** Accurate parsing and formatting of integer paise, Indian numbering groupings, and signed expense/income values.
* **DateUtils:** Period calculations for day, week, month, and year keys.
* **Category Defaults:** Verification of default expense and income classifications.

---

## 🗺️ Roadmap

- [x] **v1.0 (MVP):**
  - [x] Core offline-first ledger with integer paise calculations
  - [x] Quick Add bottom sheet with custom numeric keypad
  - [x] Chronological Ledger with search, multi-facet filtering, and swipe-to-delete undo
  - [x] Insights with 5 period views (Day, Week, Month, Year, All) and category drill-downs
  - [x] Full Categories CRUD with reassignment flow & Tag management
  - [x] Obsidian (Dark) & Vellum (Light) themes
  - [x] CSV export & Firestore background sync
- [ ] **v1.1:**
  - [ ] Multi-account tracking (Cash, Bank, UPI, Credit Card) & inter-account transfers
  - [ ] Category budgets with progressive warning alerts
  - [ ] Recurring transactions (Rent, subscriptions, monthly income)
  - [ ] Biometric app lock (Fingerprint / PIN)
- [ ] **v1.2:**
  - [ ] Receipt photo attachments
  - [ ] Formatted PDF ledger statements
  - [ ] Full Hindi (हिंदी) localization
  - [ ] iOS release

---

## 📄 License

This project is licensed under the **GNU General Public License v3.0 (GPLv3)**. See the [LICENSE](LICENSE) file for details.
