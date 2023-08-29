create procedure STAGE_CDI.PRC_UPDATE_PARAMETER_VIA_TABLE
/*
Author     : Rizaul Kamal
Date       : 06/04/2022

Description: Update the BATCH_PARAMETER.parameter_value_dt via a table and
             column passed to the process

Input      : PROCESS_NAME - Name of the process
             PARAMETER_NAME - Name of the parameter
             TABLE_NAME - The table containing the information to use for finding the maximum date value
             COLUMN_NAME - The name of the column containing the date value
			 UPDATED_BY - The name of the pipeline that called this procedure

-------------------------------------------------------------------------------
Version   Date        Description of change
-------   ----------  ---------------------------------------------------------
0.1       06/04/2022  Initial version

*/

  @p_process_name    varchar(255)  = null,
  @p_parameter_name  varchar(255)  = null,
  @p_table_name      varchar(255)  = null,
  @p_column_name     varchar(255)  = null,
  @p_updated_by      varchar(400)  = null
as
begin  -- proc
  set nocount on

  declare @v_sql          nvarchar(max)
  declare @ParameterDef   nvarchar(4000)
  declare @p_status       int
  declare @v_message      varchar(255)

  set @ParameterDef = '@p_process_name    varchar(255),
                       @p_parameter_name  varchar(255),
                       @p_table_name      varchar(255),
                       @p_column_name     varchar(255),
					   @p_updated_by      varchar(400)'

  set @p_status = 0
  
  --
  -- Set up the dynamic SQL for the update statement
  --
  set @v_sql = 'update STAGE_CDI.BATCH_PARAMETER'
  
  if (    @p_column_name is not null
      and @p_column_name <> ''
      and @p_table_name is not null
      and @p_table_name <> '')
     set @v_sql = @v_sql + ' set parameter_value_dt = (select max (' + @p_column_name + ') from ' + @p_table_name + '),'
  else
    set @p_status = 2

  set @v_sql = @v_sql + ' lastmodifieddt      = (SELECT CAST(SYSDATETIMEOFFSET() AT TIME ZONE ' + '''' + 'GMT Standard Time' + '''' + ' AS datetime)),'
  
  if (    @p_updated_by is not null
      and @p_updated_by <> '')
    set @v_sql = @v_sql + ' lastmodifiedby      = ' + '''' + @p_updated_by + ''''
  else
    set @p_status = 2
  
  if (    @p_process_name is not null 
      and @p_process_name <> '')
    set @v_sql = @v_sql + ' WHERE process_name   = ' + '''' + @p_process_name + ''''
  else
    set @p_status = 2
    
  if (    @p_parameter_name is not null 
      and @p_parameter_name <> '')
    set @v_sql = @v_sql + ' AND parameter_name = ' + '''' + @p_parameter_name + ''''
  else
    set @p_status = 2
	
	
  if @p_status = 0
  begin
	exec sp_Executesql @v_sql, @ParameterDef, @p_process_name=@p_process_name, @p_parameter_name=@p_parameter_name, @p_table_name=@p_table_name, @p_column_name=@p_column_name, @p_updated_by=@p_updated_by

    --
    -- Check 1 row has been updated and return error if no record found to update
    --
    if @@ROWCOUNT <> 1 
    begin
	  set @v_message = 'No record found to update';
      throw 50000, @v_message, 1;
	end
  end
  else
  begin
    set @v_message = 'One or more expected input parameters missing';
    throw 50000, @v_message, 2;
  end
end;  -- proc