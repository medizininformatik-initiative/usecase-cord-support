# Script to calculate the aggregate of patients corresponding to Mukoviszidose/CF Cystic Fibrosis and Birth


### 1. clone repository and checkout branch cf_script

```
git clone --branch cf_script https://github.com/medizininformatik-initiative/usecase-cord-support.git

cd usecase-cord-support/Studienprotokolle/CF/
```

### 2. create your custom config and edit
```
cp conf.yml.sample conf.yml
```



### 3. start calculation
```
Rscript script_cf.r
```