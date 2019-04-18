<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    version="2.0"
    exclude-result-prefixes="xsl tei xs">

<!-- identity template -->
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

<!-- add languages -->
    <xsl:template match="/TEI/teiHeader[1]/fileDesc[1]/titleStmt[1]/title[1]">
        <xsl:element name="title" namespace="http://www.tei-c.org/ns/1.0">
            <xsl:attribute name="type">main</xsl:attribute>
            <xsl:attribute name="xml:lang">en</xsl:attribute>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="/TEI/teiHeader[1]/fileDesc[1]/titleStmt[1]/title[2]">
        <xsl:element name="title" namespace="http://www.tei-c.org/ns/1.0">
            <xsl:attribute name="type">main</xsl:attribute>
            <xsl:attribute name="xml:lang">es</xsl:attribute>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>

<!-- adding line return after the processing instruction -->
    <xsl:template match="processing-instruction()">
        <xsl:text>
</xsl:text>
        <xsl:copy />
    </xsl:template>

<!-- adding line return before the processing instruction -->
    <xsl:template match="TEI">
        <xsl:text>
</xsl:text>
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>