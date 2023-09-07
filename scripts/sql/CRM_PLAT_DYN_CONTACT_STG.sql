IF OBJECT_ID('STAGE_CDI.CRM_PLAT_DYN_CONTACT_STG') IS NOT NULL
DROP TABLE STAGE_CDI.CRM_PLAT_DYN_CONTACT_STG;

CREATE TABLE STAGE_CDI.CRM_PLAT_DYN_CONTACT_STG
(
  S_CONTACT_KEY                         DECIMAL(38,0)    	  NOT NULL    IDENTITY(1,1),
  S_CREATE_DATETIME                     DATETIME2        	  NOT NULL,
  S_UPDATE_DATETIME                     DATETIME2        	  NOT NULL,
  CONTACTID                             VARCHAR(255)        NOT NULL,
  CUSTOMERTYPECODE                      DECIMAL(10,0),
  NEW_CONTACTCATEGORYCODE               DECIMAL(10,0),
  PARENTCUSTOMERID                      VARCHAR(255),
  PARENTCUSTOMERIDNAME                  VARCHAR(4000),
  OWNERID                               VARCHAR(255),
  OWNERIDNAME                           VARCHAR(160),
  FULLNAME                              VARCHAR(160),
  ASC_BLUEBUTTONREF                     VARCHAR(100),
  ASC_SONATACLIENTID                    VARCHAR(100),
  ASC_SONATASTATUS                      VARCHAR(20),
  ASC_SONATAOUTLETID                    VARCHAR(100),
  ASC_SONATAOUTLETTYPE                  DECIMAL(10,0),
  ASC_SONATAOUTLETSTATUS                DECIMAL(10,0),
  ASC_CALLERID                          VARCHAR(6),
  JOBTITLE                              VARCHAR(100),
  NEW_JOBCATEGORY                       DECIMAL(10,0),
  EMAILADDRESS1                         VARCHAR(100),
  ASC_CANOTIFICATIONALTERNATEEMAIL      VARCHAR(500),
  ASC_CANOTIFICATIONCCEMAIL             VARCHAR(500),
  TELEPHONE1                            VARCHAR(50),
  MOBILEPHONE                           VARCHAR(50),
  FAX                                   VARCHAR(50),
  ADDRESS1_COMPOSITE                    VARCHAR(MAX),
  ASC_INTERNALCONTACT                   DECIMAL(1,0),
  NEW_INACTIVEATCOMPANY                 DECIMAL(1,0),
  NEW_ACCOUNTEXECVALIDATED              DECIMAL(1,0),
  NEW_REFERENCEACCEXECVALIDATIONID      VARCHAR(255),
  ASC_VIP                               DECIMAL(1,0),
  ASC_VIPSETDATE                        DATETIME2,
  ASC_VIPSETBYID                        VARCHAR(255),
  ASC_REASONFORVIPSTATUS                VARCHAR(MAX),
  NEW_FINANCIALSDATE                    DATETIME2,
  NEW_FINANCIALFREEASSETS               DECIMAL(23,10),
  NEW_FINANCIALCLIENTCOUNT              DECIMAL(10,0),
  NEW_FINANCIALTOTALASSETS              DECIMAL(23,10),
  NEW_FINANCIALCASH                     DECIMAL(23,10),
  ASC_SONATAFINANCIALSDATE              DATETIME2,
  ASC_SONATAFREEASSETS                  DECIMAL(19,4),
  ASC_SONATAPENDINGPURCHASES            DECIMAL(19,4),
  ASC_SONATACLIENTCOUNT                 DECIMAL(10,0),
  ASC_SONATATOTALASSETS                 DECIMAL(19,4),
  ASC_SONATACASH                        DECIMAL(19,4),
  NEW_ACCEXEC_FSA_NO                    VARCHAR(20),
  NEW_ACCEXEC_ACCT_EXEC                 VARCHAR(20),
  ASC_MATRIXFIRMNAME                    VARCHAR(200),
  ASC_MATRIXCONTACTID                   VARCHAR(100),
  NEW_PROSPECTPHONEWORK                 VARCHAR(100),
  ASC_DDIPHONE                          VARCHAR(50),
  NEW_PROSPECTADDRESSNAME               VARCHAR(200),
  NEW_PROSPECTPHONEMOBILE               VARCHAR(100),
  NEW_PROSPECTADDRESSLINE1              VARCHAR(200),
  NEW_PROSPECTADDRESSLINE2              VARCHAR(200),
  NEW_PROSPECTADDRESSLINE3              VARCHAR(200),
  NEW_PROSPECTADDRESSLINE4              VARCHAR(200),
  NEW_PROSPECTADDRESSLINE5              VARCHAR(200),
  ASC_TWITTERUSERID                     VARCHAR(100),
  ASC_TWITTERURL                        VARCHAR(200),
  EMAILADDRESS2                         VARCHAR(100),
  EMAILADDRESS3                         VARCHAR(100),
  NEW_PROSPECTADDRESSPOSTCODE           VARCHAR(100),
  ASC_PARTNERMARKETING                  DECIMAL(1,0),
  NEW_PROSPECTADDRESSCOUNTRY            VARCHAR(100),
  NEW_INDIVIDUAL_TEL_WKDAYS_FROM_W      DECIMAL(10,0),
  NEW_INDIVIDUAL_TEL_EXT_W              VARCHAR(50),
  NEW_INDIVIDUAL_TEL_WKDAYS_TO_W        DECIMAL(10,0),
  NEW_INDIVIDUAL_TEL_WEEKEND_W          VARCHAR(10),
  TELEPHONE2                            VARCHAR(50),
  NEW_INDIVIDUAL_TEL_WKDAYS_FROM_H      DECIMAL(10,0),
  NEW_INDIVIDUAL_TEL_WKDAYS_TO_H        DECIMAL(10,0),
  NEW_INDIVIDUAL_TEL_EXT_H              VARCHAR(50),
  NEW_INDIVIDUAL_TEL_WEEKEND_H          VARCHAR(10),
  NEW_INDIVIDUAL_TEL_WKDAYS_FROM_M      DECIMAL(10,0),
  NEW_INDIVIDUAL_TEL_WKDAYS_TO_M        DECIMAL(10,0),
  NEW_INDIVIDUAL_TEL_EXT_M              VARCHAR(50),
  NEW_INDIVIDUAL_TEL_WEEKEND_M          VARCHAR(10),
  NEW_TEAM_TEL_W                        VARCHAR(50),
  NEW_TEAM_WKDAYS_FROM_W                DECIMAL(10,0),
  NEW_TEAM_WKDAYS_TO_W                  DECIMAL(10,0),
  NEW_TEAM_EXT_W                        VARCHAR(50),
  NEW_TEAM_WEEKEND_W                    VARCHAR(10),
  NEW_TEAM_TEL_F                        VARCHAR(50),
  NEW_TEAM_WKDAYS_FROM_F                DECIMAL(10,0),
  NEW_TEAM_WKDAYS_TO_F                  DECIMAL(10,0),
  NEW_TEAM_EXT_F                        VARCHAR(100),
  NEW_TEAM_WEEKEND_F                    VARCHAR(10),
  NEW_TEAM_TEL_H                        VARCHAR(50),
  NEW_TEAM_WKDAYS_FROM_H                DECIMAL(10,0),
  NEW_TEAM_WKDAYS_TO_H                  DECIMAL(10,0),
  NEW_TEAM_EXT_H                        VARCHAR(50),
  NEW_TEAM_WEEKEND_H                    VARCHAR(10),
  NEW_TEAM_TEL_M                        VARCHAR(50),
  NEW_TEAM_WKDAYS_FROM_M                DECIMAL(10,0),
  NEW_TEAM_WKDAYS_TO_M                  DECIMAL(10,0),
  NEW_TEAM_EXT_M                        VARCHAR(100),
  NEW_TEAM_WEEKEND_M                    VARCHAR(10),
  GENDERCODE                            DECIMAL(10,0),
  FAMILYSTATUSCODE                      DECIMAL(10,0),
  SPOUSESNAME                           VARCHAR(100),
  BIRTHDATE                             DATETIME2,
  ANNIVERSARY                           DATETIME2,
  ORIGINATINGLEADID                     VARCHAR(255),
  LASTUSEDINCAMPAIGN                    DATETIME2,
  DONOTSENDMM                           DECIMAL(1,0),
  TRANSACTIONCURRENCYID                 VARCHAR(255),
  CREDITLIMIT                           DECIMAL(19,4),
  CREDITONHOLD                          DECIMAL(1,0),
  PAYMENTTERMSCODE                      DECIMAL(10,0),
  DESCRIPTION                           VARCHAR(MAX),
  PREFERREDCONTACTMETHODCODE            DECIMAL(10,0),
  DONOTEMAIL                            DECIMAL(1,0),
  DONOTBULKEMAIL                        DECIMAL(1,0),
  DONOTPHONE                            DECIMAL(1,0),
  DONOTFAX                              DECIMAL(1,0),
  DONOTPOSTALMAIL                       DECIMAL(1,0),
  ADDRESS1_SHIPPINGMETHODCODE           DECIMAL(10,0),
  ADDRESS1_FREIGHTTERMSCODE             DECIMAL(10,0),
  NEW_REFERENCEMANUALLYCREATEDBYID      VARCHAR(255),
  NEW_REFERENCEMANUALLYCREATEDBYIDNAME  VARCHAR(200),
  NEW_UPDATEDBYBLUEBUTTONON             DATETIME2,
  CREATEDBY                             VARCHAR(255),
  CREATEDBYNAME                         VARCHAR(200),
  CREATEDON                             DATETIME2,
  MODIFIEDBY                            VARCHAR(255),
  MODIFIEDBYNAME                        VARCHAR(200),
  MODIFIEDON                            DATETIME2,
  ASC_LASTUPDATEDBYSONATAON             DATETIME2,
  NEW_MIGRATIONTAG                      VARCHAR(20),
  NEW_ALT_ADDRESSNAME                   VARCHAR(100),
  NEW_ALT_ADDRESSLINE_1                 VARCHAR(100),
  NEW_ALT_ADDRESSLINE_2                 VARCHAR(100),
  NEW_ALT_ADDRESSLINE_3                 VARCHAR(100),
  NEW_ALT_ADDRESSLINE_4                 VARCHAR(100),
  NEW_ALT_ADDRESSLINE_5                 VARCHAR(100),
  NEW_ALT_ADDRESSLINE_POSTCODE          VARCHAR(100),
  NEW_ALT_ADDRESSLINE_COUNTRY           VARCHAR(100),
  ASC_PROFESSIONALBODY                  DECIMAL(10,0),
  ASC_PROFESSIONALBODYOTHER             VARCHAR(200),
  ASC_SALESMANAGER                      VARCHAR(255),
  ASC_BDTEAM                            DECIMAL(10,0),
  ASC_CSTEAMID                          VARCHAR(255),
  ASC_CSCONTACTID                       VARCHAR(255),
  ASC_INDIVIDUALFSANUMBER               VARCHAR(9),
  ADDRESS1_LINE1                        VARCHAR(255),
  ADDRESS1_LINE2                        VARCHAR(255),
  ADDRESS1_LINE3                        VARCHAR(255),
  ADDRESS1_CITY                         VARCHAR(255),
  ADDRESS1_POSTALCODE                   VARCHAR(255),
  ADDRESS1_COUNTRY                      VARCHAR(255),
  MASTERCONTACTIDNAME                   VARCHAR(255),
  ADDRESS1_NAME                         VARCHAR(255),
  ACCOUNTIDNAME                         VARCHAR(255),
  PARENTCONTACTIDNAME                   VARCHAR(255),
  DERIVEDMSDYNADVSRSEQID                VARCHAR(100),
  FIRSTNAME                             VARCHAR(255),
  LASTNAME                              VARCHAR(255),
  MIDDLENAME                            VARCHAR(255),
  ADDRESS1_STATEORPROVINCE              VARCHAR(100),
  TELEPHONE3                            VARCHAR(50),
  NEW_PROSPECTPHONEHOME                 VARCHAR(100),
  NEW_PROSPECTEMAIL1                    VARCHAR(100),
  SALUTATION                            VARCHAR(200));

ALTER TABLE STAGE_CDI.CRM_PLAT_DYN_CONTACT_STG ADD CONSTRAINT DFF_CRM_PLAT_DYN_CONTACT_STG_S_CREATE_DATETIME DEFAULT CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'GMT Standard Time' AS DATETIME2) FOR S_CREATE_DATETIME; 

ALTER TABLE STAGE_CDI.CRM_PLAT_DYN_CONTACT_STG ADD CONSTRAINT DFF_CRM_PLAT_DYN_CONTACT_STG_S_UPDATE_DATETIME DEFAULT CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'GMT Standard Time' AS DATETIME2) FOR S_UPDATE_DATETIME;