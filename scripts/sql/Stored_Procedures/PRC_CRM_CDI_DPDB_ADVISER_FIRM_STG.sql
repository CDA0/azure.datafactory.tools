create procedure STAGE_CDI.PRC_CRM_CDI_DPDB_ADVISER_FIRM_STG (@DPDB_ADVISER_FIRM_STG STAGE_CDI.DPDB_ADVISER_FIRM_STG_TYPE readonly)
/*
Author     : Rizaul Kamal
Date       : 02/06/2023

Description: Generate hash value using SHA256 for data copied over from  Oracle

-------------------------------------------------------------------------------
Version   Date        Description of change
-------   ----------  ---------------------------------------------------------
0.1       02/06/2023  Initial version
*/
as
set nocount on

begin  -- proc
 insert
   into STAGE_CDI.DPDB_ADVISER_FIRM_STG
 (
   PARTY_ROLE_ID,
   ORGANISATION_NAME,
   FIRM_REFERENCE_NUMBER,
   STATUS,
   REGULATORY_STATUS_ID,
   PARTY_ROLE_TYPE_ID,
   PERM_INVESTMENT_ADVICE,
   PERM_MORTGAGE_ADVICE,
   PERM_INSURANCE_ADVICE,
   PERM_PENSION_ADVICE,
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
         ORGANISATION_NAME,
         FIRM_REFERENCE_NUMBER,
         STATUS,
         REGULATORY_STATUS_ID,
         PARTY_ROLE_TYPE_ID,
         PERM_INVESTMENT_ADVICE,
         PERM_MORTGAGE_ADVICE,
         PERM_INSURANCE_ADVICE,
         PERM_PENSION_ADVICE,
         ADDRESS_LINE_1,
         ADDRESS_LINE_2,
         ADDRESS_LINE_3,
         ADDRESS_LINE_4,
         POSTCODE,
         EMAIL_URL_ADDRESS,
         PHONE_FAX_NUMBER,
         convert(nvarchar(32), HashBytes('SHA2_256', concat(ORGANISATION_NAME,
                                                            FIRM_REFERENCE_NUMBER,
                                                            STATUS,
                                                            REGULATORY_STATUS_ID,
                                                            PARTY_ROLE_TYPE_ID,
                                                            PERM_INVESTMENT_ADVICE,
                                                            PERM_MORTGAGE_ADVICE,
                                                            PERM_INSURANCE_ADVICE,
                                                            PERM_PENSION_ADVICE,
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
    from @DPDB_ADVISER_FIRM_STG
end;  -- proc