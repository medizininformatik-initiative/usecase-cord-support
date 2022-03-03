# get shiny serves plus tidyverse packages image
FROM rocker/shiny-verse:4.1.2
# system libraries of general use
RUN apt-get update && apt-get install -y \
    libudunits2-dev \
    libgdal-dev \
    libgeos-dev \
    libproj-dev \
    openjdk-8-jre-headless \
    texlive-latex-recommended \
    texlive-latex-extra

RUN echo "options('repos' = 'http://cran.rstudio.com/')" >> /usr/local/lib/R/etc/Rprofile.site

# install R packages required 
# (change it dependeing on the packages you need)
RUN R -e "install.packages(c('dplyr', 'ggmap', 'ggplot2', 'knitr', 'leaflet', 'pander', 'readr', 'sf', 'stringr', 'tidygeocoder', 'tidyr', 'fhircrackr', 'readxl', 'config', 'tidyverse', 'geosphere', 'tibble'))"

#create script folders in container
RUN mkdir -p /srv/shiny-server/data
RUN mkdir -p /srv/shiny-server/Team1_FHIRCrackR
RUN mkdir -p /srv/shiny-server/Team2_Distance
RUN mkdir -p /srv/shiny-server/Team3_Aggregation
RUN mkdir -p /srv/shiny-server/Team4_Geoviz

# copy the app to the image
COPY runscript_1234.sh /srv/shiny-server/run.sh
COPY Team1_FHIRCrackR/cord_hackathon_fhircrackr.r /srv/shiny-server/Team1_FHIRCrackR/script1.r
COPY Team2_Distance/distance.r /srv/shiny-server/Team2_Distance/script2.r
COPY Team3_Aggregation/jars/cord-anonymization-v0.0.1.jar /srv/shiny-server/Team3_Aggregation/script3.jar
COPY Team4_Geoviz/shinyapp.r /srv/shiny-server/app.r
COPY build/data.RData /srv/shiny-server/data.RData
COPY build/PLZ_manual_correction.cleaned.csv /srv/shiny-server/data/PLZ_manual_correction.cleaned.csv

COPY Team4_Geoviz/visualization.Rmd /srv/shiny-server/Team4_Geoviz/visualization.Rmd

RUN ["chown", "-R", "shiny", "/srv/shiny-server/data"]
RUN ["chown", "-R", "shiny", "/srv/shiny-server/Team4_Geoviz"]

RUN wget https://biogeo.ucdavis.edu/data/gadm3.6/gpkg/gadm36_DEU_gpkg.zip
RUN mv gadm36_DEU_gpkg.zip /srv/shiny-server/Team4_Geoviz/gadm36_DEU_gpkg.zip

COPY build/shiny-server.sh /usr/bin/shiny-server.sh
RUN ["chmod", "+x", "/usr/bin/shiny-server.sh"]

# select port
EXPOSE 3838

USER shiny

# run app
CMD ["/usr/bin/shiny-server.sh"]
