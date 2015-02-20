<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:f="http://www.faustedition.net/ns"
  exclude-result-prefixes="xs"
  version="2.0">
  
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

  <xsl:function name="f:lineno-for-display">
    <xsl:param name="n"/>
    <xsl:choose>
      <xsl:when test="matches($n, '^\d+$')">
        <xsl:value-of select="number($n)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="0"/>
      </xsl:otherwise>
    </xsl:choose>    
  </xsl:function>
  
  <!-- Returns true of the given TEI element should probably be rendered inline -->
  <xsl:function name="f:isInline">
    <xsl:param name="element"/>    
    <xsl:choose>
      <xsl:when test="$element[self::div or self::l or self::lg or self::p or self::sp or (@n and not(self::milestone))]">
        <xsl:sequence select="false()"/>
      </xsl:when>
      <xsl:when test="$element[self::hi or self::seg or self::w]">
        <xsl:sequence select="true()"/>
      </xsl:when>
      <xsl:when test="some $descendant in $element//* satisfies not(f:isInline($descendant))">
        <xsl:sequence select="false()"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="true()"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <!-- Returns the local name of the appropriate HTML element for the given tei element -->
  <xsl:function name="f:html-tag-name">
    <xsl:param name="element"/>
    <xsl:choose>
      <xsl:when test="$element[self::p]">p</xsl:when>
      <xsl:when test="f:isInline($element)">span</xsl:when>
      <xsl:otherwise>div</xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <!-- Returns a sequence of classes for the HTML equivalant to a TEI element. -->
  <xsl:function name="f:generic-classes">
    <xsl:param name="element"/>     
    <xsl:sequence select="local-name($element)"/>
    <xsl:sequence select="for $rend in tokenize($element/@rend, ' ') return concat('rend-', $rend)"/>
    <xsl:if test="$element/@n">
      <xsl:sequence select="concat('n-', $element/@n)"/>
    </xsl:if>      
  </xsl:function>
  
  
  <xsl:function name="f:relativize" as="xs:anyURI">
    <xsl:param name="source" as="xs:string" />
    <xsl:param name="target" as="xs:string" />
    
    <!-- Fully qualified source and target to source-uri and target-uri. -->
    <xsl:variable name="target-uri" select="resolve-uri($target)" />
    <xsl:variable name="source-uri" select="resolve-uri($source)" />
    
    <!--
      Now we collapse consecutive slashes and strip trailing filenames from
      both to compute $a (source) and $b (target).
      
      We then split $a on '/' and walk through the sequence, comparing
      each part to the corresponding component in $b, concatenating the
      results with '/'. Result $c is a string representing the complete
      set of path components shared between the beginning of $a and the
      beginning of $b.
    -->
    <xsl:variable name="a"
      select="tokenize( replace( replace($source-uri, '//+', '/'), '[^/]+$', ''), '/')" />
    <xsl:variable name="b"
      select="tokenize( replace( replace($target-uri, '//+', '/'), '[^/]+$', ''), '/')" />
    <xsl:variable name="c"
      select="string-join(
      for $i in 1 to count($a)
      return (if ($a[$i] = $b[$i]) then $a[$i] else ()), '/')" />
    
    <xsl:choose>
      <!--
        if $c is empty, $a and $b do not share a common base, and we cannot
        return a relative path from the source to the target. In that case
        we just return the resolved target-uri.
      -->
      <xsl:when test="$c eq ''">
        <xsl:sequence select="$target-uri" />
      </xsl:when>
      <xsl:otherwise>
        <!--
          Given the sequence $a and the string $c, we join $a using '/' and
          extract the substring remaining  after the prefix $c is removed.
          We then replace all path components with '..', resulting in the
          steps up the directory path which must be made to reach the
          target from the source. This path is named $steps.
        -->
        <xsl:variable name="steps"
          select="replace(replace(
          substring-after(string-join($a, '/'), $c),
          '^/', ''), '[^/]+', '..')" />
        
        <!--
          Resolving $steps against $source-uri gives us $common-path, the
          fully qualified path shared between $source-uri and $target-uri.
          
          Stripping $common-path from $target-uri and prepending $steps will
          leave us with $final-path, the relative path from  $source-uri to
          $target-uri. If the result is empty, the destination is './'
        -->
        <xsl:variable name="common-path"
          select="replace(resolve-uri($steps, $source-uri), '[^/]+$', '')" />
        
        <xsl:variable name="final-path"
          select="replace(concat($steps, substring-after($target-uri, $common-path)), '^/', '')" />
        
        <xsl:sequence
          select="xs:anyURI(if ($final-path eq '') then './' else $final-path)" />
        
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>


  
  
</xsl:stylesheet>