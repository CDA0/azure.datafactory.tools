create procedure STAGE_CDI.PRC_CRM_CDI_DPDB_ADVISER_OFFICE_STG (@DPDB_ADVISER_OFFICE_STG STAGE_CDI.DPDB_ADVISER_OFFICE_STG_TYPE readonly)
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
   into STAGE_CDI.DPDB_ADVISER_OFFICE_STG
 (
   PARTY_ROLE_ID,
   FIRM_PARTY_ROLE_ID,
   PARTY_ROLE_NAME,
   STATUS,
   PARTY_ROLE_TYPE_ID,
   ADDRESS_LINE_1,
   ADDRESS_LINE_2,
   ADDRESS_LINE_3,
   ADDRESS_LINE_4,
   POSTCODE,
   EMAIL_URL_ADDRESS,
   PHONE_FAX_NUMBER,
   RECORD_UPDATE_IND,
   RECORD_DELETE_IND,
   CREATE_USER_ID,
   INSERT_DATE_TIME,
   UPDATE_DATE_TIME
  ) 
  select PARTY_ROLE_ID,
         FIRM_PARTY_ROLE_ID,
         PARTY_ROLE_NAME,
         STATUS,
         PARTY_ROLE_TYPE_ID,
         ADDRESS_LINE_1,
         ADDRESS_LINE_2,
         ADDRESS_LINE_3,
         ADDRESS_LINE_4,
         POSTCODE,
         EMAIL_URL_ADDRESS,
         PHONE_FAX_NUMBER,
         convert(nvarchar(32), HashBytes('SHA2_256', concat(PARTY_ROLE_NAME,
                                                            STATUS,
                                                            PARTY_ROLE_TYPE_ID,
                                                            ADDRESS_LINE_1,
                                                            ADDRESS_LINE_2,
                                                            ADDRESS_LINE_3,
                                                            ADDRESS_LINE_4,
                                                            POSTCODE,
                                                            EMAIL_URL_ADDRESS,
                                                            PHONE_FAX_NUMBER)), 2) as RECORD_UPDATE_IND,
         RECORD_DELETE_IND,
         CREATE_USER_ID,
         INSERT_DATE_TIME,
         UPDATE_DATE_TIME 
    from @DPDB_ADVISER_OFFICE_STG
end;  -- proc