CREATE PROCEDURE Z_ADF_SFDC.PRC_AUTOMATED_TESTING
  @p_table_name         NVARCHAR(128),
  @p_column_exclusion   NVARCHAR(max) = NULL,
  @p_date_filter        NVARCHAR(20) = NULL
/*
Author     : Rizaul Kamal
Date       : 26/07/2023

Description: Automate the testing of data for objects in Salesforce

Input      : TABLE_NAME - The name of the table to be tested
             COLUMN_EXCLUSION - List of fields to exclude from testing
             DATE_FILTER - Only process data created on or after this date 

Output     : Status code - 0 = Success
                           1 = Failure

-------------------------------------------------------------------------------
Version   Date        Description of change
-------   ----------  ---------------------------------------------------------
0.1       26/07/2023  Added process to filter date by date                      

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
  DECLARE @ParameterMaxDate     NVARCHAR(max)
  DECLARE @ParameterDef         NVARCHAR(max)
  DECLARE @v_date_filter        NVARCHAR(20) = '1900-01-01 00:00:00'

/*
  =============================================================================
   Initialise
  =============================================================================
*/  
  SET @ParameterDefCount = '@p_table_name   NVARCHAR(128),
                            @rec_count      INT OUTPUT'

  SET @ParameterMaxDate = '@p_table_name   NVARCHAR(128),
                           @max_date       DATETIME2 OUTPUT'
                            
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
  -- Confirm the table exists in Z_ADF_SFDC
  --
  IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = 'Z_ADF_SFDC' and TABLE_NAME = @p_table_name)
  BEGIN
    SET @v_message = 'ERROR: ' + @p_table_name + ' does not exist in Z_ADF_SFDC';
    
    THROW 50000, @v_message, 1
  END
  
  --
  -- Assign value to variable if it contains a value
  --
  IF @p_date_filter is not NULL
    SET @v_date_filter = @p_date_filter
 
/*
  ============================================================================
  Check source and target tables to confirm both have the same set of 
  primary key records
  ============================================================================
*/
  PRINT ''
  PRINT '*************************************************************************'
  PRINT 'Verifying the primary key values match between source and target'
  PRINT '*************************************************************************'

  --
  -- Get the count of columns that make up the primary key
  --
  SELECT @v_pk_column_count = count(1)
    FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
   WHERE TABLE_NAME  = @p_table_name 
     AND TABLE_SCHEMA = 'Z_ADF_SFDC'
     AND CONSTRAINT_NAME LIKE '%_PK'
     
  IF @v_pk_column_count = 0
  BEGIN
    SET @v_message =  @p_table_name + ' does not have a primary key. Column level comparison cannot be carried out via the automated testing route';
    THROW 50000, @v_message, 1
  END  -- @v_column_count = 0

  --
  -- Get the list of primary key(s) for the table
  --
  DECLARE pk_cursor CURSOR FOR
    SELECT COLUMN_NAME
      FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
     WHERE TABLE_NAME  = @p_table_name 
       AND TABLE_SCHEMA = 'Z_ADF_SFDC'
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

  IF OBJECT_ID('tempdb..##mismatched_z_adf_sfdc') IS NOT NULL
    DROP TABLE ##mismatched_z_adf_sfdc
 
  --
  -- Check if record exists in Z_ADF_SFDC but not in Z_IICS_SFDC
  --
  SET @v_sql = 'select @rec_count = count(1) from '
  SET @v_sql = @v_sql + '(select ' + @v_as_pk_column + ' from Z_ADF_SFDC.' + @p_table_name + ' where LastmodifiedDate >= cast(' + '''' + @v_date_filter + '''' + ' as datetime2)'
  SET @v_sql = @v_sql + ' EXCEPT '
  SET @v_sql = @v_sql + 'select ' + @v_as_pk_column + ' from Z_IICS_SFDC.' + @p_table_name + ' where LastmodifiedDate >= cast(' + '''' + @v_date_filter + '''' + ' as datetime2)) Z_ADF_SFDC'

  EXECUTE sp_executesql @v_sql, @ParameterDefCount, @p_table_name=@p_table_name, @rec_count=@v_target_rec_count OUTPUT

  IF @v_target_rec_count > 0
  BEGIN
    SET @v_sql = 'select ' + @v_temp_tab_pk_column + ' into ##mismatched_z_adf_sfdc from '
    SET @v_sql = @v_sql + '(select ' + @v_as_pk_column + ' from Z_ADF_SFDC.' + @p_table_name + ' where LastmodifiedDate >= cast(' + '''' + @v_date_filter + '''' + ' as datetime2)'
    SET @v_sql = @v_sql + ' EXCEPT '
    SET @v_sql = @v_sql + 'select ' + @v_as_pk_column + ' from Z_IICS_SFDC.' + @p_table_name + ' where LastmodifiedDate >= cast(' + '''' + @v_date_filter + '''' + ' as datetime2)) Z_ADF_SFDC'

    EXECUTE sp_executesql @v_sql
  END 

  IF OBJECT_ID('tempdb..##mismatched_z_iics_sfdc') IS NOT NULL
    DROP TABLE ##mismatched_z_iics_sfdc
 
  --
  -- Check if record exists in Z_IICS_SFDC but not in Z_ADF_SFDC
  --
  SET @v_sql = 'select @rec_count = count(1) from '
  SET @v_sql = @v_sql + '(select ' + @v_as_pk_column + ' from Z_IICS_SFDC.' + @p_table_name + ' where LastmodifiedDate >= cast(' + '''' + @v_date_filter + '''' + ' as datetime2)'
  SET @v_sql = @v_sql + ' EXCEPT '
  SET @v_sql = @v_sql + 'select ' + @v_as_pk_column + ' from Z_ADF_SFDC.' + @p_table_name + ' where LastmodifiedDate >= cast(' + '''' + @v_date_filter + '''' + ' as datetime2)) Z_IICS_SFDC'

  EXECUTE sp_executesql @v_sql, @ParameterDefCount, @p_table_name=@p_table_name, @rec_count=@v_source_rec_count OUTPUT

  IF @v_source_rec_count > 0
  BEGIN
    SET @v_sql = 'select ' + @v_temp_tab_pk_column + ' into ##mismatched_z_iics_sfdc from '
    SET @v_sql = @v_sql + '(select ' + @v_as_pk_column + ' from Z_IICS_SFDC.' + @p_table_name + ' where LastmodifiedDate >= cast(' + '''' + @v_date_filter + '''' + ' as datetime2)'
    SET @v_sql = @v_sql + ' EXCEPT '
    SET @v_sql = @v_sql + 'select ' + @v_as_pk_column + ' from Z_ADF_SFDC.' + @p_table_name + ' where LastmodifiedDate >= cast(' + '''' + @v_date_filter + '''' + ' as datetime2)) Z_IICS_SFDC'

    EXECUTE sp_executesql @v_sql
  END

  IF OBJECT_ID('tempdb..##mismatched_z_adf_sfdc') IS NOT NULL
  BEGIN
    PRINT ''
    PRINT '------------------------------------------------------------------------------------------------'
    PRINT '-- WARNING'
    PRINT '--'
    PRINT 'The record(s) with the primary key (' + @v_pk_column_list + ') listed below exist in ADF but not in IICS:'
    
    DECLARE z_adf_cursor CURSOR FOR
      select * from ##mismatched_z_adf_sfdc

    OPEN z_adf_cursor

    IF @v_pk_column_count = 1
    BEGIN
      FETCH NEXT from z_adf_cursor into @v_column_name

      WHILE @@FETCH_STATUS = 0
      BEGIN
        PRINT @v_column_name
        
        FETCH NEXT from z_adf_cursor into @v_column_name
      END  -- @@FETCH_STATUS = 0
    END  -- @v_pk_column_count = 1
    
    IF @v_pk_column_count = 2
    BEGIN
      FETCH NEXT from z_adf_cursor into @v_column_name, @v_column_name_2

      WHILE @@FETCH_STATUS = 0
      BEGIN
        PRINT @v_column_name + ' ' + @v_column_name_2

        FETCH NEXT from z_adf_cursor into @v_column_name, @v_column_name_2
      END  -- @@FETCH_STATUS = 0
    END  -- @v_pk_column_count = 2
    
    IF @v_pk_column_count = 3
    BEGIN
      FETCH NEXT from z_adf_cursor into @v_column_name, @v_column_name_2, @v_column_name_3

      WHILE @@FETCH_STATUS = 0
      BEGIN
        PRINT @v_column_name + ' ' + @v_column_name_2 + ' ' + @v_column_name_3

        FETCH NEXT from z_adf_cursor into @v_column_name, @v_column_name_2, @v_column_name_3
      END  -- @@FETCH_STATUS = 0
    END  -- @v_pk_column_count = 2
    
    CLOSE z_adf_cursor
      
    PRINT '------------------------------------------------------------------------------------------------'

    DEALLOCATE z_adf_cursor
  END 
   
  IF OBJECT_ID('tempdb..##mismatched_z_iics_sfdc') IS NOT NULL
  BEGIN
    PRINT ''
    PRINT '------------------------------------------------------------------------------------------------'
    PRINT '-- WARNING'
    PRINT '--'    
    PRINT 'The record(s) with the primary key (' + @v_pk_column_list + ') listed below exist in IICS but not in ADF:'

    DECLARE z_iics_cursor CURSOR FOR
      select * from ##mismatched_z_iics_sfdc

    OPEN z_iics_cursor

    IF @v_pk_column_count = 1
    BEGIN
      FETCH NEXT from z_iics_cursor into @v_column_name

      WHILE @@FETCH_STATUS = 0
      BEGIN
        PRINT @v_column_name
        
        FETCH NEXT from z_iics_cursor into @v_column_name
      END  -- @@FETCH_STATUS = 0
    END  -- @v_pk_column_count = 1

    IF @v_pk_column_count = 2
    BEGIN
      FETCH NEXT from z_iics_cursor into @v_column_name, @v_column_name_2

      WHILE @@FETCH_STATUS = 0
      BEGIN
        PRINT @v_column_name + ' ' + @v_column_name_2

        FETCH NEXT from z_iics_cursor into @v_column_name, @v_column_name_2
      END  -- @@FETCH_STATUS = 0
    END  -- @v_pk_column_count = 2
    
    IF @v_pk_column_count = 3
    BEGIN
      FETCH NEXT from z_iics_cursor into @v_column_name, @v_column_name_2, @v_column_name_3

      WHILE @@FETCH_STATUS = 0
      BEGIN
        PRINT @v_column_name + ' ' + @v_column_name_2 + ' ' + @v_column_name_3

        FETCH NEXT from z_iics_cursor into @v_column_name, @v_column_name_2, @v_column_name_3
      END  -- @@FETCH_STATUS = 0
    END  -- @v_pk_column_count = 2

    CLOSE z_iics_cursor

    DEALLOCATE z_iics_cursor
    
    PRINT '------------------------------------------------------------------------------------------------'
  END 

  --
  -- Create the temporary table #missing_pk_recs
  --  
  IF OBJECT_ID('tempdb..##missing_pk_recs') IS NOT NULL
    DROP TABLE ##missing_pk_recs

  SET @v_sql = 'select * into ##missing_pk_recs '
  SET @v_sql = @v_sql + 'from ( select ' + @v_pk_column_list + ' from Z_ADF_SFDC.' + @p_table_name + ' where 1 =2) src'

  EXECUTE sp_executesql @v_sql
    
  --
  -- Combine the data from the two temporary tables into 1 temporary table if either or both exist
  --
  IF OBJECT_ID('tempdb..##mismatched_z_adf_sfdc') IS NOT NULL 
  BEGIN
    insert into ##missing_pk_recs
    select * from ##mismatched_z_adf_sfdc
  END

  IF OBJECT_ID('tempdb..##mismatched_z_iics_sfdc') IS NOT NULL 
  BEGIN
    insert into ##missing_pk_recs
    select * from ##mismatched_z_iics_sfdc
  END
  
  --
  -- Drop the temp tables if they exist
  --
  IF OBJECT_ID('tempdb..##mismatched_z_adf_sfdc') IS NOT NULL
    DROP TABLE ##mismatched_z_adf_sfdc
    
  IF OBJECT_ID('tempdb..##mismatched_z_adf_sfdc') IS NOT NULL
    DROP TABLE ##mismatched_z_adf_sfdc

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
    PRINT '** Due to mismatch between source and target at primary key level, skipping record count check'
    PRINT '***********************************************************************************************'
    
    GOTO BRANCH_CROSS_CHECK
  END
 
  -- 
  -- Get the number of records in the Z_ADF_SFDC table
  --
  SET @v_sql = 'SELECT @rec_count = COUNT(1) FROM Z_ADF_SFDC.' + @p_table_name + ' where LastmodifiedDate >= cast(' + '''' + @v_date_filter + '''' + ' as datetime2)'
      
  EXECUTE sp_executesql @v_sql, @ParameterDefCount, @p_table_name=@p_table_name, @rec_count=@v_source_rec_count OUTPUT
  
  -- 
  -- Get the number of records in the Z_IICS_SFDC table
  --
  SET @v_sql = 'SELECT @rec_count = COUNT(1) FROM Z_IICS_SFDC.' + @p_table_name + ' where LastmodifiedDate >= cast(' + '''' + @v_date_filter + '''' + ' as datetime2)'
      
  EXECUTE sp_executesql @v_sql, @ParameterDefCount, @p_table_name=@p_table_name, @rec_count=@v_target_rec_count OUTPUT
  
  IF @v_source_rec_count <> @v_target_rec_count
  BEGIN
    PRINT ''
    PRINT '--------------------------------------------------------------------'
    PRINT '-- FAILURE'
    PRINT '--' 
    
    SET @v_message =  cast(@v_source_rec_count as VARCHAR(10))
    
    PRINT '-- No of records in ADF for ' + @p_table_name + ': ' + @v_message
    
    SET @v_message =  cast(@v_target_rec_count as VARCHAR(10))
    
    PRINT '-- No of records in IICS for' + @p_table_name + ': ' + @v_message
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
    
    PRINT '++ No of records in ADF for ' + @p_table_name + ': ' + @v_message
    
    SET @v_message =  cast(@v_target_rec_count as VARCHAR(10))
    
    PRINT '++ No of records in IICS for ' + @p_table_name + ': ' + @v_message
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
  PRINT '****************************************************************************'
  PRINT 'Verifying the column values between ADF and IICS versions of the table match'
  PRINT '****************************************************************************'

  --
  -- Set up the column list cursor and count of the columns in the table
  --
  IF @p_column_exclusion is NULL
  BEGIN
    DECLARE column_cursor CURSOR FOR
      SELECT COLUMN_NAME
        FROM INFORMATION_SCHEMA.COLUMNS
       WHERE TABLE_SCHEMA = 'Z_ADF_SFDC'
         AND TABLE_NAME = @p_table_name
       ORDER BY ORDINAL_POSITION
       
    SELECT @v_column_count =
           COUNT(1)
      FROM INFORMATION_SCHEMA.COLUMNS
     WHERE TABLE_SCHEMA = 'Z_ADF_SFDC'
       AND TABLE_NAME = @p_table_name 
  END
  ELSE
  BEGIN
    DECLARE column_cursor CURSOR FOR
      SELECT COLUMN_NAME
        FROM INFORMATION_SCHEMA.COLUMNS
        LEFT OUTER JOIN STRING_SPLIT(@p_column_exclusion, ',')
          ON trim(value) = COLUMN_NAME
       WHERE TABLE_SCHEMA = 'Z_ADF_SFDC'
         AND TABLE_NAME = @p_table_name
         AND trim(value) is NULL
       ORDER BY ORDINAL_POSITION
       
    SELECT @v_column_count =
           COUNT(1)
      FROM INFORMATION_SCHEMA.COLUMNS
      LEFT OUTER JOIN STRING_SPLIT(@p_column_exclusion, ',')
          ON trim(value) = COLUMN_NAME
     WHERE TABLE_SCHEMA = 'Z_ADF_SFDC'
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
    SET @v_sql_diff_check = @v_sql_diff_check + CHAR(10) + CHAR(9) + CHAR(9) + 'Z_ADF_SFDC.' + @p_table_name  + ' src '
    SET @v_sql_diff_check = @v_sql_diff_check + CHAR(10) + CHAR(9) + ' where LastmodifiedDate >= cast(' + '''' + @v_date_filter + '''' + ' as datetime2)'
  END
  ELSE
  BEGIN
    SET @v_sql_diff_check = @v_sql_diff_check + CHAR(10) + CHAR(9) + '(select ' + @v_sql_src
    SET @v_sql_diff_check = @v_sql_diff_check + CHAR(10) + CHAR(9) + 'from'
    SET @v_sql_diff_check = @v_sql_diff_check + CHAR(10) + CHAR(9) + CHAR(9) + 'Z_ADF_SFDC.' + @p_table_name + ' src '
	SET @v_sql_diff_check = @v_sql_diff_check + CHAR(10) + CHAR(9) + CHAR(9) + 'where LastmodifiedDate >= cast(' + '''' + @v_date_filter + '''' + ' as datetime2)'
    SET @v_sql_diff_check = @v_sql_diff_check + CHAR(10) + CHAR(9) + 'and'
    SET @v_sql_diff_check = @v_sql_diff_check + CHAR(10) + CHAR(9) + CHAR(9) + 'concat(' + @v_pk_column_list + ','+ '''' + '' + '''' + ') not in (select concat(' + @v_pk_column_list + ',' + '''' + '' + '''' + ') from ##missing_pk_recs)'
  END
  
  SET @v_sql_diff_check = @v_sql_diff_check + CHAR(10) + CHAR(9) + 'UNION ALL'
  
  IF @v_missing_pk_flag = 0
  BEGIN
    SET @v_sql_diff_check = @v_sql_diff_check + CHAR(10) + CHAR(9) + 'select ' + @v_sql_trg 
    SET @v_sql_diff_check = @v_sql_diff_check + CHAR(10) + CHAR(9) + 'from' 
    SET @v_sql_diff_check = @v_sql_diff_check + CHAR(10) + CHAR(9) + CHAR(9) + 'Z_IICS_SFDC.' + @p_table_name + ' trg'
    SET @v_sql_diff_check = @v_sql_diff_check + CHAR(10) + CHAR(9) + ' where LastmodifiedDate >= cast(' + '''' + @v_date_filter + '''' + ' as datetime2)) UA'
  END
  ELSE
  BEGIN
    SET @v_sql_diff_check = @v_sql_diff_check + CHAR(10) + CHAR(9) + 'select ' + @v_sql_trg
    SET @v_sql_diff_check = @v_sql_diff_check + CHAR(10) + CHAR(9) + 'from'
    SET @v_sql_diff_check = @v_sql_diff_check + CHAR(10) + CHAR(9) + CHAR(9) + 'Z_IICS_SFDC.' + @p_table_name + ' trg'
    SET @v_sql_diff_check = @v_sql_diff_check + CHAR(10) + CHAR(9) + ' where LastmodifiedDate >= cast(' + '''' + @v_date_filter + '''' + ' as datetime2)'
    SET @v_sql_diff_check = @v_sql_diff_check + CHAR(10) + CHAR(9) + 'and'
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
      PRINT '++ Data created by ADF and IICS for ' + @p_table_name + ' have an exact match - test successful'
      PRINT '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
    END
    ELSE
    BEGIN
      PRINT ''
      PRINT '----------------------------------------------------------------------------------------------'
      PRINT '-- INFORMATION'
      PRINT '--' 
      PRINT '-- Data created by ADF and IICS for ' + @p_table_name + ' have an exact match for common record set'
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
    PRINT '-- Variance found between data created by ADF and IICS for ' + @p_table_name + ' by ' + CAST(@v_difference_count AS VARCHAR(10)) + ' records'
    PRINT '------------------------------------------------------------------------------------------------------------'
  END  -- @v_difference_count = 0

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

    SET @v_sql = 'select ' + @v_temp_tab_pk_column + ', Z_ADF_SFDC_' + @v_column_name + ', Z_IICS_SFDC_'+ @v_column_name + ' into ##mismatched_data from ('
    SET @v_sql = + @v_sql + ' select * from ('
    SET @v_sql = @v_sql + 'select ' + @v_as_pk_column + ',' + @v_column_name + ', '+ '''' + 'Z_ADF_SFDC_'+ @v_column_name + '''' + ' as SOURCE_SYSTEM'
    SET @v_sql = @v_sql + ' from Z_ADF_SFDC.' + @p_table_name
    SET @v_sql = @v_sql + ' where concat (' + @v_pk_column_list + ','+ '''' + '' + '''' + ') not in (select concat(' + @v_pk_column_list + ','+ '''' + '' + '''' + ') from ##missing_pk_recs)'
    SET @v_sql = @v_sql + ' except '
    SET @v_sql = @v_sql + ' select ' + @v_as_pk_column + ',' + @v_column_name + ', '+ '''' + 'Z_ADF_SFDC_'+ @v_column_name + '''' + ' as SOURCE_SYSTEM'
    SET @v_sql = @v_sql + ' from Z_IICS_SFDC.' + @p_table_name
    SET @v_sql = @v_sql + ' where concat (' + @v_pk_column_list + ','+ '''' + '' + '''' + ') not in (select concat(' + @v_pk_column_list + ','+ '''' + '' + '''' + ') from ##missing_pk_recs)'
    SET @v_sql = @v_sql + ' union all'
    SET @v_sql = @v_sql + ' select ' + @v_as_pk_column + ',' + @v_column_name + ', ' + '''' + 'Z_IICS_SFDC_'+ @v_column_name + '''' + ' as SOURCE_SYSTEM'
    SET @v_sql = @v_sql + ' from Z_IICS_SFDC.' + @p_table_name
    SET @v_sql = @v_sql + ' where concat (' + @v_pk_column_list + ','+ '''' + '' + '''' + ') not in (select concat(' + @v_pk_column_list + ','+ '''' + '' + '''' + ') from ##missing_pk_recs)'
    SET @v_sql = @v_sql + ' except '
    SET @v_sql = @v_sql + ' select ' + @v_as_pk_column + ',' + @v_column_name + ', ' + '''' + 'Z_IICS_SFDC_'+ @v_column_name + '''' + ' as SOURCE_SYSTEM'
    SET @v_sql = @v_sql + ' from Z_ADF_SFDC.' + @p_table_name
    SET @v_sql = @v_sql + ' where concat (' + @v_pk_column_list + ','+ '''' + '' + '''' + ') not in (select concat(' + @v_pk_column_list + ','+ '''' + '' + '''' + ') from ##missing_pk_recs)) diff'
    SET @v_sql = @v_sql + ' PIVOT (max(' + @v_column_name + ') for SOURCE_SYSTEM in (Z_ADF_SFDC_'+ @v_column_name + ', Z_IICS_SFDC_' + @v_column_name + ')) as PivotTable) diff_rows'
    
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
END;  -- proc