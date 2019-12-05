<?xml version="1.0" encoding="ISO-8859-15"?>
<xsl:stylesheet version="1.1"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    >
<!--
   - htmlgen.xslt - read index file and generate ALL HTML files!
  -->

<xsl:output encoding="ISO-8859-15"/>

<xsl:variable name="headerfooter.css">
  .header, .footer {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 0 16px;
    background-color: #648ca6;
  }
</xsl:variable>

<xsl:variable name="sidenav.css">
  .sidenav {
    display: flex; /* Will be hidden on mobile */
    flex-direction: column;
    grid-area: sidenav;
    background-color: #394263;
  }
  .sidenav__list {
    padding: 0;
    margin-top: 85px;
    list-style-type: none;
  }
  .sidenav__list-item {
    padding: 20px 20px 20px 40px;
    color: #ddd;
  }
  .sidenav__list-item:hover {
    background-color: rgba(255, 255, 255, 0.2);
    cursor: pointer;
  }

</xsl:variable>

<xsl:variable name="main.css">
    /* Simple dashboard grid CSS */

    /* Assign grid instructions to our parent grid container */
    .grid-container {
      display: grid;
      grid-template-columns: 240px 1fr;
      grid-template-rows: 50px 1fr 50px;
      grid-template-areas:
        "sidenav header"
        "sidenav main"
        "sidenav footer";
      height: 100vh;
    }

    /* Give every child element its grid name */
    .header {
      grid-area: header;
      background-color: #648ca6;
    }

    .sidenav {
      grid-area: sidenav;
      background-color: #394263;
    }

    .main {
      grid-area: main;
      background-color: #8fd4d9;
    }

    .footer {
      grid-area: footer;
      background-color: #648ca6;
    }
</xsl:variable>


<!-- GenHTML: generate output HTML file for a given XML input file. -->
<xsl:template name="GenHTML">
    <xsl:param name="XmlFile"/>
    <xsl:param name="HTMLFile"/>
    
    <xsl:message>
        <xsl:value-of
        select="concat('GenHTML ',$XmlFile, ' ', $HTMLFile)"/>
    </xsl:message>
    
    <xsl:document href="{$HTMLFile}" method="html">
        <html>
        <head>
        <style>
            <xsl:value-of select="$main.css"/>
            <xsl:value-of select="$sidenav.css"/>
            <xsl:value-of select="$headerfooter.css"/>
        </style>
        </head>
        <body>
            <div class="grid-container">
                <header class="header"></header>
                <aside class="sidenav"></aside>
                <main class="main">
                    <xsl:apply-templates
                        select="document($XmlFile)/Xml/body/*"/>
                </main>
                <footer class="footer"></footer>
            </div>
        </body>
        </html>
    </xsl:document>
</xsl:template>

<!-- DoDir: scan each Index's children, recurse on other Index'es -->
<xsl:template name="DoDir">
    <xsl:param name="ParentPath"/>

    <xsl:message>
        <xsl:value-of select="concat('DoNode ',$ParentPath)"/>
    </xsl:message>

    <!-- generate HTML for this directory's XML file -->
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
            <!-- generate HTML for this XML file -->
            <xsl:call-template name="GenHTML">
                <xsl:with-param name="XmlFile"
                    select="concat($ParentPath,'/',@href,'.xml')"/>
                <xsl:with-param name="HTMLFile"
                    select="concat($ParentPath,'/',@href,'.html')"/>
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
