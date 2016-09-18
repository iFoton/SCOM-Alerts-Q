<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:template match="/">
		<html>
			<head>
				<title>ALERT</title>
			</head>
			<body>
				<h2 align="center">Alert</h2>
				<table border="1" cellpadding="5" align="center" width="50%">
					<xsl:for-each select="Alert/*">
                        <xsl:if test="not(@Name = 'Knowledge')">
							<tr>
								<td><xsl:value-of select="./@Name"/></td>
								<td><xsl:value-of select="node()"/></td>
							</tr>
                        </xsl:if>
                        <xsl:if test="@Name = 'Knowledge'">
							<tr>
								<td colspan="2" align="center"><xsl:value-of select="./@Name"/></td>
							</tr>
							<tr>
								<td colspan="2"><xsl:value-of select="node()"/></td>
							</tr>
                        </xsl:if>
      				</xsl:for-each>
				</table>
			</body>
		</html>
	</xsl:template>
</xsl:stylesheet>

