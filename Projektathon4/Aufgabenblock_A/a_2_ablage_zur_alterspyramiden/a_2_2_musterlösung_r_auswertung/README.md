#### Guide 
---
##### Pre-requisite 

1. R Studio

2. Install the following packages tidyverse, eeptools, ggplot2

3. Check your firewall settings. If you are executing from hospital network you may need to set proxy server settings as follows

   3.a. To check the existing values of proxy variables use the following Code
   
         Sys.getenv("HTTP_PROXY“)
        
         Sys.getenv("HTTPS_PROXY“)
         
         If the above mentioned variables are empty and you are executing it from inside hospital network the set the proxy server as follows
         
   3.b. To set proxy variables use the following Code
     
         Sys.setenv("HTTP_PROXY“ = “<your proxy address here along with port>“)
   
         Sys.setenv("HTTPS_PROXY“ = “<your proxy address here along with port>“)

#### Steps:
---
1. Download the script.r file 
2. [Download the input data input_data.csv from](../Aufgabenblock_A/a_2_ablage_zur_alterspyramiden/a_2_1_projektbereich/)

3. Rename the output file 

   a. If you are using windows OS you can use double slash to map the output path. For eg., "c:\\users\\yourusername\\Documents\\repo\\Output\\result.csv
  
    b. If you are using linux OS you can use the file path like as follows "r/repo/Output/result.csv")
