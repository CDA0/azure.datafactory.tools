--
-- ALTER TABLE STRUCTURE
--
ALTER TABLE STAGE_CDI.SFDC_ADVISER_RI_CONTACT_STG
  ADD CONSTRAINT DF_SFDC_ADVISER_RI_CONTACT_STG_INSERT_DATE_TIME 
  DEFAULT CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'GMT Standard Time' AS DATETIME2) FOR INSERT_DATE_TIME;

ALTER TABLE STAGE_CDI.SFDC_ADVISER_RI_CONTACT_STG
 ALTER COLUMN PRU_RECORDREMOVED__C    BIT;

--
-- PRIMARY KEY
--
ALTER TABLE STAGE_CDI.SFDC_ADVISER_RI_CONTACT_STG 
  ADD CONSTRAINT SFDC_ADVISER_RI_CONTACT_STG_PK PRIMARY KEY (PRU_AGENCYNUMBER__C);
