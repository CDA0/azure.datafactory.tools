create function STAGE_CDI.F_DEPERSONALISE (@v_string nvarchar(255))
returns nvarchar(255)
as
/*
Author     : Rizaul Kamal
Date       : 11/05/2023

Description: Mask the input data to convert into x or 9 if DEPERSONALISATION flag is set

Input      : String

Output     : String

-------------------------------------------------------------------------------
Version   Date        Description of change
-------   ----------  ---------------------------------------------------------
0.1       11/05/2023  Initial version
*/
begin  -- function
  declare @v_mask_value    nvarchar(255)
  declare @v_flag          nvarchar(1)

  select @v_flag = PARAMETER_VALUE_CHAR
    from STAGE_CDI.BATCH_PARAMETER
   where PROCESS_NAME = 'DEPERSONALISE_FLAG'
     and PARAMETER_NAME = 'F_DEPERSONALISE'

  if @v_flag = 'Y'
    select @v_mask_value = translate(@v_string collate Latin1_General_CS_AS,
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz123456789', 
	  'XXXXXXXXXXXXXXXXXXXXXXXXXXxxxxxxxxxxxxxxxxxxxxxxxxxx999999999')

  if @v_flag = 'N'
    select @v_mask_value = @v_string

  return @v_mask_value
end;  -- function