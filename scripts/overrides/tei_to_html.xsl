<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xpath-default-namespace="http://www.tei-c.org/ns/1.0"
  version="2.0"
  exclude-result-prefixes="xsl tei xs">

<!-- ==================================================================== -->
<!--                             IMPORTS                                  -->
<!-- ==================================================================== -->
  
  <xsl:import href="../.xslt/tei_to_html/lib/formatting.xsl"/>
  <xsl:import href="../.xslt/tei_to_html/lib/personography_encyclopedia.xsl"/>
  <xsl:import href="../.xslt/tei_to_html/lib/cdrh.xsl"/>
  

  <!-- For display in TEI framework, have changed all namespace declarations 
    to http://www.tei-c.org/ns/1.0. If different (e.g. Whitman), will need to change -->
  <xsl:output method="html" indent="yes" encoding="utf-8" omit-xml-declaration="yes"/>

  <!-- Removes excess space at the top of output file -->
  <!--<xsl:strip-space elements="*"/>-->
  <xsl:preserve-space elements="*"/>
  <!-- todo: Ask Andy about this. I know why to strip space but it is stripping space in weird places.  -->


<!-- ==================================================================== -->
<!--                           PARAMETERS                                 -->
<!-- ==================================================================== -->
  
  <!-- set params for development, which will be served through cocoon
       will be overwritten for production -->

  <xsl:param name="collection"/>
  <xsl:param name="environment">production</xsl:param>
  <xsl:param name="image_large">1000</xsl:param>
  <xsl:param name="image_thumb">100</xsl:param>
  <xsl:param name="data_base"/>
  <xsl:param name="media_base"/>
  <xsl:param name="shortname"/>
  <xsl:param name="site_url"/><!-- unused -->
  
  <xsl:param name="image_annotations">800</xsl:param>
  
  <!-- Andy's variable -->
  <xsl:variable name="fileID">
    <xsl:value-of select="//tei:TEI/descendant::tei:fileDesc/tei:publicationStmt/tei:idno"/>
  </xsl:variable>

<!-- ==================================================================== -->
<!--                            OVERRIDES                                 -->
<!-- ==================================================================== -->
  
  <xsl:template match="pb">
    <!-- grab the figure id, first looking in @facs, then @xml:id, and if there is a .jpg, chop it off -->
    <xsl:variable name="figure_id">
      <xsl:variable name="figure_id_full">
        <xsl:choose>
          <xsl:when test="@facs"><xsl:value-of select="@facs"></xsl:value-of></xsl:when>
          <xsl:when test="@xml:id"><xsl:value-of select="@xml:id"></xsl:value-of></xsl:when>
        </xsl:choose>
      </xsl:variable>
      <xsl:choose>
        <xsl:when test="contains($figure_id_full,'.jpg')">
          <xsl:value-of select="substring-before($figure_id_full,'.jpg')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$figure_id_full"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <span class="hr">&#160;</span>
    <xsl:if test="$figure_id != ''">
      <span>
        <xsl:attribute name="class">
          <xsl:text>pageimage</xsl:text>
        </xsl:attribute>
        <a>
          <xsl:attribute name="href">
            <xsl:value-of select="$media_base"/>
            <xsl:value-of select="$figure_id"/>
            <xsl:text>.jpg/full/!1000,1000/0/default.jpg</xsl:text>
          </xsl:attribute>
          <xsl:attribute name="rel">
            <xsl:text>prettyPhoto[pp_gal]</xsl:text>
          </xsl:attribute>
          <xsl:attribute name="title">
            <xsl:text>&lt;a href="</xsl:text>
            <xsl:value-of select="$media_base"/>
            <xsl:value-of select="$figure_id"/>
            <xsl:text>.jpg/full/!1000,1000/0/default.jpg</xsl:text>
            <xsl:text>" target="_blank" &gt;open image in new window&lt;/a&gt;</xsl:text>
          </xsl:attribute>
          
          <img>
            <xsl:attribute name="src">
              <xsl:value-of select="$media_base"/>
              <xsl:value-of select="$figure_id"/>
              <xsl:text>.jpg/full/!100,100/0/default.jpg</xsl:text>
            </xsl:attribute>
            <xsl:attribute name="class">
              <xsl:text>display</xsl:text>&#160;
            </xsl:attribute>
          </img>
        </a>
      </span>
    </xsl:if>
  </xsl:template>
  
  <!-- TODO this is not a great way to do this.... -->
  <xsl:template match="//body/div1[@type='letter'][1]">
    <h3>
      Original
    </h3>
    <xsl:apply-templates/>
  </xsl:template>
  
  <xsl:template match="//body/div1[@type='letter'][2]">
    <h3>
      Translation
    </h3>
    <xsl:apply-templates/>
  </xsl:template>

</xsl:stylesheet>
