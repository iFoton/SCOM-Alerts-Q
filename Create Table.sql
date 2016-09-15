/*
   Sunday, September 11, 201618:02:30
   User: 
   Server: localhost
   Database: OperationsManager
   Application: 
*/

/* To prevent any potential data loss issues, you should review this script in detail before running it outside the context of the database designer.*/
BEGIN TRANSACTION
SET QUOTED_IDENTIFIER ON
SET ARITHABORT ON
SET NUMERIC_ROUNDABORT OFF
SET CONCAT_NULL_YIELDS_NULL ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
COMMIT
BEGIN TRANSACTION
GO
COMMIT
BEGIN TRANSACTION
GO
CREATE TABLE dbo.SCOM_ALERTS_QUEUE
	(
	QID uniqueidentifier DEFAULT NEWID() NOT NULL,
	AlertID uniqueidentifier NOT NULL,
	SubscriptionID uniqueidentifier NOT NULL,
	Source nvarchar(255) NULL,
	TimeStmp DateTime DEFAULT GETDATE() NOT NULL
	)  ON [PRIMARY]
GO
ALTER TABLE dbo.SCOM_ALERTS_QUEUE ADD CONSTRAINT
	PK_SCOM_ALERTS_QUEUE PRIMARY KEY CLUSTERED 
	(
	QID
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO
ALTER TABLE dbo.SCOM_ALERTS_QUEUE SET (LOCK_ESCALATION = TABLE)
GO
COMMIT

