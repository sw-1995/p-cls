# PatentCloud 客製化專利分類（資料夾範圍）技術規格

> 目標：在**客戶提供的資料夾**內，使用**少樣本 (1–5/類)** 完成**3 層以內**（或依客戶需求更多）的**多標籤**專利分類（可設定 primary/secondary），產出可審查的證據、信心分數與報表。
> 前提：資料已清理；**嵌入模型使用自研 InQBERT Or Open Source Embedding**；**ANN 使用 Solr**。我們只分類該資料夾。

> 請善加利用System Prompt, 同一段要求放在User Prompt跟System Prompt解果是不同的

## 目錄

* [1. 系統概觀](#1-系統概觀)
* [2. 需求摘要](#2-需求摘要)
* [3. 重要概念與資料選取](#3-重要概念與資料選取)
* [4. 架構與流程](#4-架構與流程)
* [5. 介面規格（檔案佈局與設定）](#5-介面規格檔案佈局與設定)
* [6. 模組實作細節（LangChain + DSPy）](#6-模組實作細節langchain--dspy)
* [7. 推論與批次執行](#7-推論與批次執行)
* [8. 評估、校準與主動學習](#8-評估校準與主動學習)
* [9. 監控與可觀測性](#9-監控與可觀測性)
* [10. 安全與權限](#10-安全與權限)
* [11. 部署與設定](#11-部署與設定)
* [12. 常見問答](#12-常見問答)

## 1. 系統概觀

**重點**

* 以**資料夾**為作用域：該資料夾內有少量**已標記**樣本（每類 1–5 份）與大量**未標記**專利（待分類）。
* **混合式架構**：Retrieval（InQBERT+Solr）縮小候選 → LLM（LangChain prompt）做**比較式判斷** → DSPy 對**提示/範例自動優化**，持續逼近**宏觀 F1 ≥ 70%**（在小樣本下）。
* **多標籤**為預設：支援 primary（發明核心）+ secondary（索引/次要面向），並提供**Top-k 建議 + 證據片段**。
* **上線友善**：以**JSON I/O**、**YAML 設定**為主；不要求工程師懂訓練細節。

---

## 2. 需求摘要

* **輸入**：
  * 客戶資料夾（已清洗之專利）：每份含 `title`, `abstract`, `claims`（至少主權利項），可選 `CPC/IPC`, `priority`, `assignee`, `year`。
  * 客戶 taxonomy（≤3 層；若 >3 亦可），每節點可有 `name`, `desc`, `synonyms`，以及**1–5 範例專利 ID**。

* **輸出**：
  * `predicted_labels`（primary+secondary）、`scores`（0–1）、`evidence_spans`（正文偏移）、`rationale`（短句）、`topk_alternatives`。
  * 批次指標報告（macro/micro F1、每類覆蓋率、低信心清單）。

* **非功能性**：
  * 可離線批次；10k 級批次 2 小時內完成（依硬體/並行數調整）。
  * 可版本化 taxonomy 與模型設定；可重跑與審計。

---

## 3. 重要概念與資料選取

**為降低 token/延遲與幻覺風險，預設僅餵：**

* `abstract`（摘要）+ **主權利項**（Main claim）為主；
* 若檢索需要，追加**2–3 個證據片段**（來自 claims/description 中的高相似段）。
* 輔助特徵：`CPC/IPC`（作為檢索 prior，不直接給 LLM 當事實）。

> 理由：摘要 + 主權利項在區分技術主題上辨識度最高；多餘上下文由檢索控制選段。

---

## 4. 架構與流程

1. **資料準備**
    * 從 JSON/CSV 載入專利資料，進行正規化（欄位清理、格式統一），並建立索引。

2. **分類引導, 細節參考[分類引導](docs/分類引導.md)**

    2.1 **了解客戶技術範圍**

        1. **避免分類過大或過小**

        * 如果範圍太大（例如「能源」），分類會過於模糊，檢索結果噪音很多。
        * 如果範圍太細（例如「磷酸鐵鋰正極表面鍍鋁摻雜處理」），樣本不足，難以自動分類。

        2. **對應到客戶的研發或產品線**

        * 有的客戶關心「產品面」：像是電動車整車、充電樁。受眾：產品經理 (PM)、業務 / 商務開發 (BD, Sales)、法務 / 授權團隊、
        * 有的客戶關心「技術面」：像是電池管理系統、功率半導體。受眾：研發工程師 / 科研團隊、專利工程師 / IP 團隊、策略部門 / 技術預測分析師、競爭情報 (CI) 團隊

        3. **決定 taxonomy 的 granularity（粒度）**

        * 是否三層就夠？
        * 是否需要跨領域標籤（多標籤分類）？

3. **重點萃取**
   從`title`, `abstract`, `claims`挑出主要代表文本。根據經驗，權利項的獨立項 (independent claims)最能區分專利主題。

4. **候選生成**
   經過檢索後，系統得到一批可能的候選類別與範例，準備交給模型比較。

5. **模型判決**
   使用 LLM 做「Pairwise Judge」：在候選類別間進行比較式判斷，輸出最適合的類別、分數，以及理由（引用短句與文字位置 span）。

6. **分數校準**
   對模型輸出的分數進行校準（例如溫度縮放），並應用門檻值來判斷：是否給一個 primary label、是否允許 secondary labels，或者乾脆 abstain（拒答）。

7. **多標籤決策**
   根據校準後的分數，決定最終的多標籤分類結果。

8. **證據與理由輸出**
   同時產出 evidence span（文字位置）與 rationale（模型判斷依據），方便 UI 高亮或人工複核。

9. **結果寫回**
   把分類結果、統計報表與低信心樣本寫回指定輸出檔案，並提供給審查 UI。

### 4.1 Prompt Chaining 的五個關鍵步驟

| **Prompt Chaining 模組 (5)** | **對應的 9 大步驟**          | **說明**                                                                    |
| -------------------------- | ---------------------- | ------------------------------------------------------------------------- |
| 1. **Label Canonicalizer** | 候選生成               | 在檢索完候選後，將使用者提供的類別名稱 + 範例 → 規範化定義/同義詞/near misses，方便後續比較。                  |
| 2. **Pairwise Judge**      | 模型判決               | LLM 逐對比較候選類別，產出分數、理由、span。這是分類的核心判斷步驟。                                    |
| 3. **Calibrator**          | 分數校準 + 多標籤決策   | 對 Pairwise Judge 的分數進行校準，設定門檻值，決定 primary/secondary label，或拒答。            |
| 4. **Active Learning**     | 證據與理由輸出 + 結果寫回 | 系統標記低信心或分歧案例，交給人工複核，並回寫成新的訓練樣本。                                           |

### 4.2 補充

1. **Label Canonicalizer 的作用**
當客戶給我們一個類別名稱（例如 *「Battery Management System」*）加上一些範例專利時，這個模組要做的就是幫這個類別「長出一份完整的定義文件」，讓系統之後能更準確地判斷新專利是不是屬於這一類。

#### 它會產生什麼東西

1. **定義 (definition)**

   * 用自然語言解釋這個類別的範圍。
   * 例如：
     *「Battery Management System (BMS) 指的是用於監控、控制與平衡鋰電池組的電子與軟體系統，包括狀態估測、過充/過放保護、溫度監控等。」*

2. **同義詞 (synonyms)**

   * 把案例文本裡常見的不同叫法整理出來。
   * 例如：`["BMS", "battery controller", "battery monitoring unit"]`

3. **近似錯誤例 (near_misses)**

   * 看起來很像，但實際上**不應該被歸進去**的情況。
   * 例如：

     * 「單純的充電器控制電路（不屬於 BMS）」
     * 「一般電源管理 IC（PMIC）」

4. **CPC/IPC anchors（可選）**

   * 如果範例專利的 CPC/IPC 類別有一致性，可以順手抽出來，作為檢索的輔助過濾條件。

#### 為什麼需要這一步

* **避免模糊**：只靠「名字」或「少數案例」會很模糊，模型容易混淆。
* **標準化**：把用戶隨便寫的類別名稱變成一份清晰的規則集。
* **方便檢索**：有了 synonyms/near_misses，就能更好地做文字檢索與語意匹配。
* **減少誤判**：明確寫出「什麼不算」，能防止模型因為文字表面相似而誤歸類。

## 5. 介面規格（檔案佈局與設定）

```bash
/project
  /data/<RUN_ID>/
    patents.jsonl             # 一行一專利（見下方 schema）
    labels.jsonl              # 已標記樣本（可零星）
    taxonomy.yaml             # 客戶分類樹（≤3層；可更多）
  /output/<RUN_ID>/
    predictions.jsonl         # 分類結果
    report.json               # 指標與統計
    review_samples.jsonl      # 低信心/分歧樣本
  .env                        # API keys, Solr, model endpoints
```

**`patents.jsonl`（必要欄位）**

```json
{
  "patent_id": "US1234567A",
  "title": "....",
  "abstract": "....",
  "claims_main": "....",
  "claims_other": ["...", "..."],
  "cpc": ["H02J7/00", "G06F..."],
  "language": "en"
}
```

**`labels.jsonl`（少樣本）**

```json
{
  "patent_id": "US1234567A",
  "labels": ["Energy/Battery/BMS"],   // 以 path 表示層級
  "is_primary": true
}
```

**`taxonomy.yaml`（簡化示例）**

```yaml
version: "v1"
max_layers: 3
labels:
  - name: Energy
    desc: Energy generation, storage, conversion
    synonyms: ["power", "battery"]
    children:
      - name: Battery
        desc: Battery cell/module/pack and management
        children:
          - name: BMS
            desc: Battery Management System
  - name: Computing
    children:
      - name: Edge
      - name: Cloud
```

---

## 6. 模組實作細節（LangChain + DSPy）

### 6.1 嵌入與檢索（InQBERT + Solr）

* 建立自訂 `InQBertEmbeddings` 以符合 LangChain `Embeddings` 介面。
* 以 **Solr Dense Vector**/ANN 功能建索引：

  * `doc_vector = InQBERT(abstract + claims_main)`
  * 儲存 `doc_vector` 與 `cpc`、`label hints`（若有）。
* 針對**每個類別**產生**查詢向量**：

  * 使用類別的少樣本平均向量 + `synonyms` 文本向量；
  * 若 taxonomy 提供 `cpc_anchors`（可由 Canonicalizer 產生），在 Solr 查詢加入**過濾或加權**。

> 輸出：每類取前 N（預設 10）篇**代表段落**（段落切分可 512–1000 字元），供 LLM 裁決使用。

### 6.2 LangChain：判決 Prompt（Pairwise）

**角色**：`Patent Category Judge`
**輸入**：`focus_text`（摘要+主權利項+最多2段證據）、`candidate_labels[]`（含 definition/synonyms/near_misses）、`retrieved_snippets[]`
**輸出（嚴格 JSON）**：

```json
{
  "topk": [
    {"label":"Energy/Battery/BMS","score":0.83,"why":["..."],"spans":[[120,160],[345,380]]}
  ],
  "abstain": false
}
```

**關鍵提示要點**

* 僅以提供文本與證據判斷；證據不足則 `abstain=true`。
* `why` 必須為**原文短句**；`spans` 是對 `focus_text` 的字元偏移。
* 若多個類別同時合理，允許**多標籤**（primary=最高分）。

### 6.3 DSPy：自動優化（少樣本場景）

* 定義 **Signature**（型別化 I/O）：

  * `LabelCanonicalizer(label_name, desc, synonyms) -> {definition, synonyms+, near_misses, cpc_anchors}`
  * `PairwiseJudge(focus_text, candidates_json, retrieved_snippets) -> ranked_json`
* 使用 **DSPy Optimizers**（如 BootstrapFewShot、MIPROv2）在**該資料夾的已標記子集**上，最小化損失（如 Macro-F1 的反向）。
* 產物：

  * 自動挑選更好的 few-shot 示例與指令措辭；
  * 穩定嚴格 JSON、提高一致性。

> 工程上：把 DSPy「編譯」出的模組當成 LangChain 的**可呼叫函式**放入流程即可。

### 6.4 Calibrator（分數校準與閾值）

* 收集一小撮驗證樣本（資料夾內已標記者）。
* 以 Platt scaling / 溫度標定將 LLM 分數轉為較可比的機率。
* 設定：

  * `primary_threshold`（預設 0.6）、`secondary_threshold`（預設 0.4）、`abstain_threshold`（預設 0.25）。
  * 允許 per-class 覆蓋（在報表中建議）。

---

## 7. 推論與批次執行

### 7.1 CLI 範例

```bash
# 1) 構建索引
pc-index --run-id 2025-09-30 --data ./data/2025-09-30 --solr http://solr:8983

# 2) 進行分類
pc-classify --run-id 2025-09-30 --data ./data/2025-09-30 --out ./output/2025-09-30

# 3) 產出報表與審查樣本
pc-report --run-id 2025-09-30 --out ./output/2025-09-30
```

### 7.2 執行流程（細節）

1. 載入 `taxonomy.yaml` → **Label Canonicalizer**（LangChain + DSPy，可快取結果）。
2. 對每類建立查詢向量；以 Solr ANN 取代表段。
3. 對每份未標記專利：

   * 組合 `focus_text = abstract + claims_main + retrieved_snippets[:2]`。
   * 準備候選類（Top-M 類別，預設 M=5）→ **Pairwise Judge**。
   * 套用 **Calibrator** 決定 primary/secondary/abstain 與 Top-k。
   * 寫入 `predictions.jsonl`。
4. 彙總指標與低信心清單，輸出 `report.json`、`review_samples.jsonl`。

---

## 8. 評估、校準與主動學習

### 8.1 度量

* **多標籤**：macro/micro F1、subset accuracy、per-class coverage。
* **Top-k**：Recall@k、Precision@k。
* **拒答**（abstain）率與人工工作量節省。

### 8.2 小樣本策略

* 若每類僅 1–2 例：強化 **retrieval**（提高 exemplar/規則權重），Judge 走**比較式**。
* 若每類 ≥5 例：可加上**輕量線性頭**（例如以 InQBERT 向量訓一個 Logistic/線性 SVM 對候選 rerank；工程側可選擇性啟用），但**不是必須**。

### 8.3 主動學習（內建清單）

* **不確定性**：最高分 < `primary_threshold` 或 Top1-Top2 分差 < 0.1。
* **分歧**：LLM 與（可選）線性頭/規則不一致。
* 輸出固定數量/類別的樣本供標記者優先處理；新標記加入 `labels.jsonl`，**不需重做索引**。

---

## 9. 監控與可觀測性

* **執行層**：請接入 LangChain Tracing / 日誌（request/response、token 使用、延遲）。
* **品質層**：每批輸出 `report.json`，含：

  ```json
  {
    "macro_f1": 0.72,
    "micro_f1": 0.79,
    "per_class": {"Energy/Battery/BMS": {"f1": 0.70, "support": 18}},
    "abstain_rate": 0.11,
    "low_confidence_count": 132
  }
  ```

* **資料漂移**：統計每類平均向量/關鍵詞變化，超閾值即告警。

---

## 10. 安全與權限

* 全流程只讀取該資料夾；結果寫回 `output/<RUN_ID>`。
* 所有 API 金鑰（LLM、Solr）放 `.env`；執行時載入。
* 專利文本與向量皆**不外流**（如需雲端 LLM，請啟用企業私域/不訓練模式）。

---

## 11. 部署與設定

### 11.1 `.env` 範例

```
LLM_API_BASE=https://api.your-llm.com
LLM_API_KEY=***
INQBERT_ENDPOINT=http://inqbert:8000/embed
SOLR_URL=http://solr:8983/solr/patents
SOLR_COLLECTION=patents
```

### 11.2 依賴

* Python 3.10+
* `langchain`, `dspy`, `httpx/requests`, `pydantic`, `pyyaml`, `tqdm`
* Solr（啟用向量欄位/ANN）

### 11.3 最小程式骨架（節選，示意）

**自訂嵌入（InQBERT）**

```python
from langchain.embeddings.base import Embeddings
import requests

class InQBertEmbeddings(Embeddings):
    def __init__(self, endpoint: str):
        self.endpoint = endpoint
    def embed_documents(self, texts):
        return requests.post(f"{self.endpoint}/embed/batch", json={"texts": texts}).json()["vectors"]
    def embed_query(self, text):
        return requests.post(f"{self.endpoint}/embed", json={"text": text}).json()["vector"]
```

**Solr 檢索器（簡化）**

```python
import requests, json

def solr_ann_search(query_vec, k=10, filters=None):
    payload = {
      "knn": {"field": "vec", "vector": query_vec, "k": k},
      "query": filters or "*:*",
      "fl": "id,title,abstract,claims_main,score"
    }
    r = requests.post(f"{SOLR_URL}/{SOLR_COLLECTION}/select", json=payload)
    return r.json()["response"]["docs"]
```

**LangChain Judge Prompt（摘要）**

```python
from langchain.prompts import ChatPromptTemplate

JUDGE_PROMPT = ChatPromptTemplate.from_template("""
You are a Patent Category Judge. Decide labels using only the provided text and snippets.
Return STRICT JSON:

{"topk":[{"label":"","score":0.0,"why":[""],"spans":[[0,0]]}],"abstain":false}

FOCUS_TEXT:
{focus_text}

CANDIDATE_LABELS (JSON):
{candidates}

RETRIEVED_SNIPPETS:
{snippets}

Rules:
- Use only quotes from FOCUS_TEXT in "why".
- Provide char spans [start,end] within FOCUS_TEXT.
- If evidence is insufficient, set "abstain": true.
""")
```

**DSPy Signature（摘要）**

```python
import dspy

class PairwiseJudgeSig(dspy.Signature):
    """Return ranked JSON for candidate labels."""
    focus_text = dspy.InputField()
    candidates = dspy.InputField()  # JSON str
    snippets = dspy.InputField()
    result_json = dspy.OutputField()  # strict JSON

PairwiseJudge = dspy.Predict(PairwiseJudgeSig)
```

**DSPy 優化（骨架）**

```python
def compile_pairwise_judge(train_examples):
    # train_examples: list of dict with fields focus_text, candidates, snippets, result_json(gold)
    teleprompter = dspy.BootstrapFewShot(PairwiseJudge, max_train_examples=20)
    program = teleprompter.compile(trainset=train_examples)
    return program  # 可直接 program(focus_text=..., candidates=..., snippets=...)
```

> 實務：把 `program` 包成 LangChain 的 `RunnableLambda`，在推論節點直接呼叫。

---

## 12. 常見問答

**Q1：一定要多標籤嗎？**
A：預設**支援多標籤**，可設定 `primary_threshold` 與 `secondary_threshold`。如需單標籤，把 `secondary_threshold` 調高或僅取 Top1。

**Q2：客戶 taxonomy 超過 3 層怎麼辦？**
A：我們支援 >3 層，但 UI 與報表建議聚合到 3 層內；內部存 `path` 無限制。

**Q3：少樣本品質很差怎麼辦？**
A：DSPy 會自動挑 few-shot；同時依賴 Retrieval 的**代表段**提供穩定依據。若仍不穩，啟用 **Active Learning**，先標記 `review_samples.jsonl` 中的高價值樣本。

**Q4：可以只用 IPC/CPC 分類嗎？**
A：可把 CPC 當 prior（加權檢索），但最終由 LLM 判決；若客戶要「僅 CPC」，可改走**規則映射**（不需 LLM）。

---

## 附錄：輸出格式（`predictions.jsonl`）

```json
{
  "patent_id": "US1234567A",
  "primary_label": "Energy/Battery/BMS",
  "secondary_labels": ["Energy/Battery/Cell", "Computing/Edge"],
  "scores": {"Energy/Battery/BMS":0.83,"Energy/Battery/Cell":0.51,"Computing/Edge":0.41},
  "abstain": false,
  "why": ["the battery pack voltage balancing ...", "state-of-charge estimation ..."],
  "evidence_spans": [[120,160],[345,380]],
  "topk_alternatives": ["Energy/Battery/Cell","Computing/Edge"],
  "version": "taxonomy_v1+judge_2025-09-30"
}
```
