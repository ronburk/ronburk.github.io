<?xml version="1.0" encoding="ISO-8859-15"?>
<xsl:stylesheet version="1.1"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    href="htmlgen.xslt">
<!--
   - htmlgen.xslt - read index file and generate ALL HTML files!
  -->

<xsl:output encoding="ISO-8859-15"/>
<xsl:output method="html"/>

<!-- pull index into a variable -->
<xsl:variable name="MasterIndex" select="./masterindex.xml"/>

<xsl:template match="/">
<xsl:message>Found match /
</xsl:message>
    <xsl:apply-templates select="$MasterIndex/Index"/>
</xsl:template>

<xsl:template match="Index">
<xsl:message>Found index with href=<xsl:value-of select="@href"/>
</xsl:message>
<html>
    <head>
    <xsl:if test="/Xml/title">
        <xsl:apply-templates select="/Xml/title/*"/>
    </xsl:if>
    </head>
    <body>
    <xsl:if test="/Xml/body">
        <xsl:apply-templates select="/Xml/body/*"/>
    </xsl:if>
    </body>
</html>
</xsl:template>

<xsl:template match="@*|node()">
    <xsl:copy>
        <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
</xsl:template>
</xsl:stylesheet>
