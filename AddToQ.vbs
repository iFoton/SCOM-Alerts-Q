Set objArgs = WScript.Arguments
Set con = CreateObject("ADODB.Connection")
con.ConnectionString = "Driver={SQL Server};Server=SQLSCOM\SCOM;Database=OperationsManager;"
con.Open
IF objArgs.count > 3 THEN
strQry = "INSERT INTO dbo.AlertsQueue (AlertID,SubscriptionID,Source,isChangeState) VALUES ('" & objArgs(0) & "','" & objArgs(1) & "','" & objArgs(2) & "','" & objArgs(3) & "')"
ELSE
strQry = "INSERT INTO dbo.AlertsQueue (AlertID,SubscriptionID,Source) VALUES ('" & objArgs(0) & "','" & objArgs(1) & "','" & objArgs(2) & "')"
END IF
con.execute(strQry)

