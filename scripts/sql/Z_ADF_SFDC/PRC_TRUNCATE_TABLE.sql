create procedure Z_ADF_SFDC.PRC_TRUNCATE_TABLE
  @p_table_name      varchar(255)
/*
Author     : Rizaul Kamal
Date       : 19/05/2023

Description: Truncate table in the Z_ADF_SFDC schema

Input      : TABLE_NAME - The name of the table to be truncated. Only tables 
             starting with TD can be truncated

-------------------------------------------------------------------------------
Version   Date        Description of change
-------   ----------  ---------------------------------------------------------
0.1       19/05/2023  Initial version

*/
with encryption, execute as 'CDI_ADF_TRUNCATE_USER'
as
begin -- proc
  set NOCOUNT on

  declare @v_sql          nvarchar(max)
  declare @ParameterDef   nvarchar(4000)
  declare @v_message      varchar(255)

  set @ParameterDef = '@p_table_name      VARCHAR(255)'

  if @p_table_name is not null
  begin
    set @v_sql = 'TRUNCATE TABLE Z_ADF_SFDC.' + @p_table_name
	  
    begin try
	  exec sp_Executesql @v_sql, @ParameterDef, @p_table_name=@p_table_name
    end try

    begin catch
      set @v_message =  ERROR_MESSAGE();      
      throw 50000, @v_message, 1;
    end catch
  end
  else
  begin
    set @v_message = 'Table name cannot be empty';
    throw 50000, @v_message, 2;
  end
end;  -- proc