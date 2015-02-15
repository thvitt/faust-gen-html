<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns="http://www.w3.org/1999/xhtml"
	xpath-default-namespace="http://www.tei-c.org/ns/1.0"
	xmlns:f="http://www.faustedition.net/ns"
	exclude-result-prefixes="xs"
	version="2.0">
	
	<xsl:param name="output">variants/</xsl:param>
	<xsl:param name="docbase">https://faustedition.uni-wuerzburg.de/new</xsl:param>
	
	<xsl:output method="xhtml"/>
	
	<xsl:function name="f:output-group">
		<xsl:param name="n"/>
		<xsl:variable name="resolved-n" select="number(replace($n, '\D*(\d+).*', '$1'))"/>
		<xsl:choose>
			<xsl:when test="matches(string($resolved-n), '\d+')">
				<xsl:value-of select="$resolved-n idiv 10"/>				
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>other</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	
	<xsl:template match="f:sorted-lines">
		<xsl:for-each-group select="*" group-by="f:output-group(@n)">
			<xsl:result-document href="{$output}{current-grouping-key()}.html">
				<div class="groups" data-group="{current-grouping-key()}">
					<xsl:for-each-group select="current-group()" group-by="@n">
						<div class="variants" data-n="{current-grouping-key()}" data-size="{count(current-group())}">
							<xsl:apply-templates select="current-group()"/>
						</div>
					</xsl:for-each-group>
				</div>
			</xsl:result-document>
		</xsl:for-each-group>
	</xsl:template>
	
	<xsl:template match="*[@n]">
		<div class="variant ann-{local-name()} linenum-{@n} {@rend}" data-n="{@n}" data-source="{@f:doc}">
			<xsl:apply-templates/>
			<xsl:text> </xsl:text>
			<a class="sigil" href="{$docbase}/{@f:doc}">
				<xsl:value-of select="@f:sigil"/>
			</a>
		</div>
	</xsl:template>	
	
	<xsl:template match="*">
		<span class="ann-{local-name()} {@rend}"><xsl:apply-templates/></span>
	</xsl:template>
	
	<xsl:template match="lb">
		<br/>
	</xsl:template>
</xsl:stylesheet>