<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" xmlns:f="http://www.faustedition.net/ns"
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:pxp="http://exproc.org/proposed/steps"
	type="f:print2html"
	name="main" version="1.0">
	<p:input port="source" primary="true"/>
	<p:input port="parameters" kind="parameter"/>
	<p:output port="result" primary="true">
		<p:pipe port="result" step="body"/>
	</p:output>
	
	<p:option name="basename" select="''">
		<p:documentation>Basis for the filename of the result documents. Must be relative
			to the $html parameter, and must not include a trailing .html</p:documentation>
	</p:option>	
	<p:serialization port="result" method="xhtml" indent="true" omit-xml-declaration="false"
		include-content-type="true"/>
	
	<p:import href="apply-edits.xpl"/>
	<p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>	

	<!-- Parameter laden -->
	<p:parameters name="config">
		<p:input port="parameters">
			<p:document href="config.xml"/>
			<p:pipe port="parameters" step="main"/>
		</p:input>
	</p:parameters>
	
	<!-- wir müssen ein paar der Parameter auswerten: -->
	<p:group name="body">
		<p:output port="result">
			<p:pipe port="result" step="pagemap-xslt"/>
		</p:output>
		
		<!-- $html -> das Verzeichnis für die Ausgabedateien -->
		<p:variable name="html" select="//c:param[@name='html']/@value">
			<p:pipe port="result" step="config"/>
		</p:variable>
		
		
		<!-- 
			Wir berechnen jetzt den Ausgabedateinamen, falls er nicht als Opion $basename
			mitgegeben wurde
		-->
		<p:variable name="output-filename" 
			select="if ($basename != '')
					then $basename
					else replace(p:base-uri(), '^.*/', '')">
			<p:pipe port="source" step="main"/>
		</p:variable>
		
		<!-- nun die vollständige basis, resolved und mit extension -->
		<p:variable name="output-base" 
			select="p:resolve-uri(
					if   (ends-with($output-filename, '.xml') or ends-with($output-filename, '.html'))
			        then replace($output-filename, '\.[^.]+$', '')
			        else $output-filename, $html)"/>
	
		<p:variable name="emended-xml" select="concat($output-base, '.xml')"/>

		<!-- Vorverarbeitung der TEI-Datei: Anwendung von <del> etc. -->
		<f:apply-edits name="apply-edits">
			<p:input port="source">
				<p:pipe port="source" step="main"/>
			</p:input>
		</f:apply-edits>
		
		<!-- Wir suchen die Transkriptnummern aus den <pb>s heraus, bzw. versuchen das -->
		<p:xslt name="pbs">
			<p:input port="stylesheet">
				<p:document href="resolve-pb.xsl"/>
			</p:input>
			<p:input port="parameters">
				<p:pipe port="result" step="config"/>            
			</p:input>
		</p:xslt>
		

		<!-- Nun die eigentliche Transformation nach HTML. -->
		<p:xslt name="html">
			<p:input port="stylesheet">
				<p:document href="print2html.xsl"/>
			</p:input>
			<p:input port="parameters">
				<p:pipe port="result" step="config"/>
			</p:input>
			<p:with-param name="output-base" select="$output-base"/>
		</p:xslt>
		
		<!-- Wir setzen jetzt noch den Dateinamen an die Hauptausgabedatei. -->
		<pxp:set-base-uri name="output">
			<p:with-option name="uri" select="concat($output-base, '.html')"/>
		</pxp:set-base-uri>

		<!-- Nun speichern wir die per <result-document> generierten Dateien. -->
		<p:for-each name="save">
			<p:output port="result">
				<p:pipe port="result" step="store"></p:pipe>
			</p:output>
			
			<p:iteration-source>
				<p:pipe step="output" port="result"/>
				<p:pipe step="html" port="secondary"/>
			</p:iteration-source>
			

			<p:store name="store" method="xhtml" indent="true" include-content-type="true">
				<p:with-option name="href" select="p:base-uri()"/>
			</p:store>
		</p:for-each>
		
		<!-- jetzt die emended-Version speichern. Davon gibt's nur eine ... -->
		<p:for-each name="save-emended">
			<p:output port="result">
				<p:pipe port="result" step="store-emended"/>
			</p:output>
			<p:iteration-source>
				<p:pipe port="emended-version" step="apply-edits"/>
			</p:iteration-source>

			<p:xslt>
				<p:input port="stylesheet">
					<p:inline>
						<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
							<xsl:template match="/">
								<xsl:comment>This document has been generated from an original source and should not be edited.</xsl:comment>
								<xsl:copy-of select="."/>
							</xsl:template>
						</xsl:stylesheet>
					</p:inline>
				</p:input>
			</p:xslt>
			
			<p:store name="store-emended" method="xml" indent="true">
				<p:with-option name="href" select="concat($output-base, '-emended.xml')"/>
			</p:store>
		</p:for-each>
		
		<p:wrap-sequence wrapper="c:results">
			<p:input port="source">
				<p:pipe step="save" port="result"/>
				<p:pipe step="save-emended" port="result"/>
			</p:input>
		</p:wrap-sequence>
		
		<p:xslt name="pagemap-xslt">
			<p:input port="source">
				<p:pipe port="result" step="pbs"/>
			</p:input>
			<p:input port="stylesheet">
				<p:document href="pagemap.xsl"/>
			</p:input>
			<p:input port="parameters">
				<p:pipe port="result" step="config"/>
			</p:input>
			<p:with-param name="output-base" select="$output-base"/>
		</p:xslt>
		
	</p:group>

</p:declare-step>
