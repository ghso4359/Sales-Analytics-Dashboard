# Sales Analytics Dashboard (Flutter)

A self-contained, portfolio-ready **Flutter analytics dashboard**, adapted from my original `AnalyticsPage` implementation. The demo uses 916 **synthetic retail orders**—not real customer data—to demonstrate how order records can power charts and KPIs.

## Features

- Revenue, orders, distinct customers, and average order value for **7 / 30 / 90 / 365 days or all time**.
- Percentage changes vs the corresponding previous period; **N/A** when the comparison period has a zero baseline.
- Sales trend line chart, order count bar chart, category pie chart, and top five products.
- Items and revenue derived directly from **ordered quantity × unit price**, represented in **integer cents**.
- Excludes cancelled and future-dated orders from completed-sales KPIs.
- Interactive **Add test order** button: select a catalogue product and quantity, then immediately see the KPIs and charts change.
- **Reset** test orders to return to the bundled sample data.
- Automated tests for amounts, cancellations, unique customers, period comparisons, year boundaries, and reading the bundled sample data.
- A GitHub Actions pipeline to test, build, and deploy the web version to GitHub Pages.

## Project layout

```text
lib/
  main.dart                        Flutter entry point
  pages/analytics_page.dart        Dashboard UI (adapted from my original page)
  models/orderModel.dart           Orders / items / prices / status
  models/mock_orders.dart          Loads and parses JSON sample orders
  data/product_catalog.dart       Catalogue used in the test-order controls
  services/analytics_calculator.dart   Pure calculation logic
assets/data/sample_orders.json     916 fictional orders (relative dates)
test/                              Automated tests
.github/workflows/flutter-pages.yml    Test + GitHub Pages deployment
original/analytics_page_original.dart.txt  Original supplied source for reference
```

## Run locally

Prerequisite: [Flutter SDK](https://docs.flutter.dev/get-started/install) and Chrome.

Open a terminal in the folder containing `pubspec.yaml` and run:

```bash
flutter pub get
flutter run -d chrome
```

If Flutter reports that web project files are missing, run this once, then retry:

```bash
flutter create --platforms=web --project-name=sales_analytics_dashboard .
flutter pub get
flutter run -d chrome
```

To verify everything:

```bash
flutter analyze
flutter test
```

> **Validation note:** This source bundle was assembled without a local Flutter SDK, so Flutter analysis, tests, and actual web compilation could not be executed in the authoring environment. The commands and GitHub Actions workflow are provided to validate it in an installed Flutter environment.

## Experiment with sample data

### From the dashboard (easiest)

1. Open the page, choose **Last 7 days** or **Last 30 days**.
2. Scroll to **Test with a new order**.
3. Choose *Wireless Mouse* ($29.90) and quantity `2`.
4. Click **Add test order**. The new order contributes **$59.80** to the selected period's revenue, **1** to its orders count, **1** new unique customer, and **2** units sold of that product. (All values are recomputed.)
5. Click **Reset** to remove orders added through the UI. These added orders only live in memory; reloading the page also resets them.

### By changing the dataset

Edit `assets/data/sample_orders.json`, which is a JSON array of orders. For example:

```json
{
  "id": "ORD-TEST-001",
  "customerId": "CUST-EXAMPLE",
  "customerName": "Example Customer",
  "daysAgo": 2,
  "hour": 12,
  "minute": 0,
  "status": "completed",
  "items": [
    {
      "sku": "ELEC-01",
      "name": "Wireless Mouse",
      "category": "Electronics",
      "unitPriceCents": 2990,
      "quantity": 2
    }
  ]
}
```

Add this object to the **array** (with a comma between objects), rather than replacing the whole file with the example object. The computed order total is **2990 × 2 = 5980 cents (A$59.80)**. There is intentionally **no manually entered order total** to get out of sync with the items.

`daysAgo` is relative to the day you run the application, so the demo retains recent orders as time passes. The loader also accepts a real system's ISO 8601 `orderTime` string instead of `daysAgo`.

The JSON dataset, the catalogue used for new test orders, and the prices shown in the charts use the same item-level price/quantity formula. For production, load records from an API/database and validate payment statuses server-side; this demo does **not** connect to live orders or store added orders in a database.

## Upload to GitHub

Use repository name **`Sales-Analytics-Dashboard`** (important because the deployment base path uses this name).

### GitHub website (no Git needed)

1. On GitHub, create a new repository named `Sales-Analytics-Dashboard` and leave it public if you want to publish the demo openly.
2. **Do not upload the ZIP file as a single file.** Unzip it on your computer first.
3. Open the empty repository → **Add file → Upload files** and drag the **contents inside** the unzipped `Sales-Analytics-Dashboard` folder, so `pubspec.yaml`, `lib/`, `assets/`, `.github/` are at the repository root. Browser upload workflows may omit hidden files; ensure `.github/workflows/flutter-pages.yml` is uploaded (or create it in GitHub's file editor).
4. Click **Commit changes** (main branch).
5. In repository **Settings → Pages → Build and deployment → Source**, choose **GitHub Actions**.
6. Open the **Actions** tab and inspect the workflow. It runs `flutter analyze`, `flutter test`, builds for web and publishes Pages.
7. When the deploy workflow succeeds, the app URL is `https://YOUR-GITHUB-USERNAME.github.io/Sales-Analytics-Dashboard/`.

### Git command-line alternative

```bash
git init
git add .
git commit -m "Add Flutter sales analytics demo with sample order testing"
git branch -M main
git remote add origin https://github.com/YOUR-GITHUB-USERNAME/Sales-Analytics-Dashboard.git
git push -u origin main
```

If you change the repository name, also update the `--base-href` path in `.github/workflows/flutter-pages.yml`.

## Scope and data notes

- All customers, purchases and amounts in the bundled file are **fictional** and intended only for testing.
- The dashboard computes **sales/revenue**, not **profit or margin**. A margin feature would require cost-of-goods data and relevant refund/tax/shipping rules.
- Customers are counted using unique `customerId`, not order count or customer name.
- No persistent backend is configured. `Add test order` changes the dashboard in the current browser session only.
- The `original/` folder retains the uploaded dashboard source; only code under `lib/` is compiled.

---

## 한국어 빠른 사용법

1. Flutter가 설치되어 있다면 폴더에서 `flutter pub get` → `flutter run -d chrome` 실행.
2. 분석페이지의 기간을 선택한 다음 **Test with a new order**에서 상품·수량을 선택하여 추가하면 그래프와 매출이 재계산됨.
3. 직접 데이터를 바꾸려면 `assets/data/sample_orders.json` 편집. `unitPriceCents`는 호주달러 **센트 단위** (`2990` = A$29.90).
4. GitHub 저장소 `Sales-Analytics-Dashboard`를 만든 후 ZIP을 **압축 해제**하고 안의 파일과 폴더들을 업로드.
5. **Settings → Pages → Source: GitHub Actions**로 설정. **Actions** 탭에서 성공 여부 확인.
6. 이 예제는 실거래 데이터가 아닌 **테스트용 가상 주문 데이터**이며, 서버/실제 결제 시스템과는 연결되어 있지 않음.
