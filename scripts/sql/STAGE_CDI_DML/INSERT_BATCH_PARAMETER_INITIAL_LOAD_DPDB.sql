-- Purpose: To insert records in BATCH_PARAMETER for the mp_ADVISER_ONEOFF ADF
-- pipeline to process the extract from Oracle to Azure SQL DB for initial 
-- data transfer prior to first Adviser ADF batch run
-- 
--
-- Delete any existing records in BATCH_PARAMETER and BATCH_PARAMETER_HIST for
-- the entries created by this script
--
delete
  from STAGE_CDI.BATCH_PARAMETER
 where PROCESS_NAME = 'ORA_STAGE_CRM_TO_SQLDB_STAGE_CDI_ADVISER';
 
delete
  from STAGE_CDI.BATCH_PARAMETER_HIST
 where PROCESS_NAME = 'ORA_STAGE_CRM_TO_SQLDB_STAGE_CDI_ADVISER';

--
-- The following entries are required to transfer data from Oracle (STAGE_CRM)
-- to Azure SQL DB (STAGE_CDI) for one off process
--
insert 
  into STAGE_CDI.BATCH_PARAMETER
(
    PROCESS_NAME, 
    PARAMETER_NAME, 
    PARAMETER_VALUE_CHAR,
    LASTMODIFIEDDT, 
    LASTMODIFIEDBY
)
values
(
    'ORA_STAGE_CRM_TO_SQLDB_STAGE_CDI_ADVISER',
    'REF_DPDB_TRANSLATION',
    'P',
    (select cast(SYSDATETIMEOFFSET() at time zone 'GMT Standard Time' as datetime)),
    'Script - INSERT_BATCH_PARAMETER_INITIAL_LOAD_DPDB'
);

insert 
  into STAGE_CDI.BATCH_PARAMETER
(
    PROCESS_NAME, 
    PARAMETER_NAME, 
    PARAMETER_VALUE_CHAR,
    LASTMODIFIEDDT, 
    LASTMODIFIEDBY
)
values
(
    'ORA_STAGE_CRM_TO_SQLDB_STAGE_CDI_ADVISER',
    'SFDC_ADVISER_ACCOUNT_STG',
    'P',
    (select cast(SYSDATETIMEOFFSET() at time zone 'GMT Standard Time' as datetime)),
    'Script - INSERT_BATCH_PARAMETER_INITIAL_LOAD_DPDB'
);

insert 
  into STAGE_CDI.BATCH_PARAMETER
(
    PROCESS_NAME, 
    PARAMETER_NAME, 
    PARAMETER_VALUE_CHAR,
    LASTMODIFIEDDT, 
    LASTMODIFIEDBY
)
values
(
    'ORA_STAGE_CRM_TO_SQLDB_STAGE_CDI_ADVISER',
    'SFDC_ADVISER_HERITAGE_ARN_STG',
    'P',
    (select cast(SYSDATETIMEOFFSET() at time zone 'GMT Standard Time' as datetime)),
    'Script - INSERT_BATCH_PARAMETER_INITIAL_LOAD_DPDB'
);

insert 
  into STAGE_CDI.BATCH_PARAMETER
(
    PROCESS_NAME, 
    PARAMETER_NAME, 
    PARAMETER_VALUE_CHAR,
    LASTMODIFIEDDT, 
    LASTMODIFIEDBY
)
values
(
    'ORA_STAGE_CRM_TO_SQLDB_STAGE_CDI_ADVISER',
    'SFDC_ADVISER_RI_CONTACT_STG',
    'P',
    (select cast(SYSDATETIMEOFFSET() at time zone 'GMT Standard Time' as datetime)),
    'Script - INSERT_BATCH_PARAMETER_INITIAL_LOAD_DPDB'
);

insert 
  into STAGE_CDI.BATCH_PARAMETER
(
    PROCESS_NAME, 
    PARAMETER_NAME, 
    PARAMETER_VALUE_CHAR,
    LASTMODIFIEDDT, 
    LASTMODIFIEDBY
)
values
(
    'ORA_STAGE_CRM_TO_SQLDB_STAGE_CDI_ADVISER',
    'SFDC_RECORD_TYPE_STG',
    'P',
    (select cast(SYSDATETIMEOFFSET() at time zone 'GMT Standard Time' as datetime)),
    'Script - INSERT_BATCH_PARAMETER_INITIAL_LOAD_DPDB'
);

insert 
  into STAGE_CDI.BATCH_PARAMETER
(
    PROCESS_NAME, 
    PARAMETER_NAME, 
    PARAMETER_VALUE_CHAR,
    LASTMODIFIEDDT, 
    LASTMODIFIEDBY
)
values
(
    'ORA_STAGE_CRM_TO_SQLDB_STAGE_CDI_ADVISER',
    'DPDB_ADVISER_FIRM_STG',
    'P',
    (select cast(SYSDATETIMEOFFSET() at time zone 'GMT Standard Time' as datetime)),
    'Script - INSERT_BATCH_PARAMETER_INITIAL_LOAD_DPDB'
);

insert 
  into STAGE_CDI.BATCH_PARAMETER
(
    PROCESS_NAME, 
    PARAMETER_NAME, 
    PARAMETER_VALUE_CHAR,
    LASTMODIFIEDDT, 
    LASTMODIFIEDBY
)
values
(
    'ORA_STAGE_CRM_TO_SQLDB_STAGE_CDI_ADVISER',
    'DPDB_ADVISER_LEGACY_AGENCY_STG',
    'P',
    (select cast(SYSDATETIMEOFFSET() at time zone 'GMT Standard Time' as datetime)),
    'Script - INSERT_BATCH_PARAMETER_INITIAL_LOAD_DPDB'
);

insert 
  into STAGE_CDI.BATCH_PARAMETER
(
    PROCESS_NAME, 
    PARAMETER_NAME, 
    PARAMETER_VALUE_CHAR,
    LASTMODIFIEDDT, 
    LASTMODIFIEDBY
)
values
(
    'ORA_STAGE_CRM_TO_SQLDB_STAGE_CDI_ADVISER',
    'DPDB_ADVISER_NETWORK_STG',
    'P',
    (select cast(SYSDATETIMEOFFSET() at time zone 'GMT Standard Time' as datetime)),
    'Script - INSERT_BATCH_PARAMETER_INITIAL_LOAD_DPDB'
);

insert 
  into STAGE_CDI.BATCH_PARAMETER
(
    PROCESS_NAME, 
    PARAMETER_NAME, 
    PARAMETER_VALUE_CHAR,
    LASTMODIFIEDDT, 
    LASTMODIFIEDBY
)
values
(
    'ORA_STAGE_CRM_TO_SQLDB_STAGE_CDI_ADVISER',
    'DPDB_ADVISER_OFFICE_STG',
    'P',
    (select cast(SYSDATETIMEOFFSET() at time zone 'GMT Standard Time' as datetime)),
    'Script - INSERT_BATCH_PARAMETER_INITIAL_LOAD_DPDB'
);

insert 
  into STAGE_CDI.BATCH_PARAMETER
(
    PROCESS_NAME, 
    PARAMETER_NAME, 
    PARAMETER_VALUE_CHAR,
    LASTMODIFIEDDT, 
    LASTMODIFIEDBY
)
values
(
    'ORA_STAGE_CRM_TO_SQLDB_STAGE_CDI_ADVISER',
    'DPDB_REGISTERED_INDIVIDUAL_STG',
    'P',
    (select cast(SYSDATETIMEOFFSET() at time zone 'GMT Standard Time' as datetime)),
    'Script - INSERT_BATCH_PARAMETER_INITIAL_LOAD_DPDB'
);

insert 
  into STAGE_CDI.BATCH_PARAMETER
(
    PROCESS_NAME, 
    PARAMETER_NAME, 
    PARAMETER_VALUE_CHAR,
    LASTMODIFIEDDT, 
    LASTMODIFIEDBY
)
values
(
    'ORA_STAGE_CRM_TO_SQLDB_STAGE_CDI_ADVISER',
    'ETL_JOB_CONTROL',
    'P',
    (select cast(SYSDATETIMEOFFSET() at time zone 'GMT Standard Time' as datetime)),
    'Script - INSERT_BATCH_PARAMETER_INITIAL_LOAD_DPDB'
);
