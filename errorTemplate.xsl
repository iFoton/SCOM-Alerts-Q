<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:template match="/">
		<html>
			<head>
				<title>ALERT</title>
			</head>
			<body>
				<h2 align="center">Alert</h2>
				<table border="1" cellpadding="0" align="center" width="50%">
					<xsl:for-each select="Alert/*">
      					<tr>
							<td><xsl:value-of select="name()"/></td>
							<td><xsl:value-of select="node()"/></td>
      					</tr>
      				</xsl:for-each>
				</table>
			</body>
		</html>
	</xsl:template>
</xsl:stylesheet>	



