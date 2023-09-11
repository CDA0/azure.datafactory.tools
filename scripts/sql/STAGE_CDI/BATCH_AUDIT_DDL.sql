IF OBJECT_ID('STAGE_CDI.BATCH_AUDIT') IS NULL 
  CREATE TABLE STAGE_CDI.BATCH_AUDIT
  (
    PIPELINE_NAME            VARCHAR(400) NOT NULL,
    TABLE_NAME               VARCHAR(400) NOT NULL,
    PROCESS_NUMBER           INT          NOT NULL,
    TRIGGER_NAME             VARCHAR(400),
    PROCESS_START_DATETIME   DATETIME2,
    PROCESS_END_DATETIME     DATETIME2,
    BILLABLE_DURATION        DECIMAL(25,20),
    BILLABLE_UNIT            VARCHAR(100),
    RECORDS_READ             INT,
    RECORDS_WRITTEN          INT,
    INSERT_DATETIME          DATETIME2
    CONSTRAINT BATCH_AUDIT_PK PRIMARY KEY (PIPELINE_NAME, TABLE_NAME)
  );