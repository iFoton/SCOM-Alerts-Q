﻿function Get-DatabaseData { 

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
    $adapter.SelectCommand.CommandTimeout = 0
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

function fnMamlToHTML
{
    param ($MAMLText) 
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

function Get-HTML {
    param ( 
        $alert,
        $xslt    
    ) 
    
    $exludeFields = 'RowError','RowState','Table','ItemArray','HasErrors',
                    'QID', 'SubscriptionID','Source','AlertParams','TimeStmp'

    #Fill Description
    $param = [xml]$alert.AlertParams
    $paramCount = ($param.AlertParameters.ChildNodes).Count
        
    if ($paramCount -gt 0) {
        
        $desc = $Alert.Alert_Description
        
        for ($i=0;$i -lt $paramCount;$i++) {
            $desc = $desc.Replace("{$i}","$($param.AlertParameters."AlertParameter$($i+1)")")
        }

        $Alert.Alert_Description = $desc
    }

    #Fill Knowledge
    if ($Alert.Knowledge.Length -gt 1) {
        $Knowledge = fnMamlToHTML $Alert.Knowledge
        $Alert.Knowledge = 'Knowledge_replace'
    } else {
        $exludeFields += 'Knowledge'
    }

    #Context
    If ($alert.Context.Length -gt 1){
        $xmlContext = New-Object system.Xml.XmlDocument
        $xmlContext.LoadXml($alert.Context)
        If ($xmlContext.DataItem.Property){
				
		    $Context = $xmlContext.DataItem.Property | Select-Object Name , @{Name="Value";Expression={$_."#text"}} | ConvertTo-HTML | Out-String		

	    } else {

            $Context = "<table>"
            $out = ($xmlContext.DataItem | Out-String).Split("`n")

		    ForEach ($Line in $out){
                if ($Line.Length -gt 1) {
                    $Context += ("<tr><td>" + $Line.Replace(" : ",":</td><td>") + "</td></tr>")
                }
		    }
            $Context += "</table>"
        }

        $alert.Context = "Context_replace"
    }

    #Create XML
    $xml = New-Object system.Xml.XmlDocument
    $xml.LoadXml("<?xml version=`"1.0`" encoding=`"utf-8`"?><Alert></Alert>")
    $xmlA = $xml.SelectSingleNode("//Alert")
    
    #Fill XML
    foreach ($alertProp in ($alert.psobject.properties | select -ExpandProperty Name | ? {$_ -notin $exludeFields})) {
        
        $node = $xml.CreateElement("$alertProp")
        $xmlAtt = $xml.CreateAttribute("Name")
        
        $name = "$alertProp".replace("_"," ")
        If ($name -like 'MonitorRule*') {
            
            if ($alert.Type -eq 'Monitor') {

                $name  = $name.Replace('Rule','')

            } else  {

                $name  = $name.Replace('Monitor','')

            }

        }

        $xmlAtt.Value  = $name
        $node.Attributes.Append($xmlAtt) | Out-Null
        $xmlA.AppendChild($node) | Out-Null
        $xmlA."$alertProp".InnerText = $alert."$alertProp".tostring()

    }
    
    #Create HTML    
    $xmlStrReader = New-Object System.IO.StringReader($xml.InnerXml)
    $xmlReader    = [System.Xml.XmlReader]::Create($xmlStrReader)
    $htmlWriter   = New-Object System.IO.StringWriter("")
        
    $xslt.Transform($xmlReader,$null,$htmlWriter)
    $html = $htmlWriter.ToString().Replace('Knowledge_replace',$Knowledge).Replace("Context_replace",$Context)

    Return $html

}

if ($PSscriptRoot) {
    $rootPath = $PSscriptRoot    
} else {
    $rootPath = "C:\Users\ivan\OneDrive\Документы\GDC\AlertsQ"
    }

#Get Settings and Prepare Objects
$confXml = [xml](Get-Content (Join-Path $rootPath "Config.xml")) 
$conStr  = $confXml.Settings.Sender.SQLConnectionString
$from    = $confXml.Settings.Sender.FromAddress
$smtp    = $confXml.Settings.Sender.SMTPServerAddress

$xslt = New-Object System.Xml.Xsl.XslCompiledTransform
$xslt.Load("$rootPath\template.xsl")

$stoperrors = 'Unable to connect to the remote server'

#Get Subscriptions
$subQ = "SELECT * FROM [SCOMAddons].[dbo].[SubscriptionsView]"
$subscribtions = Get-DatabaseData -connectionString $conStr -query $subQ


#Get alerts from Queue
$AlertsQ =  Get-DatabaseData -connectionString $conStr -query "SELECT DISTINCT * FROM (SELECT TOP 100 * FROM [SCOMAddons].[dbo].[AlertsQueueView]) AS TMP"

:SA foreach ($alert in $AlertsQ ) {
    
    Write-Host $alert.Alert_ID -ForegroundColor Yellow
    
    #Create mail recipient dim
    $subscribtion = $subscribtions | ? {$_.SubscriptionId -eq $alert.SubscriptionId}
    $to = $subscribtion | Select -ExpandProperty Address
    
    #Fill Subscription fields
    $alert.Subscription = $subscribtion.SubscriptionName | Select -Unique
    $alert.Subscribers  = $to -join "; " 
        
    #Fill subject
    $alert.Resolution_State = "$($alert.Resolution_State)".Replace("Added to Queue (10)","New (0)")
    $subj = "$($alert.Resolution_State)".Split(" ")[0]  + ", Severity: " +
            $alert.Severity + ", Subscription: " +
            $alert.Subscription + ", Details: " + 
            $alert.MonitoringObjectDisplayName + ", " + 
            $alert.Alert_Name
    
    #Fill body           
    $body = Get-HTML $alert $xslt

    #Send Mail
    Send-MailMessage -BodyAsHtml -From $from -To $to -Subject $subj -Body $body -SmtpServer $smtp -Encoding UTF8 -Verbose -ErrorVariable er
    
    #Check for errors
    if ($er.Count -gt 0){

        foreach ($e in $er) {

            if ($e.Exception.Message -in $stoperrors) {
                break SA
            }
        }
    }

    #If no Errors then remove Alert from Q
    Invoke-DatabaseQuery `
        -connectionString $conStr `
        -query "DELETE FROM [SCOMAddons].[dbo].[AlertsQueue] WHERE QID = '$($alert.QID)'" | Out-Null

}

#Write log
$date = Get-Date -f {dd.MM.yyyy HH:mm:ss}
foreach ($e in ($error.Exception.message | select -Unique)) {
     
     "[$date] " + $e >> $rootPath\Error.log

}

$error.Clear()
