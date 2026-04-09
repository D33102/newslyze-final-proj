// ============================================================
// Mining AI Narratives: Engineering Time Series from Guardian
// News Articles (2022–2025)
// Course 2110430 — Time Series Mining | Midterm Project
// ============================================================

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
      #line(length: 100%, stroke: 0.4pt + rgb("#CCCCCC"))
    ]
  },
)

#set text(font: "New Computer Modern", size: 10pt, fill: rgb("#222222"))
#set par(justify: true, leading: 0.68em)

#show heading.where(level: 1): it => {
  v(1em)
  block(below: 0.3em)[
    #set text(size: 12pt, weight: "bold", fill: rgb("#1B4F72"))
    #counter(heading).display("1.")
    #h(0.4em)
    #it.body
  ]
  line(length: 100%, stroke: 0.6pt + rgb("#AED6F1"))
  v(0.4em)
}
#show heading.where(level: 2): it => {
  v(0.6em)
  block(below: 0.2em)[
    #set text(size: 10.5pt, weight: "bold", fill: rgb("#2E86C1"))
    #counter(heading).display("1.1")
    #h(0.4em)
    #it.body
  ]
  v(0.2em)
}

#let fig(path, cap, width: 100%) = figure(
  image(path, width: width),
  caption: cap,
  kind: image,
)

// ── Title block ───────────────────────────────────────────────
#align(center)[
  #v(0.3cm)
  #text(size: 10pt, weight: "bold", fill: rgb("#1B4F72"))[Course 2110430 — Time Series Mining · Midterm Project]
  #v(0.5cm)
  #text(size: 20pt, weight: "bold", fill: rgb("#1B4F72"))[Mining AI Narratives from Guardian News]
  #v(0.15cm)
  #text(size: 12pt, fill: rgb("#2E86C1"))[Engineering Time Series from Unstructured Text (2022–2025)]
  #v(0.4cm)
  #text(size: 9.5pt, fill: rgb("#555555"))[
    Group Member 1 (Student ID) · Group Member 2 (Student ID) · Group Member 3 (Student ID) \
    Submitted: 20 February 2026
  ]
  #v(0.3cm)
]

#line(length: 100%, stroke: 1pt + rgb("#1B4F72"))
#v(0.3cm)

// ── Abstract ─────────────────────────────────────────────────
*Abstract —*
News articles are not a time series, but we can engineer them into one. This project collects 23,859 Guardian articles about AI from 2022–2025, classifies them into subtopics using keyword matching, scores sentiment with VADER, and aggregates into weekly frequency and sentiment signals. We then apply trend analysis, Z-score anomaly detection, a stacked-area decomposition, a sentiment heatmap, and cross-correlation analysis. Uncategorised articles are clustered with BERTopic, revealing a large *AI & World Politics* theme. Finally, Prophet and SARIMA models are compared on an 8-week holdout to forecast the next three months. Results show that AI Safety is the fastest-rising subtopic, while AI & Big Tech coverage is declining.

#v(0.2cm)

// ============================================================
= Introduction
// ============================================================

Between 2022 and 2025, artificial intelligence shifted from a specialist topic to mainstream media. Events like the ChatGPT launch, EU AI Act negotiations, and public debates around AI safety generated a large volume of news coverage. This project asks: can we extract meaningful temporal patterns from that stream of text?

The core challenge is that a news corpus is not a time series — it is a collection of documents with timestamps. Our approach is to *engineer* the corpus into structured weekly signals by classifying articles into subtopics and aggregating frequency and sentiment per week. We then apply standard time-series mining techniques to the resulting data.

Our research questions are: (1) How did AI coverage evolve across subtopics over four years? (2) Does sentiment differ by subtopic? (3) Does AI Safety discourse lead AI Regulation? (4) Which subtopics are forecast to grow?

// ============================================================
= Data and Engineering
// ============================================================

== Data Collection

We used the Guardian Open Platform API, querying for articles containing terms like "artificial intelligence", "machine learning", "generative AI", "AI regulation", or "AI safety" between January 2022 and December 2025. The API was paginated with a 0.5-second delay. After deduplication and filtering to articles with at least 100 words, the final corpus is *23,859 articles*.

We chose the Guardian because it has a deep free archive (back to 1999), consistent editorial quality, and a clean JSON API. NewsAPI.org was considered but limits free-tier history to one month.

== Subtopic Classification

Each article's headline and first 500 characters of body text are matched against a keyword dictionary covering six subtopics: *Generative AI*, *AI Regulation*, *AI Safety*, *AI & Jobs*, *AI in Healthcare*, and *AI & Big Tech*. Classification is multi-label — an article about EU regulation of OpenAI counts under both AI Regulation and AI & Big Tech. Articles matching no keyword are labelled *Other*. After exploding to one row per (article, subtopic), the dataset has 24,584 rows.

#figure(
  table(
    columns: (1.4fr, 1.2fr, 1.9fr),
    fill: (_, row) => if row == 0 { rgb("#1B4F72") } else if calc.even(row) { rgb("#EBF5FB") } else { white },
    stroke: 0.5pt + rgb("#AED6F1"),
    inset: 6pt,
    table.header(
      text(fill: white, weight: "bold")[Subtopic],
      text(fill: white, weight: "bold")[Articles],
      text(fill: white, weight: "bold")[Sample Keywords],
    ),
    [Generative AI],    [736],   [chatgpt, gpt-4, llm, midjourney],
    [AI Regulation],    [4,442], [eu ai act, policy, legislation],
    [AI Safety],        [309],   [alignment, hallucination, deepfake],
    [AI & Jobs],        [274],   [automation, job loss, layoff],
    [AI in Healthcare], [494],   [medical ai, diagnosis, radiology],
    [AI & Big Tech],    [1,001], [openai, nvidia, anthropic],
    [*Other*],          [*17,328*], [—],
  ),
  caption: [Subtopic distribution after keyword classification. "Other" at 70% motivates clustering in Section 4.]
)

== Sentiment Scoring

Sentiment is scored with VADER on the headline plus the first 300 characters of body text, giving a compound score in [−1, 1]. VADER is fast, requires no GPU, and is calibrated for news-like text. Scores below −0.05 are labelled negative, above 0.05 positive, and the rest neutral. The corpus-wide mean is µ = 0.018 (near-neutral), but subtopics vary considerably.

== Weekly Aggregation

Articles are grouped by ISO week start and subtopic, producing five signals per (week, subtopic) cell: article count, mean sentiment, sentiment standard deviation, positive ratio, and negative ratio. The result is a 210-week × 7-subtopic matrix — our engineered time series.

// ============================================================
= Time-Series Mining
// ============================================================

== Trend Analysis

#fig(
  "data/trend_analysis.png",
  [Weekly article count per subtopic with 4-week rolling average. AI Regulation dominates by volume; Generative AI shows a clear step-change after ChatGPT launched in November 2022.],
  width: 100%
)

AI Regulation has the highest median volume (~18 articles/week). Generative AI was near-zero until late 2022, then jumped and never returned to pre-launch levels — the clearest structural break in the dataset. AI & Big Tech peaks in 2022–2023 and dips, then briefly resurges in early 2025 around the DeepSeek-R1 release.

== Anomaly Detection

#fig(
  "data/anomaly_detection.png",
  [Z-score anomaly detection (|z| > 2). The highest spike is AI Safety at z = 7.45 during the UK AI Safety Summit (Oct 2023). All three major product launches also appear as anomalies.],
  width: 100%
)

Weeks are flagged anomalous when |Z-score| > 2 relative to the subtopic's historical mean, giving 53 anomalous weeks total. The top anomalies align well with real events, validating the pipeline:

#figure(
  table(
    columns: (auto, 1.3fr, auto, 2.2fr),
    fill: (_, row) => if row == 0 { rgb("#1B4F72") } else if calc.even(row) { rgb("#EBF5FB") } else { white },
    stroke: 0.5pt + rgb("#AED6F1"),
    inset: 6pt,
    table.header(
      text(fill: white, weight: "bold")[Week],
      text(fill: white, weight: "bold")[Subtopic],
      text(fill: white, weight: "bold")[Z],
      text(fill: white, weight: "bold")[Event],
    ),
    [2023-10-30], [AI Safety],     [7.45], [UK AI Safety Summit at Bletchley Park],
    [2025-01-27], [AI & Big Tech], [5.08], [DeepSeek-R1 release],
    [2023-11-20], [AI & Big Tech], [4.01], [OpenAI boardroom crisis],
    [2023-05-01], [Generative AI], [3.49], [GPT-4 adoption surge],
  ),
  caption: [Top anomalous weeks by Z-score.]
)

== Coverage Composition and Sentiment

#grid(
  columns: (1fr, 1fr),
  gutter: 10pt,
  fig("data/stacked_area.png", [Stacked area chart showing subtopic share of total AI coverage over time. Three phases are visible: regulatory dominance (2022), the generative AI surge (2023), and consolidation (2024–2025).], width: 100%),
  fig("data/sentiment_heatmap.png", [Monthly sentiment heatmap (subtopic × month). AI in Healthcare is consistently positive; AI & Jobs is consistently negative.], width: 100%),
)

The stacked area chart reveals three phases of AI coverage: regulatory discussion dominated in 2022, Generative AI surged through 2023, and by 2024–2025 coverage has stabilised across all subtopics. The sentiment heatmap shows that while overall sentiment is near-neutral, subtopics differ persistently: AI in Healthcare is framed positively (diagnostic breakthroughs), and AI & Jobs is framed negatively (job displacement threat).

== Cross-Correlation

#fig(
  "data/cross_correlation.png",
  [Cross-correlation between AI Safety and AI Regulation weekly counts (lags −8 to +8 weeks). The peak at a positive lag suggests AI Safety coverage tends to precede AI Regulation coverage.],
  width: 72%
)

The cross-correlation shows a positive peak at a lag of roughly 1–3 weeks, meaning AI Safety discourse tends to precede AI Regulation coverage. This is directionally consistent with the idea that public safety debates generate political pressure for regulation, though the correlation is modest and not causal.

// ============================================================
= Clustering the "Other" Articles
// ============================================================

70% of articles (17,328) fell into the "Other" category, meaning the keyword dictionary missed most of the corpus. To explore this, we applied BERTopic: sentence embeddings with `all-MiniLM-L6-v2`, UMAP dimensionality reduction to 5D, HDBSCAN clustering, and c-TF-IDF topic representation.

#fig(
  "data/other_clusters_umap.png",
  [UMAP 2D projection of the 17,328 "Other" articles coloured by BERTopic cluster. Topic 0 (AI & World Politics) forms a dense coherent mass; Topic 1 is scattered noise.],
  width: 80%
)

BERTopic found two clusters. Cluster 0 (*AI & World Politics*, 15,733 articles, 91%) contains articles about AI in geopolitical contexts — chip sanctions, AI in warfare, AI in elections. Cluster 1 (*Noise*, 1,595 articles, 9%) is off-topic sports and entertainment content that matched the broad query. The geopolitical cluster is a coherent and substantive theme that keyword matching missed because it uses political rather than technical vocabulary.

*Implementation note:* With 17,328 documents, the vectorizer raised `ValueError: After pruning, no terms remain`. The fix was to cap `min_df` at 20 and switch `max_df` from a raw count to a ratio (0.85).

// ============================================================
= Forecasting
// ============================================================

For each subtopic we split the series into training (all weeks except the last 8) and an 8-week holdout. Both Prophet and SARIMA (`pmdarima.auto_arima`, m=52) are fit on training data and evaluated on the holdout. The lower-RMSE model is then refit on all data and used to forecast 13 weeks ahead.

#fig(
  "data/forecast_summary_chart.png",
  [3-month forecast: percentage change relative to the recent 4-week average. Green = Rising, blue = Stable, red = Declining.],
  width: 88%
)

#figure(
  table(
    columns: (1.5fr, auto, auto, auto, auto),
    fill: (_, row) => if row == 0 { rgb("#1B4F72") } else if calc.even(row) { rgb("#EBF5FB") } else { white },
    stroke: 0.5pt + rgb("#AED6F1"),
    inset: 6pt,
    table.header(
      text(fill: white, weight: "bold")[Subtopic],
      text(fill: white, weight: "bold")[Change %],
      text(fill: white, weight: "bold")[Trend],
      text(fill: white, weight: "bold")[Model],
      text(fill: white, weight: "bold")[Holdout RMSE],
    ),
    [AI Safety],         [+306%], [Rising ↑],    [SARIMA],  [2.23],
    [AI & Jobs],         [+36%],  [Rising ↑],    [SARIMA],  [1.12],
    [AI Regulation],     [+4%],   [Stable →],    [Prophet], [6.91],
    [Generative AI],     [+3%],   [Stable →],    [SARIMA],  [2.77],
    [AI in Healthcare],  [−13%],  [Declining ↓], [Prophet], [2.07],
    [AI & Big Tech],     [−22%],  [Declining ↓], [Prophet], [3.74],
  ),
  caption: [Forecast summary. Winner selected by 8-week holdout RMSE. Neither model universally dominates.]
)

AI Safety shows the most dramatic projected growth (+306%), driven by a rising trend from the Bletchley Park anomaly. AI & Jobs shows a steady upward trend. AI Regulation is forecast as stable — it has the highest volume but no clear directional trend. AI & Big Tech is declining, likely as corporate AI announcements normalise. SARIMA won on three subtopics; Prophet won on three, confirming that model selection should be data-driven per series.

// ============================================================
= Conclusion
// ============================================================

This project shows that a corpus of 23,859 news articles can be successfully engineered into a multi-dimensional weekly time series and analysed with standard mining techniques. Key findings:

- *Trend analysis* confirms a permanent step-change in AI coverage after the ChatGPT launch in November 2022.
- *Anomaly detection* recovers known events (Bletchley Park summit, DeepSeek release, OpenAI crisis) as statistically significant spikes, validating the pipeline.
- *Sentiment* is structured by subtopic: AI in Healthcare is consistently positive; AI & Jobs is consistently negative — differences invisible to volume-only analyses.
- *BERTopic clustering* reveals that 91% of "Other" articles form a coherent AI & World Politics cluster, showing that geopolitical AI discourse is large but not captured by technical keywords.
- *Forecasting* projects AI Safety and AI & Jobs as rising; AI & Big Tech as declining. Neither Prophet nor SARIMA universally wins — holdout evaluation is necessary.

*Limitations:* Keyword matching is coarse (70% "Other" rate). VADER may underestimate sentiment intensity in formal news text. The Guardian's editorial perspective introduces source bias.

// ── References ────────────────────────────────────────────────
= References

#set par(hanging-indent: 1.2em, justify: false)

[1] #h(0.3em) Hutto, C., & Gilbert, E. (2014). VADER: A parsimonious rule-based model for sentiment analysis of social media text. *ICWSM-14.*

[2] #h(0.3em) Taylor, S. J., & Letham, B. (2018). Forecasting at scale. *The American Statistician, 72*(1), 37–45.

[3] #h(0.3em) Grootendorst, M. (2022). BERTopic: Neural topic modeling with a class-based TF-IDF procedure. *arXiv:2203.05794.*

[4] #h(0.3em) McInnes, L., Healy, J., & Melville, J. (2018). UMAP: Uniform manifold approximation and projection. *arXiv:1802.03426.*

[5] #h(0.3em) Reimers, N., & Gurevych, I. (2019). Sentence-BERT: Sentence embeddings using Siamese BERT-networks. *EMNLP-IJCNLP 2019.*

[6] #h(0.3em) The Guardian Open Platform API. https://open-platform.theguardian.com/documentation/
