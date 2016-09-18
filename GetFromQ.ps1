function Get-DatabaseData { 

    param ( 
        [string]$connectionString, 
        [string]$query
    ) 
    
    $connection = New-Object -TypeName System.Data.SqlClient.SqlConnection 
    $connection.ConnectionString = $connectionString 
    $command = $connection.CreateCommand() 
    $command.CommandText = $query 
    $adapter = New-Object -TypeName System.Data.SqlClient.SqlDataAdapter $command 

    $dataset = New-Object -TypeName System.Data.DataSet 
    #Write-Host $dataset -ForegroundColor Cyan
    $adapter.Fill($dataset) | Out-Null
    $dataset.Tables[0]
     
} 

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

function fnMamlToHTML($MAMLText)
{
	$HTMLText = "";
	$HTMLText = $MAMLText -replace ('xmlns:maml="http://schemas.microsoft.com/maml/2004/10"');
	$HTMLText = $HTMLText -replace ("maml:para", "p");
	$HTMLText = $HTMLText -replace ("maml:");
	$HTMLText = $HTMLText -replace ("</section>");
	$HTMLText = $HTMLText -replace ("<section>");
	$HTMLText = $HTMLText -replace ("<section >");
	$HTMLText = $HTMLText -replace ("<title>", "<h3>");
	$HTMLText = $HTMLText -replace ("</title>", "</h3>");
	$HTMLText = $HTMLText -replace ("<listitem>", "<li>");
	$HTMLText = $HTMLText -replace ("</listitem>", "</li>");
    $HTMLText = $HTMLText -replace ("</MamlContent>", "");
    $HTMLText = $HTMLText -replace ("<MamlContent>", "");
	$HTMLText;
}

function Get-XML {
    param ( 
        $alertInfo     
    ) 

    $xml.LoadXml("<?xml version=`"1.0`" encoding=`"utf-8`"?><Alert></Alert>")
    $xmlA = $xml.SelectSingleNode("//Alert")

    foreach ($alertProp in ($alertInfo.psobject.properties | select -ExpandProperty Name | ? {$_ -notin ('RowError','RowState','Table','ItemArray','HasErrors')})) {
        
        $node = $xml.CreateElement("$alertProp")
        $xmlA.AppendChild($node) | Out-Null
        $xmlA."$alertProp" = $alertInfo."$alertProp".tostring()
        #"$alertProp"

    }
    
    #Fill Description
    $param = [xml]$alertInfo.AlertParams
    $paramCount = ($param.AlertParameters.ChildNodes).Count
        
    if ($paramCount -gt 0) {
        
        $desc = $xml.Alert.Alert_Description
        
        for ($i=0;$i -lt $paramCount;$i++) {
            $desc = $desc.Replace("{$i}","$($param.AlertParameters."AlertParameter$($i+1)")")
        }

        $xml.Alert.Alert_Description = $desc
    }

    $xml.Alert.RemoveChild($xml.SelectSingleNode('//Alert/AlertParams')) | Out-Null
    $Knowledge = fnMamlToHTML $xml.Alert.Knowledge
    $xml.Alert.Knowledge = 'Knowledge_replace'
    
    #Create HTML

    $xslt = New-Object System.Xml.Xsl.XslCompiledTransform
    $xmlStrReader = New-Object System.IO.StringReader($xml.InnerXml)
    $xmlReader = [System.Xml.XmlReader]::Create($xmlStrReader)
    $htmlWriter = [System.IO.StringWriter]::new("")
    $xslt.Load("$rootPath\errorTemplate.xsl")
    
    $xslt.Transform($xmlReader,$null,$htmlWriter)
    $html = $htmlWriter.ToString().Replace('Knowledge_replace',$Knowledge)

    Return $html


}

$rootPath = "C:\Users\ivan\OneDrive\Документы\GDC\AlertsQ"
$conStr = 'Server=SQLSCOM\SCOM;Database=OperationsManager;Trusted_Connection=True;'
$from = 'vCloud@f.loc'
$smtp = 'iis.f.loc'

$subQuery = Get-Content "$rootPath\Subscription.sql"
$alertQuery = Get-Content "$rootPath\getAlert.sql"

$xmlStruct = Get-Content "$rootPath\alertInfo.xml"
[xml]$xml = New-Object system.Xml.XmlDocument

#$subQuery = "select * from Alert where Alertid = 'SUBSCRIPTION_ID'"
$AlertsQ =  Get-DatabaseData -connectionString $conStr -query "SELECT * FROM dbo.SCOM_ALERTS_QUEUE ORDER BY TimeStmp"

foreach ($alert in $AlertsQ ){
    
    Write-Host $alert.AlertID -ForegroundColor Yellow

    #Create mail recipient dim
    $subQ = "$subQuery".Replace("SUBSCRIPTION_ID","$($alert.SubscriptionID)")
    $subscribers = Get-DatabaseData -connectionString $conStr -query $subQ
    $to = @()
    $subscribers | % {if($_.Devicename){$to += $_.Devicename}}

    #Get Alert Info
    
    $alertQ = "$alertQuery".Replace("ALERT_ID","$($alert.AlertID)")
    $alertInfo =  Get-DatabaseData -connectionString $conStr -query $alertQ
    

    
    #Send Mail
    $subj = 'Alert'
    $body = Get-XML $alertInfo 
    Send-MailMessage -BodyAsHtml -From $from -To $to -Subject $subj -Body $body -SmtpServer $smtp -Encoding UTF8 -Verbose

    #Invoke-DatabaseQuery `
    # -connectionString $conStr `
    # -query "DELETE FROM dbo.SCOM_ALERTS_QUEUE WHERE QID = '$($alert.QID)'" | Out-Null


    pause

}












