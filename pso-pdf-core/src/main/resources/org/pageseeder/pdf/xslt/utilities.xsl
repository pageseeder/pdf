<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                              xmlns:fo="http://www.w3.org/1999/XSL/Format"
                              xmlns:psf="http://www.pageseeder.com/function"
                              exclude-result-prefixes="psf">

  <xsl:param name="source-filename" />

  <xsl:variable name="uriusertitle" select="if (/document/documentinfo/uri/displaytitle) then /document/documentinfo/uri/displaytitle else $source-filename"/>
  <xsl:variable name="foconfigs-document" select="document($foconfigfileurl)" />
  <xsl:variable name="foconfigs">
    <xsl:for-each select="$foconfigs-document//foconfig//styles">
      <xsl:variable name="config-name"     select="if (@label) then concat('label-', @label) else ancestor::foconfig/@config" />
      <xsl:variable name="config-priority" select="if (@label) then 2 else if (ancestor::foconfig/@config = 'custom') then 1 else 0" />
      <foconfig xmlns="" config="{$config-name}" priority="{$config-priority}">
        <xsl:if test="@label"><xsl:attribute name="label" select="@label" /></xsl:if>
        <xsl:copy-of select="*" />
      </foconfig>
    </xsl:for-each>
  </xsl:variable>
  
  <!--
    Find the config that defines a margin zone.
    It could be the current one, the 'mainconfig' parameter or default
    
    @param context     the current context
  -->
  <xsl:function name="psf:config-with-region">
    <xsl:param name="context" />
    <xsl:variable name="labels" select="psf:load-labels($context)" />
    <xsl:variable name="label-config" select="if (not(empty($labels))) then ($foconfigs//foconfig[@label and not(empty(index-of($labels, @label)))])[1] else ()" />

    <!-- find all the configs with margin zones defined -->
    <xsl:variable name="all" select="$foconfigs//foconfig[@config = $label-config/@config or @config = 'custom' or @config = 'default']
                                                         [body | page | header | footer | left | right]" />

    <!-- now only use the one with the highest priority -->
    <xsl:variable name="max-priority" select="max($all/@priority)" />
    <xsl:sequence select="($all[@priority = $max-priority])[1]/@config" />

  </xsl:function>
  
  <!--
    Method used to load the margin zone definition.
    
    @param context    the current context
    @param type       the type of margin zone (supported values are 'header', 'footer', 'left' and 'right')
    @param first      if we should get the one for the first page (values are 'true', 'false' or '' which means any value)
  -->
  <xsl:function name="psf:margin-zone">
    <xsl:param name="context" />
    <xsl:param name="type" />
    <xsl:param name="first" />

    <xsl:variable name="config" select="psf:config-with-region($context)" />
    <xsl:sequence select="$foconfigs//foconfig[@config = $config]/*[name() = $type]
                          [$first = '' or ($first = 'true' and @first = 'true') or ($first = 'false' and empty(@first))]" />

  </xsl:function>
  
  <!--
    Method used to apply the styling of margin zones (headers, footers, lefts and rights).
    
    @param context     the current context (used to retrieve the FOConfig.xml config file)
    @param type        the type of margin zone (supported values are 'header', 'footer', 'left' and 'right')
    @param odd-or-even the scope of the margin zone (supported values are 'first', 'odd', 'even')
    @param position    the sub element to style (supported values are 'left', 'center' and 'right' for headers and footers
                                                 and 'top', 'middle' and 'bottom' for left and right)
    @param labels      the labels of the document, used to insert a value in the margin zone
  -->
  <xsl:function name="psf:margin-zone-styling">
    <xsl:param name="context" />
    <xsl:param name="type" />
    <xsl:param name="odd-or-even" />
    <xsl:param name="position" />
    <xsl:param name="labels" />

    <!-- find which config should apply to current context -->
    <xsl:variable name="config" select="$foconfigs//foconfig[@config = psf:config-with-region($context)]" />
    <xsl:variable name="element">
      <xsl:choose>
        <!-- if 'first' then only search for styling in the 'first' zone -->
        <xsl:when test="$odd-or-even = 'first'">
          <xsl:sequence select="$config/*[name() = $type][@first = 'true']/*[name(.) = $position]" />
        </xsl:when>
        <!-- otherwise, try to find the zone exactly matching the 'odd-or-even' flag -->
        <xsl:when test="$config/*[name() = $type][@odd-or-even = $odd-or-even]">
          <xsl:sequence select="$config/*[name() = $type][@odd-or-even = $odd-or-even]/*[name(.) = $position]" />
        </xsl:when>
        <!-- otherwise find a general zone (no 'odd-or-even' and no 'first') -->
        <xsl:when test="$config/*[name() = $type][empty(@odd-or-even) and not(@first = 'true')]">
          <xsl:sequence select="$config/*[name() = $type][empty(@odd-or-even) and not(@first = 'true')]/*[name(.) = $position]" />
        </xsl:when>
      </xsl:choose>
    </xsl:variable>

    <!-- and apply template to the correct element within (using position: left, right, center or top, middle, bottom) -->
    <xsl:apply-templates select="$element" mode="style">
      <xsl:with-param name="labels" select="$labels" tunnel="yes" />
    </xsl:apply-templates>

  </xsl:function>

  
  <!-- ================================= Style ============================================ -->
  <!-- These templates are generating XSL-FO elements in FOConfig.xml -->
  
  <!-- Match everything with mode = 'style' -->
  <xsl:template match="*" mode="style"><xsl:apply-templates mode="style" /></xsl:template>
  <!-- labels -->
  <xsl:template match="label" mode="style">
    <xsl:param name="labels" tunnel="yes" />
    <xsl:value-of select="$labels//label[@name = current()/@name]" />
  </xsl:template>
  <!-- don't output properties -->
  <xsl:template match="property" mode="style"/>
  <!-- Template for inserting page number -->
  <xsl:template match="page-number" mode="style"><fo:page-number /></xsl:template>
  <!-- Template for inserting total page -->
  <xsl:template match="total-pages" mode="style"><fo:page-number-citation ref-id="last-page" /></xsl:template>
  <!-- Template for inserting image -->
  <xsl:template match="image" mode="style">
    <fo:external-graphic><xsl:copy-of select="@*" /></fo:external-graphic>
  </xsl:template>
  <!-- Template for inserting dates -->
  <xsl:template match="date" mode="style">
    <xsl:variable name="pat">
      <xsl:choose><xsl:when test="@pattern"><xsl:value-of select="@pattern" /></xsl:when>
      <xsl:otherwise>[MNn] [D], [Y]</xsl:otherwise></xsl:choose>
    </xsl:variable>
    <xsl:value-of select="format-date(current-date(), $pat)" />
  </xsl:template>
  <!-- Template for inserting filename -->
  <xsl:template match="filename" mode="style">
    <xsl:value-of select="$uriusertitle" />
  </xsl:template>
  <!-- Template for inserting link -->
  <xsl:template match="link" mode="style">
    <xsl:variable name="href" select="@href"/>
    <fo:basic-link background-color="#ffffff" external-destination="{$href}" color="#1f4f76">
      <fo:inline text-decoration="underline"><xsl:value-of select="."/></fo:inline>
    </fo:basic-link>
  </xsl:template>

  <!--
    Load the name of the config to use for the context provided
    
    @param context       the current context (used to retrieve the FOConfig.xml config file)
   -->
  <xsl:function name="psf:load-config">
    <xsl:param name="context" />
    <!-- find which config should apply to current context -->
    <xsl:variable name="labels" select="psf:load-labels($context)" />
    <xsl:variable name="label-config" select="if (not(empty($labels))) then ($foconfigs//foconfig[@label and not(empty(index-of($labels, @label)))])[1] else ()" />
    <!-- find all the configs -->
    <xsl:variable name="all" select="$foconfigs//foconfig[@config = $label-config/@config or @config = 'custom' or @config = 'default']" />

    <!-- now only use the one with the highest priority -->
    <xsl:variable name="max-priority" select="max($all/@priority)" />
    <xsl:sequence select="($all[@priority = $max-priority])[1]/@config" />
  </xsl:function>

  <!--
    Load the document labels of the config to use for the context provided

    @param context       the current context (used to retrieve the FOConfig.xml config file)
   -->
  <xsl:function name="psf:load-labels">
    <xsl:param name="context" />
    <!-- only support transcluded docs in xref-fragment -->
    <xsl:variable name="transcluded" select="($context/ancestor::blockxref)[last()][empty(parent::xref-fragment)]" />
    <xsl:sequence select="if ($transcluded) then psf:load-labels($transcluded) else
                          tokenize(($context/ancestor-or-self::document)[last()]/documentinfo/uri/labels, ',')" />
  </xsl:function>

  <!--
    Load the style properties as property elements for the element specified.
    A property element has the following format:
      <property name="[name]" value="[value]" />
    
    @param context       the current context (used to retrieve the FOConfig.xml config file)
    @param element-name  the name of the element which properties should be loaded
   -->
  <xsl:function name="psf:load-style-properties">
    <xsl:param name="context" />
    <xsl:param name="element-name" />
    <xsl:sequence select="psf:load-style-properties-more(psf:load-config($context), $element-name, 'property', '')" />
  </xsl:function>

  <!--
  -->
  <xsl:function name="psf:load-general-style-properties">
    <xsl:param name="config" />
    <xsl:param name="type" />
    <xsl:param name="odd-or-even" />
    <xsl:param name="position" />
    <xsl:param name="property-tag" />

    <!-- find config -->
    <xsl:variable name="config" select="$foconfigs//foconfig[@config = $config]" />

    <xsl:choose>
      <xsl:when test="$type = 'page' or $type = 'body'">
        <xsl:sequence select="$config/*[name() = $type]/*[name() = $property-tag]" />
      </xsl:when>
      <!-- For first, select properties from first if found somewhere, otherwise, use non even properties -->
      <xsl:when test="$position = '' and $odd-or-even = 'first'">
        <xsl:variable name="prop" select="$config/*[name() = $type][@first = 'true']/*[name() = $property-tag]" />
        <xsl:choose>
          <xsl:when test="$prop"><xsl:sequence select="$prop" /></xsl:when>
          <xsl:otherwise>
            <xsl:sequence select="$config/*[name() = $type][@odd-or-even = 'odd' or (string(@odd-or-even) = '' and string(@first) = '')]/*[name() = $property-tag]" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="$odd-or-even = 'first'">
        <xsl:variable name="prop" select="$config/*[name() = $type][@first = 'true']/*[name(.) = $position]/*[name() = $property-tag]" />
        <xsl:choose>
          <xsl:when test="$prop"><xsl:sequence select="$prop" /></xsl:when>
          <xsl:otherwise>
            <xsl:sequence select="$config/*[name() = $type][@odd-or-even = 'odd' or (string(@odd-or-even) = '' and string(@first) = '')]/*[name(.) = $position]/*[name() = $property-tag]" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <!-- For odd or even, select properties with the right "scope" if found somewhere, otherwise, use normal properties -->
      <xsl:when test="$position = ''">
        <xsl:variable name="prop" select="$config/*[name() = $type][@odd-or-even = $odd-or-even]/*[name() = $property-tag]" />
        <xsl:choose>
          <xsl:when test="$prop"><xsl:sequence select="$prop" /></xsl:when>
          <xsl:otherwise>
            <xsl:sequence select="$config/*[name() = $type][string(@odd-or-even) = '' and string(@first) = '']/*[name() = $property-tag]" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="prop" select="$config/*[name() = $type][@odd-or-even = $odd-or-even]/*[name(.) = $position]/*[name() = $property-tag]" />
        <xsl:choose>
          <xsl:when test="$prop"><xsl:sequence select="$prop" /></xsl:when>
          <xsl:otherwise>
            <xsl:sequence select="$config/*[name() = $type][string(@odd-or-even) = '' and string(@first) = '']/*[name(.) = $position]/*[name() = $property-tag]" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:function>


  <!--
    Load the style properties as property elements for the element specified.
    A property element has the following format:
      <property name="[name]" value="[value]" />
      or
      <region-property name="[name]" value="[value]" />
    
    @param config        the FOConfig.xml config file
    @param element-name  the name of the element which properties should be loaded
    @param property-tag  the tag name of the properties to load (only supported values are 'property' and 'region-property')
    @param role          a role that should be present on the element (if no role, '' is used)
   -->
  <xsl:function name="psf:load-style-properties-more">
    <xsl:param name="config" />
    <xsl:param name="element-name" />
    <xsl:param name="property-tag" />
    <xsl:param name="role" />

    <!-- find what element we're looking for -->
    <xsl:variable name="first"   select="tokenize($element-name, '-')[1]" />
    <xsl:variable name="second"  select="tokenize($element-name, '-')[2]" />
    <xsl:variable name="third"   select="tokenize($element-name, '-')[3]" />

    <!--  then load all the properties wanted -->
    <xsl:variable name="all-properties">
      <xsl:for-each select="$foconfigs//foconfig[@config = $config or @config = 'custom' or @config = 'default']">
        <foconfig xmlns="" priority="{@priority}">
          <xsl:choose>
            <!-- heading/para prefix: heading-prefix-2 ==> <element name="heading-prefix" level="2"> -->
            <xsl:when test="($first = 'heading' or $first = 'para') and $second = 'prefix'">
              <xsl:sequence select="element[string(@name) = concat($first, '-prefix') and @level = $third]/*[name() = $property-tag]" />
            </xsl:when>
            <!-- list/nlist label: list-label-2 ==> <element name="list-label" level="2"> -->
            <xsl:when test="($first = 'list' or $first = 'nlist') and $second = 'label'">
              <xsl:sequence select="element[string(@name) = concat($first, '-label') and @level = $third][string(@role) = $role]/*[name() = $property-tag]" />
            </xsl:when>
            <!-- heading/para: heading-2 ==> <element name="heading" level="2"> -->
            <xsl:when test="($first = 'heading' or $first = 'para') and element[string(@name) = $first and @level = $second]">
              <xsl:sequence select="element[string(@name) = $first and @level = $second]/*[name() = $property-tag]" />
            </xsl:when>
            <!-- fallback heading: heading-2 ==> <element name="heading2"> -->
            <xsl:when test="$first = 'heading' and $second">
              <xsl:sequence select="element[string(@name) = concat($first, $second)]/*[name() = $property-tag]" />
            </xsl:when>
            <xsl:when test="$first = 'para' and $second" /> <!-- don't get para[@level] properties for all paras -->
            <xsl:otherwise>
              <xsl:sequence select="element[string(@name) = $element-name and string(@level) = ''][string(@role) = $role]/*[name() = $property-tag]" />
            </xsl:otherwise>
          </xsl:choose>
        </foconfig>
      </xsl:for-each>
    </xsl:variable>

    <!-- finally filter the duplicates by removing the lower priorities -->
    <!-- and make sure that all properties are present -->
    <xsl:for-each select="$all-properties//foconfig/*">
      <xsl:variable name="max-priority" select="max($all-properties//foconfig[*[@name = current()/@name]][@priority]/@priority)" />
      <xsl:if test="../@priority = $max-priority">
        <xsl:sequence select="." />
      </xsl:if>
    </xsl:for-each>
    
  </xsl:function>

  <!--
    Output properties by combining the two sets of properties provided.
    The first properties will overwrite the second properties.
    
    @param high-priority  the set of properties with the highest priority
    @param low-priority   the set of properties with the lowest priority
   -->
  <xsl:function name="psf:style-properties-overwrite">
    <xsl:param name="high-priority" />
    <xsl:param name="low-priority" />
    
    <xsl:variable name="properties">
      <xsl:for-each select="$high-priority">
        <xsl:sequence select="." />
      </xsl:for-each>
      <xsl:for-each select="$low-priority">
        <xsl:if test="empty($high-priority[@name = current()/@name])">
          <xsl:sequence select="." />
        </xsl:if>
      </xsl:for-each>
    </xsl:variable>
    
    <xsl:for-each select="$properties/*[not(starts-with(@name, 'ps-'))][string(@value) != '']">
      <xsl:attribute name="{@name}" select="@value" />
    </xsl:for-each>
    
  </xsl:function>
  
  <!--
    Load the style properties for the given element AS ATTRIBUTES.
    This function should only be called immediately after an element as been created.
    
    @param context       the current context (used to retrieve the FOConfig.xml config file)
    @param element-name  the name of the element which properties should be loaded
   -->
  <xsl:function name="psf:style-properties">
    <xsl:param name="context" />
    <xsl:param name="element-name" />
    <xsl:sequence select="psf:style-properties-all(psf:load-config($context), $element-name, 'property', '')" />
  </xsl:function>
  
  <!--
    Load the style region properties for the given element AS ATTRIBUTES.
    This function should only be called immediately after an element as been created.
    
    @param config        the current FOConfig.xml config file to use
    @param element-name  the name of the element which region properties should be loaded
   -->
  <xsl:function name="psf:general-style-region-properties">
    <xsl:param name="config" />
    <xsl:param name="type" />
    <xsl:param name="odd-or-even" />
    <xsl:variable name="properties" select="psf:load-general-style-properties($config, $type, $odd-or-even, '', 'region-property')"/>
    <xsl:for-each select="$properties[not(starts-with(@name, 'ps-'))][string(@value) != '']">
      <xsl:attribute name="{@name}" select="@value" />
    </xsl:for-each>
  </xsl:function>

  <!--
    Load the style region properties for the given element AS ATTRIBUTES.
    This function should only be called immediately after an element as been created.

    @param config        the current FOConfig.xml config file to use
    @param element-name  the name of the element which region properties should be loaded
   -->
  <xsl:function name="psf:general-style-properties">
    <xsl:param name="config" />
    <xsl:param name="type" />
    <xsl:param name="odd-or-even" />
    <xsl:param name="position" />
    <xsl:variable name="properties" select="psf:load-general-style-properties($config, $type, $odd-or-even, $position, 'property')"/>
    <xsl:for-each select="$properties[not(starts-with(@name, 'ps-'))][string(@value) != '']">
      <xsl:attribute name="{@name}" select="@value" />
    </xsl:for-each>
  </xsl:function>
  
  <!--
    Load the style properties witha specified role for the given element AS ATTRIBUTES.
    This function should only be called immediately after an element as been created.
    
    @param context       the current context (used to retrieve the FOConfig.xml config file)
    @param element-name  the name of the element which properties should be loaded
    @param role          a role that should be present on the element
   -->
  <xsl:function name="psf:style-properties-role">
    <xsl:param name="context" />
    <xsl:param name="element-name" />
    <xsl:param name="role" />
    <xsl:sequence select="psf:style-properties-all(psf:load-config($context), $element-name, 'property', $role)" />
  </xsl:function>
  
  <!--
    Load the style properties for the given element AS ATTRIBUTES.
    This function should only be called immediately after an element as been created.
    
    @param config        the FOConfig.xml config file to use
    @param element-name  the name of the element which properties should be loaded
    @param property-tag  the tag name of the properties to load (only supported values are 'property' and 'region-property')
    @param role          a role that should be present on the element (if no role, '' is used)
   -->
  <xsl:function name="psf:style-properties-all">
    <xsl:param name="config" />
    <xsl:param name="element-name" />
    <xsl:param name="property-tag" />
    <xsl:param name="role" />
    <xsl:variable name="debug" select="false()" />
    
    <xsl:variable name="properties" select="psf:load-style-properties-more($config, $element-name, $property-tag, $role)" />
    
    <xsl:if test="$debug">
      <xsl:message>style-properties: element "<xsl:value-of select="$element-name" />"</xsl:message>
      <xsl:for-each select="$properties">
        <xsl:message><xsl:value-of select='@name' />="<xsl:value-of select="@value" />"</xsl:message>
      </xsl:for-each>
    </xsl:if>
    
    <xsl:for-each select="$properties[not(starts-with(@name, 'ps-'))][string(@value) != '']">
      <xsl:attribute name="{@name}" select="@value" />
    </xsl:for-each>

  </xsl:function>
  
  <!-- 
    Check if an element is a fragment, one of:
      - fragment
      - xref-fragment
      - properties-fragment
      - media-fragment
    
    @param elem the potential fragment element
  -->
  <xsl:function name="psf:is-fragment">
    <xsl:param name="elem" />
    <xsl:sequence select="$elem[self::fragment or self::properties-fragment or self::xref-fragment or self::media-fragment]" />
  </xsl:function>

</xsl:stylesheet>