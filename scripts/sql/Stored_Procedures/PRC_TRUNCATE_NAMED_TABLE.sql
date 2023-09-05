create procedure STAGE_CDI.PRC_TRUNCATE_NAMED_TABLE
  @p_table_name      VARCHAR(128)
/*
Author       : Rizaul Kamal
Date         : 27/04/2022
Updated By   : Nikita Varnwal
Last Updated : 30/08/2023

Description: Truncate table in the STAGE_CDI schema (only tables listed can be truncated)

Input      : TABLE_NAME - The name of the table to be truncated
             Expected values are:
             SFDC_ALERTS_STG
             SFDC_PLAT_MSMGRTN_PARENT_CASE_STG
             CRM_PLAT_DYN_DEATHCLAIM_STG
             CRM_PLAT_DYN_ANNOTATION_STG
             CRM_PLAT_DYN_EMAILMESSAGE_STG
             CRM_PLAT_DYN_INCIDENT_STG
             SFDC_PLAT_DYN_ACTIVITY_POINTER_STG
             SFDC_PLAT_DYN_EMAIL_STG
             SFDC_PLAT_MSMGRTN_CASEFEED_STG
             CRM_PLAT_DYN_CONTRIBUTION_STG
             CRM_PLAT_DYN_DEMATACTIVITY_STG
             CRM_PLAT_DYN_DRAWDOWN_STG
             CRM_PLAT_DYN_NONADVSWRKITEM_STG
             CRM_PLAT_DYN_PAYMENT_STG
             CRM_PLAT_DYN_TRNSFRINACTVTY_STG
             CRM_PLAT_DYN_SRC_ACTVTYPNTR_STG
             CRM_PLAT_DYN_APAWORKITEM_STG
             CRM_PLAT_DYN_ATTACHMENT_STG
             CRM_PLAT_DYN_CASECLNTMASTR_STG
             CRM_PLAT_DYN_CLIENTMASTR_STG
             CRM_PLAT_DYN_DIVORCECLAIM_STG
             CRM_PLAT_DYN_TRANSFEROUT_STG 
             CRM_PLAT_DYN_ACCOUNT_STG
             CRM_PLAT_DYN_CONTACT_STG

-------------------------------------------------------------------------------
Version   Date        Description of change
-------   ----------  ---------------------------------------------------------
0.1       27/04/2022  Initial version
0.2       28/07/2023  Amend table name CRM_PLAT_DYN_SRC_ACTVTYPNTR_STG to include SRC
0.3       29/07/2023  Amend table name CRM_PLAT_DYN_CASECLNTMASTR_STG to CRM_PLAT_DYN_CASECLNTMASTER_STG
0.4       21/08/2023  Amend table name CRM_PLAT_DYN_TRANSFEROUT_STG
0.5       23/08/2023  Amend table name CRM_PLAT_DYN_ACCOUNT_STG
0.6       30/08/2023  Amend table name CRM_PLAT_DYN_ACTIVITYPARTY_STG
0.7       05/09/2023  Amend table name CRM_PLAT_DYN_CONTACT_STG

*/
with encryption, execute as 'CDI_ADF_TRUNCATE_USER'
as
begin -- proc
  set nocount on

  declare @v_sql          nvarchar(max),
          @v_message      nvarchar(500),
          @ParameterDef   nvarchar(128)

  SET @ParameterDef = '@p_table_name      VARCHAR(128)'

  if @p_table_name in ('SFDC_ALERTS_STG', 
                       'SFDC_PLAT_MSMGRTN_PARENT_CASE_STG',
                       'CRM_PLAT_DYN_DEATHCLAIM_STG',
                       'CRM_PLAT_DYN_ANNOTATION_STG',
                       'CRM_PLAT_DYN_EMAILMESSAGE_STG',
                       'CRM_PLAT_DYN_INCIDENT_STG',
                       'SFDC_PLAT_DYN_ACTIVITY_POINTER_STG',
                       'SFDC_PLAT_DYN_EMAIL_STG',
                       'SFDC_PLAT_MSMGRTN_CASEFEED_STG',
                       'CRM_PLAT_DYN_CONTRIBUTION_STG',
                       'CRM_PLAT_DYN_DEMATACTIVITY_STG',
                       'CRM_PLAT_DYN_DRAWDOWN_STG',
                       'CRM_PLAT_DYN_NONADVSWRKITEM_STG',
                       'CRM_PLAT_DYN_PAYMENT_STG',
                       'CRM_PLAT_DYN_TRNSFRINACTVTY_STG',
                       'CRM_PLAT_DYN_SRC_ACTVTYPNTR_STG',
                       'CRM_PLAT_DYN_APAWORKITEM_STG',
                       'CRM_PLAT_DYN_ATTACHMENT_STG',
                       'CRM_PLAT_DYN_CASECLNTMASTER_STG',
                       'CRM_PLAT_DYN_CLIENTMASTR_STG',
                       'CRM_PLAT_DYN_DIVORCECLAIM_STG',
                       'CRM_PLAT_DYN_TRANSFEROUT_STG',
                       'CRM_PLAT_DYN_ACCOUNT_STG',
                       'CRM_PLAT_DYN_ACTIVITYPARTY_STG',
                       'CRM_PLAT_DYN_CONTACT_STG')
  begin
    begin try
      set @v_sql = 'TRUNCATE TABLE STAGE_CDI.' + @p_table_name
      
      exec sp_Executesql @v_sql, @ParameterDef, @p_table_name=@p_table_name
    end try
  
    begin catch
      set @v_message = ERROR_MESSAGE();
    
      throw 50000, @v_message, 1;
  
    end catch
  end
  else
    begin
      set @v_message = 'This process is not set up to truncate ' + @p_table_name;
    
      throw 50000, @v_message, 2;
    end 
  
end;  -- proc