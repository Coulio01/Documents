dbt integration with fabric datawarehouse 
----------------------------------------
ref: https://www.youtube.com/watch?v=yJEg5n1r3Ks&t=782s 

Resource : 
Visual studio code
dbt extension in VS code 
python extension in VS code

Concept : 
----------
When you have a datawarehouse (Fabric , databtiks , snowflake, bigquery....)
In you need to automatically make some change following a kind of medallion architecure.In dbt we have 
raw = raw (in seeds folder)
model folder , we have 
stage = silver 
mart = gold 

in stage and mart 
the files are created as .sql file contening sql statement 


