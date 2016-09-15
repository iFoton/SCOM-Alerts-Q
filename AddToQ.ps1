Param(
	[string]$alertID,
	[string]$SubscriptionID
)

function Invoke-DatabaseQuery { 
    param ( 
        [string]$connectionString, 
        [string]$query     
    ) 
    
    $connection = New-Object -TypeName System.Data.SqlClient.SqlConnection 
    $connection.ConnectionString = $connectionString 
    $command = $connection.CreateCommand()
    $command.CommandText = $query 
    $connection.Open() 
    $command.ExecuteNonQuery() 
    $connection.close() 
}

#$alertID = '6c0f74e7-83c6-435d-b7fb-6224c15314d7'
#$SubscriptionID = '6c0f74e7-83c6-435d-b7fb-6224c15314d4'

$conString = 'Server=SQLSCOM\SCOM;Database=OperationsManager;Trusted_Connection=True;'
$query = "INSERT INTO dbo.SCOM_ALERTS_QUEUE (AlertID,SubscriptionID,Source) VALUES ('$alertID','$SubscriptionID','$env:COMPUTERNAME')"

Invoke-DatabaseQuery `
     -connectionString $conString `
     -query $query