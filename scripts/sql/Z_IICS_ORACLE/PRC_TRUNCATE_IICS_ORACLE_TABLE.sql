create procedure Z_IICS_ORACLE.PRC_TRUNCATE_IICS_ORACLE_TABLE
  @p_table_name      varchar(128)
/*
Author     : Rizaul Kamal
Date       : 09/06/2023

Description: Truncate table in the Z_IICS_ORACLE schema

Input      : TABLE_NAME - The name of the table to be truncated.

-------------------------------------------------------------------------------
Version   Date        Description of change
-------   ----------  ---------------------------------------------------------
0.1       09/06/2023  Initial version

*/
with encryption, execute as 'cdi_adf_truncate_user'
as
begin -- proc
  set nocount on

  declare @v_sql          nvarchar(max),
          @v_message      varchar(400)
  
  declare @ParameterDef   nvarchar(128)

  set @ParameterDef = '@p_table_name      VARCHAR(128)'

  begin try
    set @v_sql = 'truncate table Z_IICS_ORACLE.' + @p_table_name
	  
	exec sp_Executesql @v_sql, @ParameterDef, @p_table_name=@p_table_name
  end try
  
  begin catch
    set @v_message = ERROR_MESSAGE();
	
	throw 50000, @v_message, 1;
  
  end catch
end;  -- proc