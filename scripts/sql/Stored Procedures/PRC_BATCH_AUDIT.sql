create procedure STAGE_CDI.PRC_BATCH_AUDIT
/*
Author     : Rizaul Kamal

Date       : 05/06/2023

Description: Update BATCH_AUDIT & BATCH_AUDIT_HIST to keep a log of the total 
             number of records processed by a pipeline
             
Input      : PIPELINE_NAME - Name of the process
             TABLE_NAME - Name of the target table populated by the pipeline
             TRIGGER_NAME - The name of the trigger that kicked off the pipeline
             PROCESS_START_DT - Date and time the pipeline started
             DURATION - The time (in seconds) it took to complete
             BILLABLE_DURATION - The time the pipeline was billed for
             BILLABLE_UNIT - The unit used for billing

-------------------------------------------------------------------------------
Version   Date        Description of change
-------   ----------  ---------------------------------------------------------
0.1       05/06/2023  Initial version

*/
  @p_pipeline_name      varchar(255),
  @p_table_name         varchar(255),
  @p_trigger_name       varchar(255),
  @p_process_start_dt   varchar(25),
  @p_duration           int,     
  @p_billable_duration  decimal(25,20),
  @p_billable_unit      varchar(100),
  @p_records_read       int,
  @p_records_written  int
as
set nocount on

declare
  @v_message             varchar(400),
  @v_process_start_dt    datetime2,
  @v_process_end_dt      datetime2

/*
===============================================================================
Initialise 
===============================================================================
*/
begin  -- proc
  --
  --  Check @p_pipeline_name is supplied, Fail process if not
  --
  if (@p_pipeline_name is null or @p_pipeline_name = '')
  begin
    set @v_message = 'Pipeline name cannot be blank or NULL. Aborting pipeline';

    throw 50000, @v_message, 1;
  end  -- @p_pipeline_name is null or @p_pipeline_name = ''

  --
  --  Check @p_table_name is supplied, Fail process if not
  --
  if (@p_table_name is null or @p_table_name = '')
  begin
    set @v_message = 'Table name cannot be blank or NULL. Aborting pipeline';

    throw 50000, @v_message, 1;
  end  -- @p_table_name is null or @p_table_name = ''
  
  --
  --  Check @p_process_start_dt is supplied, Fail process if not
  --
  if (@p_process_start_dt is null or @p_process_start_dt = '')
  begin
    set @v_message = 'Process Start Date Time cannot be blank or NULL. Aborting pipeline';

    throw 50000, @v_message, 1;
  end  -- @p_process_start_dt is null or @p_process_start_dt = ''

  --
  --  Check @p_duration is supplied, Fail process if not
  --
  if (@p_duration is null or @p_duration = '')
  begin
    set @v_message = 'Duration value cannot be blank or NULL. Aborting pipeline';

    throw 50000, @v_message, 1;
  end  -- @p_duration is null or @p_duration = ''

  --
  --  Check @p_duration is supplied, Fail process if not
  --
  if (@p_duration is null or @p_duration = '')
  begin
    set @v_message = 'Duration value cannot be blank or NULL. Aborting pipeline';

    throw 50000, @v_message, 1;
  end  -- @p_duration is null or @p_duration = ''    
/*
===============================================================================
Main process
===============================================================================
*/
  -- 
  -- Convert p_process_start_dt into date and calculate end time
  --
  select @v_process_start_dt = cast(cast(replace(@p_process_start_dt, ',', '') as datetimeoffset) at time zone 'GMT Standard Time' as datetime2)

  set @v_process_end_dt = dateadd(second, @p_duration, @v_process_start_dt)

  --
  -- Check an entry for the pipeline exists in the BATCH_AUDIT table for the 
  -- pipeline and table name combination
  --
  
  begin transaction updatebatchaudit
  
  begin try
    if exists (select 1 from STAGE_CDI.BATCH_AUDIT where PIPELINE_NAME = @p_pipeline_name and table_name = @p_table_name)
      update STAGE_CDI.BATCH_AUDIT
         set PROCESS_NUMBER = PROCESS_NUMBER + 1,
             PROCESS_START_DATETIME = @v_process_start_dt,
             PROCESS_END_DATETIME = @v_process_end_dt,
             BILLABLE_DURATION = @p_billable_duration,
             BILLABLE_UNIT = @p_billable_unit,
             RECORDS_READ = @p_records_read,
             RECORDS_WRITTEN = @p_records_written,
             TRIGGER_NAME = @p_trigger_name,
             INSERT_DATETIME = cast(sysdatetimeoffset() at time zone 'GMT Standard Time' as datetime)
       where PIPELINE_NAME = @p_pipeline_name
         and TABLE_NAME = @p_table_name
  
    else
      insert
        into STAGE_CDI.BATCH_AUDIT 
      (
        PIPELINE_NAME,
        TABLE_NAME,
        PROCESS_NUMBER,
        TRIGGER_NAME,
        PROCESS_START_DATETIME,
        PROCESS_END_DATETIME,
        BILLABLE_DURATION,
        BILLABLE_UNIT,
        RECORDS_READ,
        RECORDS_WRITTEN,
        INSERT_DATETIME
      )
      values
      (
        @p_pipeline_name,
        @p_table_name,
        1,
        @p_trigger_name,
        @v_process_start_dt,
        @v_process_end_dt,
        @p_billable_duration,
        @p_billable_unit,
        @p_records_read,
        @p_records_written,
        cast(sysdatetimeoffset() at time zone 'GMT Standard Time' as datetime))

    -- 
    -- Copy the entry to the BATCH_AUDIT_HIST table
    --
    insert
      into STAGE_CDI.BATCH_AUDIT_HIST 
    (
      PIPELINE_NAME,
      TABLE_NAME,
      PROCESS_NUMBER,
      TRIGGER_NAME,
      PROCESS_START_DATETIME,
      PROCESS_END_DATETIME,
      BILLABLE_DURATION,
      BILLABLE_UNIT,
      RECORDS_READ,
      RECORDS_WRITTEN,
      INSERT_DATETIME
    )
    select PIPELINE_NAME,
           TABLE_NAME,
           PROCESS_NUMBER,
           TRIGGER_NAME,
           PROCESS_START_DATETIME,
           PROCESS_END_DATETIME,
           BILLABLE_DURATION,
           BILLABLE_UNIT,
           RECORDS_READ,
           RECORDS_WRITTEN,
           INSERT_DATETIME
      from STAGE_CDI.BATCH_AUDIT
     where PIPELINE_NAME = @p_pipeline_name
       and TABLE_NAME = @p_table_name

    if @@trancount > 0
      commit transaction updatebatchaudit
  end try
    
  begin catch
    if @@trancount > 0
    begin
       rollback transaction updatebatchaudit
      
       set @v_message = ERROR_MESSAGE();
      
       throw 50000, @v_message, 1;
    end -- @@trancount > 0
  end catch
end;  -- proc