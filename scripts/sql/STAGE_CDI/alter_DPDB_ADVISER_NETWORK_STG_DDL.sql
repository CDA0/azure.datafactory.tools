--
-- ALTER TABLE STRUCTURE
--
ALTER TABLE STAGE_CDI.DPDB_ADVISER_NETWORK_STG
 ALTER COLUMN PERM_INVESTMENT_ADVICE  BIT;

ALTER TABLE STAGE_CDI.DPDB_ADVISER_NETWORK_STG
 ALTER COLUMN PERM_MORTGAGE_ADVICE    BIT;

ALTER TABLE STAGE_CDI.DPDB_ADVISER_NETWORK_STG
 ALTER COLUMN PERM_INSURANCE_ADVICE   BIT;

ALTER TABLE STAGE_CDI.DPDB_ADVISER_NETWORK_STG
 ALTER COLUMN PERM_PENSION_ADVICE     BIT;

ALTER TABLE STAGE_CDI.DPDB_ADVISER_NETWORK_STG
 ALTER COLUMN RECORD_DELETE_IND     BIT;

ALTER TABLE STAGE_CDI.DPDB_ADVISER_NETWORK_STG
  ADD CONSTRAINT DF_DPDB_ADVISER_NETWORK_STG_INSERT_DATE_TIME DEFAULT CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'GMT Standard Time' AS DATETIME2) FOR INSERT_DATE_TIME;

--
-- UNIQUE INDEX
--
ALTER TABLE STAGE_CDI.DPDB_ADVISER_NETWORK_STG 
  ADD CONSTRAINT DPDB_ADVISER_NETWORK_STG_UI_01 UNIQUE (NETWORK_PARTY_ROLE_ID, REL_FIRM_PARTY_ROLE_ID);