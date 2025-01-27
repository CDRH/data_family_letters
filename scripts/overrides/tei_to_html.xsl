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
  
  <xsl:import href="../.xslt-datura/tei_to_html/lib/formatting.xsl"/>
  <xsl:import href="../.xslt-datura/tei_to_html/lib/personography_encyclopedia.xsl"/>  
  <!-- For display in TEI framework, have changed all namespace declarations 
    to http://www.tei-c.org/ns/1.0. If different (e.g. Whitman), will need to change -->
  <xsl:output method="html" indent="yes" encoding="utf-8" omit-xml-declaration="yes"/>

<!-- ==================================================================== -->
<!--                           PARAMETERS                                 -->
<!-- ==================================================================== -->
 

  <xsl:param name="collection"/>
  <xsl:param name="environment">production</xsl:param>
  <xsl:param name="image_large">1000</xsl:param>
  <xsl:param name="image_thumb">100</xsl:param>
  <xsl:param name="data_base"/>
  <xsl:param name="media_base"/>
  <xsl:param name="shortname"/>
  <xsl:param name="site_url"/>
  

<!-- ==================================================================== -->
<!--                            OVERRIDES                                 -->
<!-- ==================================================================== -->
  
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
