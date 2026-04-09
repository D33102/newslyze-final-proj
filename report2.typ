// ============================================================
// Mining AI Narratives: Engineering Time Series from Guardian
// News Articles (2022–2025)
// Course 2110430 — TIME SERIES MINING AND KNOWLEDGE DISCOVERY | Midterm Project
// Thanapat Chotipun
// ============================================================

// ── Colour palette ───────────────────────────────────────────
#let accent    = rgb("#1B4F72")
#let accent-mid = rgb("#2E86C1")
#let accent-lt  = rgb("#AED6F1")
#let neutral   = rgb("#222222")
#let hdr-fill  = rgb("#1B4F72")
#let row-even  = rgb("#EBF5FB")

// ── Page setup ───────────────────────────────────────────────
#set page(
  paper: "a4",
  margin: (top: 2.2cm, bottom: 2.4cm, left: 2.4cm, right: 2.2cm),
  numbering: "1",
  number-align: right,
  header: context {
    if counter(page).get().first() > 1 [
      #set text(size: 8pt, fill: rgb("#888888"))
      #grid(
        columns: (1fr, 1fr),
        align(left)[Mining AI Narratives — Time Series Mining],
        align(right)[Course 2110430]
      )
      #line(length: 100%, stroke: 0.4pt + accent-lt)
    ]
  },
)

// ── Typography ───────────────────────────────────────────────
#set text(font: "Times New Roman", size: 10pt, fill: neutral)
#set par(justify: true, leading: 0.62em, spacing: 0.9em, first-line-indent: 1.5em)

#set heading(numbering: "1.1")

#show heading.where(level: 1): it => {
  v(1em)
  block(below: 0.6em)[
    #set text(size: 12pt, weight: "bold", fill: accent)
    #it
  ]
  line(length: 100%, stroke: 0.6pt + accent-lt)
  v(0.5em)
  par(first-line-indent: 0em)[#box()]
}
#show heading.where(level: 2): it => {
  v(0.5em)
  block(below: 0.45em)[
    #set text(size: 10.5pt, weight: "bold", fill: accent-mid)
    #it
  ]
  v(0.25em)
  par(first-line-indent: 0em)[#box()]
}

// ── Helpers ──────────────────────────────────────────────────
#let fig(path, cap, width: 100%) = figure(
  image(path, width: width),
  caption: text(size: 8pt, style: "italic")[#cap],
  kind: image,
)

// Figure caption styling
#show figure.caption: it => text(size: 8pt, style: "italic")[#it]

#let tbl-fill = (_, row) => {
  if row == 0 { hdr-fill }
  else if calc.even(row) { row-even }
  else { white }
}

#let tbl-stroke = 0.5pt + accent-lt

// ── Title block ──────────────────────────────────────────────
#align(center)[
  #v(0.3cm)
  #text(size: 8pt, weight: "light", fill: accent)[2110430 TIME SERIES MINING AND KNOWLEDGE DISCOVERY]
  #v(0.15cm)
  #text(size: 20pt, weight: "bold", fill: accent)[Mining AI Narratives from Guardian News]
  #v(0.12cm)
  #text(size: 12pt, fill: accent-mid)[Time Series from Unstructured Text from 2022–2025]
  #v(0.35cm)
  #text(size: 9.5pt, fill: rgb("#555555"))[
    Thanapat Chotipun 6532089921
  ]
  #v(0.25cm)
]

#line(length: 100%, stroke: 1pt + accent)
#v(0.25cm)

// ── Abstract ─────────────────────────────────────────────────
#text(size: 8pt, style: "italic")[
  #set par(first-line-indent: 0em)
  *Abstract —*
  This project transforms 4,491 Guardian articles about artificial intelligence (2022–2025) from an unstructured text corpus into a structured multi-dimensional time series. Articles are embedded with #emph[all-mpnet-base-v2] (768-dim) and clustered via BERTopic (UMAP 10D → HDBSCAN → c-TF-IDF), producing 12 data-driven subtopics with no predefined keywords. Each article is then assigned one or more subtopic labels using cosine similarity to cluster centroids. Sentiment is scored with VADER and signals are aggregated weekly, yielding a 260-week × 12-subtopic matrix. We apply trend analysis, Z-score anomaly detection, stacked-area decomposition, sentiment heatmap, and cross-correlation lag analysis. Forecasting with Prophet and SARIMA on an 8-week holdout selects the best model per subtopic for a 13-week forward projection. *Big Tech* (+11%) and *AI Safety* (+8%) are rising; *Social Media* (−55%) and *Stocks market* (−49%) are declining most sharply.
]

#v(0.1cm)

// ============================================================
= Introduction
// ============================================================

Between 2022 and 2025, artificial intelligence became a dominant subject of mainstream news coverage. Events such as the ChatGPT launch, the UK AI Safety Summit at Bletchley Park, EU AI Act negotiations, and high-profile debates over copyright and job displacement generated a sustained and varied stream of articles. This project asks: can we extract meaningful temporal patterns from that stream?

The core challenge is that a news corpus is not a time series — it is a collection of documents with timestamps. Our approach is to *engineer* the corpus into structured weekly signals. Rather than imposing predefined topic labels through keyword matching, we let the data determine its own thematic structure through unsupervised clustering, then aggregate article counts and sentiment per topic per week. Standard time-series mining techniques are then applied to the resulting matrix.

Our research questions are: (1) How did AI-related coverage evolve across subtopics from 2022–2025, and what events explain the anomalies? (2) Does sentiment differ systematically by subtopic? (3) Does coverage in one subtopic temporally lead another? (4) Which subtopics are projected to grow or decline over the next three months?

// ============================================================
= Data and Engineering
// ============================================================

== Data Collection

We used the Guardian Open Platform API with a tightened query strategy: exact phrases ("artificial intelligence", "ChatGPT", "large language model", "AI regulation", etc.) combined with a server-side section allow-list (technology, business, science, politics, world, opinion, environment, society, and related sections) and a post-fetch relevance filter requiring at least one AI term in the headline or first 300 characters of the body. This prevents deep-body incidental matches — sports articles mentioning "machine-like" performance or gambling pieces about "AI slot machines" — from polluting the corpus.

After deduplication and filtering to articles with at least 100 words, the final corpus is *4,491 articles* spanning January 2022 to December 2025. The top sections are Technology (1,720), Business (542), World news (358), and US news (358), confirming strong editorial focus on AI as a technology and policy topic.

== Subtopic Classification via BERTopic

Rather than a predefined keyword dictionary, we discover subtopics directly from the data using a three-stage pipeline. First, each article's headline plus the first 512 characters of body text is embedded with *all-mpnet-base-v2* (768-dimensional, 12-layer Transformer), which provides substantially richer semantic representations than lighter models. Second, UMAP reduces the embeddings to 10 dimensions and HDBSCAN clusters them with a minimum cluster size of approximately 48 articles (~1% of corpus), automatically determining the number of topics. Third, BERTopic applies c-TF-IDF to each cluster to produce human-readable keyword labels.

This yielded *12 coherent subtopics* with no articles left as "uncategorised." To support multi-label assignment (an article about EU regulation of OpenAI should belong to both *AI Safety* and *OpenAI*), we compute cosine similarity of each article's embedding to each topic centroid and assign all labels above a threshold of 0.30, capped at 3 labels per article. After exploding to one row per (article, subtopic), the dataset has *12,448 rows*.

#figure(
  table(
    columns: (1.4fr, auto, 2.5fr),
    fill: tbl-fill,
    stroke: tbl-stroke,
    inset: 5pt,
    table.header(
      text(fill: white, weight: "bold", size: 9pt)[Subtopic],
      text(fill: white, weight: "bold", size: 9pt)[Articles],
      text(fill: white, weight: "bold", size: 9pt)[Top Keywords],
    ),
    [AI Safety],             [2,029], [summit, ai safety, bletchley park, regulation],
    [OpenAI],                [1,597], [openai, chatbot, sam altman, microsoft],
    [Politics],              [1,252], [sunak, labour, ukraine, election, russia],
    [Social Media],          [1,156], [tiktok, twitter, facebook, elon, ban],
    [Legal],                 [1,072], [copyright, artists, music, openai, art],
    [Stocks market],         [1,069], [nvidia, stock, shares, wall street, crypto],
    [Supply Chain],          [1,058], [amazon, robots, ocado, warehouse, automation],
    [Big Tech],                [911], [meta, facebook, journalism, zuckerberg],
    [Flash news #super[†]],    [899], [morning mail, afternoon update, albanese],
    [Healthcare],              [545], [cancer, nhs, patients, brain, medical],
    [Energy & Environment],    [476], [energy, electricity, datacentres, nuclear],
    [Weather & Animal #super[†]], [383], [weather, animals, ocean, climate crisis],
  ),
  caption: [12 subtopics discovered by BERTopic (4,491 articles; multi-label counts). #super[†] low-quality clusters — see Section 4.]
)

== Sentiment Scoring

Each article is scored with VADER (Valence Aware Dictionary and sEntiment Reasoner) applied to the headline plus the first 300 characters of body text. VADER requires no GPU, is calibrated for news-like text, and produces a compound score in [−1, 1]. Scores are discretised: negative (< −0.05), neutral (−0.05 to 0.05), positive (> 0.05). The corpus-wide mean is µ = 0.018 — near-neutral overall, with meaningful subtopic-level divergences described in Section 3.

== Weekly Aggregation

Articles are grouped by ISO week start and subtopic, producing five signals per (week, subtopic) cell: article count, mean sentiment, sentiment standard deviation, positive ratio, and negative ratio. Missing weeks are filled with zero for count and linearly interpolated for sentiment. The result is a *260-week × 12-subtopic matrix* — the engineered time series dataset.

// ============================================================
= Time-Series Mining
// ============================================================

== Trend Analysis

#fig(
  "data/trend_analysis.png",
  [Weekly article count per subtopic with 4-week rolling average. *AI Safety* and *OpenAI* are the highest-volume topics; a structural break is visible around late 2022 following ChatGPT's launch.],
  width: 50%
)

AI Safety and OpenAI account for the largest weekly volume, reflecting how much AI discourse centres on safety, governance, and the corporate dynamics of frontier AI systems. A structural break is visible across multiple subtopics around late 2022, consistent with ChatGPT catalysing mainstream coverage. Social Media and Stocks market show high early volume that declines post-2023 — classic hype-then-normalisation patterns.

== Anomaly Detection

#fig(
  "data/anomaly_detection.png",
  [Z-score anomaly detection (|z| > 2). Top flagged weeks: AI Safety at the UK AI Safety Summit (Oct 2023), Stocks market at DeepSeek-R1 release (Jan 2025), OpenAI at the Altman boardroom crisis (Nov 2023) and ChatGPT launch (Nov 2022).],
  width: 100%
)

Weeks are flagged anomalous when |Z-score| > 2 relative to each subtopic's mean. All top anomalies align with real AI milestones — validating that the engineered signals carry temporally accurate information about discourse dynamics.

== Coverage Composition and Sentiment

#grid(
  columns: (1fr, 1fr),
  gutter: 10pt,
  fig("data/stacked_area.png", [Stacked area chart of subtopic coverage over time (4-week rolling average). AI Safety and OpenAI dominate; Social Media and Stocks market decline after 2023.], width: 100%),
  fig("data/sentiment_heatmap.png", [Monthly mean sentiment per subtopic (VADER compound score). Healthcare is persistently positive; Legal and AI Safety are persistently negative.], width: 100%),
)

Three phases emerge: (1) 2022 — lower total volume with Politics and Supply Chain prominent; (2) late 2022–2023 — a surge as ChatGPT catalyses mainstream coverage; (3) 2024–2025 — stabilisation with AI Safety and OpenAI sustaining high volume. The sentiment heatmap reveals persistent structural differences: Healthcare is the most positive (medical AI as breakthrough); Legal is persistently negative (copyright disputes); AI Safety oscillates around existential-risk events. These patterns are invisible to volume-only analysis.

== Cross-Correlation

#fig(
  "data/cross_correlation.png",
  [Cross-correlation between the two largest subtopics across lags −8 to +8 weeks. A positive peak at lag > 0 indicates the first subtopic tends to lead the second in coverage.],
  width: 72%
)

The bar chart shows a peak at a positive lag, consistent with one subtopic leading the other by approximately 1–3 weeks. While the correlation is modest, the directional asymmetry suggests that safety-framed discourse tends to generate downstream coverage in related domains — though correlation here is not causation.

// ============================================================
= Topic Discovery and Quality Review
// ============================================================

#grid(
  columns: (1fr, 1fr),
  gutter: 10pt,
  fig("data/topic_size_distribution.png", [Article count per subtopic (unique articles). AI Safety is the largest cluster; Flash news and Weather & Animal are the smallest.], width: 100%),
  fig("data/topic_clusters_umap.png", [UMAP 2D projection of all 4,491 articles coloured by primary subtopic. Clusters show reasonable separation; some overlap between OpenAI and AI Safety is expected.], width: 100%),
)

Most subtopics form visually distinct regions, validating that 768-dim embeddings carry sufficient signal for BERTopic. OpenAI and AI Safety overlap — expected, as many OpenAI articles concern safety and governance. Legal and Social Media overlap in copyright/platform-regulation territory.

Two clusters are lower quality. *Flash news* (899 articles) captures Guardian newsletter digests ("Morning Mail", "Afternoon Update") that mention AI incidentally — a document-type cluster, not a thematic one. *Weather & Animal* (383 articles) captures AI-in-science articles peripheral to mainstream AI discourse. Both are retained but should be interpreted with caution. The highest multi-label co-occurrence pairs are OpenAI ↔ AI Safety and Social Media ↔ Legal.

// ============================================================
= Forecasting
// ============================================================

For each subtopic, the weekly article-count series is split into training (all weeks except the last 8) and an 8-week holdout. Both *Prophet* and *SARIMA* (via `pmdarima.auto_arima`, m = 52 for weekly seasonality) are fit on training data and evaluated on the holdout by RMSE. The lower-RMSE model is then refit on the full series and used to project 13 weeks (~3 months) ahead with 90% confidence intervals. Subtopics with fewer than 18 weeks of data are skipped.

#fig(
  "data/forecast_summary_chart.png",
  [3-month forecast: percentage change in weekly article count relative to the recent 4-week average. Green = Rising, blue = Stable, red = Declining.],
  width: 90%
)

#figure(
  table(
    columns: (1.6fr, auto, auto, auto, auto),
    fill: tbl-fill,
    stroke: tbl-stroke,
    inset: 6pt,
    table.header(
      text(fill: white, weight: "bold")[Subtopic],
      text(fill: white, weight: "bold")[Recent avg],
      text(fill: white, weight: "bold")[Forecast avg],
      text(fill: white, weight: "bold")[Change %],
      text(fill: white, weight: "bold")[Trend · Model],
    ),
    [Big Tech],              [6.0],  [6.7],  [+11.1%], [Rising ↑ · SARIMA],
    [AI Safety],             [15.0], [16.3], [+8.4%],  [Rising ↑ · SARIMA],
    [Flash news],            [5.5],  [5.5],  [+0.1%],  [Stable → · SARIMA],
    [Healthcare],            [3.0],  [3.0],  [−0.8%],  [Stable → · SARIMA],
    [OpenAI],                [14.2], [13.7], [−3.6%],  [Stable → · SARIMA],
    [Supply Chain],          [8.2],  [7.8],  [−5.0%],  [Declining ↓ · SARIMA],
    [Legal],                 [8.2],  [7.1],  [−14.4%], [Declining ↓ · SARIMA],
    [Weather & Animal],      [2.2],  [1.5],  [−33.9%], [Declining ↓ · Prophet],
    [Politics],              [8.5],  [5.5],  [−35.4%], [Declining ↓ · Prophet],
    [Energy & Environment],  [3.8],  [2.3],  [−39.8%], [Declining ↓ · Prophet],
    [Stocks market],         [10.0], [5.1],  [−48.8%], [Declining ↓ · Prophet],
    [Social Media],          [11.2], [5.0],  [−55.4%], [Declining ↓ · Prophet],
  ),
  caption: [Full forecast summary. "Recent avg" = mean articles/week over last 4 observed weeks. Winner selected by 8-week holdout RMSE.]
)

The forecasts are substantively interpretable. *AI Safety* (+8.4%) and *Big Tech* (+11.1%) are the only rising subtopics — consistent with ongoing AI governance negotiations and the expansion of Big Tech's AI product portfolios in early 2026. *OpenAI* is forecast as stable despite very high volume, suggesting its dominant position in discourse has normalised. *Social Media* (−55.4%) and *Stocks market* (−48.8%) show the sharpest declines, consistent with post-hype coverage normalisation: the initial wave of "AI and social platforms" and "AI stocks" journalism has passed its peak.

SARIMA outperformed Prophet on 9 of 12 subtopics. This suggests these series are relatively stationary with weak long-range seasonality — conditions where SARIMA's explicit differencing is advantageous over Prophet's trend-changepoint model. Prophet won on the four most steeply declining subtopics (Weather & Animal, Politics, Energy, Social Media), where its flexible trend component better captures structural decline.

// ============================================================
= Conclusion
// ============================================================

This project demonstrates that 4,491 Guardian news articles can be engineered into a rich 12-topic, 260-week time series and analysed with standard mining techniques. Key findings from the actual ran pipeline:

- *BERTopic clustering* with 768-dim embeddings successfully discovers 12 coherent AI subtopics with no predefined keywords and no residual "Other" category — a substantial improvement over keyword-based approaches.
- *Trend analysis* shows AI Safety and OpenAI as the dominant long-run topics, with a visible structural break across all subtopics around the ChatGPT launch in late 2022.
- *Anomaly detection* recovers the UK AI Safety Summit (Oct 2023), the DeepSeek-R1 release (Jan 2025), and the OpenAI boardroom crisis (Nov 2023) as statistically significant spikes, validating the engineered signals.
- *Sentiment* diverges by subtopic: Healthcare is persistently positive; Legal and AI Safety persistently negative — differences invisible to volume-only analysis.
- *Forecasting* projects AI Safety and Big Tech as rising; Social Media and Stocks market as declining sharply. SARIMA dominated (9/12) suggesting the series are largely stationary.

*Limitations:* The corpus of 4,491 articles is smaller than the original 23,859 — the tighter relevance filter improved topic quality at the cost of volume. VADER may underestimate sentiment intensity in formal journalistic text. The Guardian's editorial perspective (centre-left, UK-based) introduces source bias. Flash news and Weather & Animal clusters are noise artifacts of the broad query and should be excluded from substantive interpretation.

// ── References ────────────────────────────────────────────────
= References

#set par(hanging-indent: 1.2em, justify: false)

[1] #h(0.3em) Hutto, C., & Gilbert, E. (2014). VADER: A parsimonious rule-based model for sentiment analysis of social media text. *Proceedings of ICWSM-14.*

[2] #h(0.3em) Taylor, S. J., & Letham, B. (2018). Forecasting at scale. *The American Statistician, 72*(1), 37–45.

[3] #h(0.3em) Grootendorst, M. (2022). BERTopic: Neural topic modeling with a class-based TF-IDF procedure. *arXiv:2203.05794.*

[4] #h(0.3em) McInnes, L., Healy, J., & Melville, J. (2018). UMAP: Uniform manifold approximation and projection. *arXiv:1802.03426.*

[5] #h(0.3em) Reimers, N., & Gurevych, I. (2019). Sentence-BERT: Sentence embeddings using Siamese BERT-networks. *Proceedings of EMNLP-IJCNLP 2019.*

[6] #h(0.3em) Song, K., et al. (2020). MPNet: Masked and permuted pre-training for language understanding. *NeurIPS 2020.* (basis of all-mpnet-base-v2)

[7] #h(0.3em) The Guardian Open Platform API. https://open-platform.theguardian.com/documentation/
