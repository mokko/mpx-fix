<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" exclude-result-prefixes="mpx xs func mpxvok"
  xmlns="http://www.mpx.org/mpx" xmlns:mpx="http://www.mpx.org/mpx"
  xmlns:func="http://www.mpx.org/mpxfunc" xmlns:mpxvok="http://www.mpx.org/mpxvok"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">


  <!--
		F1: Sammlungsobjekte mit der Verantwortlichkeit 'Musterdatensätze Sammlung' werden aussortiert
		TODO: test
  -->

  <xsl:template
    match="/mpx:museumPlusExport/mpx:sammlungsobjekt [mpx:verantwortlichkeit = 'Musterdatensätze Sammlung']">
    <xsl:message>
      <xsl:value-of
        select=" 'F1: Drop sammlungsobjekt if verantwortlichkeit = Musterdatensätze Sammlung' "/>
    </xsl:message>
  </xsl:template>


  <!-- F2: Delete trailing star from sachbegriff -->
  <xsl:template match="/mpx:museumPlusExport/mpx:sammlungsobjekt/mpx:sachbegriff">
    <xsl:variable name="objId" select="../@objId"/>
    <xsl:choose>
      <xsl:when test="matches (.,'\*$')">
        <xsl:message>
          <xsl:value-of select=" 'F2: Del trailing star sachbegriff:', ., $objId"/>
        </xsl:message>
        <xsl:element name="sachbegriff">
          <xsl:copy-of select="@*"/>
          <xsl:value-of select="substring-before(.,'*')"/>
        </xsl:element>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="."/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
