# Newslyze

A comprehensive news analysis pipeline that scrapes, classifies, and forecasts trends in global risk topics using machine learning and time series analysis.

## Overview

Newslyze is a data science project that analyzes news articles from The Guardian to identify and forecast trends across multiple risk domains including AI, geopolitics, energy markets, climate, cybersecurity, public health, and macroeconomic indicators.

The project processes over 37,000 articles spanning multiple years, applying natural language processing, topic modeling, sentiment analysis, and time series forecasting to extract insights from news data.

## Key Features

- **Automated News Collection**: Scrapes articles from The Guardian API with multi-topic filtering
- **Topic Classification**: Uses BERTopic and custom taxonomies to classify articles into 17+ categories
- **Sentiment Analysis**: Applies VADER sentiment scoring to track sentiment trends over time
- **Time Series Engineering**: Constructs and engineers time series features for trend analysis
- **Pattern Mining**: Analyzes co-occurrence patterns and topic relationships
- **Clustering**: Groups miscellaneous topics using HDBSCAN and UMAP
- **Forecasting**: Predicts future topic volumes using Prophet and ARIMA models

## Project Workflow

The analysis pipeline consists of 7 sequential notebooks:

1. **01_scrape_guardian.ipynb** - Fetch articles from The Guardian API
   - Queries 17 topic categories (AI, geopolitics, energy, climate, etc.)
   - Filters by relevance and quality (minimum word count)
   - Outputs: `data/raw_articles.csv` (~37K articles)

2. **02_classify_subtopics.ipynb** - Topic modeling and classification
   - Generates sentence embeddings using transformer models
   - Applies BERTopic for unsupervised topic discovery
   - Assigns primary and secondary topics to each article

3. **03_sentiment_scoring.ipynb** - Sentiment analysis
   - Calculates sentiment scores using VADER
   - Tracks sentiment trends by topic and time period

4. **04_engineer_timeseries.ipynb** - Time series feature engineering
   - Aggregates article counts by topic and date
   - Creates rolling averages, trends, and statistical features

5. **05_mining_analysis.ipynb** - Pattern and relationship mining
   - Discovers topic co-occurrence patterns
   - Analyzes correlations between different risk domains

6. **06_cluster_others.ipynb** - Cluster miscellaneous topics
   - Groups articles labeled as "other" using dimensionality reduction
   - Identifies emergent themes not covered by initial taxonomy

7. **07_forecast_subtopics.ipynb** - Time series forecasting
   - Predicts future article volumes by topic
   - Uses Prophet and pmdarima (ARIMA) models
   - Generates forecast visualizations and accuracy metrics

## Installation

### Prerequisites

- Python 3.13 or higher
- uv package manager (recommended) or pip

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd newslyze
```

2. Install dependencies using uv:
```bash
uv sync
```

Or using pip:
```bash
pip install -e .
```

### Development Setup

To install with development dependencies (includes Jupyter):
```bash
uv sync --group dev
```

## Usage

### Running the Pipeline

Execute the notebooks in sequence (01 through 07) to run the complete analysis pipeline:

```bash
jupyter notebook
```

### Guardian API Key

To scrape fresh data, you'll need a Guardian API key:
1. Register at [The Guardian Open Platform](https://open-platform.theguardian.com/)
2. Update the `API_KEY` variable in `01_scrape_guardian.ipynb`

### Quick Start

```bash
# Activate the environment
source .venv/bin/activate  # or activate your virtual environment

# Launch Jupyter
jupyter notebook

# Run notebooks 01-07 in sequence
```

## Project Structure

```
newslyze/
├── 01_scrape_guardian.ipynb       # Data collection
├── 02_classify_subtopics.ipynb    # Topic modeling
├── 03_sentiment_scoring.ipynb     # Sentiment analysis
├── 04_engineer_timeseries.ipynb   # Feature engineering
├── 05_mining_analysis.ipynb       # Pattern mining
├── 06_cluster_others.ipynb        # Clustering analysis
├── 07_forecast_subtopics.ipynb    # Time series forecasting
├── data/                          # Data directory (CSV files)
├── main.py                        # Entry point
├── pyproject.toml                 # Project configuration
├── report.typ                     # Project report (Typst format)
└── README.md                      # This file
```

## Dependencies

### Core Libraries

- **Data Processing**: pandas, numpy, scipy
- **Machine Learning**: scikit-learn, sentence-transformers, transformers, torch
- **Topic Modeling**: bertopic, hdbscan, umap-learn
- **Sentiment Analysis**: vadersentiment
- **Time Series**: prophet, pmdarima
- **Visualization**: matplotlib, seaborn
- **API Access**: requests

### Development

- jupyter
- ipykernel

See `pyproject.toml` for complete dependency list with versions.

## Data

The project processes articles across 17 primary topic categories:

- Artificial Intelligence
- Geopolitics & Conflict
- Energy Markets
- Macroeconomy
- Climate & Weather
- Public Health
- Cybersecurity
- Supply Chain
- Food & Water Security
- Finance & Banking
- Elections & Governance
- Defense & Security
- Trade & Industry
- Labor & Social Issues
- Natural Disasters
- Technology Policy
- Commodities & Metals

### Data Files

Generated data files are stored in the `data/` directory:
- `raw_articles.csv` - Scraped articles with metadata
- `embeddings.npy` - Sentence embeddings for topic modeling
- Additional intermediate CSV files from each analysis stage

## Reports

Project documentation and analysis reports are available in Typst format:
- `report.typ` - Main project report
- `report2.typ` - Additional analysis report
  

## Acknowledgments

- Data source: [The Guardian Open Platform](https://open-platform.theguardian.com/)
- Built with Python 3.13 and modern NLP/ML libraries
