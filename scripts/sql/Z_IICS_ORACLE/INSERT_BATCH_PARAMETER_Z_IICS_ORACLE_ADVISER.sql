-- Purpose: To insert records in BATCH_PARAMETER for Adviser testing.
-- Extract from Oracle to Azure SQL DB (Z_IICS_ORACLE) for data comparison
-- between IICS and ADF
--
-- Delete any existing records in BATCH_PARAMETER and BATCH_PARAMETER_HIST for
-- the entries created by this script
--
delete
  from Z_IICS_ORACLE.BATCH_PARAMETER
 where PROCESS_NAME = 'ORA_STAGE_CRM_TO_SQLDB_Z_IICS_ORACLE_ADVISER';
 
--
-- The following entries are required to transfer data from Oracle (STAGE_CRM)
-- to Azure SQL DB (Z_IICS_ORACLE) for data comparison
--
insert 
  into Z_IICS_ORACLE.BATCH_PARAMETER
(
    PROCESS_NAME, 
    PARAMETER_NAME, 
    PARAMETER_VALUE_CHAR,
    LASTMODIFIEDDT, 
    LASTMODIFIEDBY
)
values
(
    'ORA_STAGE_CRM_TO_SQLDB_Z_IICS_ORACLE_ADVISER',
    'DPDB_ADVISER_FIRM_STG',
    'P',
    (select cast(SYSDATETIMEOFFSET() at time zone 'GMT Standard Time' as datetime)),
    'Script - INSERT_BATCH_PARAMETER_ADVISER_IICS_ADF'
);

insert 
  into Z_IICS_ORACLE.BATCH_PARAMETER
(
    PROCESS_NAME, 
    PARAMETER_NAME, 
    PARAMETER_VALUE_CHAR,
    LASTMODIFIEDDT, 
    LASTMODIFIEDBY
)
values
(
    'ORA_STAGE_CRM_TO_SQLDB_Z_IICS_ORACLE_ADVISER',
    'DPDB_ADVISER_LEGACY_AGENCY_STG',
    'P',
    (select cast(SYSDATETIMEOFFSET() at time zone 'GMT Standard Time' as datetime)),
    'Script - INSERT_BATCH_PARAMETER_ADVISER_IICS_ADF'
);

insert 
  into Z_IICS_ORACLE.BATCH_PARAMETER
(
    PROCESS_NAME, 
    PARAMETER_NAME, 
    PARAMETER_VALUE_CHAR,
    LASTMODIFIEDDT, 
    LASTMODIFIEDBY
)
values
(
    'ORA_STAGE_CRM_TO_SQLDB_Z_IICS_ORACLE_ADVISER',
    'DPDB_ADVISER_NETWORK_STG',
    'P',
    (select cast(SYSDATETIMEOFFSET() at time zone 'GMT Standard Time' as datetime)),
    'Script - INSERT_BATCH_PARAMETER_ADVISER_IICS_ADF'
);

insert 
  into Z_IICS_ORACLE.BATCH_PARAMETER
(
    PROCESS_NAME, 
    PARAMETER_NAME, 
    PARAMETER_VALUE_CHAR,
    LASTMODIFIEDDT, 
    LASTMODIFIEDBY
)
values
(
    'ORA_STAGE_CRM_TO_SQLDB_Z_IICS_ORACLE_ADVISER',
    'DPDB_ADVISER_OFFICE_STG',
    'P',
    (select cast(SYSDATETIMEOFFSET() at time zone 'GMT Standard Time' as datetime)),
    'Script - INSERT_BATCH_PARAMETER_ADVISER_IICS_ADF'
);

insert 
  into Z_IICS_ORACLE.BATCH_PARAMETER
(
    PROCESS_NAME, 
    PARAMETER_NAME, 
    PARAMETER_VALUE_CHAR,
    LASTMODIFIEDDT, 
    LASTMODIFIEDBY
)
values
(
    'ORA_STAGE_CRM_TO_SQLDB_Z_IICS_ORACLE_ADVISER',
    'DPDB_REGISTERED_INDIVIDUAL_STG',
    'P',
    (select cast(SYSDATETIMEOFFSET() at time zone 'GMT Standard Time' as datetime)),
    'Script - INSERT_BATCH_PARAMETER_ADVISER_IICS_ADF'
);

insert 
  into Z_IICS_ORACLE.BATCH_PARAMETER
(
    PROCESS_NAME, 
    PARAMETER_NAME, 
    PARAMETER_VALUE_CHAR,
    LASTMODIFIEDDT, 
    LASTMODIFIEDBY
)
values
(
    'ORA_STAGE_CRM_TO_SQLDB_Z_IICS_ORACLE_ADVISER',
    'REF_DPDB_TRANSLATION',
    'P',
    (select cast(SYSDATETIMEOFFSET() at time zone 'GMT Standard Time' as datetime)),
    'Script - INSERT_BATCH_PARAMETER_ADVISER_IICS_ADF'
);

insert 
  into Z_IICS_ORACLE.BATCH_PARAMETER
(
    PROCESS_NAME, 
    PARAMETER_NAME, 
    PARAMETER_VALUE_CHAR,
    LASTMODIFIEDDT, 
    LASTMODIFIEDBY
)
values
(
    'ORA_STAGE_CRM_TO_SQLDB_Z_IICS_ORACLE_ADVISER',
    'SFDC_ADVISER_ACCOUNT_STG',
    'P',
    (select cast(SYSDATETIMEOFFSET() at time zone 'GMT Standard Time' as datetime)),
    'Script - INSERT_BATCH_PARAMETER_ADVISER_IICS_ADF'
);

insert 
  into Z_IICS_ORACLE.BATCH_PARAMETER
(
    PROCESS_NAME, 
    PARAMETER_NAME, 
    PARAMETER_VALUE_CHAR,
    LASTMODIFIEDDT, 
    LASTMODIFIEDBY
)
values
(
    'ORA_STAGE_CRM_TO_SQLDB_Z_IICS_ORACLE_ADVISER',
    'SFDC_ADVISER_HERITAGE_ARN_STG',
    'P',
    (select cast(SYSDATETIMEOFFSET() at time zone 'GMT Standard Time' as datetime)),
    'Script - INSERT_BATCH_PARAMETER_ADVISER_IICS_ADF'
);

insert 
  into Z_IICS_ORACLE.BATCH_PARAMETER
(
    PROCESS_NAME, 
    PARAMETER_NAME, 
    PARAMETER_VALUE_CHAR,
    LASTMODIFIEDDT, 
    LASTMODIFIEDBY
)
values
(
    'ORA_STAGE_CRM_TO_SQLDB_Z_IICS_ORACLE_ADVISER',
    'SFDC_ADVISER_RI_CONTACT_STG',
    'P',
    (select cast(SYSDATETIMEOFFSET() at time zone 'GMT Standard Time' as datetime)),
    'Script - INSERT_BATCH_PARAMETER_ADVISER_IICS_ADF'
);

insert 
  into Z_IICS_ORACLE.BATCH_PARAMETER
(
    PROCESS_NAME, 
    PARAMETER_NAME, 
    PARAMETER_VALUE_CHAR,
    LASTMODIFIEDDT, 
    LASTMODIFIEDBY
)
values
(
    'ORA_STAGE_CRM_TO_SQLDB_Z_IICS_ORACLE_ADVISER',
    'SFDC_RECORD_TYPE_STG',
    'P',
    (select cast(SYSDATETIMEOFFSET() at time zone 'GMT Standard Time' as datetime)),
    'Script - INSERT_BATCH_PARAMETER_ADVISER_IICS_ADF'
);