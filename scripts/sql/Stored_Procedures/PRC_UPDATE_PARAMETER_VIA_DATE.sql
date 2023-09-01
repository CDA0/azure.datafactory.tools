create procedure STAGE_CDI.PRC_UPDATE_PARAMETER_VIA_DATE
/*
Author     : Rizaul Kamal

Date       : 06/04/2022

Description: Update the BATCH_PARAMETER via a date passed to the process
             
Input      : PROCESS_NAME - Name of the process
             PARAMETER_NAME - Name of the parameter
             PARAMETER_VALUE - The date value to update
             UPDATED_BY - The name of the pipeline that called this procedure         

-------------------------------------------------------------------------------
Version   Date        Description of change
-------   ----------  ---------------------------------------------------------
0.1       06/04/2022  Initial version

*/
  @p_process_name     varchar(255),
  @p_parameter_name   varchar(255),
  @p_parameter_value  varchar(128),
  @p_updated_by       varchar(255)
as
set nocount on

declare @v_message      varchar(255)

begin  -- proc
  if (    @p_parameter_value is not null
      and @p_parameter_value <> ''
      and @p_process_name is not null
      and @p_process_name <> ''
      and @p_parameter_name is not null 
      and @p_parameter_name <> '')
  begin
    update stage_cdi.batch_parameter
       set parameter_value_dt = cast(@p_parameter_value as datetime2),
           lastmodifieddt = (select cast(sysdatetimeoffset() at time zone 'GMT Standard Time' as datetime)),
           lastmodifiedby = @p_updated_by
     where process_name = @p_process_name
       and parameter_name = @p_parameter_name

    --
    -- Check 1 row has been updated and return error if no record found to update
    --
    if @@ROWCOUNT <> 1 
    begin
      set @v_message = 'No record found to update';
      throw 50000, @v_message, 1;
    end
  end
end;  -- proc