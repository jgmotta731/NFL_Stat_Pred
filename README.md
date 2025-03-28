# NFL Player Stat Predictor 🏈  
**Full-Stack Sports Analytics Dashboard powered by R, Shiny, and Machine Learning**  
_Author: Jack Motta_

## 🔍 Overview

NFL Player Stat Predictor is an interactive R Shiny web application that predicts weekly NFL player performance for Quarterbacks (QBs), Running Backs (RBs), and Wide Receivers/Tight Ends (WR/TE). It leverages advanced data engineering, machine learning pipelines, and a custom-themed frontend to deliver real-time player stat forecasts in a production-ready format.

This project demonstrates full-stack R development — from data ingestion and modeling to UI/UX design — and showcases my ability to build end-to-end data products in a real-world sports analytics context.

---

## 🎯 Key Features

- **Weekly Player Predictions**  
  Forecasts passing, rushing, and receiving stats using historical performance and contextual in-game features.

- **Advanced Modeling Pipeline**  
  Uses multi-response LASSO regression (`glmnet`) and rolling-origin cross-validation to handle time-series data and tune model hyperparameters.

- **Custom Shiny Dashboard**  
  Clean, mobile-friendly interface with player headshots, dynamic tables, dark mode styling (`bslib`), and fully interactive components.

- **Metrics Tab**  
  Explains RMSE and R-squared for non-technical users while displaying model diagnostics across each position group.

- **Extensive Data Engineering**  
  Aggregates, merges, and cleans player and game-level data from:
  - `nflreadr` (core player stats)
  - `nflfastR` (game context)
  - ESPN QBR
  - NextGen Stats
  - Pro Football Reference (advanced stats)

---

## 📊 Model Metrics

Each position group is trained on its own dataset with engineered features tailored to how that position contributes on the field.

**Performance Metrics Used:**

- **RMSE (Root Mean Squared Error):**  
  Measures average prediction error in the unit of the stat. In this domain, an RMSE that’s ~10–20% of a stat’s range is often solid.

- **R-squared (R²):**  
  Indicates how much variation is explained by the model. In real-world settings like NFL performance prediction, R² values between 0.3–0.5 (or lower) are common due to high game-to-game variance and external factors like game flow, weather, and injuries.

_The app’s "Metrics" tab includes both the numbers and beginner-friendly explanations to help contextualize model performance._

---

## 🧰 Tech Stack

| Layer              | Tools Used                                                                 |
|-------------------|------------------------------------------------------------------------------|
| **Frontend**       | `shiny`, `bslib`, `reactable`, `shinyWidgets`, custom HTML/CSS              |
| **Backend**        | `tidymodels`, `glmnet`, `recipes`, `doParallel`                             |
| **Data Ingestion** | `nflreadr`, `nflfastR`, `arrow`, `readr`                                    |
| **Modeling**       | LASSO (`glmnet`) with rolling-origin CV for robust time-aware tuning        |
| **Visualization**  | `ggplot2`, `factoextra` (clustering diagnostics)                            |

---

## 🚀 Running the App Locally

1. Clone this repository:

    ```r
    # In your R console or terminal:
    git clone https://github.com/yourusername/nfl-player-predictor.git
    setwd("nfl-player-predictor")
    ```

2. Install required packages:

    ```r
    install.packages(c(
      "shiny", "bslib", "reactable", "shinyWidgets", "dplyr", "readr", "arrow",
      "nflreadr", "nflfastR", "tidymodels", "zoo", "doParallel", 
      "glmnet", "factoextra", "cluster"
    ))
    ```

3. Run the Shiny app:

    ```r
    shiny::runApp("app.R")
    ```

Make sure the prediction and metrics files (`QB_Preds.parquet`, `RB_Metrics.parquet`, etc.) are saved in the app directory. You can regenerate them using the modeling scripts (`QB_Stat_Pred.Rmd`, `RB_Stat_Pred.Rmd`, `WR_TE_Stat_Pred.Rmd`).

---

## 💼 Why This Project Stands Out

This project simulates a real-world workflow in data science and applied modeling:

- **End-to-End Ownership**  
  Covers data collection, preprocessing, modeling, evaluation, and interactive presentation.

- **Real-World Constraints**  
  Handles noisy and volatile data in a domain (sports) where perfect prediction is unrealistic — and embraces it with transparent metric explanations.

- **Clear Communication**  
  Bridges the gap between technical output and human interpretation with a polished user interface and intuitive insights.

- **Production-Ready Workflow**  
  Designed with maintainability in mind — modularized data cleaning, modeling, and deployment-ready `.parquet` outputs.

This project serves as both a practical tool and a demonstration of applied modeling, reproducibility, and front-end integration in R.

---

## 📬 Contact

If you're interested in this project or want to discuss more:

**Jack Motta**  
📧 jgmotta2000@gmail.com  
🔗 [LinkedIn](https://www.linkedin.com/in/jack-motta-3210a3241)  
🐙 [GitHub](https://github.com/jgmotta731)

---

> _"In predictive modeling, especially in sports analytics, insight often lies in improving over noise—not eliminating it entirely."_  
