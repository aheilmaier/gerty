/* Mysql table definitions for
   Gerty::PropHistory
*/



/* ***********  Actual property values  ************ */

CREATE TABLE PROP_VALUES
(
  DEVICE_SYSNAME        VARCHAR(150) NOT NULL,
  PROP_CATEGORY         VARCHAR(40) NOT NULL,
  AID_NAME              VARCHAR(60) NOT NULL,
  PROP_NAME             VARCHAR(60) NOT NULL,
  PROP_VALUE            VARCHAR(256) NOT NULL,
  MODIFIED_TS           DATETIME NOT NULL,
  CONSTRAINT PROP_VALUES_UC01 UNIQUE
      (DEVICE_SYSNAME, PROP_CATEGORY, AID_NAME, PROP_NAME)
);

CREATE INDEX PROP_VALUES_I01
  ON PROP_VALUES(PROP_NAME, PROP_VALUE);

CREATE INDEX PROP_VALUES_I02
  ON PROP_VALUES(DEVICE_SYSNAME, PROP_NAME);



/* ***********  History  ************ */

CREATE TABLE PROP_HISTORY
(
  DEVICE_SYSNAME        VARCHAR(150) NOT NULL,
  PROP_CATEGORY         VARCHAR(40) NOT NULL,
  AID_NAME              VARCHAR(60) NOT NULL,
  PROP_NAME             VARCHAR(60) NOT NULL,
  PROP_VALUE            VARCHAR(256) NOT NULL,
  ADDED_TS              DATETIME NOT NULL,
  ARCHIVED_TS           DATETIME DEFAULT NULL,  
  CONSTRAINT PROP_HISTORY_UC01 UNIQUE
    (DEVICE_SYSNAME, PROP_CATEGORY, AID_NAME, PROP_NAME, ADDED_TS),
  CONSTRAINT PROP_HISTORY_CC01 CHECK
    ((ARCHIVED_TS IS NULL) OR (ARCHIVED_TS > ADDED_TS))
);

CREATE INDEX PROP_HISTORY_I01
  ON PROP_VALUES(DEVICE_SYSNAME, PROP_CATEGORY, AID_NAME,
                 PROP_NAME, ARCHIVED_TS);
