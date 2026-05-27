SELECT CustomerProjectId, COUNT(*)
FROM EDS_STG_PROV."EDS_ETL_Test_MCContractCustomerProject"
GROUP BY CustomerProjectId
HAVING COUNT(*) > 1;