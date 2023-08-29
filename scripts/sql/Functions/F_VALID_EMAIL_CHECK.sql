create function STAGE_CDI.F_VALID_EMAIL_CHECK (@email     varchar(100))
returns bit as

begin     
  declare
    @bitemailval    bit,
    @emailtext      varchar(100)

  set @emailtext=ltrim(rtrim(isnull(@email,'')))

  set @bitemailval = case 
                       when @emailtext = '' then 
					     0
                       when @emailtext like '% %' then
  	       	    	     0
                       when @emailtext like ('%["(),:;<>\]%') then 
					     0
                       when substring(@emailtext,charindex('@',@emailtext),len(@emailtext)) like ('%[!#$%&*+/=?^`_{|]%') then 
					     0
                       when (   left(@emailtext,1) like ('[-_.+]') 
					         or right(@emailtext,1) like ('[-_.+]')) then 
					     0                                                                                    
                       when (   @emailtext like '%[%' 
					         or @emailtext like '%]%') then 
					     0
                       when @emailtext LIKE '%@%@%' then 
					     0
                       when @emailtext NOT LIKE '_%@_%._%' then 
					     0
                     else
					   1 
                     end
  return @bitemailval
end;