<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" exclude-result-prefixes="mpx xs func mpxvok"
    xmlns="http://www.mpx.org/mpx" xmlns:mpx="http://www.mpx.org/mpx"
    xmlns:func="http://www.mpx.org/mpxfunc" xmlns:mpxvok="http://www.mpx.org/mpxvok"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    
	<!--
		[not (exists(mpx:titel)) or not (exists(mpx:verwaltendeInstitution))]
	-->

    <xsl:template match="/museumPlusExport">
        <xsl:message>XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXsammlungs</xsl:message>
    </xsl:template>
    

	<xsl:template
		match="/mpx:museumPlusExport/mpx:sammlungsobjekt[mpx:verantwortlichkeit = 'Musterdatensätze Sammlung']">
		<!-- apparently this does not work yet! -->
		<xsl:message>
			<xsl:value-of
				select="'Fix 24: Drop sammlungsobjekt if verantwortlichkeit = Musterdatensätze Sammlung'" />
		</xsl:message>
	</xsl:template>

	<xsl:template match="/mpx:museumPlusExport/mpx:sammlungsobjekt">
		<xsl:variable name="elementnode" select="."/>
		<xsl:variable name="objId" select="@objId"/>
	        <xsl:message>get here</xsl:message>
		<xsl:copy>
			<!-- This seems necessary to copy all the stuff that exists already ... -->
			<xsl:apply-templates select="@*|node()"/>

			<!--
			Check for children of sammlungsobjekt that do NOT exist already
			(in alphabetical order of result element)

			The first is oov. I create [virtual collections] (Mediathek, Phonogramm-Archiv
			and Originalarchiv.

			[Parts and wholes] I also check items of Mediathek if they have track information
			and vice versa and tracks if they have parents and write oov accordingly.
			-->

			<!-- TODO: Dieses Vokabular gehört in MPXVOK.xml
				Film/Video, Ektachrom, Dia/Farbe?
			-->
			<xsl:for-each
				select="/mpx:MuseumPlusExport/mpx:multimediaobjekt[mpx:verlinktesObjekt = $objId]">
				<xsl:message>
					<xsl:value-of
						select="'DDDDDDDDDDDDDD'"
					/>
				</xsl:message>
				<xsl:element name="oov">
					<xsl:attribute name="art">Umfasst</xsl:attribute>
					<xsl:attribute name="id"><xsl:value-of select="@mulId"/></xsl:attribute>
				</xsl:element>
			</xsl:for-each>

			<xsl:if
				test="mpx:sachbegriff = 'CD' or
				mpx:sachbegriff = 'CD-ROM' or
				mpx:sachbegriff = 'DAT'  or
				mpx:sachbegriff = 'DVD'  or
				mpx:sachbegriff = 'Kassette'  or
				mpx:sachbegriff = 'Schallplatte' or
				mpx:sachbegriff = 'Schellackplatte'  or
				mpx:sachbegriff = 'Tonband'  or
				mpx:sachbegriff = 'VCD' or
				mpx:sachbegriff = 'Video' or
				mpx:sachbegriff = 'Walze' ">
				<!-- check if this has already been done! -->
				<xsl:variable name="list" select="mpx:sachbegriff"/>
				<xsl:if test="count($list[@id != mpx:maßangabe[1]])">
					<xsl:element name="maßangabe">
						<xsl:attribute name="typ">Medientyp</xsl:attribute>
						<xsl:value-of select="mpx:sachbegriff"/>
					</xsl:element>
					<xsl:message>
						<xsl:value-of
							select="'Fix 13h: Write maßangabe from Sachbegriff(',$elementnode/@objId,')'"
						/>
					</xsl:message>
				</xsl:if>
			</xsl:if>

			<!-- virtuelle Sammlung: Mediathek -->
			<xsl:if
				test="mpx:verantwortlichkeit = 'EM-Medienarchiv' and (
				contains (mpx:identNr[1], 'VII 78/') or
				contains (mpx:identNr[1], 'VII LP') or
				contains (mpx:identNr[1], 'VII K') or
				contains (mpx:identNr[1], 'VII VB') or
				contains (mpx:identNr[1], 'VII CD')
				) ">
				<!-- art="Gegenstück zu" sachbegriff="Sammlung Originalarchiv">VII OA 0688</oov> -->
				<xsl:if test="not (mpx:oov/@sachbegriff = 'Mediathek')">
					<xsl:message>
						<xsl:value-of
							select="'Fix 20a: Add virtual collection (Mediathek',$elementnode/@objId,')'"
						/>
					</xsl:message>
					<xsl:element name="oov">
						<xsl:attribute name="art">Teil von</xsl:attribute>
						<xsl:attribute name="sachbegriff">Mediathek</xsl:attribute>
					</xsl:element>
				</xsl:if>
				<!--
					Check for parts according to mpx:sachbegriff
					This is parent (whole). Look for children (parts) that belong to this according to identNr
				-->
				<xsl:variable name="thisidentNr" select="mpx:identNr[1]"/>
				<xsl:for-each
					select="/mpx:museumPlusExport/mpx:sammlungsobjekt[
							mpx:sachbegriff = 'Track' and
							contains (mpx:identNr,$thisidentNr) and
							mpx:identNr != $thisidentNr] ">

					<xsl:message>
						<xsl:value-of
							select="'Fix 21: Add oov linking from parent to child(',$elementnode/@objId,')'"
						/>
					</xsl:message>
					<xsl:element name="oov">
						<xsl:attribute name="art">Umfasst</xsl:attribute>
						<xsl:attribute name="id">
							<xsl:value-of select="@objId"/>
						</xsl:attribute>
						<xsl:attribute name="sachbegriff">
							<xsl:value-of select="mpx:sachbegriff"/>
						</xsl:attribute>
						<xsl:value-of select="mpx:identNr"/>
					</xsl:element>
				</xsl:for-each>
				<!--
					Check for parts (children) that need to reference their wholes (parents).
					This check assumes that NO oov has been written so far
				-->
				<xsl:if test="mpx:sachbegriff  = 'Track' ">
					<xsl:variable name="parentIdentNr"
						select="tokenize(mpx:identNr,' ')" />
					<xsl:variable name="parentIdentNr"
						select="normalize-space(string-join (($parentIdentNr[1], $parentIdentNr[2], $parentIdentNr[3]),' '))" />


					<!-- test if oov already exists-->
					<xsl:choose>
						<xsl:when test="not(mpx:oov = $parentIdentNr)">
							<xsl:if test="$parentIdentNr and ($parentIdentNr ne '') ">
								<xsl:element name="oov">
									<xsl:attribute name="art">Teil von</xsl:attribute>
									<xsl:variable name="parent"
										select="/mpx:museumPlusExport/mpx:sammlungsobjekt[mpx:identNr = $parentIdentNr]"/>

									<xsl:attribute name="id">
										<xsl:value-of select="$parent/@objId"/>
									</xsl:attribute>
									<xsl:attribute name="sachbegriff">
										<xsl:value-of select="$parent/mpx:sachbegriff"/>
									</xsl:attribute>
									<xsl:value-of select="$parentIdentNr"/>
								</xsl:element>
								<xsl:message>
									<xsl:value-of
										select="'Fix 22: Add oov linking from child to parent(',$elementnode/@objId,')'"
									/>
								</xsl:message>
							</xsl:if>
						</xsl:when>
						<!--
								otherwise:an oov pointing from the child to the parent is already there. Now I check if all available
								and desirebale 	information (id) is already included in oov. Titles are not desireable
								see below at mpx:oov
						-->
					</xsl:choose>
				</xsl:if>
			</xsl:if>

			<!-- virtuelle Sammlung: Originalarchiv -->
			<xsl:if
				test="mpx:verantwortlichkeit = 'EM-Medienarchiv'  and
				not (mpx:oov/@sachbegriff = 'Originalarchiv') and (
				contains (mpx:identNr[1], 'VII OA') or
				contains (mpx:identNr[1], 'VII VS')
				) ">
				<!-- virtuelle Sammlung -->
				<xsl:message>
					<xsl:value-of
						select="'Fix 20b: Add virtual collection (OA',$elementnode/@objId,')'"/>
				</xsl:message>
				<xsl:element name="oov">
					<xsl:attribute name="art">Teil von</xsl:attribute>
					<xsl:attribute name="sachbegriff">Originalarchiv</xsl:attribute>
				</xsl:element>
			</xsl:if>

			<!-- virtuelle Sammlung: Phonogramm-Archiv -->
			<xsl:if test="mpx:verantwortlichkeit = 'EM-Phonogramm-Archiv' ">
				<!-- virtuelle Sammlung -->
				<xsl:message>
					<xsl:value-of
						select="'Fix 20c: Add virtual collection (BPA',$elementnode/@objId,')'"/>
				</xsl:message>
				<xsl:element name="oov">
					<xsl:attribute name="art">Teil von</xsl:attribute>
					<xsl:attribute name="sachbegriff">Phonogramm-Archiv</xsl:attribute>
				</xsl:element>
			</xsl:if>

			<!-- something doesn't work here. In source I have a record-->
			<xsl:if test="not (exists(mpx:titel))">
				<xsl:choose>
					<xsl:when test="mpx:sachbegriff = 'Sammlung Originalarchiv'">
						<xsl:element name="titel">
							<!-- GENERATE GENERIC TITELS FROM OTHER FIELDS -->
							<xsl:value-of
								select="mpx:personKörperschaftRef[@funktion ='Sammler'],mpx:geogrBezug[@bezeichnung ='Land'],mpx:datierung[ contains(@art, 'Aufnahme')]"
							/>
						</xsl:element>
						<xsl:message>
							<xsl:value-of
								select="'Fix 6: Generischer Titel (',$elementnode/@objId,')'"/>
						</xsl:message>
					</xsl:when>
					<xsl:when test="mpx:oov">
						<xsl:message>
							<xsl:value-of
								select="'Fix 6ab: Generischer Titel mit oov (',$elementnode/@objId,')'"
							/>
						</xsl:message>
						<!-- this breaks the order of the elements and I need another transformation to get it right again! -->
						<xsl:element name="titel">
							<xsl:value-of
								select="'[',  mpx:oov[1]/@art,mpx:oov[1]/@sachbegriff,mpx:oov,']'"/>
						</xsl:element>
					</xsl:when>
				</xsl:choose>
			</xsl:if>
			<xsl:if test="not (exists(mpx:verwaltendeInstitution))">
				<!--If no tag value , put default-value -->

				<xsl:element name="verwaltendeInstitution">
					<xsl:value-of select="'Ethnologisches Museum, Staatliche Museen zu Berlin'"/>
				</xsl:element>

				<xsl:message>
					<xsl:value-of
						select="'Fix 6a: Ergänze verwaltende Institution (',$elementnode/@objId,')'"
					/>
				</xsl:message>
			</xsl:if>
		</xsl:copy>
	</xsl:template>


	<!--
		<xsl:template
		match="/mpx:museumPlusExport/mpx:sammlungsobjekt/mpx:datierung[@art = document('file:///c:/cygwin/home/Mengel/usr/levelup/lib/mpxvok.xml')/mpxvok:mpxvok/mpxvok:context[@name eq 'mpx:sammlungsobjekt/mpx:datierung/@art']/mpxvok:concept/mpxvok:synonym]/@art">

		anscheinend kann ich nicht automatisch ein 2. template für das Attribut @art nehmen.
		Also alles wie immer in einem!
	-->
	<xsl:template match="/mpx:museumPlusExport/mpx:sammlungsobjekt/mpx:datierung">
		<xsl:variable name="elementnode" select="."/>
		<!-- Various corrections on datierung inside the Medienarchiv-->
		<xsl:choose>
			<!-- nur Aenderungen in EM-Medienarchiv ODER BPA , sonst nichts tun IST DAS NOCH ZEITGEMAESS?-->
			<xsl:when
				test="(../mpx:verantwortlichkeit eq 'EM-Medienarchiv') or (../mpx:verantwortlichkeit eq 'EM-Phonogramm-Archiv' )">
				<xsl:choose>
					<xsl:when
						test="$elementnode/@art ne 'Einstelldatum' and not (matches($elementnode,'^Aufnahme'))">
						<!-- drop Einstelldatum außer
						in Fällen, in denen zwar das @art="Einstelldatum" haben, aber tatsächlich ein Aufnahmedatum besitzen
					"-->


						<!-- walk thru all attributes -->
						<xsl:element name="{name()}">
							<!-- walk thru every attribute -->
							<xsl:for-each select="@*">
								<xsl:variable name="attribname" select="name()"/>
								<xsl:variable name="attribtext" select="."/>
								<xsl:attribute name="{$attribname}">
									<xsl:choose>
										<!-- replace obsolete qualifiers according to mpxvok-->
										<xsl:when test="$attribname eq 'art'">
											<xsl:choose>
												<xsl:when
												test="$attribtext eq 'Einstelldatum' and (matches($elementnode,'^Aufnahme'))">
												<xsl:value-of select="'Aufnahme'"/>
												</xsl:when>
												<xsl:otherwise>
												<xsl:value-of
												select="func:normalize-vok (
												'mpx:sammlungsobjekt/mpx:datierung/@art',
												$attribtext,
												('objId',$elementnode/../@objId))"
												/>
												</xsl:otherwise>
											</xsl:choose>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="$attribtext"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:attribute>
							</xsl:for-each>
							<!--  TODO: I would like to test which $newdate comply with a
								regular date format and warn if they do not-->
							<xsl:value-of
								select="replace ($elementnode,'^Aufnahmejahr |^Aufnahme ','')"/>
						</xsl:element>
					</xsl:when>
					<xsl:otherwise>
						<xsl:message>
							<xsl:value-of
								select="'Fix 18: Drop Einstelldatum (',$elementnode/../@objId,')'"/>
						</xsl:message>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="../mpx:verantwortlichkeit eq 'EM-Am Archäologie'">
				<xsl:element name="{name()}">
					<xsl:if test="not(@art)">
						<xsl:message>
							<xsl:value-of select="'Fix 1: (',@objId,')'"/>
						</xsl:message>
						<xsl:attribute name="art">
							<xsl:value-of select="'Herstellung'"/>
						</xsl:attribute>
					</xsl:if>
					<xsl:if test="contains ($elementnode,'-') and not(@vonJahr) and not(@bisJahr)">
						<xsl:message>
							<xsl:value-of select="'Fix 2: (',@objId,')'"/>
						</xsl:message>
						<xsl:variable name="dates" select="tokenize($elementnode,'-')"/>
						<xsl:choose>
							<xsl:when test="count($dates) = 2">
								<xsl:variable name="von" select="normalize-space($dates[1])"/>
								<xsl:variable name="bis" select="normalize-space($dates[2])"/>
								<xsl:attribute name="bisJahr">
									<xsl:value-of select="$bis"/>
								</xsl:attribute>
								<xsl:attribute name="vonJahr">
									<xsl:value-of select="$von"/>
								</xsl:attribute>
							</xsl:when>
							<xsl:when test="count($dates) = 3">
								<xsl:variable name="von"
									select="string-join(('-', normalize-space($dates[2])),'')"/>
								<xsl:variable name="bis" select="normalize-space($dates[3])"/>
								<xsl:attribute name="bisJahr">
									<xsl:value-of select="$bis"/>
								</xsl:attribute>
								<xsl:attribute name="vonJahr">
									<xsl:value-of select="$von"/>
								</xsl:attribute>
							</xsl:when>
						</xsl:choose>
					</xsl:if>
					<!-- alle anderen Attribute, bleiben wie sie sind! -->
					<xsl:for-each select="@*">
						<xsl:variable name="attribname" select="name()"/>
						<xsl:variable name="attribtext" select="."/>
						<xsl:attribute name="{$attribname}">
							<xsl:value-of select="$attribtext"/>
						</xsl:attribute>
					</xsl:for-each>
					<xsl:value-of select="$elementnode"/>
				</xsl:element>
			</xsl:when>
			<xsl:otherwise>
				<!-- in case it is not in the range specified above, don't do anything  -->
				<xsl:copy-of select="."/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>


	<!-- WAS BEDEUTET -1 ?
		<xsl:template
		match="/mpx:museumPlusExport/mpx:sammlungsobjekt/mpx:dokumentation">
		</xsl:template>
	-->

	<xsl:template match="/mpx:museumPlusExport/mpx:sammlungsobjekt/mpx:farbe">
		<xsl:variable name="me" select="."/>
		<xsl:choose>
			<xsl:when test="not (../mpx:maßangabe[@typ = 'Farbe'])">
				<xsl:message>
					<xsl:value-of select="'Fix 13c: Write maßangabe from farbe (',./../@objId,')'"/>
				</xsl:message>
				<xsl:element name="maßangabe">
					<xsl:attribute name="typ">Farbe</xsl:attribute>
					<xsl:value-of select="$me"/>
				</xsl:element>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of select="."/>
				<xsl:message>
					<xsl:value-of select="'Fix 13g: Why do i end up here? (',./../@objId,')'"/>
				</xsl:message>
			</xsl:otherwise>
		</xsl:choose>

	</xsl:template>

	<xsl:template match="/mpx:museumPlusExport/mpx:sammlungsobjekt/mpx:format">
		<xsl:variable name="me" select="."/>
		<xsl:variable name="year" select="number(subsequence(tokenize(../mpx:bearbDatum,'\.'),3,1))"/>
		<xsl:choose>
			<xsl:when
				test="$year &lt; 2006 and not (exists(../mpx:maßangabe[@typ = 'Medientyp']))">
				<xsl:choose>
					<xsl:when test="contains ($me,'WAV')">
						<xsl:message>
							<xsl:value-of
								select="'Fix 13d: Write maßangabe from format (',$year,./../@objId,')'"
							/>
						</xsl:message>
						<xsl:element name="maßangabe">
							<xsl:attribute name="typ">verfügbareFormate</xsl:attribute>
							<xsl:value-of select="$me"/>
						</xsl:element>
					</xsl:when>
					<xsl:otherwise>
						<xsl:message>
							<xsl:value-of
								select="'Fix 13d: Write maßangabe from format (',$year,./../@objId,')'"
							/>
						</xsl:message>
						<xsl:element name="maßangabe">
							<xsl:attribute name="typ">Medientyp</xsl:attribute>
							<xsl:value-of select="$me"/>
						</xsl:element>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of select="."/>
				<xsl:message>
					<xsl:value-of select="'Warn 13e: Why do i end up here? (',./../@objId,')'"/>
				</xsl:message>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>


	<xsl:template
		match="/mpx:museumPlusExport/mpx:sammlungsobjekt/mpx:geogrBezug|
			/mpx:museumPlusExport/mpx:personKörperschaft/mpx:geogrBezug">
		<xsl:variable name="elementnode" select="."/>
		<!--
			1. Wenn kein Default art, fuege "Herkunft (Allgemein)" hinzu.
			2. Normiere @funktion (ehem. @art) und @bezeichnung-Vokabular
			3. Schreibe richtige Eintraege in art und bezeichnung.

			We re basically looping thru all sammlungsobjekte in EM-Medienarchiv here
			I do it now for personKörperschaft as well and not any more only for EM-MEDIENARCHIV!
		-->
		<xsl:variable name="elementnode" select="."/>

		<xsl:element name="{name()}">
			<!--
				WENN
				a) kein art-content versehentlich in @bezeichnung UND
				b) kein art Attribute vorhanden
				DANN
				erzeuge Default-Funktion "Herkunft (Allgemein)"
				ODER wenn art Bezeichnung-content hat
			-->

			<!-- Ergänze Default Value Herkunft (Allgemein), wenn kein @art existiert UND auch kein @funktion-Begriffs versehentlich in
				@bezeichnung. Wenn letzteres der Fall, dann wird dieser Fehler unten korrigiert -->
			<xsl:if
				test="not (exists ($elementnode[@art]))  and
				not (func:existsInVoc('mpx:geogrBezug/@funktion', @bezeichnung))">
				<xsl:attribute name="funktion">
					<xsl:value-of select="'Herkunft (Allgemein)'"/>
				</xsl:attribute>
				<!--
					<xsl:message>
					<xsl:value-of
					select="'Fix 3: geogrBezug: ergänze default @funktion (',$elementnode/../@objId,'EM-Medienarchiv)'" />
					</xsl:message>
				-->
			</xsl:if>

			<!-- loop thru all attributes and fix problems-->
			<xsl:for-each select="@*">
				<xsl:variable name="attribname" select="name()"/>
				<xsl:variable name="attribtext" select="."/>
				<xsl:variable name="id" select="$elementnode/../@objId, $elementnode/../@kueId"/>

				<xsl:choose>
					<xsl:when test="$attribname eq 'art'">
						<!--
							KORRIGIERE ART
							Wenn du in Art einen Begriff aus Bezeichnung findest,
							schreibe ihn in	@bezeichnung.
							1. Wenn ausserdem noch ein Synonym, ersetze außerdem mit prefTerm
							2. Ansonsten ist es schon ein pref-Term
							3. Wenn in @Art ein Synonym steht, schreibe in @funktion mit prefTerm
							4. Sonst: schreibe @art einfach nur in @funktion
						-->
						<xsl:choose>
							<xsl:when
								test="func:existsInVoc('mpx:geogrBezug/@bezeichnung', $attribtext)">
								<xsl:attribute name="bezeichnung">
									<xsl:value-of
										select="func:normalize-vok('mpx:geogrBezug/@bezeichnung', $attribtext,$id)"
									/>
								</xsl:attribute>
							</xsl:when>
							<xsl:when
								test="func:existsInVoc('mpx:geogrBezug/@funktion', $attribtext)">
								<xsl:attribute name="funktion">
									<xsl:value-of
										select="func:normalize-vok('mpx:geogrBezug/@funktion', $attribtext,$id)"
									/>
								</xsl:attribute>
							</xsl:when>
							<xsl:otherwise>
								<xsl:message>
									<xsl:value-of
										select="' Warn: Unbekannter Term in geogrBezug@art (', $attribtext, $id,')'"
									/>
								</xsl:message>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<!-- Der Rest ist praktisch eine Wiederholung, ich könnte hier also ein named template callen,
						um die Redundanz zu vermeiden, aber warum der Aufstand!-->
					<xsl:when test="$attribname eq 'bezeichnung'">
						<xsl:choose>
							<xsl:when
								test="func:existsInVoc('mpx:geogrBezug/@bezeichnung', $attribtext)">
								<xsl:attribute name="bezeichnung">
									<xsl:value-of
										select="func:normalize-vok('mpx:geogrBezug/@bezeichnung', $attribtext,$id)"
									/>
								</xsl:attribute>
							</xsl:when>
							<xsl:when
								test="func:existsInVoc('mpx:geogrBezug/@funktion', $attribtext)">
								<xsl:attribute name="funktion">
									<xsl:value-of
										select="func:normalize-vok('mpx:geogrBezug/@funktion', $attribtext,$id)"
									/>
								</xsl:attribute>
							</xsl:when>
							<xsl:otherwise>
								<xsl:message>
									<xsl:value-of
										select="' Warn: Unbekannter Term in geogrBezug@art (', $attribtext, $id,')'"
									/>
								</xsl:message>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<xsl:when test="$attribname eq 'kommentar'">
						<xsl:if test="not (matches ($attribtext, 'code:','i'))">
							<xsl:copy-of select="."/>
						</xsl:if>
					</xsl:when>
					<xsl:otherwise>
						<!-- for other attributes: just copy them, but there shouldn't be others so warn
							funktion ist ein Attribut, das hier regulär auftreten kann
						<xsl:message>
							<xsl:value-of select="' Warn 101: unknown attribute (',$attribname,')!'"/>
						</xsl:message>
						-->
						<xsl:copy-of select="."/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
			<xsl:value-of select="$elementnode"/>
		</xsl:element>
	</xsl:template>

	<xsl:template match="mpx:museumPlusExport/mpx:sammlungsobjekt/mpx:kurzeBeschreibung">
		<!-- Fuer WLehmann: Zusatz (HK) wird entfernt -->
		<langeBeschreibung>
			<xsl:choose>
				<xsl:when test="contains (.,'(HK)')">
					<xsl:message>
						<xsl:value-of
							select="'Fix 16: Lösche [(HK)] aus kurze Beschreibung(',../@objId,')'"/>
					</xsl:message>
					<xsl:value-of select="replace(replace(.,'\(HK\)',''),'\. $|\.$','')"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="."/>
				</xsl:otherwise>
			</xsl:choose>
		</langeBeschreibung>
	</xsl:template>


	<xsl:template match="mpx:museumPlusExport/mpx:sammlungsobjekt/mpx:langeBeschreibung">
		<!-- Fuer WLehmann: Wenn Text "Bis zur Erweiterung des Textfeldes" auftaucht, nimm nur den Text davor  -->
		<xsl:variable name="elementnode" select="."/>
		<xsl:choose>
			<xsl:when test="contains (., 'Bis zur Erweiterung des Textfeldes')">
				<xsl:message>
					<xsl:value-of
						select="'Fix 4: Kürze Lange Beschreibung, wenn best. String auftaucht (',@objId,')'"
					/>
				</xsl:message>
				<xsl:element name="{name()}">
					<xsl:for-each select="@*">
						<xsl:variable name="attribname" select="name()"/>
						<xsl:variable name="attribtext" select="."/>
						<xsl:attribute name="{$attribname}">
							<xsl:value-of select="$attribtext"/>
						</xsl:attribute>
					</xsl:for-each>
					<xsl:value-of
						select="substring-before ($elementnode,'Bis zur Erweiterung des Textfeldes')"
					/>
				</xsl:element>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of select="."/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- NADELSCHLIFF IST KEINE FORMATANGABE, WEIL ES WIE <format> nicht das sammlungsobjekt, sondern  sein Digitalisat beschreibt
		xsl:template
		match="/mpx:museumPlusExport/mpx:sammlungsobjekt/mpx:nadelschliff">
		<xsl:variable name="me" select="."/>

		<xsl:choose>
			<xsl:when test="$me ne '' and not (exists(../mpx:maßangabe[@typ = 'Nadelschliff']))">
				<xsl:message>
					<xsl:value-of select="'Fix 13z: Write maßangabe from Nadelschliff (',./../@objId,')'"
					/>
				</xsl:message>
				<xsl:element name="maßangabe">
					<xsl:attribute name="typ">Nadelschliff</xsl:attribute>
					<xsl:value-of select="$me"/>
				</xsl:element>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of select="."/>
				<xsl:message>
					<xsl:value-of select="'Warn 13y: Why do i end up here? (',./../@objId,')'"/>
				</xsl:message>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template-->


	<xsl:template match="mpx:oov">
		<xsl:variable name="elementnode" select="."/>
		<xsl:element name="{name($elementnode)}">
			<!--xsl:call-template name="addKueId">
				<xsl:with-param name="name" select="$name"/>
				<xsl:with-param name="curId" select="$elementnode"/>
			</xsl:call-template-->

			<xsl:copy-of select="@art"/>
			<xsl:copy-of select="@bemerkung"/>
			<xsl:if test="not (exists (@id))">
				<!--  ADD KUEID FOR objId IF AVAILABLE-->
				<xsl:variable name="objId" select="func:identifyObjektByIdentNr ($elementnode,/)"/>

				<xsl:if test="$objId ne ''  ">
					<xsl:message>
						<xsl:value-of
							select="'Fix 17a: Addiere objId in oov (',$elementnode/../@objId,')' "/>
					</xsl:message>
					<xsl:attribute name="id">
						<xsl:value-of select="$objId"/>
					</xsl:attribute>
				</xsl:if>
			</xsl:if>
			<xsl:copy-of select="@sachbegriff"/>
			<xsl:copy-of select="@titel"/>

			<xsl:value-of select="$elementnode"/>
		</xsl:element>
		<!-- 							<xsl:element name="oov">
			there could be a test that @art is obligatory
			<xsl:copy-of select="@art"/>
			<xsl:copy-of select="@bemerkung"/>

			<xsl:choose>
			<xsl:when test="not(@id)">
			<xsl:attribute name="id">
			<xsl:value-of select="@objId"/>
			</xsl:attribute>
			<xsl:message>
			<xsl:value-of
			select="'Fix 23a: Add attribute to oov from child to parent(',$elementnode/@objId,')'"
			/>
			</xsl:message>
			</xsl:when>
			<xsl:otherwise>
			<xsl:copy-of select="@id"/>
			</xsl:otherwise>
			</xsl:choose>

			<xsl:choose>
			<xsl:when test="not(@sachbegriff)">
			<xsl:attribute name="sachbegriff">
			<xsl:value-of select="mpx:sachbegriff"/>
			</xsl:attribute>
			<xsl:message>
			<xsl:value-of
			select="'Fix 23b: Add attribute to oov from child to parent(',$elementnode/@objId,')'"
			/>
			</xsl:message>
			</xsl:when>
			<xsl:otherwise>
			<xsl:copy-of select="@sachbegriff"/>
			</xsl:otherwise>
			</xsl:choose>
			<xsl:copy-of select="@titel"/>
			<xsl:value-of select="mpx:oov"/>
			</xsl:element>
			</xsl:otherwise>-->
	</xsl:template>

	<xsl:template match="mpx:museumPlusExport/mpx:sammlungsobjekt/mpx:personKörperschaftRef">
		<xsl:variable name="elementnode" select="."/>
		<xsl:variable name="name" select="replace(replace ($elementnode,'\$',''),'§','')"/>

		<!--
			split double  funktions in two
			TODO: This is very clumsy.
			What about all these variations with spaces before or after the comma etc.- normalize-space should solve this!
			I cannot do these exceptions all individually.

			And I need to do more than two. But I also need to be able to treat cases in which several attributes exist:
			@funktion @bemerkung etc.

			Can I use a sequence containing several regEx? I doubt it. But I can probably use a sequence to store
			an arbitrary number of results. I could use tokenize to get a number of results. A perl hash would come
			in handy here. Is there any other way I can store param=value pairs?

			I think I should also introduce a relId for the kueId if I can find it
		-->
		<xsl:choose>
			<xsl:when test="matches (@funktion, '/|\+|,')">
				<xsl:message>
					<xsl:value-of
						select="'Fix 5: Splitte personKörperschaftRef, wenn mehrere Entitäten in einer Zeile (',$elementnode/../@objId,')'"
					/>
				</xsl:message>
				<xsl:element name="{name($elementnode)}">
					<xsl:call-template name="addKueId">
						<xsl:with-param name="name" select="$name"/>
						<xsl:with-param name="curId" select="$elementnode"/>
					</xsl:call-template>
					<xsl:for-each select="@*">
						<xsl:variable name="attribname" select="name()"/>
						<xsl:variable name="attribtext" select="."/>
						<xsl:choose>
							<xsl:when
								test="$attribname eq 'funktion' and contains ($attribtext, '/')">
								<xsl:attribute name="{$attribname}">
									<xsl:value-of
										select="normalize-space(substring-before ($attribtext,'/'))"
									/>
								</xsl:attribute>
							</xsl:when>
							<xsl:when
								test="$attribname eq 'funktion' and contains ($attribtext, '+')">
								<xsl:attribute name="{$attribname}">
									<xsl:value-of
										select="normalize-space(substring-before ($attribtext,'+'))"
									/>
								</xsl:attribute>
							</xsl:when>
							<xsl:when
								test="$attribname eq 'funktion' and contains ($attribtext, ',')">
								<xsl:attribute name="{$attribname}">
									<xsl:value-of
										select="normalize-space(substring-before ($attribtext,', '))"
									/>
								</xsl:attribute>
							</xsl:when>
							<xsl:otherwise>
								<xsl:attribute name="{$attribname}">
									<xsl:value-of select="$attribtext"/>
								</xsl:attribute>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:for-each>
					<xsl:value-of select="$name"/>
				</xsl:element>

				<xsl:element name="{name($elementnode)}">
					<xsl:call-template name="addKueId">
						<xsl:with-param name="name" select="$name"/>
						<xsl:with-param name="curId" select="$elementnode"/>
					</xsl:call-template>
					<xsl:for-each select="@*">
						<xsl:variable name="attribname" select="name()"/>
						<xsl:variable name="attribtext" select="."/>
						<xsl:choose>
							<xsl:when
								test="$attribname eq 'funktion' and contains ($attribtext, '/')">
								<xsl:attribute name="{$attribname}">
									<xsl:value-of
										select="normalize-space(substring-after ($attribtext,'/'))"
									/>
								</xsl:attribute>
							</xsl:when>
							<xsl:when
								test="$attribname eq 'funktion' and contains ($attribtext, '+')">
								<xsl:attribute name="{$attribname}">
									<xsl:value-of
										select="normalize-space(substring-after ($attribtext,'+'))"
									/>
								</xsl:attribute>
							</xsl:when>
							<xsl:when
								test="$attribname eq 'funktion' and contains ($attribtext, ',')">
								<xsl:attribute name="{$attribname}">
									<xsl:value-of
										select="normalize-space(substring-after ($attribtext,','))"
									/>
								</xsl:attribute>
							</xsl:when>
							<xsl:otherwise>
								<xsl:attribute name="{$attribname}">
									<xsl:value-of select="$attribtext"/>
								</xsl:attribute>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:for-each>
					<xsl:message>
						<xsl:value-of
							select="'Fix 7: Eliminiere $ u. § in personKörperschaftRef(',$elementnode/../@objId,')'"
						/>
					</xsl:message>
					<xsl:value-of select="$name"/>
				</xsl:element>
			</xsl:when>
			<xsl:otherwise>
				<!-- Wenn keines der Sonderzeichen, tue nichts.
					Ich habe schon mal was fuer die Zukunft vorbereitet -->
				<xsl:element name="{name()}">
					<!-- Check if a @ID can be added with the kueId of  that person. Lasts a very long time in a large XML-File! -->
					<xsl:call-template name="addKueId">
						<xsl:with-param name="name" select="$name"/>
						<xsl:with-param name="curId" select="$elementnode"/>
					</xsl:call-template>


					<xsl:for-each select="@*">
						<xsl:variable name="attribname" select="name()"/>
						<xsl:variable name="attribtext" select="."/>
						<xsl:attribute name="{$attribname}">
							<xsl:value-of select="$attribtext"/>
						</xsl:attribute>
					</xsl:for-each>
					<xsl:value-of select="$name"/>
				</xsl:element>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="mpx:museumPlusExport/mpx:sammlungsobjekt/mpx:sachbegriff">
		<!-- Fix for the stupid M+ bug that adds all the thesaurus terms to the Sachbegriff -->
		<xsl:variable name="elementnode" select="."/>

		<xsl:element name="{name()}">
			<xsl:copy-of select="@*"/>
			<xsl:choose>
				<xsl:when test="contains (., '(')">
					<xsl:message>
						<xsl:value-of select="'Fix 8: (',@objId,')'"/>
					</xsl:message>
					<xsl:variable name="new"
						select="normalize-space(substring-before ($elementnode,'('))"/>
					<xsl:value-of
						select="func:normalize-vok ( 'sammlungsobjekt/sachbegriff', $new,('objId',$elementnode/../@objId))"
					/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of
						select="func:normalize-vok ( 'sammlungsobjekt/sachbegriff', $elementnode,('objId',$elementnode/../@objId))"
					/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:element>
	</xsl:template>


	<xsl:template match="/mpx:museumPlusExport/mpx:sammlungsobjekt/mpx:systematikArt">
		<!--
			Loesche Laendercode, weil dieser ausser fuer uns intern, nicht zu verstehen ist.
			Ich habe erwogen, Landercode in geogrBezug zu konvertieren,
			wo dieser fehlt, lohnt aber nicht -->
		<xsl:choose>
			<xsl:when test="contains (.,'Ländercode|Länderode|ländercode')">
				<xsl:message>
					<xsl:value-of select="'Fix 19: Lösche Landercode(',../@objId,')'"/>
				</xsl:message>
				<!-- Drop systematikArt, wenn Ländercode enthalten-->
			</xsl:when>
			<xsl:otherwise>
				<!-- in case it is not in the range specified above, just copy as it is -->
				<xsl:copy-of select="."/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="mpx:museumPlusExport/mpx:sammlungsobjekt/mpx:titel">
		<!-- changed on 18.06.08. debugged! -->
		<xsl:variable name="elementnode" select="."/>
		<xsl:variable name="titel" select="string(.)"/>
		<xsl:variable name="str" select="'Titel B:'"/>
		<xsl:variable name="str2" select="'Teil B:'"/>
		<xsl:variable name="str3" select="'Titel A:'"/>

		<xsl:choose>
			<!-- Wenn CDs oder Schallplatten und hat @art="Titel A", dann lass dieses @attrib weg-->
			<xsl:when
				test="../mpx:sachbegriff = 'CD' or ../mpx:sachbegriff =  'CD-ROM' or ../mpx:sachbegriff =  'DVD'">
				<xsl:element name="{name($elementnode)}">
					<xsl:for-each select="$elementnode/@*">
						<xsl:variable name="attribname" select="name()"/>
						<xsl:variable name="attribtext" select="."/>
						<xsl:if test="not ($attribname eq 'art' and $attribtext eq 'Titel A')">
							<xsl:message>
								<xsl:value-of
									select="'Fix 9: titel: Lösche [Titel A] bei best. Sachbegriffen(',$elementnode/../@objId,')'"
								/>
							</xsl:message>
							<xsl:attribute name="{$attribname}">
								<xsl:value-of select="$attribtext"/>
							</xsl:attribute>
						</xsl:if>
					</xsl:for-each>
					<xsl:value-of select="$elementnode"/>
				</xsl:element>
			</xsl:when>

			<!-- alter doofer Titelfix fuer Schellack. Wenn "Titel A:" etc. Teil des Titels ist-->
			<xsl:when test="matches ($titel , $str)">
				<xsl:message>
					<xsl:value-of
						select="'Fix 10: Schreibe Titel A etc. in Qualifikator (',$elementnode/../@objId,')'"
					/>
				</xsl:message>
				<xsl:variable name="titel" select="tokenize($titel,$str)"/>
				<xsl:element name="titel">
					<xsl:attribute name="art" select="'Titel A'"/>
					<xsl:value-of
						select="replace(normalize-space(replace($titel[1],'Titel A:','')),';$','')"
					/>
				</xsl:element>
				<xsl:element name="titel">
					<xsl:attribute name="art" select="'Titel B'"/>
					<xsl:value-of select="normalize-space($titel[2])"/>
				</xsl:element>
			</xsl:when>
			<xsl:when test="matches ($titel , $str2)">
				<xsl:variable name="titel" select="tokenize($titel,$str2)"/>
				<xsl:element name="titel">
					<xsl:attribute name="art" select="'Titel A'"/>
					<xsl:value-of
						select="replace(normalize-space(replace($titel[1],'Titel A:','')),';$','')"
					/>
				</xsl:element>
				<xsl:element name="titel">
					<xsl:attribute name="art" select="'Titel B'"/>
					<xsl:value-of select="normalize-space($titel[2])"/>
				</xsl:element>
			</xsl:when>
			<xsl:when test="matches ($titel , $str3)">
				<xsl:message>
					<xsl:value-of
						select="'Fix 12: Schreibe Titel A etc. in Qualifikator (',$elementnode/../@objId,')'"
					/>
				</xsl:message>
				<xsl:element name="titel">
					<xsl:attribute name="art" select="'Titel A'"/>
					<xsl:value-of select="normalize-space(replace($titel[1],'Titel A:',''))"/>
				</xsl:element>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of select="$elementnode"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="/mpx:museumPlusExport/mpx:sammlungsobjekt/mpx:ton">
		<xsl:variable name="me" select="."/>
		<xsl:choose>
			<xsl:when test="$me ne '' and not (exists(../mpx:maßangabe[@typ = 'Kanaligkeit']))">
				<xsl:message>
					<xsl:value-of select="'Fix 13c: Write maßangabe from ton (',./../@objId,')'"/>
				</xsl:message>
				<xsl:element name="maßangabe">
					<xsl:attribute name="typ">Kanaligkeit</xsl:attribute>
					<xsl:value-of select="$me"/>
				</xsl:element>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of select="."/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="/mpx:museumPlusExport/mpx:sammlungsobjekt/mpx:tvNorm">
		<xsl:variable name="me" select="."/>
		<xsl:choose>
			<xsl:when test="$me ne '' and not (exists(../mpx:maßangabe[@typ = 'tvNorm']))">
				<xsl:message>
					<xsl:value-of select="'Fix 13c: Write maßangabe from tvNorm (',../@objId,')'"/>
				</xsl:message>
				<xsl:element name="maßangabe">
					<xsl:attribute name="typ">tvNorm</xsl:attribute>
					<xsl:value-of select="$me"/>
				</xsl:element>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of select="."/>
				<xsl:message>
					<xsl:value-of select="'Fix 13f: Why do i end up here? (',./../@objId,')'"/>
				</xsl:message>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>


	<xsl:template match="/mpx:museumPlusExport/mpx:sammlungsobjekt/mpx:verwaltendeInstitution">
		<xsl:element name="verwaltendeInstitution">
			<xsl:value-of select="normalize-space(.)"/>
		</xsl:element>
	</xsl:template>


	<xsl:template match="/mpx:museumPlusExport/mpx:sammlungsobjekt/mpx:verfügbareFormate">
		<xsl:variable name="me" select="."/>
		<xsl:choose>
			<xsl:when test="$me ne'' and not (exists(../mpx:maßangabe[@typ = 'verfügbareFormate']))">
				<xsl:message>
					<xsl:value-of
						select="'Fix 13c: Write maßangabe from verfügbareFormate (',./../@objId,')'"
					/>
				</xsl:message>
				<xsl:element name="maßangabe">
					<xsl:attribute name="typ">verfügbareFormate</xsl:attribute>
					<xsl:value-of select="$me"/>
				</xsl:element>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of select="."/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>



    <xsl:template name="addKueId">
        <xsl:param name="name"/>
        <xsl:param name="curId"/>
        <xsl:variable name="root" select="/"/>
        <xsl:if test="not (exists (@id))">
            <!--  ADD KUEID FOR PERKOR IF AVAILABLE-->
            <xsl:variable name="kueId" select="func:identifyPerKörByName($name,$root)"/>
            <xsl:message>
                <xsl:value-of
                    select="'Fix 17: Addiere kueId in personKörperschaftRef (',$curId/../@objId,')' "
                />
            </xsl:message>

            <xsl:if test="$kueId ne '' ">
                <xsl:attribute name="id">
                    <xsl:value-of select="$kueId"/>
                </xsl:attribute>
            </xsl:if>
        </xsl:if>
    </xsl:template>


</xsl:stylesheet>
