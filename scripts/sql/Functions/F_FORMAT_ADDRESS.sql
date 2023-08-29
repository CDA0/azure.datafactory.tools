create function STAGE_CDI.F_FORMAT_ADDRESS 
    (@v_organization_name       nvarchar(30),
    @v_pobox                    nvarchar(6),
    @v_house_number             nvarchar(10),
    @v_thorough_name            nvarchar(30),
    @v_sub_building             nvarchar(30),
    @v_building                 nvarchar(30),
    @v_thorough_desc            nvarchar(15),
    @v_dpnthorough_name         nvarchar(30),
    @v_dpnthorough_desc         nvarchar(15),
    @v_ddlc_name                nvarchar(30),
    @v_locl_name                nvarchar(30),
    @v_ptwn_name                nvarchar(30),
    @v_cnty_name                nvarchar(50),
    @v_out_postal_code          nvarchar(7),
    @v_non_paf_premise_no       nvarchar(25),
    @v_non_paf_address_line_1   nvarchar(90),
    @v_non_paf_address_line_2   nvarchar(80),
    @v_non_paf_address_line_3   nvarchar(70),
    @v_non_paf_address_line_4   nvarchar(60),
    @v_non_paf_address_line_5   nvarchar(60),
    @v_non_paf_post_code        nvarchar(12),
    @v_struct_unstruct_ind      char(1))
returns nvarchar(600)
as
/*
Author     : Rizaul Kamal
Date       : 17/05/2022

Description: Formats address

Input      : String

Output     : String

-------------------------------------------------------------------------------
Version   Date        Description of change
-------   ----------  ---------------------------------------------------------
0.1       17/05/2022  Initial version
*/

begin  -- function
  declare 
    @v_return_address       nvarchar(600),
    @v_initcap_string       nvarchar(200),
    @v_id                   int             = 0,
    @v_work_line_1          nvarchar(200)   = null,
    @v_work_line_2          nvarchar(200)   = null,
    @v_temp_thorough_name   nvarchar(80)    = null,
    @v_temp_postcode        nvarchar(12)    = null,
    @v_postcode             nvarchar(12)    = null,
    @v_ignore_prem_num      bit             = 0,
    @v_len_ptwn_name        tinyint         = 0,
    @v_ptwn_name_temp       nvarchar(30)    = null,
	@v_pos_ptwn_name        tinyint,
    @v_address_value        nvarchar(200),
	@v_address_line_1       nvarchar(100),
    @v_address_line_2       nvarchar(100),
    @v_address_line_3       nvarchar(100),
    @v_address_line_4       nvarchar(100),
    @v_address_line_5       nvarchar(100)

  --
  -- Create temporary table
  --
  declare 
    @AddressTable table
    (
       ID int, 
       ADDRESS_VALUE  nvarchar(200)
    )

  declare
    address_cursor cursor for
      select ID,
             ADDRESS_VALUE
        from @AddressTable
       order by ID

  /* **************************************************************************
  Most of the code from here on is dependent on the structured indicator. To
  avoid the complication of having to figure out which address lines have
  actually been populated, the lines are added to a temporary table, which is
  moved in sequence to the output variable at the end of the processing 
  ************************************************************************** */
    
  --
  -- Process structured address
  --
  if @v_struct_unstruct_ind = 'Y'  
  begin  -- structured data

    --
    -- Address line 1: this is populated with the organisation name if populated
    --
    if @v_organization_name is not null
    begin
      set @v_id = @v_id + 1
    
      set @v_initcap_string = STAGE_CDI.F_INITCAP(@v_organization_name)
    
      insert 
        into @AddressTable (ID, ADDRESS_VALUE)
      values(@v_id, @v_initcap_string)
    end  -- @v_organization_name is not null

    --
    -- Address line 2: this is normally a concatenation of SUB_BUILDING and
    -- BUILDING. However, if this results in a single alphabetic character, 
    -- it should later be concatenated with line 3
	--
	if @v_sub_building is not null
	  set @v_work_line_1 = STAGE_CDI.F_INITCAP(@v_sub_building)
	
    if @v_building is not null
    begin
      if @v_sub_building is not null
        set @v_work_line_1 = @v_work_line_1 + ' ' +  STAGE_CDI.F_INITCAP(@v_building)
	  else
	    set @v_work_line_1 = STAGE_CDI.F_INITCAP(@v_building)
    end  -- @v_building is not null

    --
    -- PO Box addresses: if the address is a PO Box address then 'PO BOX' 
    -- resides in the THOROUGH_NAME column and should be concatenated with
    -- the POBOX column. However, DQA shows that POBOX is not always
    -- populated - in which case the numeric part of the address seems to be
    -- held in the HOUSE_NUMBER column
    --
    if @v_thorough_name = 'PO BOX'
    begin
      if @v_pobox is not null
        set @v_temp_thorough_name = @v_thorough_name + ' ' + @v_pobox
      else
        set @v_temp_thorough_name = @v_thorough_name + ' ' + isnull(@v_house_number, '')
    end
    else
      set @v_temp_thorough_name = STAGE_CDI.F_INITCAP(@v_thorough_name)

    --
    -- Address line 3: this is a concatenation of HOUSE_NUMBER, DPNTHOROUGH_NAME,
    -- DPNTHOROUGH_DESC, THOROUGH_NAME and THOROUGH_DESC. If address line 2 
    -- is a single alphabetic character, line 2 and line 3 are concatenated 
    -- into line 2 and line 3 is left blank
    --
    if @v_house_number is not null
    begin
      if (   @v_thorough_name is null 
          or @v_thorough_name != 'PO BOX')
        set @v_work_line_2 = @v_house_number
    end  -- @v_house_number is not null

    if @v_dpnthorough_name is not null
    begin     
      if @v_work_line_2 is not null
        set @v_work_line_2 = @v_work_line_2 + ' ' + STAGE_CDI.F_INITCAP(@v_dpnthorough_name)
      else
        set @v_work_line_2 = STAGE_CDI.F_INITCAP(@v_dpnthorough_name)
    end  -- @v_dpnthorough_name is not null
  
    if @v_dpnthorough_desc is not null
    begin
      if @v_work_line_2 is not null
        set @v_work_line_2 = @v_work_line_2 + ' ' + STAGE_CDI.F_INITCAP(@v_dpnthorough_desc)
      else
        set @v_work_line_2 = STAGE_CDI.F_INITCAP(@v_dpnthorough_desc)
    end  -- @v_dpnthorough_desc is not null
  
    if @v_temp_thorough_name is not null
    begin
      if @v_work_line_2 is not null
        set @v_work_line_2 = @v_work_line_2 + ' ' + @v_temp_thorough_name
      else
        set @v_work_line_2 = @v_temp_thorough_name
    end  -- @v_temp_thorough_name is not null
  
    if @v_thorough_desc is not null
    begin
      if @v_work_line_2 is not null
        set @v_work_line_2 = @v_work_line_2 + ' ' + STAGE_CDI.F_INITCAP(@v_thorough_desc)
      else
        set @v_work_line_2 = STAGE_CDI.F_INITCAP(@v_thorough_desc)
    end  -- @v_thorough_desc is not null
  
    --
    -- If building was not populated and sub-building is just a single alphabetic character:
    --
    if (    (len(trim(@v_work_line_1)) = 1) 
        and (upper(substring(@v_work_line_1, 1, 1)) in ('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z')))
    begin
      set @v_work_line_1 = substring(@v_work_line_1, 1, 1) + ' ' + isnull(@v_work_line_2, '')
      set @v_work_line_2 = null
    end  -- (LEN(TRIM(@v_work_line_1)) = 1 .....
  
    --
    -- DQA shows that sometimes there is a house number, but nothing else that ought to go
    -- into line 3 - in which case add what's in work line 2 to the front of work line 1
    --
    if (    @v_work_line_2 is not null 
        and @v_thorough_name is null
        and @v_thorough_desc is null
        and @v_dpnthorough_name is null 
        and @v_dpnthorough_desc is null)
    begin
      set @v_work_line_1 = @v_work_line_2 + ' ' + isnull(@v_work_line_1, '')
      set @v_work_line_2 = null
    end  -- @v_work_line_2 is not null ....
  
    if @v_work_line_1 is not null
    begin
      set @v_id = @v_id + 1

      insert 
        into @AddressTable (ID, ADDRESS_VALUE)
      values(@v_id, @v_work_line_1)
    end  -- @v_work_line_1 is not null

    if @v_work_line_2 is not null
    begin
      set @v_id = @v_id + 1
    
      insert 
        into @AddressTable (ID, ADDRESS_VALUE)
      values(@v_id, @v_work_line_2)
    end  -- @v_work_line_2 is not null

    --
    -- Address line 4: Concatenate DDLC_NAME and LOCL_NAME
    --
    set @v_work_line_1 = null
  
    if @v_ddlc_name is not null 
      set @v_work_line_1 = STAGE_CDI.F_INITCAP(@v_ddlc_name)

    if @v_locl_name is not null
    begin   
      if @v_work_line_1 is not null
        set @v_work_line_1 = @v_work_line_1 + ' ' + STAGE_CDI.F_INITCAP(@v_locl_name)
      else
        set @v_work_line_1 = STAGE_CDI.F_INITCAP(@v_locl_name)
    end  -- @v_locl_name is not null

    if @v_work_line_1 is not null
    begin
        set @v_id = @v_id + 1
      
      insert 
        into @AddressTable (ID, ADDRESS_VALUE)
      values(@v_id, @v_work_line_1)
    end  -- @v_work_line_1 is not null

    --
    -- Address line 5: If address line 4 is currently blank, then address line 4 = PTWN_NAME
    -- and therefore address line 5 = CNTY_NAME if CNTY_NAME is not the same as PTWN_NAME,
    -- otherwise it is left blank. If address line 4 was already populated, 
	-- address line 5 is a concatenation of
    -- PTWN_NAME and CNTY_NAME, omitting CNTY_NAME if it is the same as PTWN_NAME.
    --

    set @v_work_line_1 = null
    
    if @v_ptwn_name is not null
    begin
      if @v_id < 4
      begin
        set @v_id = @v_id + 1
      
        insert 
          into @AddressTable (ID, ADDRESS_VALUE)
        values(@v_id, @v_ptwn_name)
      end
      else
        set @v_work_line_1 = @v_ptwn_name
    end  -- @v_ptwn_name is not null
  
    if @v_ptwn_name != @v_cnty_name
    begin
      if @v_work_line_1 is not null
        set @v_work_line_1 = @v_work_line_1 + ' ' + STAGE_CDI.F_INITCAP(@v_cnty_name)
      else
        set @v_work_line_1 = STAGE_CDI.F_INITCAP(@v_cnty_name)
    end  -- @v_ptwn_name != @v_cnty_name
  
    if @v_work_line_1 is not null
    begin
      set @v_id = @v_id + 1
      
      insert 
        into @AddressTable (ID, ADDRESS_VALUE)
      values(@v_id, @v_work_line_1)
    end  -- @v_work_line_1 is not null
  
    --
    -- Postcode: postcodes that are without a space in between
    --
    if CHARINDEX(' ', @v_out_postal_code) = 0
    begin
      if len(@v_out_postal_code) = 6
        set @v_temp_postcode = substring(@v_out_postal_code,1,3) + ' ' + substring(@v_out_postal_code,4,3)
      else
        set @v_temp_postcode = substring(@v_out_postal_code,1,4) + ' ' + substring(@v_out_postal_code,5,3)
    end
    else
      set @v_temp_postcode = @v_out_postal_code
  
    set @v_id = @v_id + 1
      
    insert 
      into @AddressTable (ID, ADDRESS_VALUE)
    values(@v_id, @v_temp_postcode)
    
    set @v_postcode = @v_temp_postcode
  end  -- structured data
  
  --
  -- Process non-structured address
  --
  else
  begin  -- non structured data
  
    -- Address line 1 and 2: for address line 1, we need to consider whether
    -- NON_PAF_PREMISE_NO is populated. If it is, we need to check whether 
    -- either address line 1 or 2 contains it. The number might exist anywhere
    -- within address line 1, but if it exists in address line 2 it will be 
    -- found at the very beginning. If it is not found, then its value should 
    -- be concatenated with address line 1 if address line 1 is not blank or 
    -- purely numeric otherwise it should be concatenated with address line 2.
    --
    
    --
    -- Premise number is populated
    --
    if @v_non_paf_premise_no is not null
    begin
      if @v_non_paf_address_line_1 is not null
      begin
        if len(trim(translate(@v_non_paf_address_line_1, ' +-.,/*0123456789', '                 '))) is null
        begin
          set @v_ignore_prem_num = 0
          set @v_work_line_1 = null
        end
        else
        begin
          if patindex('%' + @v_non_paf_premise_no + '%', @v_non_paf_address_line_1) > 0
          begin
            set @v_work_line_1 = @v_non_paf_address_line_1
            set @v_ignore_prem_num = 1
          end
          else
          begin
            set @v_work_line_1 = @v_non_paf_premise_no + ' ' + @v_non_paf_address_line_1
            set @v_ignore_prem_num = 1
          end
        end
      end
      else -- address line 1 was not populated
      begin
        set @v_work_line_1 = null
        set @v_ignore_prem_num = 0
      end

      if @v_ignore_prem_num = 0  -- we still haven't dealt with premise number yet
      begin
        if @v_non_paf_address_line_2 is not null
        begin
          if patindex('%' + @v_non_paf_premise_no + '%', @v_non_paf_address_line_2) = 1
            set @v_work_line_2 = @v_non_paf_address_line_2
          else
            set @v_work_line_2 = @v_non_paf_premise_no + ' ' + @v_non_paf_address_line_2
        end
        else  -- line 2 is empty - DQA suggests doesn't happen if premise num is populated
        begin
          if @v_work_line_1 is not null -- capture premise number in line 1 anyway
            set @v_work_line_1 = @v_non_paf_premise_no
          else
          begin
            set @v_work_line_1 = @v_non_paf_premise_no + ' ' + @v_work_line_1
            set @v_work_line_2 = null
          end
        end
      end
      else
        set @v_work_line_2 = @v_non_paf_address_line_2
	end
    else -- premise number was not populated
    begin
      set @v_work_line_1 = @v_non_paf_address_line_1
      set @v_work_line_2 = @v_non_paf_address_line_2
    end  -- @v_ignore_prem_num = 0
	
    --
    -- Convert the values into mixed case
    --
    set @v_work_line_1 = STAGE_CDI.F_INITCAP(@v_work_line_1);
    set @v_work_line_2 = STAGE_CDI.F_INITCAP(@v_work_line_2);

    if @v_work_line_1 is not null
    begin
      set @v_id = @v_id + 1
      
      insert 
        into @AddressTable (ID, ADDRESS_VALUE)
      values (@v_id, @v_work_line_1)
    end  -- @v_work_line_1 is not null

    if @v_work_line_2 is not null
    begin
      set @v_id = @v_id + 1
      
      insert 
        into @AddressTable (ID, ADDRESS_VALUE)
      values (@v_id, @v_work_line_2)
    end  -- @v_work_line_2 is not null

    --
    -- Address lines 3, 4 and 5: these are simply assigned whatever is in the
    -- relevant columns in the database
    --
    if @v_non_paf_address_line_3 is not null
    begin
      set @v_id = @v_id + 1
      set @v_non_paf_address_line_3 = STAGE_CDI.F_INITCAP(@v_non_paf_address_line_3)

      insert
        into @AddressTable (ID, ADDRESS_VALUE)
      values (@v_id, @v_non_paf_address_line_3)
    end  -- @v_non_paf_address_line_3 is not null

    if @v_non_paf_address_line_4 is not null
    begin
      set @v_id = @v_id + 1
      set @v_non_paf_address_line_4 = STAGE_CDI.F_INITCAP(@v_non_paf_address_line_4)
      
      insert 
        into @AddressTable (ID, ADDRESS_VALUE)
      values (@v_id, @v_non_paf_address_line_4)
    end  -- @v_non_paf_address_line_4 is not null

    if @v_non_paf_address_line_5 is not null
    begin
      set @v_id = @v_id + 1
      set @v_non_paf_address_line_4 = STAGE_CDI.F_INITCAP(@v_non_paf_address_line_4)

	  insert 
        into @AddressTable (ID, ADDRESS_VALUE)
      values (@v_id, @v_non_paf_address_line_5)
    end  -- @v_non_paf_address_line_5 is not null

    --
    -- Postcode: without the space
    --
    if PATINDEX(' ', @v_non_paf_post_code) = 0
    begin
      if LEN(@v_non_paf_post_code) = 6
        set @v_temp_postcode = substring(@v_non_paf_post_code,1,3) + ' ' + substring(@v_non_paf_post_code,4,3)
      else
        set @v_temp_postcode = substring(@v_non_paf_post_code,1,4) + ' ' + substring(@v_non_paf_post_code,5,3)
    end
    else
      set @v_temp_postcode = @v_non_paf_post_code

    set @v_id = @v_id + 1
    set @v_non_paf_address_line_3 = STAGE_CDI.F_INITCAP(@v_non_paf_address_line_3)

    insert
      into @AddressTable (ID, ADDRESS_VALUE)
    values (@v_id, @v_temp_postcode)

    set @v_postcode = @v_temp_postcode

    if @v_ptwn_name is not null -- do this here as value needed outside loop
    begin
      set @v_ptwn_name_temp = STAGE_CDI.F_INITCAP(@v_ptwn_name)
      set @v_len_ptwn_name = len(@v_ptwn_name_temp)
    end
    else
    begin
      set @v_ptwn_name_temp = null
      set @v_len_ptwn_name = 0
    end  -- @v_ptwn_name is not null 
  end -- STRUCT_UNSTRUCT_IND was = 'Y'

  -- *********************************************************************************************
  -- move the la_temp_lines array to the return
  -- variables. Because the temporary lines have only been populated when values were present to
  -- do so, there are no gaps in the address lines and unassigned lines will be null.  This allows
  -- a straight forward sequential assignment to the final output variables using the l_line_num
  -- variable as the counter of how many lines were populated.

  --
  -- Identity and upper case the post town if it's recognisable as such for 
  -- non-paf addresses, 'BFPO' and 'PO BOX'. When non-paf postcode is populated,
  -- the postcode generally does not occur within the address lines, so no 
  -- attempt is made to revert postcodes back to upper case
  --
  if (    @v_struct_unstruct_ind = 'N' 
      and @v_ptwn_name_temp is not null)
  begin
    open address_cursor
    
    fetch next from address_cursor into @v_id, @v_address_value
    
    while @@FETCH_STATUS = 0
    begin
      set @v_pos_ptwn_name = PATINDEX(@v_ptwn_name_temp, @v_address_value)
      
      if @v_pos_ptwn_name != 0
      begin
        set @v_work_line_1 = substring(@v_address_value, 1, (@v_pos_ptwn_name -1)) + upper(@v_ptwn_name_temp) +  substring(@v_address_value, (@v_pos_ptwn_name + @v_len_ptwn_name), 78)
        
        update @AddressTable
           set ADDRESS_VALUE = @v_work_line_1
         where ID = @v_id
      end  -- @v_pos_ptwn_name != 0
      
      fetch next from address_cursor into @v_id, @v_address_value
    end  -- @@FETCH_STATUS = 0
    
    close address_cursor
  end  --  @v_struct_unstruct_ind = 'N'

  --
  -- Find the BFPO address
  --
  open address_cursor
    
  fetch next from address_cursor into @v_id, @v_address_value
    
  while @@FETCH_STATUS = 0
  begin
    set @v_pos_ptwn_name = PATINDEX('Bfpo', @v_address_value)
    
    if @v_pos_ptwn_name != 0
      begin
        set @v_work_line_1 = substring(@v_address_value, 1, (@v_pos_ptwn_name -1)) + 'BFPO' +  substring(@v_address_value, (@v_pos_ptwn_name + 4), 78)
        
        update @AddressTable
           set ADDRESS_VALUE = @v_work_line_1
         WHERE ID = @v_id
      end  -- @v_pos_ptwn_name != 0
    
    fetch next from address_cursor into @v_id, @v_address_value
  end  -- @@FETCH_STATUS = 0

  close address_cursor

  --
  -- Find the PO BOX address
  --
  open address_cursor
    
  fetch next from address_cursor into @v_id, @v_address_value
    
  while @@FETCH_STATUS = 0
  begin
    set @v_pos_ptwn_name = PATINDEX('Po Box', @v_address_value)
    
    if @v_pos_ptwn_name != 0
      begin
        set @v_work_line_1 = substring(@v_address_value, 1, (@v_pos_ptwn_name -1)) + 'PO BOX' +  substring(@v_address_value, (@v_pos_ptwn_name + 6), 78)
        
        update @AddressTable
           set ADDRESS_VALUE = @v_work_line_1
         WHERE ID = @v_id
      end  -- @v_pos_ptwn_name != 0
    
    fetch next from address_cursor into @v_id, @v_address_value
  end  -- @@FETCH_STATUS = 0

  close address_cursor

  --
  -- Set up the return value
  --
  open address_cursor
    
  fetch next from address_cursor into @v_id, @v_address_value
    
  while @@FETCH_STATUS = 0
  begin
    if @v_id = 1
	  set @v_address_line_1 = @v_address_value
	else
	  if @v_id = 2 
	    set @v_address_line_2 = @v_address_value
	  else
	    if @v_id = 3
	      set @v_address_line_3 = @v_address_value
		else
	     if @v_id = 4
	      set @v_address_line_4 = @v_address_value
	     else
		   if @v_id = 5
	         set @v_address_line_5 = @v_address_value
	
	fetch next from address_cursor into @v_id, @v_address_value
   end  -- @@FETCH_STATUS = 0
   
   close address_cursor

   DEALLOCATE address_cursor
	
  --
  --  Merge the individual lines into a single line
  --  
  if (   @v_address_line_1 is not null 
      and @v_address_line_1 != isnull(@v_postcode, ' '))
    set @v_return_address = substring(replace(@v_address_line_1, '|', '/'), 1, 78)
       
  if (    @v_address_line_2 is not null 
      and @v_address_line_2 != isnull(@v_postcode, ' '))
    set @v_return_address = @v_return_address + '|' + substring(replace(@v_address_line_2, '|', '/'), 1, 78)
  else
    set @v_return_address = @v_return_address + '|'
   
  if (    @v_address_line_3 is not null 
      and @v_address_line_3 != isnull(@v_postcode, ' '))
    set @v_return_address = @v_return_address + '|' + substring(replace(@v_address_line_3, '|', '/'), 1, 78)
  else
    set @v_return_address = @v_return_address + '|'
       
  if (    @v_address_line_4 is not null 
      and @v_address_line_4 != isnull(@v_postcode, ' '))
    set @v_return_address = @v_return_address + '|' + substring(replace(@v_address_line_4, '|', '/'), 1, 78)
  else
    set @v_return_address = @v_return_address + '|'
       
  if (      @v_address_line_5 is not null 
      and @v_address_line_5 != isnull(@v_postcode, ' '))
    set @v_return_address = @v_return_address + '|' + substring(replace(@v_address_line_5, '|', '/'), 1, 78)
  else
    set @v_return_address = @v_return_address + '|'
	    
  if @v_postcode is not null 
    set @v_return_address = @v_return_address + '|' + replace(@v_postcode, '|', '/')
  else
    set @v_return_address = @v_return_address + '|'
    
  RETURN @v_return_address

end;  -- function