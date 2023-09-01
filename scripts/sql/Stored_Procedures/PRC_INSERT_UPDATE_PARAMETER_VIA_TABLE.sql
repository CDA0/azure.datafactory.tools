create procedure STAGE_CDI.PRC_INSERT_UPDATE_PARAMETER_VIA_TABLE
/*
Author     : Rizaul Kamal
Date       : 30/05/2023

Description: Insert a record in BATCH_PARAMETER table if it does not exist 
             otherwise update when a table name is passed to the process.
             
             This stored procedure is for creating an entry for 'prm_EXTRACTDT' only

Input      : TABLE_NAME - The table containing the information to use for finding the maximum date value
             FIELD_NAME - The name of the column to drive the population of the 'prm_EXTRACTDT' value
			 PROCESS_NAME - The name of the process in BATCH_PARAMETER
             UPDATED_BY - The name of the pipeline that called this procedure

-------------------------------------------------------------------------------
Version   Date        Description of change
-------   ----------  ---------------------------------------------------------
0.1       30/05/2023  Initial version

*/

  @p_table_name      varchar(128)  = null,
  @p_column_name     varchar(128)  = null,
  @p_process_name    varchar(400)  = null,
  @p_updated_by      varchar(400)  = null
as

begin  -- proc
  set nocount on

  declare @v_sql              nvarchar(max)
  declare @v_rec_count        smallint
  declare @v_sql_ins          nvarchar(max)
  declare @v_sql_upd          nvarchar(max)
  declare @v_message          varchar(255)
  declare @parameterdef       nvarchar(528)
  declare @parameterdefcount  nvarchar(max)

  set @ParameterDef = '@p_table_name      varchar(128),
                       @p_column_name     varchar(128),
                       @p_process_name   varchar(400),
                       @p_updated_by      varchar(400)'
                       
  set @ParameterDefCount = '@p_table_name   nvarchar(128),
                            @rec_count      int output'                      

  if (   @p_table_name is null
      or @p_table_name = ''
      or @p_column_name is null
      or @p_column_name = ''
      or @p_process_name is null
      or @p_process_name = ''
      or @p_updated_by is null
      or @p_updated_by = '')
  begin
    set @v_message = 'ERROR: One or more input parameter values missing';
    
    throw 50000, @v_message, 1
  end

  --
  -- Set up the dynamic SQL for update statement
  --
  set @v_sql_upd = 'UPDATE stage_cdi.batch_parameter'
  set @v_sql_upd = @v_sql_upd + ' set parameter_value_dt = (select max (' + @p_column_name + ') from STAGE_CDI.' + @p_table_name + '),'
  set @v_sql_upd = @v_sql_upd + ' lastmodifieddt      = (select cast(sysdatetimeoffset() at time zone ' + '''' + 'GMT Standard Time' + '''' + ' as datetime)),'
  set @v_sql_upd = @v_sql_upd + ' lastmodifiedby      = ' + '''' + @p_updated_by + ''''
  set @v_sql_upd = @v_sql_upd + ' where process_name   = ' + '''' + @p_process_name + ''''
  set @v_sql_upd = @v_sql_upd + ' and parameter_name = ' + '''' + 'prm_EXTRACTDT' + ''''
    
  --
  -- Set up the dynamic SQL for the insert statement
  --
  set @v_sql_ins = 'INSERT INTO STAGE_CDI.BATCH_PARAMETER (PROCESS_NAME, PARAMETER_NAME, PARAMETER_VALUE_DT, LASTMODIFIEDDT, LASTMODIFIEDBY)'
  set @v_sql_ins = @v_sql_ins + ' VALUES ('  
  set @v_sql_ins = @v_sql_ins + '''' + @p_process_name + '''' + ','
  set @v_sql_ins = @v_sql_ins + '''' + 'prm_EXTRACTDT' + '''' + ','
  set @v_sql_ins = @v_sql_ins + '(select max(' + @p_column_name + ') from STAGE_CDI.' + @p_table_name + '),'
  set @v_sql_ins = @v_sql_ins + '(SELECT CAST(SYSDATETIMEOFFSET() AT TIME ZONE ' + '''' + 'GMT Standard Time' + '''' + ' AS datetime)),'
  set @v_sql_ins = @v_sql_ins + '''' + @p_updated_by + ''''    + ')'
  
  --
  -- Set up dynamic SQL to check if record already exists in BATCH_PARAMETER
  --
  set @v_sql = 'SELECT @rec_count = count(1) from STAGE_CDI.BATCH_PARAMETER where PROCESS_NAME = ' + '''' + @p_process_name + '''' + ' and PARAMETER_NAME = ' + '''' + 'prm_EXTRACTDT' + ''''
    
  execute sp_executesql @v_sql, @ParameterDefCount, @p_table_name=@p_table_name, @rec_count=@v_rec_count output
    
  --
  -- Record exists in BATCH_PARAMETER table - update
  --    
  if @v_rec_count = 1
  begin
    begin try
      exec sp_Executesql @v_sql_upd, @ParameterDef, @p_table_name=@p_table_name, @p_column_name=@p_column_name, @p_process_name=@p_process_name, @p_updated_by=@p_updated_by
    end try
  
    begin catch
      set @v_message =  ERROR_MESSAGE();
      
      throw 50000, @v_message, 2;
    end catch
  end
  else
  begin
    -- 
    -- Record does not exist in BATCH_PARAMETER table - insert
    --
    begin try
      exec sp_Executesql @v_sql_ins, @ParameterDef, @p_table_name=@p_table_name, @p_column_name=@p_column_name, @p_process_name=@p_process_name, @p_updated_by=@p_updated_by
    end try
  
    begin catch
      set @v_message =  ERROR_MESSAGE();
      
      throw 50000, @v_message, 3;
    end catch
  end
end;  -- proc