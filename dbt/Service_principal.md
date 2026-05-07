Setps: 

1. In azure portal go to Microsoft Endra --> app registration an create the a app example name : sp-fabric-deployment-test
2. after creating save carefully app id ,  tenant Id 
3. create a secret that will generate a secret value  save carefully the secret value.
4. The the following , you should have something like this:



name : sp-fabric-deployment-test

app id             = <REDACTED>  

tenant Id          = <REDACTED>

fabrict-dbt-secret = <REDACTED>



5\. the app is like an user (dummy user that will run process in non-dev environment) see below it user account 

user : app:<app id>@<tenant Id>

user : app:<REDACTED>@<REDACTED> 



6\. create a security group for your databases (here is fabric  ) , like Fabric\_sg add will adim  access to all fabric infrastructure

7\. Add the service principal (sp-fabric-deployment-test) to the security group :Fabric\_sg

8\. Go to fabric admin portal and search for service principle : and the enable all action for specific group (in owr case :Fabric\_sg )

9\. go to your fabric workspace(s) add at the MANAGE ACCESSES section add the security group :Fabric\_sg as admin. 

10\. test , open you powershell  and run the following (dbt specific ) assuming the follwing variables .even file:



variables values



&#x20;  FABRIC\_TEST\_SERVER=hywuyaxauvqupogac6yriiqgbm-v67bkc7azf4udaj6pwkhtzxrwu.datawarehouse.fabric.microsoft.com

&#x20;  FABRIC\_TEST\_DATABASE=FreshCart\_DW

&#x20;  FABRIC\_LAKEHOUSE\_DATABASE=FreshCart\_lakehouse



&#x20;  FABRIC\_TEST\_CLIENT\_ID=<REDACTED>

&#x20;  FABRIC\_TENANT\_ID=<REDACTED>

&#x20;   FABRIC\_TEST\_CLIENT\_SECRET=<REDACTED> 



command line 

dbt\_your\_project> 

\# Load env

Get-Content .env | ForEach-Object {

&#x20;   if ($\_ -match '^\\s\*(\[^#]\[^=]+)=(.\*)$') {

&#x20;       \[System.Environment]::SetEnvironmentVariable($matches\[1].Trim(), $matches\[2].Trim())

&#x20;   }

}



\# Verify

echo $env:FABRIC\_TEST\_CLIENT\_ID

echo $env:FABRIC\_TENANT\_ID



\# Debug

dbt debug --target test





out put 

\-------

should be all green with with comment : Connection test: \[OK connection ok] All checks passed!



