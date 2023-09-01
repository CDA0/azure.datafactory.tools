create procedure STAGE_CDI.PRC_CRM_CDI_DPDB_ADVISER_LEGACY_AGENCY_STG (@DPDB_ADVISER_LEGACY_AGENCY_STG STAGE_CDI.DPDB_ADVISER_LEGACY_AGENCY_STG_TYPE readonly)
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
   into STAGE_CDI.DPDB_ADVISER_LEGACY_AGENCY_STG
 (
   ACCOUNT_NUMBER,
   OFFICE_PARTY_ROLE_ID,
   FIRM_PARTY_ROLE_ID,
   ACCOUNT_STATUS,
   OFFICE_STATUS,
   PARTY_ROLE_TYPE_ID,
   INDIVIDUAL_PARTY_ROLE_ID,
   ACCOUNT_TYPE_ID,
   LEGACY_SYSTEM_ID,
   RECORD_UPDATE_IND,
   RECORD_DELETE_IND,
   CREATE_USER_ID,
   INSERT_DATE_TIME,
   UPDATE_DATE_TIME
  ) 
  select ACCOUNT_NUMBER,
         OFFICE_PARTY_ROLE_ID,
         FIRM_PARTY_ROLE_ID,
         ACCOUNT_STATUS,
         OFFICE_STATUS,
         PARTY_ROLE_TYPE_ID,
         INDIVIDUAL_PARTY_ROLE_ID,
         ACCOUNT_TYPE_ID,
         LEGACY_SYSTEM_ID,
         convert(nvarchar(32), HashBytes('SHA2_256', concat(ACCOUNT_NUMBER,
                                                            OFFICE_PARTY_ROLE_ID,
                                                            FIRM_PARTY_ROLE_ID,
                                                            ACCOUNT_STATUS,
                                                            OFFICE_STATUS,
                                                            INDIVIDUAL_PARTY_ROLE_ID)), 2) as RECORD_UPDATE_IND,
         RECORD_DELETE_IND,
         CREATE_USER_ID,
         INSERT_DATE_TIME,
         UPDATE_DATE_TIME 
    from @DPDB_ADVISER_LEGACY_AGENCY_STG
end;  -- proc   