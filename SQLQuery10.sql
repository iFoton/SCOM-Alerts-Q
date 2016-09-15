/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP 1000 [AlertID]
      ,[Subscribers]
      ,[Source]
  FROM [OperationsManager].[dbo].[SCOM_ALERTS_QUEUE]

  INSERT INTO dbo.SCOM_ALERTS_QUEUE VALUES ('3734DB5F-96BE-4072-843F-C3CE2FD17722', 'ALARM!!!', 'MS')
  DELETE FROM dbo.SCOM_ALERTS_QUEUE WHERE AlertID = '9EC8BED4-8DA2-415E-B69E-C56C1320A5C9'

  UPDATE dbo.Alert
  SET ResolutionState = 0,
      LastModifiedBy = 'AlertsQ',
      TimeResolutionStateLastModifiedInDB = (SELECT CURRENT_TIMESTAMP),
      TimeResolutionStateLastModified = (SELECT CURRENT_TIMESTAMP),
	  LastModified = (SELECT CURRENT_TIMESTAMP),
	  LastModifiedByNonConnector = (SELECT CURRENT_TIMESTAMP),
	  LastModifiedExceptRepeatCount = (SELECT CURRENT_TIMESTAMP)
  WHERE AlertId = '9EC8BED4-8DA2-415E-B69E-C56C1320A5C9'

  select ResolutionState, TimeResolutionStateLastModified, TimeResolutionStateLastModifiedInDB from Alert where AlertId = '9EC8BED4-8DA2-415E-B69E-C56C1320A5C9'
   select * from AlertView where id = '9EC8BED4-8DA2-415E-B69E-C56C1320A5C9'
   select * from Alert where Alertid = '9EC8BED4-8DA2-415E-B69E-C56C1320A5C9'

ResolutionState	TimeResolutionStateLastModified	TimeResolutionStateLastModifiedInDB
0	                2016-09-11 10:11:35.090	      2016-09-11 10:11:35.090

ResolutionState	TimeResolutionStateLastModified	TimeResolutionStateLastModifiedInDB
247	                2016-09-11 10:21:41.007	      2016-09-11 10:21:41.007

SELECT CURRENT_TIMESTAMP