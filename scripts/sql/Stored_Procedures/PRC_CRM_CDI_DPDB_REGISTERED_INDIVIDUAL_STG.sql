create procedure STAGE_CDI.PRC_CRM_CDI_DPDB_REGISTERED_INDIVIDUAL_STG (@DPDB_REGISTERED_INDIVIDUAL_STG STAGE_CDI.DPDB_REGISTERED_INDIVIDUAL_STG_TYPE readonly)
/*
Author     : Rizaul Kamal
Date       : 07/06/2023

Description: Generate hash value using SHA256 for data copied over from  Oracle

-------------------------------------------------------------------------------
Version   Date        Description of change
-------   ----------  ---------------------------------------------------------
0.1       07/06/2023  Initial version
*/
as
set nocount on

begin  -- proc
 insert
   into STAGE_CDI.DPDB_REGISTERED_INDIVIDUAL_STG
 (
   LEGACY_SYSTEM_ID,
   ACCOUNT_TYPE_ID,
   ACCOUNT_NUMBER,
   PARTY_ROLE_ID,
   OFFICE_PARTY_ROLE_ID,
   FIRM_PARTY_ROLE_ID,
   REL_OFFICE_PARTY_ROLE_ID,
   REL_FIRM_PARTY_ROLE_ID,
   TITLE_ID,
   FORENAME,
   SURNAME,
   INDIVIDUAL_REFERENCE_NUMBER,
   STATUS,
   FIRM_REFERENCE_NUMBER,
   ACCOUNT_STATUS,
   JOB_TITLE_ID,
   ADDRESS_LINE_1,
   ADDRESS_LINE_2,
   ADDRESS_LINE_3,
   ADDRESS_LINE_4,
   POSTCODE,
   RECORD_UPDATE_IND,
   RECORD_DELETE_IND,
   CREATE_USER_ID,
   INSERT_DATE_TIME,
   UPDATE_DATE_TIME
  ) 
  select LEGACY_SYSTEM_ID,
         ACCOUNT_TYPE_ID,
         ACCOUNT_NUMBER,
         PARTY_ROLE_ID,
         OFFICE_PARTY_ROLE_ID,
         FIRM_PARTY_ROLE_ID,
         REL_OFFICE_PARTY_ROLE_ID,
         REL_FIRM_PARTY_ROLE_ID,
         TITLE_ID,
         FORENAME,
         SURNAME,
         INDIVIDUAL_REFERENCE_NUMBER,
         STATUS,
         FIRM_REFERENCE_NUMBER,
         ACCOUNT_STATUS,
         JOB_TITLE_ID,
         ADDRESS_LINE_1,
         ADDRESS_LINE_2,
         ADDRESS_LINE_3,
         ADDRESS_LINE_4,
         POSTCODE,
         convert(nvarchar(32), HashBytes('SHA2_256', concat(ACCOUNT_NUMBER,
                                                            PARTY_ROLE_ID,
                                                            REL_OFFICE_PARTY_ROLE_ID,
                                                            REL_FIRM_PARTY_ROLE_ID,
                                                            TITLE_ID,
                                                            FORENAME,
                                                            SURNAME,
                                                            INDIVIDUAL_REFERENCE_NUMBER,
                                                            STATUS,
                                                            FIRM_REFERENCE_NUMBER,
                                                            ACCOUNT_STATUS,
                                                            ADDRESS_LINE_1,
                                                            ADDRESS_LINE_2,
                                                            ADDRESS_LINE_3,
                                                            ADDRESS_LINE_4,
                                                            POSTCODE)), 2) as RECORD_UPDATE_IND,
         RECORD_DELETE_IND,
         CREATE_USER_ID,
         INSERT_DATE_TIME,
         UPDATE_DATE_TIME 
    from @DPDB_REGISTERED_INDIVIDUAL_STG
end;  -- proc