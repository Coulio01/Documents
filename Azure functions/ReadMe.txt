(FreshCart_lakehouse) conn strg =hywuyaxauvqupogac6yriiqgbm-v67bkc7azf4udaj6pwkhtzxrwu.datawarehouse.fabric.microsoft.com

table : bronze.raw_sales_transactions


container name : ocoadlstoragefiles
accessKey conn string : DefaultEndpointsProtocol=https;AccountName=ocoadlstoragefiles;AccountKey=<REDACTED - rotate in Azure Portal>;EndpointSuffix=core.windows.net



service principal : 
FABRIC_TEST_CLIENT_ID=16c5b3c7-b58b-49e8-8a45-f33bbdf5c54c
FABRIC_TENANT_ID=024c2d3e-a5e0-4761-b8c0-17b11422060b
FABRIC_TEST_CLIENT_SECRET=<REDACTED - regenerate in Azure AD>
kvault : scrt-sp-fabric-deployment-test 

teams Channel : https://lacois.webhook.office.com/webhookb2/42d231ca-2b38-4997-a5c6-197186cfd9ee@024c2d3e-a5e0-4761-b8c0-17b11422060b/IncomingWebhook/6ca5e97e6a844c62bcbeec5c21b6b494/5f05b997-8951-48b3-8df4-fc1e2ade38ff/V211WTuLdxLHlpq1ivRObf1I6t3mGuj9EtdhUrbKszhY01

Dev ws :  https://app.powerbi.com/groups/0b15beaf-c9e0-4179-813e-7d9479e6f1b5/list?experience=fabric-developer
DEV LKH : https://app.powerbi.com/groups/0b15beaf-c9e0-4179-813e-7d9479e6f1b5/lakehouses/56255052-bca9-4d06-ab72-49754d9219b4?experience=fabric-developer
Dev WHS : https://app.powerbi.com/groups/0b15beaf-c9e0-4179-813e-7d9479e6f1b5/warehouses/0698c8fa-2ba2-4a5b-b17f-77f9578f6f2b?experience=fabric-developer


test ws :  https://app.powerbi.com/groups/1017687f-93c5-4ae3-989e-a3e3ad038064/list?experience=fabric-developer
test LKH : https://app.powerbi.com/groups/1017687f-93c5-4ae3-989e-a3e3ad038064/lakehouses/49130531-0533-436a-9873-2ab0bf13ef2c?experience=fabric-developer
test WHS : https://app.powerbi.com/groups/1017687f-93c5-4ae3-989e-a3e3ad038064/warehouses/ad7ef1ee-6f9a-4723-a1e0-39161761504b?experience=fabric-developer