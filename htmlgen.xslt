<?xml version="1.0" encoding="ISO-8859-15"?>
<xsl:stylesheet version="1.1"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
          xmlns:func="http://exslt.org/functions"
          extension-element-prefixes="func"
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

<!-- GetPath: return full path associated with this node.
  -->
<func:function name="func:GetPath">
    <xsl:param name="node" select="."/>

    <xsl:choose>
    <xsl:when test="name($node/..)='Index'">
        <func:result
            select="concat(func:GetPath($node/..),$node/@href,'/')"
        />
    </xsl:when>
    <xsl:otherwise>
        <func:result select="'/'"/>
    </xsl:otherwise>
    </xsl:choose>
</func:function>

<!-- MasterIndex: make copy of input masterindex, annotated for us.
   -
  -->
<xsl:variable name="MasterIndex">
    <xsl:apply-templates mode="annotate"/>
</xsl:variable>
<xsl:template match="Index|Entry" mode="annotate">
    <xsl:variable name="Path" select="func:GetPath(.)"/>
    <xsl:variable name="PathTrim"
        select="substring($Path,1,string-length($Path)-1)"
        />
    <xsl:copy>
        <xsl:choose>
            <xsl:when test="name()='Index'">
                <xsl:attribute name="input">
                    <xsl:value-of
                        select="concat('.',$Path,'index.xml')"/>
                </xsl:attribute>
                <xsl:attribute name="output">
                    <xsl:value-of
                        select="concat('.',$Path,'index.html')"/>
                </xsl:attribute>
                <xsl:attribute name="abs">
                    <xsl:value-of
                        select="concat($Path,'index.html')"/>
                </xsl:attribute>
            </xsl:when>
            <xsl:otherwise>
                <xsl:attribute name="input">
                    <xsl:value-of
                        select="concat('.',$PathTrim,'.xml')"/>
                </xsl:attribute>
                <xsl:attribute name="output">
                    <xsl:value-of
                        select="concat('.',$PathTrim,'.html')"/>
                </xsl:attribute>
                <xsl:attribute name="abs">
                    <xsl:value-of
                        select="concat($PathTrim,'.html')"/>
                </xsl:attribute>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:copy-of select="@*" />
        <xsl:apply-templates mode="annotate"/>
    </xsl:copy>
</xsl:template>

<!-- GenHTML: generate output HTML file for a given XML input file.
   -
   - Note that current node is the one in masterindex.xml.
 -->
<xsl:template name="GenHTML">
    <xsl:param name="XmlFile"/>
    <xsl:param name="HTMLFile"/>
    
    <xsl:message>
        <xsl:value-of
        select="concat('GenHTML ',$XmlFile, ' ', $HTMLFile)"/>
        <xsl:value-of
        select="concat('    UP= ',func:GetPath())"/>
    </xsl:message>
    
    <!-- UP is parent node, or empty if we are the topmost node. -->
    <xsl:variable name="UP" select=".."/>
    <xsl:choose>
    <xsl:when test="name(..)='Index'">
        <xsl:message> UP is present</xsl:message>
    </xsl:when>
    <xsl:otherwise>
        <xsl:message> UP is not present</xsl:message>
    </xsl:otherwise>
    </xsl:choose>

    <xsl:variable name="NEXT" />
    
    <!-- create output HTML file here -->
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
                    <xsl:if test="@href">
                        <xsl:for-each select="*">
                            <xsl:variable name="Title"
                                select="document(@href)/Xml/head/title"
                                          />
                            <p>
                                <a href="{func:GetPath(.)}">
                                    <xsl:value-of select="$Title"/>
                                </a>
                            </p>
                        </xsl:for-each>
                    </xsl:if>
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
            <xsl:call-template name="DoDir">
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
 <xsl:copy-of select="$MasterIndex"/>

    <!-- should only be one (outer) "Index" -->
    <xsl:for-each select="/Index">
        <xsl:call-template name="DoDir">
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
