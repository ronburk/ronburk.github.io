<?xml version="1.0" encoding="ISO-8859-15"?>
<xsl:stylesheet version="1.1"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
          xmlns:func="http://exslt.org/functions"
          xmlns:exsl="http://exslt.org/common"
          extension-element-prefixes="func exsl"
    >
<!--
   - htmlgen.xslt - read index file and generate ALL HTML files!
   -
   - You must maintain "masterindex.xml", which is a simple XML
   - representation of the complete set of XML files we will xform
   - into HTML.
   -
   - Inside the global variable $MasterIndex, we create a copy of
   - the "masterindex.xml" file in which we have added some information
   - for convenience.
   - 
   - Finally, we make a pass over $MasterIndex to locate each XML
   - file and create its matching .html file.
   - 
  -->

<xsl:output encoding="ISO-8859-15"/>

<xsl:variable name="menu.css">

/* [COLLAPSIBLE] */
#menutree label {
  position: relative;
  display: block;
  width: 100%;
  cursor: pointer;
}
#menutree {
  list-style-type: none;
  padding-left: 3px;
  margin: 0;
  font-size: smaller;
}

#menutree, #menutree ul {
  list-style-type: none;
  padding-left: 1em;
  margin: 0;
}
#menutree input[type=checkbox] {
  display: none; /* Hide ugly checkbox */
}

#menutree a, #menutree a:visited {
  color: white;
  text-decoration: none;
}
/* Hide/collapse by default */
li.collapse ul {
  visibility: hidden;
  opacity: 0;
  max-height: 0; /* CSS bug. Cannot animate height... */
  transition: all 0.5s;
}
label::before {
  content: "\25b6";
  position: absolute;
  top: 0;
  right: 0;
  transition: all 0.5s;
}

/* Show when checked */
li.collapse input:checked ~ ul {
  visibility: visible;
  opacity: 1;
  max-height: 999px; /* Just give a big enough height for animation */
}
li.collapse input:checked ~ label::before {
  transform: rotate(90deg);
  }
</xsl:variable>

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
<!-- add some convenient attributes to Index and Entry elements.
  -->
<xsl:template match="Index|Entry" mode="annotate">
    <xsl:variable name="Path" select="func:GetPath(.)"/>
    <xsl:variable name="PathTrim"
        select="substring($Path,1,string-length($Path)-1)"
        />
    <xsl:copy>
        <xsl:attribute name="id">
            <xsl:value-of select="generate-id()"/>
        </xsl:attribute>
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


<xsl:template match="Index" mode="GenNav">
    <xsl:param name="This"/>
    <li class="collapse">
        <input type="checkbox" id="{generate-id()}">
            <xsl:if test="descendant-or-self::*[@id=$This/@id]">
                <xsl:attribute name="class">
                    <xsl:text>open-on-load</xsl:text>
                </xsl:attribute>
            </xsl:if>
        </input>
        <label for="{generate-id()}"> </label>
            <a href="{@abs}">
                <xsl:apply-templates select="document(@input)//title/node()"/>
            </a>
        <ul>
            <xsl:apply-templates mode="GenNav">
                <xsl:with-param name="This" select="$This"/>
            </xsl:apply-templates>
        </ul>
    </li>
</xsl:template>

<xsl:template match="Entry" mode="GenNav">
    <xsl:param name="This"/>
    <li>
        <a href="{@abs}">
            <xsl:apply-templates select="document(@input)//title/node()"/>
        </a>
    </li>
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
    <xsl:variable name="UP">
        <xsl:if test="name(..)='Index'">
            UP:
            <a href="{../@abs}">
                <xsl:value-of select="document(../@input)/Xml/head/title/node()"/>
            </a>
        </xsl:if>
    </xsl:variable>

    <!-- NEXT is next sibling, or empty if we are last sibling -->
    <xsl:variable name="NEXT">
        <xsl:for-each select="(child::* | following-sibling::*)[1]">
            <xsl:text>NEXT: </xsl:text>
            <a href="{@abs}">
                <xsl:value-of select="document(@input)/Xml/head/title/node()"/>
            </a>
        </xsl:for-each>
    </xsl:variable>

    <!-- PREV is next sibling, or empty if we are last sibling -->
    <xsl:variable name="PREV">
        <xsl:for-each select="(ancestor::* | preceding-sibling::*)[last()]">
            <xsl:text>PREV: </xsl:text>
            <a href="{@abs}">
                <xsl:value-of select="document(@input)/Xml/head/title/node()"/>
            </a>
        </xsl:for-each>
    </xsl:variable>
    
    <!-- create output HTML file here -->
    <xsl:document href="{@output}" method="html" indent="yes">
        <html>
        <head>
        <style>
            <xsl:value-of select="$main.css"/>
            <xsl:value-of select="$sidenav.css"/>
            <xsl:value-of select="$menu.css"/>
            <xsl:value-of select="$headerfooter.css"/>
        </style>
        <script>
            function InitNav(){
                //document.getElementsByClassName("open-on-load").checked = true;
                let nodes = document.getElementsByClassName("open-on-load");
                for(let i = 0; i &lt; nodes.length; ++i){
                    nodes[i].click();
                    }
                }
                window.onload = InitNav;
        </script>
        </head>
        <body><xsl:text>&#10;</xsl:text>
            <div class="grid-container">
                <header class="header">
                    <xsl:apply-templates
                        select="document(@input)/Xml/head/title/node()"/>
                </header><xsl:text>&#10;</xsl:text>
                <aside class="sidenav"><xsl:text>&#10;</xsl:text>
                <ul id="menutree">
                    <xsl:apply-templates select="exsl:node-set($MasterIndex)/Index" mode="GenNav">
                        <xsl:with-param name="This" select="."/>
                    </xsl:apply-templates>
                </ul><xsl:text>&#10;</xsl:text>
                </aside><xsl:text>&#10;</xsl:text>
                <main class="main">
                    <xsl:apply-templates
                        select="document(@input)/Xml/body/*"/>
                    <xsl:if test="@href">
                        <xsl:for-each select="*">
                            <xsl:variable name="Title"
                                select="document(@input)/Xml/head/title"
                                          />
                            <p>
                                <a href="{func:GetPath(.)}">
                                    <xsl:value-of select="$Title"/>
                                </a>
                            </p>
                        </xsl:for-each>
                    </xsl:if>
                </main>
                <footer class="footer">
                    <div>
                        <xsl:copy-of select="$NEXT"/>
                    </div>
                    <div>
                        <xsl:if test="name(..)='Index'">
                            <xsl:copy-of select="$UP"/>
                        </xsl:if>
                    </div>
                    <div>
                        <xsl:copy-of select="$PREV"/>
                    </div>
                </footer>
            </div>
        </body>
        </html>
    </xsl:document>
</xsl:template>

<!-- DoDir: scan each Index's children, recurse on other Index'es -->
<xsl:template name="DoDir">
    <xsl:param name="ParentPath"/>

    <xsl:message>
        <xsl:value-of select="concat('DoDir ',$ParentPath)"/>
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
    <xsl:for-each select="exsl:node-set($MasterIndex)/Index">
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
