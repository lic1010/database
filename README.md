# 🛒 團購商務系統 — 安裝與執行說明 (Windows 11 + Docker)

這份說明是針對你的環境寫的：
**Windows 11、資料庫跑在 Docker、專案資料夾在 `C:\Users\lee09\database>`**

---

## 📁 檔案說明

| 檔案 | 用途 |
|---|---|
| `01_schema_original.sql` | 你原本的資料表、10 筆種子資料、原本的 6 個 View（一字未改） |
| `02_groupbuy_extension.sql` | **新增**的 `GroupProduct` 關聯表 + 10 筆種子資料 + 4 個新 View（讓「瀏覽團購／加入團購」可以運作） |
| `app.py` | 全新改寫的 Streamlit 前端，支援會員「加入團購」與團主「開新團/上架商品」 |
| `requirements.txt` | Python 套件清單 |

> ⚠️ 重要：兩支 SQL 要**依序**執行，`02` 必須在 `01` 之後執行（因為它參照 `01` 建立的表）。

---

## 🧩 為什麼新增了 `GroupProduct` 表？

你原本的設計裡，商品 (`Product`) 只透過「訂單」間接連到「團購活動」(`GroupBuyGroup`)，
也就是說：**沒有人下單之前，根本看不出某個團購裡賣什麼商品**。

`GroupProduct` 是團購活動與商品的「上架關聯表」，紀錄：
- 哪個團 (`groupId`) 賣哪個商品 (`productId`)
- 這個團的「團購價」(`groupPrice`，可能跟原價不同)
- 這個團限定的庫存 (`groupStock`)

有了這張表，會員才能在下單**之前**先看到「這個團在賣什麼」，這是「加入團購」功能能成立的關鍵。

---

## 🪜 安裝步驟

### 1. 確認 Docker 容器正在跑

打開 PowerShell 或 CMD，進入你的專案資料夾：

```powershell
cd C:\Users\lee09\database
```

如果你還沒建立過 PostgreSQL 容器，用下面指令建立一個（帳密請自行替換，並同步修改 `app.py` 裡的 `DB_CONFIG`）：

```powershell
docker run --name nhust-postgres -e POSTGRES_PASSWORD=mysecretpassword -e POSTGRES_DB=nhust_shop -p 5432:5432 -d postgres
```

如果容器已經存在但是關閉的，啟動它：

```powershell
docker start nhust-postgres
```

確認容器有在跑：

```powershell
docker ps
```

應該要看到一行 `nhust-postgres ... Up X minutes ... 0.0.0.0:5432->5432/tcp`。

---

### 2. 把兩支 SQL 檔放進專案資料夾

把 `01_schema_original.sql` 和 `02_groupbuy_extension.sql` 複製到：

```
C:\Users\lee09\database\
```

---

### 3. 執行 SQL（建表 + 灌資料）

**方法 A：用 docker exec + psql（推薦，不用額外裝軟體）**

```powershell
cd C:\Users\lee09\database

docker exec -i nhust-postgres psql -U postgres -d nhust_shop < 01_schema_original.sql
docker exec -i nhust-postgres psql -U postgres -d nhust_shop < 02_groupbuy_extension.sql
```

> 如果你的容器名稱不是 `nhust-postgres`，請用 `docker ps` 查看實際名稱並替換。

**方法 B：用 DBeaver / pgAdmin 等圖形化工具**

連線到 `localhost:5432`，資料庫選 `nhust_shop`，帳號 `postgres`，密碼你自己設定的那組，
然後依序開啟並執行 `01_schema_original.sql`、`02_groupbuy_extension.sql`。

**如果中途要重來（砍掉重練）：**

```powershell
docker exec -i nhust-postgres psql -U postgres -d nhust_shop -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
```

跑完這行之後，再重新執行步驟 3 的兩支 SQL。

---

### 4. 安裝 Python 套件

建議使用虛擬環境，但直接裝也可以：

```powershell
cd C:\Users\lee09\database
pip install -r requirements.txt
```

---

### 5. 確認 `app.py` 裡的連線設定

打開 `app.py`，找到最上面這段，確認跟你 Docker 容器的設定一致：

```python
DB_CONFIG = dict(
    host="localhost",
    database="nhust_shop",
    user="postgres",
    password="mysecretpassword",  # 改成你自己的密碼
    port="5432",
)
```

---

### 6. 啟動系統

```powershell
cd C:\Users\lee09\database
streamlit run app.py
```

瀏覽器會自動開啟 `http://localhost:8501`，看到「🛒 物聯網導購與團購運轉系統」就代表成功了。

---

## ✅ 功能總覽

### 一般會員 (買家)

| 分頁 | 功能 |
|---|---|
| 🔥 瀏覽團購／加入團購 | 看所有**進行中**的團、每團賣什麼商品、選商品+規格+數量+優惠券後**一鍵加入（下單）** |
| 📋 我的選購紀錄 | 沿用原本的 `View_Member_Browsing_Specs`，看自己跟過哪些團、選過什麼規格 |
| 💰 我的訂單 | 看訂單狀態、**付款**（會寫入 `Payment` 表）、**取消訂單**（邏輯刪除，status 改 0） |
| 💳 付款收據 | 沿用原本的 `View_Member_Payment_Receipt` |

### 團主 (主揪)

| 分頁 | 功能 |
|---|---|
| 🆕 開新團／上架商品 | **建立新的團購活動**（寫入 `GroupBuyGroup`），並把商品**上架到該團**（寫入 `GroupProduct`，可自訂團購價、團購限定庫存） |
| 📦 庫存管理 | 看自己每個團、每樣商品的庫存狀況 |
| 🚀 開團成效 | 看自己開的團目前狀態，以及**有哪些人跟團下單**（含買家帳號、金額、狀態） |
| 📝 宣傳貼文 | 看歷史宣傳貼文，並可**發佈新貼文**到指定團購 |

---

## 🔍 加入團購的運作邏輯（給想了解細節的你）

會員按下「✅ 確認加入團購」之後，系統會做三件事（在同一個交易內）：

1. 在 `"Order"` 表新增一筆訂單（狀態 = `'1'` 處理中）
2. 在 `ProductSpecification` 表新增一筆規格紀錄，連到剛剛的訂單
3. 把 `GroupProduct.groupStock` 扣掉購買數量

如果中途任何一步失敗（例如庫存不足），整筆交易會自動 rollback，不會留下半套資料。

之後在「我的訂單」分頁按「付款」，才會在 `Payment` 表寫入付款紀錄，這時訂單才會出現在「付款收據」分頁——這跟真實電商「下單 → 付款」是兩個步驟的邏輯一致。

---

## 🛠️ 常見問題

**Q: 跑起來顯示「無法連線到 PostgreSQL 資料庫」？**
A: 90% 是 Docker 容器沒開。執行 `docker ps` 確認容器狀態，沒有的話 `docker start <容器名稱>`。

**Q: 商品選單是空的、或團購清單是空的？**
A: 確認 `02_groupbuy_extension.sql` 真的有跑成功。可以用以下指令檢查：
```powershell
docker exec -i nhust-postgres psql -U postgres -d nhust_shop -c "SELECT * FROM GroupProduct;"
```
應該要看到 10 筆資料。

**Q: 想砍掉重練怎麼辦？**
A: 參考上面步驟 3 的「砍掉重練」指令，重跑兩支 SQL 即可，App 完全不用動。

**Q: 團購截止時間都設在 2026 年，會不會「看不到團」？**
A: 不會。10 個種子團購中，有 9 個截止日期晚於 2026/06/20（系統目前日期）且狀態為「進行中」，會出現在「瀏覽團購」清單；唯一一個 `g260100004`（不沾鍋特惠組）是刻意設計的「歷史已結團」測試資料（state='2'、建立於 2025/12），因為超過原本系統設計的「近 35 天」時間窗，所以也不會出現在團主後台的「開團成效」分頁——這是延續你原始 SQL 的設計邏輯，純粹用來驗證歷史資料有被正確隔離。
