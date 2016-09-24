<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:template match="/">

		<xsl:variable name="color">
			<xsl:choose>
			<xsl:when test="Alert/Severity/node() = 'Warning'">#FAAC58</xsl:when>
			<xsl:when test="Alert/Severity/node() = 'Critical'">#F78181</xsl:when>
			<xsl:otherwise>#FFFFFF</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<html>
			<head>
				<style>
					table { width: 50%; }
					div   { max-width: 10px; }
				</style>
				<title>ALERT</title>
			</head>
			<body bgcolor="#2b2b2b">
				<h1 align="center" style="color:#ffffff">Alert</h1>
				<div>
				<table border="1" cellpadding="5" align="center" bgcolor="#ffffff">
					<xsl:for-each select="Alert/*">
                        <xsl:if test="not(@Name = 'Knowledge')">
							<tr>
								<td bgcolor="{$color}"><b><xsl:value-of select="./@Name"/></b></td>
								<td><xsl:value-of select="node()"/></td>
							</tr>
                        </xsl:if>
                        <xsl:if test="@Name = 'Knowledge'">
							<tr>
								<td colspan="2" align="center"><b><h3><xsl:value-of select="./@Name"/></h3></b></td>
							</tr>
							<tr>
								<td colspan="2"><xsl:value-of select="node()"/></td>
							</tr>
                        </xsl:if>
      				</xsl:for-each>
				</table>
				</div>
			</body>
		</html>
	</xsl:template>
</xsl:stylesheet>

