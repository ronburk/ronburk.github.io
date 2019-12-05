<?xml version="1.0" encoding="ISO-8859-15"?>
<xsl:stylesheet version="1.1"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    >
<!--
   - htmlgen.xslt - read index file and generate ALL HTML files!
  -->

<xsl:output encoding="ISO-8859-15"/>
<xsl:output method="html"/>

<xsl:template name="GenHTML">
    <xsl:param name="XmlFile"/>
    <xsl:param name="HTMLFile"/>
    
    <xsl:message>
        <xsl:value-of select="concat('GenHTML ',$XmlFile, ' ', $HTMLFile)"/>
    </xsl:message>
</xsl:template>

<xsl:template name="DoDir">
    <xsl:param name="ParentPath"/>

    <xsl:message>
        <xsl:value-of select="concat('DoNode ',$ParentPath)"/>
    </xsl:message>

    <xsl:call-template name="GenHTML">
        <xsl:with-param name="XmlFile" select="concat($ParentPath,'/index.xml')"/>
        <xsl:with-param name="HTMLFile" select="concat($ParentPath,'/index.html')"/>
    </xsl:call-template>
    <!-- for each child element of this directory node -->
    <xsl:for-each select="*">
        <xsl:variable name="Path" select="concat($ParentPath,'/',@href)"/>
        <xsl:message>    <xsl:value-of select="concat('mypath=',$Path)"/>
        </xsl:message>
        <xsl:choose>
        <xsl:when test="name(.)='Index'">
            <xsl:call-template name="DoDir" select=".">
                <xsl:with-param name="ParentPath" select="$Path"/>
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:call-template name="GenHTML">
                <xsl:with-param name="XmlFile" select="concat($ParentPath,'/',@href,'.xml')"/>
                <xsl:with-param name="HTMLFile" select="concat($ParentPath,'/',@href,'.html')"/>
            </xsl:call-template>
        </xsl:otherwise>
        </xsl:choose>
    </xsl:for-each>

</xsl:template>

<xsl:template match="/">
    <xsl:for-each select="/Index">
        <xsl:call-template name="DoDir" select=".">
            <xsl:with-param name="ParentPath" select="@href"/>
        </xsl:call-template>
    </xsl:for-each>
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
