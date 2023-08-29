create function STAGE_CDI.F_INITCAP (@v_input_string varchar(8000))
returns varchar(8000)
as
/*
Author     : Rizaul Kamal
Date       : 11/05/2023

Description: Convert text to initial capital letter format

Input      : String

Output     : String

-------------------------------------------------------------------------------
Version   Date        Description of change
-------   ----------  ---------------------------------------------------------
0.1       11/05/2023  Initial version
*/
begin  -- function
  declare 
    @v_output_string nvarchar(max) = lower(@v_input_string),
	@v_char char(1),
	@v_alphanum bit = 0,
	@v_len int = len(@v_input_string),
    @v_position int = 1;		  
 
    --
    -- Iterate through all characters in the input string
	--
    while @v_position <= @v_len 
	begin
    
      --	
      -- get the next character
	  --
      set @v_char = substring(@v_input_string, @v_position, 1)
 
      --
	  -- convert to upper case the first character or the previous character
      -- if it is not alphanumeric
	  --
      if @v_position = 1 or @v_alphanum = 0
        set @v_output_string = stuff(@v_output_string, @v_position, 1, upper(@v_char))
 
      set @v_position = @v_position + 1;
 
      --
      -- define if the current character is non-alphanumeric
	  --
      if ascii(@v_char) <= 47 or (ascii(@v_char) between 58 and 64) or
	    (ascii(@v_char) between 91 and 96) or (ascii(@v_char) between 123 and 126)
	    set @v_alphanum = 0
      else
	    set @v_alphanum = 1
 
    end  -- @v_position <= @v_len 
 
   return @v_output_string;		   
end;  -- function