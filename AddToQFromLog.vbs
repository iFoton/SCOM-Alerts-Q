objArgs = split(split(wscript.arguments.item(0),",")(5)," ")
Set con = CreateObject("ADODB.Connection")
con.ConnectionString = "Driver={SQL Server};Server=SQLSCOM\SCOM;Database=SCOMAddons;"
con.Open
strQry = "INSERT INTO dbo.AlertsQueue (AlertID,SubscriptionID,Source,toState) VALUES ('" & objArgs(2) & "','" & objArgs(3) & "','" & objArgs(4) & "_log" & "','" & objArgs(5) & "')"
con.execute(strQry)