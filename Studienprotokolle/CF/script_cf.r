####################################################################################################################
# To calculate the aggregate of patients corresponding to
# Mukoviszidose/CF Cystic Fibrosis and Birth
####################################################################################################################
start_time <- Sys.time()
options(warn = -1)# to suppress warnings
if (!require("fhircrackr")) install.packages("fhircrackr")
if (!require("config")) install.packages("config")
if (!require("dplyr")) install.packages("dplyr")

dir.create(file.path(getwd(),"results"), showWarnings = FALSE)

conf <- config::get(file = paste(getwd(), "/conf.yml", sep = ""))

#check for proxy configuration
if (exists("http_proxy", where = conf)) {
  if (nchar(conf$http_proxy) >= 1) {
    Sys.setenv(http_proxy = conf$http_proxy)
  }
}

if (exists("https_proxy", where = conf)) {
  if (nchar(conf$https_proxy) >= 1) {
    Sys.setenv(https_proxy = conf$https_proxy)
  }
}

if (exists("count", where = conf)) {
  if (nchar(conf$no_proxy) >= 1) {
    Sys.setenv(no_proxy = conf$no_proxy)
  }
}

# check for custom recordedDate
if (exists("recordedDate_col", where = conf)) {
  if (nchar(conf$recordedDate_col) >= 1) {
    recorded_date_custom <- conf$recordedDate_col
  } else {
    recorded_date_custom <- "recordedDate"
  }
  search_date <- paste0("&", strsplit(recorded_date_custom, "Date")[[1]][1],  "-date")
} else {
  recorded_date_custom <- "recordedDate"
  search_date <- paste0("&", strsplit(recorded_date_custom, "Date")[[1]][1],  "-date")
}

# check for custom subject_reference_prefix
if (exists("subject_reference_prefix", where = conf)) {
  if (nchar(conf$subject_reference_prefix) >= 1) {
    subject_reference_prefix <- conf$subject_reference_prefix
  } else {
    subject_reference_prefix <- "Patient/"
  }
} else {
  subject_reference_prefix <- "Patient/"
}

# check for custom icd_code_system
if (exists("icd_code_system", where = conf)) {
  if (nchar(conf$icd_code_system) >= 1) {
    icd_code_system_custom <- conf$icd_code_system
  } else {
    icd_code_system_custom <- "http://fhir.de/CodeSystem/dimdi/icd-10-gm"
  }
} else {
  icd_code_system_custom <- "http://fhir.de/CodeSystem/dimdi/icd-10-gm"
}

if (exists("ssl_verify_peer", where = conf)) {
  if (!(conf$ssl_verify_peer)) {
    httr::set_config(httr::config(ssl_verifypeer = 0L))
  }
}

if (exists("max_bundles", where = conf)) {
  if (nchar(conf$max_bundles) >= 1) {
    max_bundles_custom <- conf$max_bundles
  } else {
    max_bundles_custom <- 0
  }
} else {
  max_bundles_custom <- 0
}

if (exists("count", where = conf)) {
  if (nchar(conf$count) >= 1) {
    count_custom <- paste0("&_count=", conf$count)
  } else {
    count_custom <- ""
  }
} else {
  count_custom <- ""
}

search_request_pat <- paste0(
  conf$serverbase,
  "Patient?",
  "_has:Condition:patient:code=",
  "E84.0,E84.1,E84.8,E84.80,E84.87,E84.88,E84.9",
  "&_has:Encounter:patient:date=ge2015",
  # blaze server takes 10x more time for the query with last _has
  #"&_has:Encounter:patient:date=le2022",
  count_custom
)

if (exists("token", where = conf)) {
  if (nchar(conf$token) >= 1) {
    patient_bundle <- fhir_search(request = search_request_pat, username = conf$user, password = conf$password, token = conf$token, verbose = 2, max_bundles = max_bundles_custom)
    } else {
    patient_bundle <- fhir_search(request = search_request_pat, username = conf$user, password = conf$password, verbose = 2, max_bundles = max_bundles_custom)
    }
  } else {
    if (exists("username", where = conf)) {
      patient_bundle <- fhir_search(request = search_request_pat, username = conf$user, password = conf$password, verbose = 2, max_bundles = max_bundles_custom)
    } else {
      patient_bundle <- fhir_search(request = search_request_pat, verbose = 2, max_bundles = max_bundles_custom)
    }
}

conditions <- fhir_table_description(resource = "Condition",
                                     cols = c(diagnosis = "code/coding/code",
                                              display = "code/coding/display",
                                              system = "code/coding/system",
                                              recorded_date = recorded_date_custom,
                                              patient_id = "subject/reference"
                                              )
)

patients <- fhir_table_description(resource = "Patient",
                                   cols = c(patient_id = "id",
                                            hospital_id = "meta/source",
                                            gender = "gender",
                                            birthdate = "birthDate",
                                            patient_zip = "address/postalCode",
                                            countrycode = "address/country"
                                            )
)

design_pat <- fhir_design(patients)
design_con <- fhir_design(conditions)

# flatten the XML object bundles from patients and conditions to a list
if (packageVersion("fhircrackr") >= 2) {
  list_cdn <- fhir_crack(patient_bundle, design_pat, sep = "|", brackets = c("[", "]"), verbose = 2, ncores = 1)
} else {
  list_cdn <- fhir_crack(patient_bundle, design_pat, sep = "|", brackets = c("[", "]"), verbose = 2)
}

# save conditions and patients in separate dataframes
#df_conditions_raw <- list_cdn$conditions
df_patients_raw <- list_cdn$patients
df_patients_tmp <- fhir_melt(df_patients_raw,
                             columns = c("patient_zip", "countrycode"),
                             brackets = c("[", "]"), sep = "|", all_columns = TRUE)

df_patients_tmp <- fhir_rm_indices(df_patients_tmp, brackets = c("[", "]"))

# remove duplicate entries
df_patients_tmp <- df_patients_tmp[!duplicated(df_patients_tmp$patient_id), ]

pat_ref_ids <- paste(df_patients_tmp$patient_id,collapse=',')

patient_ids <- unique(df_patients_tmp$patient_id)
nchar_for_ids <- 500 #- nchar(search_request_con)
n <- length(patient_ids)
list <- split(patient_ids, ceiling(seq_along(patient_ids)/n)) 
nchar <- sapply(list, function(x){sum(nchar(x))+(length(x)-1)}) 

#reduce the chunk size until number of characters is small enough
while(any(nchar > nchar_for_ids)){
  n <- n/2
  list <- split(patient_ids, ceiling(seq_along(patient_ids)/n))
  nchar <- sapply(list, function(x){sum(nchar(x))+(length(x)-1)})
}

condition_bundle <- list()
message("Downloading Conditions.\n")
invisible({
  lapply(list, function(x){
    
    ids <- paste(x, collapse = ",")
    
    search_request_con <- paste0(
      conf$serverbase,
      "Condition?",
      "subject=",ids,
      "&code=",
      "E84.0,E84.1,E84.8,E84.80,E84.87,E84.88,E84.9",
      ",J18.0,J18.1,J18.2,J18.8,J18.9",
      ",O09.0,O09.1,O09.2,O09.3,O09.4,O09.5,O09.6,O09.7,O09.9",
      ",O09.0%21,O09.1%21,O09.2%21,O09.3%21,O09.4%21,O09.5%21,O09.6%21,O09.7%21,O09.9%21",
      ",O09.0%20Z37.0%21,O09.0%20Z37.1%21,O09.0%20Z37.2%21,O09.0%20Z37.3%21,O09.0%20Z37.4%21,O09.0%20Z37.5%21,O09.0%20Z37.6%21,O09.0%20Z37.7%21,O09.0%20Z37.9%21",
      ",O09.1%20Z37.0%21,O09.1%20Z37.1%21,O09.1%20Z37.2%21,O09.1%20Z37.3%21,O09.1%20Z37.4%21,O09.1%20Z37.5%21,O09.1%20Z37.6%21,O09.1%20Z37.7%21,O09.1%20Z37.9%21",
      ",O09.2%20Z37.0%21,O09.2%20Z37.1%21,O09.2%20Z37.2%21,O09.2%20Z37.3%21,O09.2%20Z37.4%21,O09.2%20Z37.5%21,O09.2%20Z37.6%21,O09.2%20Z37.7%21,O09.2%20Z37.9%21",
      ",O09.3%20Z37.0%21,O09.3%20Z37.1%21,O09.3%20Z37.2%21,O09.3%20Z37.3%21,O09.3%20Z37.4%21,O09.3%20Z37.5%21,O09.3%20Z37.6%21,O09.3%20Z37.7%21,O09.3%20Z37.9%21",
      ",O09.4%20Z37.0%21,O09.4%20Z37.1%21,O09.4%20Z37.2%21,O09.4%20Z37.3%21,O09.4%20Z37.4%21,O09.4%20Z37.5%21,O09.4%20Z37.6%21,O09.4%20Z37.7%21,O09.4%20Z37.9%21",
      ",O09.5%20Z37.0%21,O09.5%20Z37.1%21,O09.5%20Z37.2%21,O09.5%20Z37.3%21,O09.5%20Z37.4%21,O09.5%20Z37.5%21,O09.5%20Z37.6%21,O09.5%20Z37.7%21,O09.5%20Z37.9%21",
      ",O09.6%20Z37.0%21,O09.6%20Z37.1%21,O09.6%20Z37.2%21,O09.6%20Z37.3%21,O09.6%20Z37.4%21,O09.6%20Z37.5%21,O09.6%20Z37.6%21,O09.6%20Z37.7%21,O09.6%20Z37.9%21",
      ",O09.7%20Z37.0%21,O09.7%20Z37.1%21,O09.7%20Z37.2%21,O09.7%20Z37.3%21,O09.7%20Z37.4%21,O09.7%20Z37.5%21,O09.7%20Z37.6%21,O09.7%20Z37.7%21,O09.7%20Z37.9%21",
      ",O09.9%20Z37.0%21,O09.8%20Z37.1%21,O09.9%20Z37.2%21,O09.9%20Z37.3%21,O09.9%20Z37.4%21,O09.9%20Z37.5%21,O09.9%20Z37.6%21,O09.9%20Z37.7%21,O09.9%20Z37.9%21",
      ",O24.4",
      ",O30.0,O30.1,O30.2,O30.8,O30.9",
      ",O63.0,O63.1,O63.2,O63.9",
      ",O64.0,O64.1,O64.2,O64.3,O64.4,O64.5,O64.8,O64.9",
      ",O64.0%20Z37.0%21,O64.0%20Z37.1%21,O64.0%20Z37.2%21,O64.0%20Z37.3%21,O64.0%20Z37.4%21,O64.0%20Z37.5%21,O64.0%20Z37.6%21,O64.0%20Z37.7%21,O64.0%20Z37.9%21",
      ",O64.1%20Z37.0%21,O64.1%20Z37.1%21,O64.1%20Z37.2%21,O64.1%20Z37.3%21,O64.1%20Z37.4%21,O64.1%20Z37.5%21,O64.1%20Z37.6%21,O64.1%20Z37.7%21,O64.1%20Z37.9%21",
      ",O64.2%20Z37.0%21,O64.2%20Z37.1%21,O64.2%20Z37.2%21,O64.2%20Z37.3%21,O64.2%20Z37.4%21,O64.2%20Z37.5%21,O64.2%20Z37.6%21,O64.2%20Z37.7%21,O64.2%20Z37.9%21",
      ",O64.3%20Z37.0%21,O64.3%20Z37.1%21,O64.3%20Z37.2%21,O64.3%20Z37.3%21,O64.3%20Z37.4%21,O64.3%20Z37.5%21,O64.3%20Z37.6%21,O64.3%20Z37.7%21,O64.3%20Z37.9%21",
      ",O64.4%20Z37.0%21,O64.4%20Z37.1%21,O64.4%20Z37.2%21,O64.4%20Z37.3%21,O64.4%20Z37.4%21,O64.4%20Z37.5%21,O64.4%20Z37.6%21,O64.4%20Z37.7%21,O64.4%20Z37.9%21",
      ",O64.5%20Z37.0%21,O64.5%20Z37.1%21,O64.5%20Z37.2%21,O64.5%20Z37.3%21,O64.5%20Z37.4%21,O64.5%20Z37.5%21,O64.5%20Z37.6%21,O64.5%20Z37.7%21,O64.5%20Z37.9%21",
      ",O64.8%20Z37.0%21,O64.8%20Z37.1%21,O64.8%20Z37.2%21,O64.8%20Z37.3%21,O64.8%20Z37.4%21,O64.8%20Z37.5%21,O64.8%20Z37.6%21,O64.8%20Z37.7%21,O64.8%20Z37.9%21",
      ",O64.9%20Z37.0%21,O64.8%20Z37.1%21,O64.9%20Z37.2%21,O64.9%20Z37.3%21,O64.9%20Z37.4%21,O64.9%20Z37.5%21,O64.9%20Z37.6%21,O64.9%20Z37.7%21,O64.9%20Z37.9%21",
      ",O75.0,O75.1,O75.2,O75.3,O75.4,O75.5,O75.6,O75.7,O75.8,O75.9",
      ",O80,O81,O82",
      ",O80%20Z37.0%21,O81%20Z37.0%21,O82%20Z37.0%21",
      ",O80%20Z37.1%21,O81%20Z37.1%21,O82%20Z37.1%21",
      ",O80%20Z37.2%21,O81%20Z37.2%21,O82%20Z37.2%21",
      ",O80%20Z37.3%21,O81%20Z37.3%21,O82%20Z37.3%21",
      ",O80%20Z37.4%21,O81%20Z37.4%21,O82%20Z37.4%21",
      ",O80%20Z37.5%21,O81%20Z37.5%21,O82%20Z37.5%21",
      ",O80%20Z37.6%21,O81%20Z37.6%21,O82%20Z37.6%21",
      ",O80%20Z37.7%21,O81%20Z37.7%21,O82%20Z37.7%21",
      ",O80%20Z37.9%21,O81%20Z37.9%21,O82%20Z37.9%21",
      ",Z37.0,Z37.1,Z37.2,Z37.3,Z37.4,Z37.5,Z37.6,Z37.7,Z37.9",
      ",Z38.0,Z38.1,Z38.2,Z38.3,Z38.4,Z38.5,Z38.6,Z38.7,Z38.8",
      ",e84.0,e84.1,e84.8,e84.80,e84.87,e84.88,e84.9",
      ",j18.0,j18.1,j18.2,j18.8,j18.9",
      ",o09.0,o09.1,o09.2,o09.3,o09.4,o09.5,o09.6,o09.7,o09.9",
      ",o09.0%21,o09.1%21,o09.2%21,o09.3%21,o09.4%21,o09.5%21,o09.6%21,o09.7%21,o09.9%21",
      ",o09.0%20z37.0%21,o09.0%20z37.1%21,o09.0%20z37.2%21,o09.0%20z37.3%21,o09.0%20z37.4%21,o09.0%20z37.5%21,o09.0%20z37.6%21,o09.0%20z37.7%21,o09.0%20z37.9%21",
      ",o09.1%20z37.0%21,o09.1%20z37.1%21,o09.1%20z37.2%21,o09.1%20z37.3%21,o09.1%20z37.4%21,o09.1%20z37.5%21,o09.1%20z37.6%21,o09.1%20z37.7%21,o09.1%20z37.9%21",
      ",o09.2%20z37.0%21,o09.2%20z37.1%21,o09.2%20z37.2%21,o09.2%20z37.3%21,o09.2%20z37.4%21,o09.2%20z37.5%21,o09.2%20z37.6%21,o09.2%20z37.7%21,o09.2%20z37.9%21",
      ",o09.3%20z37.0%21,o09.3%20z37.1%21,o09.3%20z37.2%21,o09.3%20z37.3%21,o09.3%20z37.4%21,o09.3%20z37.5%21,o09.3%20z37.6%21,o09.3%20z37.7%21,o09.3%20z37.9%21",
      ",o09.4%20z37.0%21,o09.4%20z37.1%21,o09.4%20z37.2%21,o09.4%20z37.3%21,o09.4%20z37.4%21,o09.4%20z37.5%21,o09.4%20z37.6%21,o09.4%20z37.7%21,o09.4%20z37.9%21",
      ",o09.5%20z37.0%21,o09.5%20z37.1%21,o09.5%20z37.2%21,o09.5%20z37.3%21,o09.5%20z37.4%21,o09.5%20z37.5%21,o09.5%20z37.6%21,o09.5%20z37.7%21,o09.5%20z37.9%21",
      ",o09.6%20z37.0%21,o09.6%20z37.1%21,o09.6%20z37.2%21,o09.6%20z37.3%21,o09.6%20z37.4%21,o09.6%20z37.5%21,o09.6%20z37.6%21,o09.6%20z37.7%21,o09.6%20z37.9%21",
      ",o09.7%20z37.0%21,o09.7%20z37.1%21,o09.7%20z37.2%21,o09.7%20z37.3%21,o09.7%20z37.4%21,o09.7%20z37.5%21,o09.7%20z37.6%21,o09.7%20z37.7%21,o09.7%20z37.9%21",
      ",o09.9%20z37.0%21,o09.8%20z37.1%21,o09.9%20z37.2%21,o09.9%20z37.3%21,o09.9%20z37.4%21,o09.9%20z37.5%21,o09.9%20z37.6%21,o09.9%20z37.7%21,o09.9%20z37.9%21",
      ",o24.4",
      ",o30.0,o30.1,o30.2,o30.8,o30.9",
      ",o63.0,o63.1,o63.2,o63.9",
      ",o64.0,o64.1,o64.2,o64.3,o64.4,o64.5,o64.8,o64.9",
      ",o64.0%20z37.0%21,o64.0%20z37.1%21,o64.0%20z37.2%21,o64.0%20z37.3%21,o64.0%20z37.4%21,o64.0%20z37.5%21,o64.0%20z37.6%21,o64.0%20z37.7%21,o64.0%20z37.9%21",
      ",o64.1%20z37.0%21,o64.1%20z37.1%21,o64.1%20z37.2%21,o64.1%20z37.3%21,o64.1%20z37.4%21,o64.1%20z37.5%21,o64.1%20z37.6%21,o64.1%20z37.7%21,o64.1%20z37.9%21",
      ",o64.2%20z37.0%21,o64.2%20z37.1%21,o64.2%20z37.2%21,o64.2%20z37.3%21,o64.2%20z37.4%21,o64.2%20z37.5%21,o64.2%20z37.6%21,o64.2%20z37.7%21,o64.2%20z37.9%21",
      ",o64.3%20z37.0%21,o64.3%20z37.1%21,o64.3%20z37.2%21,o64.3%20z37.3%21,o64.3%20z37.4%21,o64.3%20z37.5%21,o64.3%20z37.6%21,o64.3%20z37.7%21,o64.3%20z37.9%21",
      ",o64.4%20z37.0%21,o64.4%20z37.1%21,o64.4%20z37.2%21,o64.4%20z37.3%21,o64.4%20z37.4%21,o64.4%20z37.5%21,o64.4%20z37.6%21,o64.4%20z37.7%21,o64.4%20z37.9%21",
      ",o64.5%20z37.0%21,o64.5%20z37.1%21,o64.5%20z37.2%21,o64.5%20z37.3%21,o64.5%20z37.4%21,o64.5%20z37.5%21,o64.5%20z37.6%21,o64.5%20z37.7%21,o64.5%20z37.9%21",
      ",o64.8%20z37.0%21,o64.8%20z37.1%21,o64.8%20z37.2%21,o64.8%20z37.3%21,o64.8%20z37.4%21,o64.8%20z37.5%21,o64.8%20z37.6%21,o64.8%20z37.7%21,o64.8%20z37.9%21",
      ",o64.9%20z37.0%21,o64.8%20z37.1%21,o64.9%20z37.2%21,o64.9%20z37.3%21,o64.9%20z37.4%21,o64.9%20z37.5%21,o64.9%20z37.6%21,o64.9%20z37.7%21,o64.9%20z37.9%21",
      ",o75.0,o75.1,o75.2,o75.3,o75.4,o75.5,o75.6,o75.7,o75.8,o75.9",
      ",o80,o81,o82",
      ",o80%20z37.0%21,o81%20z37.0%21,o82%20z37.0%21",
      ",o80%20z37.1%21,o81%20z37.1%21,o82%20z37.1%21",
      ",o80%20z37.2%21,o81%20z37.2%21,o82%20z37.2%21",
      ",o80%20z37.3%21,o81%20z37.3%21,o82%20z37.3%21",
      ",o80%20z37.4%21,o81%20z37.4%21,o82%20z37.4%21",
      ",o80%20z37.5%21,o81%20z37.5%21,o82%20z37.5%21",
      ",o80%20z37.6%21,o81%20z37.6%21,o82%20z37.6%21",
      ",o80%20z37.7%21,o81%20z37.7%21,o82%20z37.7%21",
      ",o80%20z37.9%21,o81%20z37.9%21,o82%20z37.9%21",
      ",z37.0,z37.1,z37.2,z37.3,z37.4,z37.5,z37.6,z37.7,z37.9",
      ",z38.0,z38.1,z38.2,z38.3,z38.4,z38.5,z38.6,z38.7,z38.8",
      search_date,"=gt2014-12-31",
      search_date,"=lt2023-01-01",
      count_custom
    )
    
    if (exists("token", where = conf)) {
      if (nchar(conf$token) >= 1) {
        condition_bundle <<- append(condition_bundle,fhir_search(request = search_request_con, username = conf$user, password = conf$password, token = conf$token, verbose = 2, max_bundles = max_bundles_custom))
      } else {
        condition_bundle <<- append(condition_bundle,fhir_search(request = search_request_con, username = conf$user, password = conf$password, verbose = 2, max_bundles = max_bundles_custom))
      }
    } else {
      if (exists("username", where = conf)) {
        condition_bundle <<- append(condition_bundle,fhir_search(request = search_request_con, username = conf$user, password = conf$password, verbose = 2, max_bundles = max_bundles_custom))
      } else {
        condition_bundle <<- append(condition_bundle,fhir_search(request = search_request_con, verbose = 2, max_bundles = max_bundles_custom))
      }
    }
  })
})
#bring condition results together and flatten
condition_bundle <- fhircrackr:::fhir_bundle_list(condition_bundle)

if (packageVersion("fhircrackr") >= 2) {
  list_cdn <- fhir_crack(condition_bundle, design_con, sep = "|", brackets = c("[", "]"), verbose = 2, ncores = 1)
} else {
  list_cdn <- fhir_crack(condition_bundle, design_con, sep = "|", brackets = c("[", "]"), verbose = 2)
}

# save conditions and patients in separate dataframes
df_conditions_raw <- list_cdn$conditions

# unnest raw conditions dataframe columns diagnosis, system
df_conditions_tmp <- fhir_melt(df_conditions_raw,
                               #columns = c("diagnosis", "display", "system"),
                               columns = c("diagnosis", "system"),
                               brackets = c("[", "]"), sep = "|", all_columns = TRUE)

# unnest raw conditions dataframe columns diagnosis, system
df_conditions_tmp <- fhir_melt(df_conditions_tmp,
                               #columns = c("diagnosis", "display", "system"),
                               columns = c("diagnosis", "system"),
                               brackets = c("[", "]"), sep = "|", all_columns = TRUE)

df_conditions_tmp <- fhir_rm_indices(df_conditions_tmp, brackets = c("[", "]"))

# filter conditions by system to obtain only icd-10-gm system
df_conditions_tmp <- df_conditions_tmp[df_conditions_tmp$system == icd_code_system_custom, ]

# remove the "Patient/" tag from column patient_id in condition resource
df_conditions_tmp$patient_id <- sub(subject_reference_prefix, "", df_conditions_tmp[, "patient_id"])


x <- c(1, 17, 31, 99)

# merge conditions and patients dataframe
df_conditions_patients <- base::merge(df_conditions_tmp, df_patients_tmp, by = "patient_id")

df_conditions_patients$recorded_date <- as.Date(df_conditions_patients$recorded_date, format = "%Y-%m-%d")
df_conditions_patients <- df_conditions_patients[df_conditions_patients$recorded_date > "2014-12-31", ]
df_conditions_patients <- df_conditions_patients[df_conditions_patients$recorded_date < "2022-12-31", ]

# check for custom hospital_id
if (exists("hospital_name", where = conf)) {
  if (nchar(conf$hospital_name) >= 1) {
    df_conditions_patients$hospital_id <- conf$hospital_name
  }
}

# remove merge identifier column as its not needed and could cause problems
df_conditions_patients <- df_conditions_patients %>% select(-contains("resource_identifier"))

# check if birthdate is in format YYYY-MM-DD, if not append -01-01
df_conditions_patients <- mutate(df_conditions_patients, birthdate = ifelse(nchar(df_conditions_patients$birthdate) >= 10, df_conditions_patients$birthdate, paste0(df_conditions_patients$birthdate, "-01-01")))

# calculate age as of recorded_date - birthdate
df_conditions_patients$age <- round(as.double(as.Date(df_conditions_patients$recorded_date) - as.Date(df_conditions_patients$birthdate)) / 365.25, 0)

# set age groups
df_conditions_patients$age_group <- cut(df_conditions_patients$age, x, breaks = c(0, 17, 30, 99), labels = c("[0,17]", "[18,30]", "[31,99]"))

# filter conditions for ICD-Code E84*
df_conditions_cf <- subset(df_conditions_patients, grepl("^E84", diagnosis))
df_conditions_cf$diagnosis <- "E84*"

# filter conditions for ICD-Codes for Birth O* and Z37, Z38
df_conditions_birth_all <- subset(df_conditions_patients, grepl("^O|^Z", diagnosis))

# merge CF and Birth dataframes by patient
df_cf_birth_all <- base::merge(df_conditions_cf, df_conditions_birth_all, by = "patient_id")
df_cf_birth_all <- df_cf_birth_all[!duplicated(df_cf_birth_all$patient_id), ]

# filter all "children"
df_cf_birth_all <- subset(df_cf_birth_all, !grepl("^Z38", diagnosis.y))

#df_result_primaer <- as.data.frame(df_cf_birth_all %>% group_by(Einrichtungsindikator = df_cf_birth_all$hospital_id.x, Diagn1 = df_cf_birth_all$diagnosis.x, Diagn2 = df_cf_birth_all$diagnosis.y, Geschlecht = df_cf_birth_all$gender.x, Alter = df_cf_birth_all$age_group.x) %>% summarise(Anzahl = n()) )# %>% mutate(Haeufigkeit = paste0(round(100 * n() / sum(n()), 0), "%")))
df_result_primaer <- as.data.frame(df_cf_birth_all %>% group_by(Einrichtungsindikator = df_cf_birth_all$hospital_id.x, Diagn1 = df_cf_birth_all$diagnosis.x, Diagn2 = df_cf_birth_all$diagnosis.y) %>% summarise(Anzahl = n()) )# %>% mutate(Haeufigkeit = paste0(round(100 * n() / sum(n()), 0), "%")))
#df_result_primaer <- mutate(df_result_primaer, Anzahl = ifelse(Anzahl > 0 & Anzahl <= 5, "<5", Anzahl))

df_conditions_birth <- subset(df_conditions_patients, grepl("^O09|^O3|^O63|^O8|^Z", diagnosis))

#df_cf_birth <- base::merge(df_conditions_cf, df_conditions_birth, by = "patient_id")
#df_cf_birth <- df_cf_birth[!duplicated(df_cf_birth$patient_id), ]
#df_cf_birth <- subset(df_cf_birth, !grepl("^Z38", diagnosis.y))

#df_result_sekundaer_a <- as.data.frame(df_cf_birth %>% group_by(Einrichtungsindikator = df_cf_birth$hospital_id.x, Diagn1 = df_cf_birth$diagnosis.x, Diagn2 = df_cf_birth$diagnosis.y, Geschlecht = df_cf_birth$gender.x, Alter = df_cf_birth$age_group.x) %>% summarise(Anzahl = n()) )# %>% mutate(Haeufigkeit = paste0(round(100 * n() / sum(n()), 0), "%")))
#df_result_sekundaer_a <- as.data.frame(df_cf_birth %>% group_by(Einrichtungsindikator = df_cf_birth$hospital_id.x, Diagn1 = df_cf_birth$diagnosis.x, Diagn2 = df_cf_birth$diagnosis.y) %>% summarise(Anzahl = n()) )# %>% mutate(Haeufigkeit = paste0(round(100 * n() / sum(n()), 0), "%")))
#df_result_sekundaer_a <- mutate(df_result_sekundaer_a, Anzahl = ifelse(Anzahl > 0 & Anzahl <= 5, "<5", Anzahl))

df_conditions_complication <- subset(df_conditions_patients, grepl("^O64|^O75|^O24", diagnosis))

df_cf_complication <- base::merge(df_conditions_cf, df_conditions_birth, by = "patient_id")
df_cf_complication <- base::merge(df_cf_complication, df_conditions_complication, by = "patient_id")
df_cf_complication <- df_cf_complication[!duplicated(df_cf_complication$patient_id), ]
df_cf_complication <- subset(df_cf_complication, !grepl("^Z38", diagnosis.y))

#df_result_sekundaer_b <- as.data.frame(df_cf_complication %>% group_by(Einrichtungsindikator = df_cf_complication$hospital_id.x, Diagn1 = df_cf_complication$diagnosis.x, Diagn2 = df_cf_complication$diagnosis, Geschlecht = df_cf_complication$gender, Alter = df_cf_complication$age_group) %>% summarise(Anzahl = n()) )# %>% mutate(Haeufigkeit = paste0(round(100 * n() / sum(n()), 0), "%")))
df_result_sekundaer_b <- as.data.frame(df_cf_complication %>% group_by(Einrichtungsindikator = df_cf_complication$hospital_id.x, Diagn1 = df_cf_complication$diagnosis.x, Diagn2 = df_cf_complication$diagnosis) %>% summarise(Anzahl = n()) )# %>% mutate(Haeufigkeit = paste0(round(100 * n() / sum(n()), 0), "%")))
#df_result_sekundaer_b <- mutate(df_result_sekundaer_b, Anzahl = ifelse(Anzahl > 0 & Anzahl <= 5, "<5", Anzahl))

# display the final output
df_result_primaer
#df_result_sekundaer_a
df_result_sekundaer_b
now <- format(Sys.time(), "%Y%m%d_%H%M%S")
########################################################################################################################################################
# write result to a csv file
########################################################################################################################################################
write.csv(df_result_primaer, file = paste0("results/result_primaer_",now,".csv"), row.names = FALSE)
#write.csv(df_result_sekundaer_a, file = paste0("results/result_sekundaer_a_",now,".csv"), row.names = FALSE)
write.csv(df_result_sekundaer_b, file = paste0("results/result_sekundaer_b_",now,".csv"), row.names = FALSE)
########################################################################################################################################################
end_time <- Sys.time()
print(end_time - start_time)