# Omicbot

Omicbot is an RStudio-oriented AI assistant package for interactive R programming, exploratory data analysis, and omics-focused workflows. It is designed to give bioinformaticians and data analysts a lightweight way to work with large language models directly inside RStudio, without constantly switching between the IDE and external chat tools.

## What Omicbot is

Omicbot is an R package that adds AI-assisted interaction to the RStudio workflow. Instead of treating an LLM as a separate website or app, Omicbot brings prompting, quick troubleshooting, and lightweight assistant-style interaction closer to the R console and RStudio addin system.

In practice, this makes it feel more like a coding and analysis companion embedded in the place where bioinformatics work already happens.

## What it can do

Omicbot is intended to help with tasks such as:

- answering analysis questions while you work in RStudio
- helping explain or debug console errors
- assisting with quick code generation or code refinement
- supporting iterative data exploration workflows
- making model/provider setup easier for users who want to use AI in R
- offering shortcut-based and quick-chat interactions for low-friction use

Based on the current package structure and documentation, it supports:

- an RStudio addin / shortcut-driven chat workflow
- multi-provider model configuration
- quick console-driven prompting
- interactive setup and configuration management
- browser-chat launching and lightweight chat utilities

## Why it is useful for bioinformaticians

Bioinformatics work in R often involves many small but cognitively heavy steps: loading expression matrices, cleaning metadata, checking object structure, debugging pipeline errors, sketching visualizations, testing package functions, and interpreting intermediate results. Omicbot is useful because it can act as an always-available assistant during those steps.

For example, a bioinformatician could use Omicbot to:

- troubleshoot an error while running an RNA-seq or single-cell analysis script
- get help writing or refining data wrangling code for expression matrices and sample metadata
- draft plotting code for PCA, clustering, volcano plots, heatmaps, or violin plots
- quickly ask for explanations of statistical concepts or package behavior
- iterate on exploratory analysis ideas without leaving RStudio
- reduce friction when moving from a question to a runnable R snippet

The value is less about full automation and more about speeding up the day-to-day analysis loop: think, ask, test, revise.

## Installation

At the moment, the most straightforward way to install Omicbot is from the GitHub repository.

```r
# install.packages("remotes")
remotes::install_github("WuJianHITSZ/omicbot")
```

After installation:

1. Open RStudio.
2. Go to **Tools -> Modify Keyboard Shortcuts**.
3. Search for the addin named **omicbot**.
4. Assign a shortcut key. (`Shift+Enter` is recommended in the current README.)
5. Type a prompt in the RStudio Console and trigger the shortcut instead of pressing Enter.

If your prompt is multi-line, you can place it in the clipboard and trigger the addin from the Console; the package is documented to pick up clipboard content for multi-line prompts.

## Current state

This repository appears to be an actively developed R package prototype with package metadata, addin integration, tests, examples, and supporting scripts. The current implementation already shows a practical direction: bringing AI assistance into the native RStudio workflow for data-centric users.

## Intended audience

Omicbot is aimed at R users who want a simple IDE-native AI workflow, especially:

- bioinformaticians
- computational biologists
- omics data analysts
- R users doing iterative exploratory analysis
- researchers who want faster troubleshooting and prototyping inside RStudio
