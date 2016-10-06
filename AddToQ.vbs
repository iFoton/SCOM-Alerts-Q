Set objArgs = WScript.Arguments
Set con = CreateObject("ADODB.Connection")
con.ConnectionString = "Driver={SQL Server};Server=SQLSCOM\SCOM;Database=SCOMAddons;"
con.Open
strQry = "INSERT INTO dbo.AlertsQueue (AlertID,SubscriptionID,Source,toState) VALUES ('" & objArgs(0) & "','" & objArgs(1) & "','" & objArgs(2) & "','" & objArgs(3) & "')"
con.execute(strQry)

