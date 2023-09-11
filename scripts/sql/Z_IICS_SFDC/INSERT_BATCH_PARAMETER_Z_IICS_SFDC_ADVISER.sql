-- Purpose: To insert records in BATCH_PARAMETER for Adviser testing.
-- Extract from Salesforce to Azure SQL DB (Z_IICS_SFDC) for data comparison
-- between IICS and ADF
--
-- Delete any existing records in BATCH_PARAMETER for the entries created by 
-- this script
--
delete
  from Z_IICS_SFDC.BATCH_PARAMETER
 where PROCESS_NAME = 'SFDC_TO_SQLDB_Z_IICS_SFDC_ADVISER';
 
--
-- The following entries are required to transfer data from Oracle (STAGE_CRM)
-- to Azure SQL DB (Z_IICS_SFDC) for data comparison
--
insert 
  into Z_IICS_SFDC.BATCH_PARAMETER
(
    PROCESS_NAME, 
    PARAMETER_NAME, 
    PARAMETER_VALUE_CHAR,
    LASTMODIFIEDDT, 
    LASTMODIFIEDBY
)
values
(
    'SFDC_TO_SQLDB_Z_IICS_SFDC_ADVISER',
    'Account',
    'P',
    (select cast(SYSDATETIMEOFFSET() at time zone 'GMT Standard Time' as datetime)),
    'Script - INSERT_BATCH_PARAMETER_ADVISER_IICS_ADF'
);

insert 
  into Z_IICS_SFDC.BATCH_PARAMETER
(
    PROCESS_NAME, 
    PARAMETER_NAME, 
    PARAMETER_VALUE_CHAR,
    LASTMODIFIEDDT, 
    LASTMODIFIEDBY
)
values
(
    'SFDC_TO_SQLDB_Z_IICS_SFDC_ADVISER',
    'Contact',
    'P',
    (select cast(SYSDATETIMEOFFSET() at time zone 'GMT Standard Time' as datetime)),
    'Script - INSERT_BATCH_PARAMETER_ADVISER_IICS_ADF'
);

insert 
  into Z_IICS_SFDC.BATCH_PARAMETER
(
    PROCESS_NAME, 
    PARAMETER_NAME, 
    PARAMETER_VALUE_CHAR,
    LASTMODIFIEDDT, 
    LASTMODIFIEDBY
)
values
(
    'SFDC_TO_SQLDB_Z_IICS_SFDC_ADVISER',
    'PRU_AccountToAccountRelationship__c',
    'P',
    (select cast(SYSDATETIMEOFFSET() at time zone 'GMT Standard Time' as datetime)),
    'Script - INSERT_BATCH_PARAMETER_ADVISER_IICS_ADF'
);

insert 
  into Z_IICS_SFDC.BATCH_PARAMETER
(
    PROCESS_NAME, 
    PARAMETER_NAME, 
    PARAMETER_VALUE_CHAR,
    LASTMODIFIEDDT, 
    LASTMODIFIEDBY
)
values
(
    'SFDC_TO_SQLDB_Z_IICS_SFDC_ADVISER',
    'PRU_HeritageARNAssociation__c',
    'P',
    (select cast(SYSDATETIMEOFFSET() at time zone 'GMT Standard Time' as datetime)),
    'Script - INSERT_BATCH_PARAMETER_ADVISER_IICS_ADF'
);
