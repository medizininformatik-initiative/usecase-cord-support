#### Guide 
---
##### Pre-requisite 

1. R Studio

2. Install the following packages fhircrackr, dplyr, tibble, stringr, tidyr

3. Check your firewall settings. If you are executing from hospital network you may need to set proxy server settings as follows

   3.a. To check the existing values of proxy variables use the following Code
   
         Sys.getenv("HTTP_PROXY“)
        
         Sys.getenv("HTTPS_PROXY“)
         
   3.b. To set proxy variables use the following Code
     
         Sys.setenv("HTTP_PROXY“ = “<your proxy address here along with port>“)
   
         Sys.setenv("HTTPS_PROXY“ = “<your proxy address here along with port>“)

#### Steps:
---
1. Download the script.r file 
2. Formulate the search request parameter according to the task
3. Rename the output file 

   a. If you are using windows OS you can use double slash to map the output path
  
    b. If you are using linux OS you can use the file path like as follows "r/projectathon/filename.csv")
