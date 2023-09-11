CREATE PROCEDURE Z_IICS_ORACLE.PRC_AUTOMATED_TESTING
  @p_table_name         NVARCHAR(128),
  @p_column_exclusion   NVARCHAR(4000) = NULL,
  @p_key                NVARCHAR(2) = NULL
/*
Author     : Rizaul Kamal
Date       : 03/05/2022

Description: Automate the testing of data

Input      : TABLE_NAME - The name of the table to be tested

Output     : Status code - 0 = Success
						   1 = Failure

-------------------------------------------------------------------------------
Version   Date        Description of change
-------   ----------  ---------------------------------------------------------
0.1       03/05/2022  Initial version
0.2       06/05/2022  Fix issue where source and target tables can have different 
                      list of columns
0.3       09/05/2022  Update process to deal with table with identity column
0.4       19/05/2022  Update process to provide count of source and target records
                      for table with identity column
0.5       14/06/2022  Added validation for incorrect column name in MAX_COLUMN_NAME
                      Fixed issue where PK consists of more than 1 field	
0.6       01/07/2022  Removed the need to include @p_column_exclusion parameter
                      even if no columns need to be excluded
0.7       11/08/2023  Added validation to take place if a table has a unique index
                      and/or primary key; removed check for BATCH_PARAMETER	as
                      it is no longer relevant; validation will also take place
                      against a table if it has an identity column as long as
                      it is not part of the primary key/unique index                      

*/
AS
SET NOCOUNT ON
SET ANSI_WARNINGS OFF

BEGIN -- procedure
  DECLARE @v_td_table_name      NVARCHAR(128)
  DECLARE @v_message            NVARCHAR(1000)
  DECLARE @v_prm_EXTRACTDT      DATETIME2
  DECLARE @v_tab_max_date       DATETIME2
  DECLARE @v_sql                NVARCHAR(max)
  DECLARE @v_sql_src            NVARCHAR(max)
  DECLARE @v_sql_trg            NVARCHAR(max)
  DECLARE @v_row_count          INT
  DECLARE @v_source_rec_count   INT
  DECLARE @v_target_rec_count   INT
  DECLARE @v_pk_column          NVARCHAR(128)
  DECLARE @v_pk_column_list     NVARCHAR(2000) = ''
  DECLARE @v_temp_tab_pk_column NVARCHAR(2000) = ''
  DECLARE @v_missing_pk_flag    BIT     = 0
  DECLARE @v_as_pk_column       NVARCHAR(2000) = ''
  DECLARE @v_column_name        NVARCHAR(128)
  DECLARE @v_column_name_2      NVARCHAR(128)
  DECLARE @v_column_name_3      NVARCHAR(128)
  DECLARE @v_column_name_4      NVARCHAR(128)
  DECLARE @v_identity_column    NVARCHAR(128) = NULL
  DECLARE @v_identity_flag      BIT     = 0
  DECLARE @v_loop_count         TINYINT = 0
  DECLARE @v_column_count       TINYINT = 0
  DECLARE @v_pk_column_count    TINYINT = 0
  DECLARE @v_difference_count   INT     = 0
  DECLARE @v_sql_diff_check     NVARCHAR(max)
  DECLARE @ParameterDefCount    NVARCHAR(max)
  DECLARE @ParameterDef         NVARCHAR(max)
  DECLARE @v_key                NVARCHAR(2)

/*
  =============================================================================
   Initialise
  =============================================================================
*/  
  SET @ParameterDefCount = '@p_table_name   NVARCHAR(128),
							@rec_count      INT OUTPUT'
							
  SET @ParameterDef = '@p_sql   NVARCHAR(max)'

  SELECT @v_message = cast(cast(SYSDATETIMEOFFSET() at time zone 'GMT Standard Time' as datetime) as varchar)
 
  PRINT '================================================================'
  PRINT '== Start of Automated Testing : ' + @v_message
  PRINT '================================================================'

/*
  =============================================================================
  Main process
  =============================================================================
*/
  --
  -- Validate the @p_key parameter value passed to the process
  --
  IF (  @p_key IS NOT NULL and @p_key != 'NK')
  BEGIN
    SET @v_message = 'ERROR: ' + 'Valid value for @p_key is null or NK';
	
	THROW 50000, @v_message, 1
  END
  
  IF @p_key IS NULL 
    SET @v_key = 'PK'
  ELSE
    SET @v_key = 'NK'
  
  --
  -- Confirm the table exists in STAGE_CDI & Z_IICS_ORACLE
  --
  IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = 'STAGE_CDI' and TABLE_NAME = @p_table_name)
  BEGIN
    SET @v_message = 'ERROR: ' + @p_table_name + ' does not exist in STAGE_CDI';
	
	THROW 50000, @v_message, 1
  END
  
  IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = 'Z_IICS_ORACLE' and TABLE_NAME = @p_table_name)
  BEGIN
    SET @v_message = 'ERROR: ' + @p_table_name + ' does not exist in Z_IICS_ORACLE';
    
    THROW 50000, @v_message, 2
  END
  
  /*
  ============================================================================
  Check source and target tables to confirm both have the same set of 
  records for primary key / unique index
  ============================================================================
  */
  
  PRINT ''
  PRINT '*************************************************************************'
  PRINT 'Verifying the key values match between source and target'
  PRINT '*************************************************************************'
  --
  -- Check if the table has an identity column
  --
  SELECT @v_identity_column = IC.NAME
    FROM SYS.IDENTITY_COLUMNS IC
   INNER JOIN SYS.TABLES T
      ON T.OBJECT_ID = IC.OBJECT_ID
   WHERE T.NAME = @P_TABLE_NAME
   
  --
  -- If check is to be done against primary key, get the list of primary key(s)
  -- for the table
  --
  IF @v_key = 'PK'
  BEGIN
    --
    -- Get the count of columns that make up the primary key
    --
    SELECT @v_pk_column_count = count(1)
      FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
     WHERE TABLE_NAME  = @p_table_name 
       AND TABLE_SCHEMA = 'STAGE_CDI  '
       AND CONSTRAINT_NAME LIKE '%_PK'
    
    IF @v_pk_column_count = 0
    BEGIN
      SET @v_message =  @p_table_name + ' does not have a primary key. Column level comparison cannot be carried out via the automated testing route';
      THROW 50000, @v_message, 1
    END  -- @v_column_count = 0    
     
    DECLARE pk_cursor CURSOR FOR
	  SELECT COLUMN_NAME
	    FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
	   WHERE TABLE_NAME  = @p_table_name 
	     AND TABLE_SCHEMA = 'STAGE_CDI'
	     AND CONSTRAINT_NAME LIKE '%_PK'
	   ORDER BY ORDINAL_POSITION

    SET @v_loop_count = 0
   
    OPEN pk_cursor

    FETCH NEXT from pk_cursor into @v_pk_column

    WHILE @@FETCH_STATUS = 0
    BEGIN
	  SET @v_loop_count = @v_loop_count + 1
	
	  IF @v_loop_count = @v_pk_column_count
	  BEGIN
	    SET @v_pk_column_list = @v_pk_column_list + @v_pk_column
	    SET @v_temp_tab_pk_column = @v_temp_tab_pk_column + 'PK_' + @v_pk_column
	    SET @v_as_pk_column = @v_as_pk_column + @v_pk_column + ' as PK_' + @v_pk_column
	  END
	  ELSE
	  BEGIN
       SET @v_pk_column_list = @v_pk_column_list + @v_pk_column + ','
       SET @v_temp_tab_pk_column = @v_temp_tab_pk_column + 'PK_' + @v_pk_column + ','
      SET @v_as_pk_column = @v_as_pk_column + @v_pk_column + ' as PK_' + @v_pk_column + ','
      END  -- @v_loop_count = @v_column_count
    
      FETCH NEXT from pk_cursor into @v_pk_column
    END -- @@FETCH_STATUS = 0

    CLOSE pk_cursor

    DEALLOCATE pk_cursor
  END  -- @v_key = 'PK'
  
  IF @v_key = 'NK'
  BEGIN
    --
    -- Get the count of columns that make up the unique key
    --
    SELECT @v_pk_column_count = count(1)
      FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
     WHERE TABLE_NAME  = @p_table_name 
       AND TABLE_SCHEMA = 'STAGE_CDI  '
       AND CONSTRAINT_NAME LIKE '%_UI_%'
       
    IF @v_pk_column_count = 0
    BEGIN
      SET @v_message =  @p_table_name + ' does not have a unique key. Column level comparison cannot be carried out via the automated testing route';
      THROW 50000, @v_message, 1
    END  -- @v_column_count = 0         

    DECLARE pk_cursor CURSOR FOR
	  SELECT COLUMN_NAME
	    FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
	   WHERE TABLE_NAME  = @p_table_name 
	     AND TABLE_SCHEMA = 'STAGE_CDI'
	     AND CONSTRAINT_NAME LIKE '%_UI_%'
	   ORDER BY ORDINAL_POSITION

    SET @v_loop_count = 0
   
    OPEN pk_cursor

    FETCH NEXT from pk_cursor into @v_pk_column

    WHILE @@FETCH_STATUS = 0
    BEGIN
	  SET @v_loop_count = @v_loop_count + 1
	
	  IF @v_loop_count = @v_pk_column_count
	  BEGIN
	    SET @v_pk_column_list = @v_pk_column_list + @v_pk_column
	    SET @v_temp_tab_pk_column = @v_temp_tab_pk_column + 'PK_' + @v_pk_column
	    SET @v_as_pk_column = @v_as_pk_column + @v_pk_column + ' as PK_' + @v_pk_column
	  END
	  ELSE
	  BEGIN
       SET @v_pk_column_list = @v_pk_column_list + @v_pk_column + ','
       SET @v_temp_tab_pk_column = @v_temp_tab_pk_column + 'PK_' + @v_pk_column + ','
      SET @v_as_pk_column = @v_as_pk_column + @v_pk_column + ' as PK_' + @v_pk_column + ','
      END  -- @v_loop_count = @v_column_count
    
      FETCH NEXT from pk_cursor into @v_pk_column
    END -- @@FETCH_STATUS = 0

    CLOSE pk_cursor

    DEALLOCATE pk_cursor
  END  -- @v_key = 'NK'
  
  --
  -- If the table has an identity column and the primary key/unique index is 
  -- part of the identity column, then not possible to carry out checks at the
  -- key level between source and target
  --
  IF (    @v_identity_column IS NOT NULL 
      AND CHARINDEX(@v_identity_column, @v_pk_column_list) > 0)
  BEGIN
    SET @v_pk_column_list = @v_identity_column
    SET @v_temp_tab_pk_column = 'PK_' + @v_identity_column
    SET @v_as_pk_column = @v_identity_column + ' as PK_' + @v_identity_column
    
    PRINT ''
    PRINT '-------------------------------------------------------------------------'
    PRINT '-- WARNING: Target table has an identity column: ' + @v_identity_column + ' which is also the key for comparing the data'
    PRINT '--'
    PRINT '-- Cannot carry out check between source and target at primary/unique key level'
    PRINT '--'
    PRINT '-- Carrying out simple row count check'
    PRINT '-------------------------------------------------------------------------'
    
    -- 
    -- Get the number of records in the STAGE_CDI table
    --
    SET @v_sql = 'SELECT @rec_count = COUNT(1) FROM STAGE_CDI.' + @p_table_name

    EXECUTE sp_executesql @v_sql, @ParameterDefCount, @p_table_name=@p_table_name, @rec_count=@v_source_rec_count OUTPUT

    -- 
    -- Get the number of records in the Z_IICS_ORACLE table
    --
    SET @v_sql = 'SELECT @rec_count = COUNT(1) FROM Z_IICS_ORACLE.' + @p_table_name
      
    EXECUTE sp_executesql @v_sql, @ParameterDefCount, @p_table_name=@p_table_name, @rec_count=@v_target_rec_count OUTPUT

    IF @v_source_rec_count <> @v_target_rec_count
    BEGIN
      PRINT ''
      PRINT '--------------------------------------------------------------------'
      PRINT '-- FAILURE'
      PRINT '--' 
    
      SET @v_message =  cast(@v_source_rec_count as VARCHAR(10))
    
      PRINT '-- No of records in SQL DB for ' + @p_table_name + ': ' + @v_message
    
      SET @v_message =  cast(@v_target_rec_count as VARCHAR(10))
    
      PRINT '-- No of records in Oracle STAGE_CRM for ' + @p_table_name + ': ' + @v_message
      PRINT '--'
      PRINT '-- Source and target counts do not match - test failed'
      PRINT '--------------------------------------------------------------------'
    END
    ELSE
    BEGIN
      PRINT ''
      PRINT '+++++++++++++++++++++++++++++++++++++++++++++'
      PRINT '++ INFORMATION'
      PRINT '++' 
    
      SET @v_message =  cast(@v_source_rec_count as VARCHAR(10))
    
      PRINT '++ No of records in SQL DB for ' + @p_table_name + ': ' + @v_message
    
      SET @v_message =  cast(@v_target_rec_count as VARCHAR(10))
    
      PRINT '++ No of records in Oracle STAGE_CRM.' + @p_table_name + ': ' + @v_message
      PRINT '++'
      PRINT '++ Source and target counts match - test successful'
      PRINT '+++++++++++++++++++++++++++++++++++++++++++++'
    END

    --
    -- Create the temporary table #missing_pk_recs
    --  
    IF OBJECT_ID('tempdb..##missing_pk_recs') IS NOT NULL
      DROP TABLE ##missing_pk_recs

    SET @v_sql = 'select * into ##missing_pk_recs '
    SET @v_sql = @v_sql + 'from ( select ' + @v_pk_column_list + ' from STAGE_CDI.' + @p_table_name + ' where 1 = 2) src'

    EXECUTE sp_executesql @v_sql
    
    SET @v_identity_flag = 1
    
    SET @p_column_exclusion = @v_identity_column
    
    GOTO BRANCH_CROSS_CHECK
  END  -- @v_identity_column IS NOT NULL AND @v_identity_column = @v_pk_column_list
  
  --
  -- Carry out checks against tables at the primary key/unique index level
  --
  IF OBJECT_ID('tempdb..##mismatched_stage_cdi') IS NOT NULL
    DROP TABLE ##mismatched_stage_cdi
 
  --
  -- Check if record exists in STAGE_CDI but not in Z_IICS_ORACLE
  --
  SET @v_sql = 'select @rec_count = count(1) from '
  SET @v_sql = @v_sql + '(select ' + @v_as_pk_column + ' from STAGE_CDI.' + @p_table_name
  SET @v_sql = @v_sql + ' EXCEPT '
  SET @v_sql = @v_sql + 'select ' + @v_as_pk_column + ' from Z_IICS_ORACLE.' + @p_table_name + ') STAGE_CDI'

  EXECUTE sp_executesql @v_sql, @ParameterDefCount, @p_table_name=@p_table_name, @rec_count=@v_target_rec_count OUTPUT

  IF @v_target_rec_count > 0
  BEGIN
    SET @v_sql = 'select ' + @v_temp_tab_pk_column + ' into ##mismatched_stage_cdi from '
    SET @v_sql = @v_sql + '(select ' + @v_as_pk_column + ' from STAGE_CDI.' + @p_table_name
    SET @v_sql = @v_sql + ' EXCEPT '
    SET @v_sql = @v_sql + 'select ' + @v_as_pk_column + ' from Z_IICS_ORACLE.' + @p_table_name + ') STAGE_CDI'

    EXECUTE sp_executesql @v_sql
  END 

  IF OBJECT_ID('tempdb..##mismatched_stage_crm') IS NOT NULL
    DROP TABLE ##mismatched_stage_crm
 
  --
  -- Check if record exists in Z_IICS_ORACLE but not in STAGE_CDI
  --
  SET @v_sql = 'select @rec_count = count(1) from '
  SET @v_sql = @v_sql + '(select ' + @v_as_pk_column + ' from Z_IICS_ORACLE.' + @p_table_name
  SET @v_sql = @v_sql + ' EXCEPT '
  SET @v_sql = @v_sql + 'select ' + @v_as_pk_column + ' from STAGE_CDI.' + @p_table_name + ') STAGE_CDI'

  EXECUTE sp_executesql @v_sql, @ParameterDefCount, @p_table_name=@p_table_name, @rec_count=@v_source_rec_count OUTPUT

  IF @v_source_rec_count > 0
  BEGIN
    SET @v_sql = 'select ' + @v_temp_tab_pk_column + ' into ##mismatched_stage_crm from '
    SET @v_sql = @v_sql + '(select ' + @v_as_pk_column + ' from Z_IICS_ORACLE.' + @p_table_name
    SET @v_sql = @v_sql + ' EXCEPT '
    SET @v_sql = @v_sql + 'select ' + @v_as_pk_column + ' from STAGE_CDI.' + @p_table_name + ') STAGE_CDI'

    EXECUTE sp_executesql @v_sql
  END

  IF OBJECT_ID('tempdb..##mismatched_stage_cdi') IS NOT NULL
  BEGIN
    PRINT ''
    PRINT '------------------------------------------------------------------------------------------------'
    PRINT '-- WARNING'
    PRINT '--'
    PRINT 'The record(s) with the key (' + @v_pk_column_list + ') listed below exist in SQL DB but not in Oracle STAGE_CRM:'
    
    DECLARE stage_cdi_cursor CURSOR FOR
      select * from ##mismatched_stage_cdi

    OPEN stage_cdi_cursor

    IF @v_pk_column_count = 1
    BEGIN
      FETCH NEXT from stage_cdi_cursor into @v_column_name

      WHILE @@FETCH_STATUS = 0
      BEGIN
        PRINT @v_column_name
        
        FETCH NEXT from stage_cdi_cursor into @v_column_name
      END  -- @@FETCH_STATUS = 0
    END  -- @v_pk_column_count = 1
    
    IF @v_pk_column_count = 2
    BEGIN
      FETCH NEXT from stage_cdi_cursor into @v_column_name, @v_column_name_2

      WHILE @@FETCH_STATUS = 0
      BEGIN
        PRINT @v_column_name + ' ' + @v_column_name_2

        FETCH NEXT from stage_cdi_cursor into @v_column_name, @v_column_name_2
      END  -- @@FETCH_STATUS = 0
    END  -- @v_pk_column_count = 2
    
    IF @v_pk_column_count = 3
    BEGIN
      FETCH NEXT from stage_cdi_cursor into @v_column_name, @v_column_name_2, @v_column_name_3

      WHILE @@FETCH_STATUS = 0
      BEGIN
        PRINT @v_column_name + ' ' + @v_column_name_2 + ' ' + @v_column_name_3

        FETCH NEXT from stage_cdi_cursor into @v_column_name, @v_column_name_2, @v_column_name_3
      END  -- @@FETCH_STATUS = 0
    END  -- @v_pk_column_count = 2
    
    CLOSE stage_cdi_cursor
      
    PRINT '------------------------------------------------------------------------------------------------'

    DEALLOCATE stage_cdi_cursor
  END 
   
  IF OBJECT_ID('tempdb..##mismatched_stage_crm') IS NOT NULL
  BEGIN
    PRINT ''
    PRINT '------------------------------------------------------------------------------------------------'
    PRINT '-- WARNING'
    PRINT '--'    
    PRINT 'The record(s) with the key (' + @v_pk_column_list + ') listed below exist in Oracle STAGE_CRM but not in SQL DB:'

    DECLARE stage_crm_cursor CURSOR FOR
      select * from ##mismatched_stage_crm

    OPEN stage_crm_cursor

    IF @v_pk_column_count = 1
    BEGIN
      FETCH NEXT from stage_crm_cursor into @v_column_name

      WHILE @@FETCH_STATUS = 0
      BEGIN
        PRINT @v_column_name
        
        FETCH NEXT from stage_crm_cursor into @v_column_name
      END  -- @@FETCH_STATUS = 0
    END  -- @v_pk_column_count = 1

        IF @v_pk_column_count = 2
    BEGIN
      FETCH NEXT from stage_crm_cursor into @v_column_name, @v_column_name_2

      WHILE @@FETCH_STATUS = 0
      BEGIN
        PRINT @v_column_name + ' ' + @v_column_name_2

        FETCH NEXT from stage_crm_cursor into @v_column_name, @v_column_name_2
      END  -- @@FETCH_STATUS = 0
    END  -- @v_pk_column_count = 2
    
    IF @v_pk_column_count = 3
    BEGIN
      FETCH NEXT from stage_crm_cursor into @v_column_name, @v_column_name_2, @v_column_name_3

      WHILE @@FETCH_STATUS = 0
      BEGIN
        PRINT @v_column_name + ' ' + @v_column_name_2 + ' ' + @v_column_name_3

        FETCH NEXT from stage_crm_cursor into @v_column_name, @v_column_name_2, @v_column_name_3
      END  -- @@FETCH_STATUS = 0
    END  -- @v_pk_column_count = 2

    CLOSE stage_crm_cursor

    DEALLOCATE stage_crm_cursor
    
    PRINT '------------------------------------------------------------------------------------------------'
  END 

  --
  -- Create the temporary table #missing_pk_recs
  --  
  IF OBJECT_ID('tempdb..##missing_pk_recs') IS NOT NULL
    DROP TABLE ##missing_pk_recs

  SET @v_sql = 'select * into ##missing_pk_recs '
  SET @v_sql = @v_sql + 'from ( select ' + @v_pk_column_list + ' from STAGE_CDI.' + @p_table_name + ' where 1 =2) src'

  EXECUTE sp_executesql @v_sql
    
  --
  -- Combine the data from the two temporary tables into 1 temporary table if either or both exist
  --
  IF OBJECT_ID('tempdb..##mismatched_stage_cdi') IS NOT NULL 
  BEGIN
    insert into ##missing_pk_recs
    select * from ##mismatched_stage_cdi
  END

  IF OBJECT_ID('tempdb..##mismatched_stage_crm') IS NOT NULL 
  BEGIN
    insert into ##missing_pk_recs
    select * from ##mismatched_stage_crm
  END
  
  --
  -- Drop the temp tables if they exist
  --
  IF OBJECT_ID('tempdb..##mismatched_stage_cdi') IS NOT NULL
    DROP TABLE ##mismatched_stage_cdi
    
  IF OBJECT_ID('tempdb..##mismatched_stage_crm') IS NOT NULL
    DROP TABLE ##mismatched_stage_crm

  -- 
  -- Check if there are any records in the temporary table ##missing_pk_recs
  -- 
  -- No point in checking table counts from source and target match if that
  -- is the case
  --
  SELECT @v_row_count = count(1) from ##missing_pk_recs
  
  IF @v_row_count > 0
  BEGIN
    SET @v_missing_pk_flag = 1
    
    PRINT ''
    PRINT '***********************************************************************************************'
    PRINT '** INFORMATION'
    PRINT '**'
    PRINT '** Due to mismatch between source and target at key level, skipping record count check'
    PRINT '***********************************************************************************************'
    
    GOTO BRANCH_CROSS_CHECK
  END
 
  -- 
  -- Get the number of records in the STAGE_CDI table
  --
  SET @v_sql = 'SELECT @rec_count = COUNT(1) FROM STAGE_CDI.' + @p_table_name
      
  EXECUTE sp_executesql @v_sql, @ParameterDefCount, @p_table_name=@p_table_name, @rec_count=@v_source_rec_count OUTPUT
  
  -- 
  -- Get the number of records in the Z_IICS_ORACLE table
  --
  SET @v_sql = 'SELECT @rec_count = COUNT(1) FROM Z_IICS_ORACLE.' + @p_table_name
      
  EXECUTE sp_executesql @v_sql, @ParameterDefCount, @p_table_name=@p_table_name, @rec_count=@v_target_rec_count OUTPUT
  
  IF @v_source_rec_count <> @v_target_rec_count
  BEGIN
    PRINT ''
    PRINT '--------------------------------------------------------------------'
    PRINT '-- FAILURE'
    PRINT '--' 
    
    SET @v_message =  cast(@v_source_rec_count as VARCHAR(10))
    
    PRINT '-- No of records in SQL DB for ' + @p_table_name + ': ' + @v_message
    
    SET @v_message =  cast(@v_target_rec_count as VARCHAR(10))
    
    PRINT '-- No of records in Oracle STAGE_CRM for' + @p_table_name + ': ' + @v_message
    PRINT '--'
    PRINT '-- Source and target counts do not match - test failed'
    PRINT '--------------------------------------------------------------------'
  END
  ELSE
  BEGIN
    PRINT ''
    PRINT '+++++++++++++++++++++++++++++++++++++++++++++'
    PRINT '++ INFORMATION'
    PRINT '++' 
    
    SET @v_message =  cast(@v_source_rec_count as VARCHAR(10))
    
    PRINT '++ No of records in SQL DB for ' + @p_table_name + ': ' + @v_message
    
    SET @v_message =  cast(@v_target_rec_count as VARCHAR(10))
    
    PRINT '++ No of records in Oracle STAGE_CRM for ' + @p_table_name + ': ' + @v_message
    PRINT '++'
    PRINT '++ Source and target counts match - test successful'
    PRINT '+++++++++++++++++++++++++++++++++++++++++++++'
  END

/* ============================================================================
   Cross check all columns (except for the ones in the exclusion list to spot
   any differences
   ============================================================================
 */
 
  BRANCH_CROSS_CHECK:
  
  PRINT ''
  PRINT '*************************************************************************'
  PRINT 'Verifying the column values between SQL DB and Oracle STAGE_CRM match'
  PRINT '*************************************************************************'

  --
  -- Set up the column list cursor and count of the columns in the table
  --
  IF @p_column_exclusion is NULL
  BEGIN
    DECLARE column_cursor CURSOR FOR
      SELECT COLUMN_NAME
        FROM INFORMATION_SCHEMA.COLUMNS
       WHERE TABLE_SCHEMA = 'STAGE_CDI'
         AND TABLE_NAME = @p_table_name
       ORDER BY ORDINAL_POSITION
       
    SELECT @v_column_count =
           COUNT(1)
      FROM INFORMATION_SCHEMA.COLUMNS
     WHERE TABLE_SCHEMA = 'STAGE_CDI'
       AND TABLE_NAME = @p_table_name 
  END
  ELSE
  BEGIN
    DECLARE column_cursor CURSOR FOR
      SELECT COLUMN_NAME
        FROM INFORMATION_SCHEMA.COLUMNS
        LEFT OUTER JOIN STRING_SPLIT(@p_column_exclusion, ',')
          ON trim(value) = COLUMN_NAME
       WHERE TABLE_SCHEMA = 'STAGE_CDI'
         AND TABLE_NAME = @p_table_name
         AND trim(value) is NULL
       ORDER BY ORDINAL_POSITION
       
    SELECT @v_column_count =
           COUNT(1)
      FROM INFORMATION_SCHEMA.COLUMNS
      LEFT OUTER JOIN STRING_SPLIT(@p_column_exclusion, ',')
          ON trim(value) = COLUMN_NAME
     WHERE TABLE_SCHEMA = 'STAGE_CDI'
       AND TABLE_NAME = @p_table_name
       AND trim(value) is NULL
  END

  OPEN column_cursor

  FETCH NEXT from column_cursor into @v_column_name

  SET @v_sql = ''
  SET @v_sql_src = ''
  SET @v_sql_trg = ''
  SET @v_loop_count = 1
  
  WHILE @@FETCH_STATUS = 0
  BEGIN
    IF @v_loop_count <> @v_column_count
    BEGIN
      SET @v_sql = @v_sql + CHAR(10) + CHAR(9) + 'UA.' + @v_column_name + ','
      SET @v_sql_src = @v_sql_src + CHAR(10) + CHAR(9) + CHAR(9) + 'src.' + @v_column_name + ','
      SET @v_sql_trg = @v_sql_trg + CHAR(10) + CHAR(9) + CHAR(9) + 'trg.' + @v_column_name + ','
    END
    ELSE
    BEGIN
      SET @v_sql = @v_sql + CHAR(10) + CHAR(9) + 'UA.' + @v_column_name 
      SET @v_sql_src = @v_sql_src + CHAR(10) + CHAR(9) + CHAR(9) + 'src.' + @v_column_name
      SET @v_sql_trg = @v_sql_trg + CHAR(10) + CHAR(9) + CHAR(9) + 'trg.' + @v_column_name
    END
    
    SET @v_loop_count = @v_loop_count + 1

    FETCH NEXT from column_cursor into @v_column_name
  END  -- @@FETCH_STATUS = 0

  CLOSE column_cursor
  
  SET @v_sql_diff_check = 'select @rec_count = COUNT(1)'
  SET @v_sql_diff_check = @v_sql_diff_check + CHAR(10) + 'from'
  SET @v_sql_diff_check = @v_sql_diff_check + CHAR(10) + '(select' + @v_sql
  SET @v_sql_diff_check = @v_sql_diff_check + CHAR(10) + 'from'
  
  IF @v_missing_pk_flag = 0
  BEGIN
    SET @v_sql_diff_check = @v_sql_diff_check + CHAR(10) + CHAR(9) + '(select ' + @v_sql_src
    SET @v_sql_diff_check = @v_sql_diff_check + CHAR(10) + CHAR(9) + 'from'
    SET @v_sql_diff_check = @v_sql_diff_check + CHAR(10) + CHAR(9) + CHAR(9) + 'STAGE_CDI.' + @p_table_name + ' src'
  END
  ELSE
  BEGIN
    SET @v_sql_diff_check = @v_sql_diff_check + CHAR(10) + CHAR(9) + '(select ' + @v_sql_src
    SET @v_sql_diff_check = @v_sql_diff_check + CHAR(10) + CHAR(9) + 'from'
    SET @v_sql_diff_check = @v_sql_diff_check + CHAR(10) + CHAR(9) + CHAR(9) + 'STAGE_CDI.' + @p_table_name + ' src'
    SET @v_sql_diff_check = @v_sql_diff_check + CHAR(10) + CHAR(9) + 'where'
    SET @v_sql_diff_check = @v_sql_diff_check + CHAR(10) + CHAR(9) + CHAR(9) + 'concat(' + @v_pk_column_list + ','+ '''' + '' + '''' + ') not in (select concat(' + @v_pk_column_list + ',' + '''' + '' + '''' + ') from ##missing_pk_recs)'
  END
  
  SET @v_sql_diff_check = @v_sql_diff_check + CHAR(10) + CHAR(9) + 'UNION ALL'
  
  IF @v_missing_pk_flag = 0
  BEGIN
    SET @v_sql_diff_check = @v_sql_diff_check + CHAR(10) + CHAR(9) + 'select ' + @v_sql_trg 
    SET @v_sql_diff_check = @v_sql_diff_check + CHAR(10) + CHAR(9) + 'from' 
    SET @v_sql_diff_check = @v_sql_diff_check + CHAR(10) + CHAR(9) + CHAR(9) + 'Z_IICS_ORACLE.' + @p_table_name + ' trg) UA'
  END
  ELSE
  BEGIN
    SET @v_sql_diff_check = @v_sql_diff_check + CHAR(10) + CHAR(9) + 'select ' + @v_sql_trg
    SET @v_sql_diff_check = @v_sql_diff_check + CHAR(10) + CHAR(9) + 'from'
    SET @v_sql_diff_check = @v_sql_diff_check + CHAR(10) + CHAR(9) + CHAR(9) + 'Z_IICS_ORACLE.' + @p_table_name + ' trg'
    SET @v_sql_diff_check = @v_sql_diff_check + CHAR(10) + CHAR(9) + 'where'
    SET @v_sql_diff_check = @v_sql_diff_check + CHAR(10) + CHAR(9) + CHAR(9) + 'concat(' + @v_pk_column_list + ','+ '''' + '' + '''' + ') not in (select concat(' + @v_pk_column_list + ',' + '''' + '' + '''' + ') from ##missing_pk_recs)) UA'
  END
  
  SET @v_sql_diff_check = @v_sql_diff_check + CHAR(10) + 'group by'
  SET @v_sql_diff_check = @v_sql_diff_check + @v_sql
  SET @v_sql_diff_check = @v_sql_diff_check + CHAR(10) + 'having count(1) = 1'
  SET @v_sql_diff_check = @v_sql_diff_check + CHAR(10) + ') as DIFFERENCE_COUNT'

  PRINT ''
  PRINT @v_sql_diff_check

  BEGIN TRY  
    EXECUTE sp_executesql @v_sql_diff_check, @ParameterDefCount, @p_table_name=@p_table_name, @rec_count=@v_difference_count OUTPUT
  END TRY
  
  BEGIN CATCH
    SET @v_message =  ERROR_MESSAGE();
      
    THROW 50000, @v_message, 1;
  
  END CATCH

  IF @v_difference_count = 0
  BEGIN
    IF @v_missing_pk_flag = 0
    BEGIN
      PRINT ''
      PRINT '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
      PRINT '++ INFORMATION'
      PRINT '++' 
      PRINT '++ Data in SQL DB and Oracle STAGE_CRM for ' + @p_table_name + ' have an exact match - test successful'
      PRINT '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
    END
    ELSE
    BEGIN
      PRINT ''
      PRINT '----------------------------------------------------------------------------------------------'
      PRINT '-- INFORMATION'
      PRINT '--' 
      PRINT '-- Data in SQL DB and Oracle STAGE_CRM for ' + @p_table_name + ' have an exact match for common record set'
      PRINT '--'
      PRINT '-- Overall test has failed due to mismatch found at primary key level'
      PRINT '----------------------------------------------------------------------------------------------'
    END
    
    GOTO BRANCH_END
  END
  ELSE
  BEGIN
    PRINT ''
    PRINT '------------------------------------------------------------------------------------------------------------'
    PRINT '-- WARNING'
    PRINT '--' 
    PRINT '-- Variance found between SQL DB and Oracle STAGE_CRM for ' + @p_table_name + ' by ' + CAST(@v_difference_count AS VARCHAR(10)) + ' records'
    PRINT '------------------------------------------------------------------------------------------------------------'
  END  -- @v_difference_count = 0

  -- 
  -- If table has an identity column, verifying at column level not possible
  --
  IF @v_identity_flag = 1
  BEGIN
    PRINT ''
    PRINT '------------------------------------------------------------------------------------------------------------'
    PRINT '-- WARNING'
    PRINT '--'
    PRINT '-- Cannot carry out checks at column level between source and target due to the presence of identity column'
    PRINT '-- Data issue will have to be verified manually'
    PRINT '------------------------------------------------------------------------------------------------------------'
    GOTO BRANCH_END
  END
  --
  --Since issue has been identified, review each column to find the issue
  --
  PRINT ''
  PRINT '*********************************************************'
  PRINT 'Verifying each column for match between source and target'
  PRINT '*********************************************************'
 
  OPEN column_cursor

  FETCH NEXT from column_cursor into @v_column_name

  WHILE @@FETCH_STATUS = 0
  BEGIN
    PRINT ''
    PRINT '** Checking difference in data for: ' + @v_column_name
    
    --
    -- Create temporary table to store the result
    --
    IF OBJECT_ID('tempdb..##mismatched_data') IS NOT NULL
      DROP TABLE ##mismatched_data

    SET @v_sql = 'select ' + @v_temp_tab_pk_column + ', STAGE_CDI_' + @v_column_name + ', STAGE_CRM_'+ @v_column_name + ' into ##mismatched_data from ('
    SET @v_sql = + @v_sql + ' select * from ('
    SET @v_sql = @v_sql + 'select ' + @v_as_pk_column + ',' + @v_column_name + ', '+ '''' + 'STAGE_CDI_'+ @v_column_name + '''' + ' as SOURCE_SYSTEM'
    SET @v_sql = @v_sql + ' from STAGE_CDI.' + @p_table_name
    SET @v_sql = @v_sql + ' where concat (' + @v_pk_column_list + ','+ '''' + '' + '''' + ') not in (select concat(' + @v_pk_column_list + ','+ '''' + '' + '''' + ') from ##missing_pk_recs)'
    SET @v_sql = @v_sql + ' except '
    SET @v_sql = @v_sql + ' select ' + @v_as_pk_column + ',' + @v_column_name + ', '+ '''' + 'STAGE_CDI_'+ @v_column_name + '''' + ' as SOURCE_SYSTEM'
    SET @v_sql = @v_sql + ' from Z_IICS_ORACLE.' + @p_table_name
    SET @v_sql = @v_sql + ' where concat (' + @v_pk_column_list + ','+ '''' + '' + '''' + ') not in (select concat(' + @v_pk_column_list + ','+ '''' + '' + '''' + ') from ##missing_pk_recs)'
    SET @v_sql = @v_sql + ' union all'
    SET @v_sql = @v_sql + ' select ' + @v_as_pk_column + ',' + @v_column_name + ', ' + '''' + 'STAGE_CRM_'+ @v_column_name + '''' + ' as SOURCE_SYSTEM'
    SET @v_sql = @v_sql + ' from Z_IICS_ORACLE.' + @p_table_name
    SET @v_sql = @v_sql + ' where concat (' + @v_pk_column_list + ','+ '''' + '' + '''' + ') not in (select concat(' + @v_pk_column_list + ','+ '''' + '' + '''' + ') from ##missing_pk_recs)'
    SET @v_sql = @v_sql + ' except '
    SET @v_sql = @v_sql + ' select ' + @v_as_pk_column + ',' + @v_column_name + ', ' + '''' + 'STAGE_CRM_'+ @v_column_name + '''' + ' as SOURCE_SYSTEM'
    SET @v_sql = @v_sql + ' from STAGE_CDI.' + @p_table_name
    SET @v_sql = @v_sql + ' where concat (' + @v_pk_column_list + ','+ '''' + '' + '''' + ') not in (select concat(' + @v_pk_column_list + ','+ '''' + '' + '''' + ') from ##missing_pk_recs)) diff'
    SET @v_sql = @v_sql + ' PIVOT (max(' + @v_column_name + ') for SOURCE_SYSTEM in (STAGE_CDI_'+ @v_column_name + ', STAGE_CRM_' + @v_column_name + ')) as PivotTable) diff_rows'

    EXECUTE sp_executesql @v_sql
    
    SET @v_difference_count = @@ROWCOUNT
    
    IF @v_difference_count > 0
    BEGIN
      PRINT '-- WARNING: Number of records found to differ for ' + @v_column_name + ': ' + cast(@v_difference_count as VARCHAR(5))
      PRINT '-- Please check Results tab for the details'
      
      SELECT * 
        FROM ##mismatched_data
    END
    ELSE
    BEGIN
      PRINT '** No difference found in data for: ' + @v_column_name
    END    -- @v_difference_count > 0

    FETCH NEXT from column_cursor into @v_column_name
  END  -- @@FETCH_STATUS = 0

  CLOSE column_cursor

  DEALLOCATE column_cursor
  
  BRANCH_END:
  
  --
  -- Drop the temporary tables if they still exist
  --
  IF OBJECT_ID('tempdb..##mismatched_data') IS NOT NULL
    DROP TABLE ##mismatched_data
      
  IF OBJECT_ID('tempdb..##mismatched_data') IS NOT NULL
    DROP TABLE ##missing_pk_recs
    
  --
  -- Deallocate column_cursor if required
  -- 
  IF CURSOR_STATUS('global','column_cursor') >=-1
    DEALLOCATE column_cursor
      
  SELECT @v_message = cast(cast(SYSDATETIMEOFFSET() at time zone 'GMT Standard Time' as datetime) as varchar)

  PRINT ''
  PRINT '================================================================'
  PRINT '== End of Automated Testing : ' + @v_message
  PRINT '================================================================'
END;  -- procedure