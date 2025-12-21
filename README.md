# Count Data Modeling
This repository is a MATLAB project to model Count Data to
predict the number of a tickets reported through a helpdesk
system. The project contains the scripts to perform the required
EDA and models prediction.

# Data Source
The project is based on the
[Help Desk Tickets](https://data.mendeley.com/datasets/btm76zndnt/2) dataset
published in Mendely. The dataset is described in the repository.

# How to run
- Download/clone the project into a directory.
- Import the project into MATLAB, noting that that project was built using
MATLAB R2025b
- Run the run_pre_process.m file which will download the dataset from Mendeley
and do the required preprocessing and preperation
- Then run any live script that starts with run_ for the exploratory Data
Analysis.
    - run_EDA.mlx: explore the helpdesk issues count patterns and inspect
its relation with other features
    - run_ANOVA.mlx: inspect the possible differences in issues count
over different time period of the year.

