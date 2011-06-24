<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:mpx="http://www.mpx.org/mpx"
	xmlns:mpxvok="http://www.mpx.org/mpxvok" xmlns:func="http://www.mpx.org/mpxfunc"
	exclude-result-prefixes="mpx xs func mpxvok">

	<!--
	DESCRIPTION
	mpx-newfix is meant as system that will gradually expanded and finally replace the old 
	badly written mpx fix. For the time being, we will run both of them in the tool chain. 
		
	The basic idea remains the same: expect as input mpx and output mpx. Correct various 
	mistakes on the way. Do not change anything if data is correct.

	Write an intelligible log file describing the changes.
		
	HISTORY. 
	(For a more detailed history see the github repository)
	
	2011-06-24 mpx-newfix will be XSLT 2. 
	-->

	<!--
		IMPORT VS INCLUDE
		with import oder is important since it has low precendence;
		with import I had trouble to take precedence over the rule of the
		identity template. So better take include. It has a high precedence
		
		<xsl:include href="mpx-fix/functions.xsl"/>
	-->
	<xsl:include href="mpx-fix/multimediaobjekt.xsl"/>
	<xsl:include href="mpx-fix/sammlungsobjekt.xsl"/>
	<xsl:include href="mpx-fix/personKörperschaft.xsl"/>

	<!--
		xsl:include href="mpx-fix/generell.xsl"/
	-->

	<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
	<xsl:strip-space elements="*"/>

	<xsl:template match="@*|node()">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>

</xsl:stylesheet>
