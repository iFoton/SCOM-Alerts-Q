Set objArgs = WScript.Arguments
Set con = CreateObject("ADODB.Connection")
con.ConnectionString = "Driver={SQL Server};Server=SQLSCOM\SCOM;Database=OperationsManager;"
con.Open
strQry = "INSERT INTO dbo.SCOM_ALERTS_QUEUE (AlertID,SubscriptionID,Source,isChangeState) VALUES ('" & objArgs(0) & "','" & objArgs(1) & "','" & objArgs(2) & "','" & objArgs(3) & "')"
con.execute(strQry)

