#### Guide 
---
##### Pre-requisite 

1. R Studio

2. Install the following packages fhircrackr, dplyr, tibble, stringr, tidyr

3. Check your firewall settings. If you are executing from hospital network you may need to set proxy server settings as follows

   3.a. To check the existing values of proxy variables use the following Code
   
         Sys.getenv("HTTP_PROXY“)
        
         Sys.getenv("HTTPS_PROXY“)
         
  If the above mentioned variables are empty and if you are executing the code from inside hospital network then set the proxy server as follows
  
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

4. How to handle Connection timed out error?

     Fehler in curl::curl_fetch_memory(url, handle = handle) :
     
     Timeout was reached: [mii-agiop-cord.life.uni-leipzig.de] Connection timed out after 10000 milliseconds
     
The reason for the above mentioned timeout error is that access to requested URI https:// mii-agiop-cord.life.uni-leipzig.de is  directed through the firewall. This action takes longer time than the normal expected time to access the URI. The firewall is blocking the access to the given URI. This error can be solved by setting up appropriate proxy variable, so that access to the URI is granted.
