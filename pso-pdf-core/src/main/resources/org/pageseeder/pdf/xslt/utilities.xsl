<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                              xmlns:fo="http://www.w3.org/1999/XSL/Format"
                              xmlns:psf="http://www.pageseeder.com/function"
                              exclude-result-prefixes="psf">

  <xsl:param name="source-filename" />

  <xsl:variable name="foconfigs"    select="document($foconfigfileurl)" />
  <xsl:variable name="mainconfig"   select="/document/@type" />
  <xsl:variable name="uriusertitle" select="if (/document/documentinfo/uri/displayname) then /document/documentinfo/uri/displayname else $source-filename"/>
  
  <!--
    Find the config that defines a margin zone.
    It could be the current one, the 'mainconfig' parameter or default
    
    @param config     the current config
  -->
  <xsl:function name="psf:config-with-margin-zone">
    <xsl:param name="config" />
    <xsl:choose>
      <xsl:when test="exists($foconfigs//foconfig[@config = $config]//header |
                             $foconfigs//foconfig[@config = $config]//footer |
                             $foconfigs//foconfig[@config = $config]//left |
                             $foconfigs//foconfig[@config = $config]//right)"><xsl:value-of select="$config" /></xsl:when>
      <xsl:when test="$mainconfig != '' and exists($foconfigs//foconfig[@config = $mainconfig]//header |
                             $foconfigs//foconfig[@config = $mainconfig]//footer |
                             $foconfigs//foconfig[@config = $mainconfig]//left |
                             $foconfigs//foconfig[@config = $mainconfig]//right)"><xsl:value-of select="$mainconfig" /></xsl:when>
      <xsl:otherwise>default</xsl:otherwise>
    </xsl:choose>

  </xsl:function>
  
  <!--
    Method used to load the margin zone definition.
    
    @param config     the FOConfig.xml config file
    @param type       the type of margin zone (supported values are 'header', 'footer', 'left' and 'right')
    @param first      if we should get the one for the first page (values are 'true', 'false' or '' which means any value)
  -->
  <xsl:function name="psf:margin-zone">
    <xsl:param name="config" />
    <xsl:param name="type" />
    <xsl:param name="first" />

    <!-- find all the margin zones defined -->
    <xsl:variable name="all" select="$foconfigs//foconfig[@config = $config or @config = 'default']//*[name() = $type]
                                     [$first = '' or ($first = 'true' and @first = 'true') or ($first = 'false' and empty(@first))]" />
    <!-- now only use the one with the highest priority -->
    <xsl:variable name="max-priority" select="max($all/ancestor::foconfig/@priority)" />
    <xsl:sequence select="$all[ancestor::foconfig/@priority = $max-priority][1]" />

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
    <xsl:variable name="config" select="psf:load-config($context)" />
    <!-- find all the header/footer/left/right defined -->
    <xsl:variable name="all">
      <xsl:for-each select="$foconfigs//foconfig[@config = $config or @config = 'default']">
        <xsl:choose>
          <!-- if 'first' then only search for styling in the 'first' zone -->
          <xsl:when test="$odd-or-even = 'first'">
            <xsl:if test=".//*[name() = $type][@first = 'true']">
              <foconfig xmlns="" priority="{@priority}">
                <xsl:sequence select=".//*[name() = $type][@first = 'true']" />
              </foconfig>
            </xsl:if>
          </xsl:when>
          <!-- otherwise, try to find the zone exactly matching the 'odd-or-even' flag -->
          <xsl:when test=".//*[name() = $type][@odd-or-even = $odd-or-even]">
            <foconfig xmlns="" priority="{@priority}">
              <xsl:sequence select=".//*[name() = $type][@odd-or-even = $odd-or-even]" />
            </foconfig>
          </xsl:when>
          <!-- otherwise find a general zone (no 'odd-or-even' and no 'first') -->
          <xsl:when test=".//*[name() = $type][empty(@odd-or-even) and not(@first = 'true')]">
            <foconfig xmlns="" priority="{@priority}">
              <xsl:sequence select=".//*[name() = $type][empty(@odd-or-even) and not(@first = 'true')]" />
            </foconfig>
          </xsl:when>
        </xsl:choose>
      </xsl:for-each>
    </xsl:variable>
    <!-- now only use the one with the highest priority -->
    <xsl:variable name="max-priority" select="max($all//foconfig/@priority)" />
    <!-- and apply template to the correct element within (using position: left, right, center or top, middle, bottom) -->
    <xsl:apply-templates select="$all//foconfig[@priority = $max-priority][1]/*/*[name(.) = $position]" mode="style">
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
    <xsl:variable name="pat"><xsl:choose><xsl:when test="@pattern"><xsl:value-of select="@pattern" /></xsl:when>
    <xsl:otherwise>[MNn] [D], [Y]</xsl:otherwise></xsl:choose></xsl:variable>
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
    <xsl:choose>
    <!-- if in a transclusion, then use the parent's config -->
      <xsl:when test="$context/ancestor::blockxref">
        <xsl:value-of select="psf:load-config($context/ancestor::blockxref)" />
      </xsl:when>
      <!-- if in transcluded document with a config -->
      <xsl:when test="$context/ancestor-or-self::document[@type]">
        <xsl:value-of select="$context/ancestor-or-self::document[@type][1]/@type" />
      </xsl:when>
      <!-- if there's a general style config -->
      <xsl:when test="$mainconfig != ''">
        <xsl:value-of select="$mainconfig" />
      </xsl:when>
      <xsl:otherwise>default</xsl:otherwise>
    </xsl:choose>
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
    <xsl:variable name="type"         select="tokenize($element-name, '-')[1]" />
    <xsl:variable name="odd-or-even"  select="tokenize($element-name, '-')[2]" />
    <xsl:variable name="position"     select="tokenize($element-name, '-')[3]" />

    <!--  then load all the properties wanted -->
    <xsl:variable name="all-properties">
      <xsl:for-each select="$foconfigs//foconfig[@config = $config or @config = 'default']">
        <foconfig xmlns="" priority="{@priority}">
          <xsl:choose>
            <xsl:when test="($type = 'header' or $type = 'footer' or $type = 'right' or $type = 'left') and
                            ($position = 'left' or $position = 'center' or $position = 'right')">
              <xsl:choose>
                <!-- For first, select properties from first if found somewhere, otherwise, use non even properties -->
                <xsl:when test="$odd-or-even = 'first'">
                  <xsl:choose>
                    <xsl:when test=".//*[name() = $type][@first = 'true']/*[name(.) = $position]/*[name() = $property-tag]">
                      <xsl:sequence select=".//*[name() = $type][@first = 'true']/*[name(.) = $position]/*[name() = $property-tag]" />
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:sequence select=".//*[name() = $type][@odd-or-even = 'odd' or (string(@odd-or-even) = '' and string(@first) = '')]
                                              /*[name(.) = $position]/*[name() = $property-tag]" />
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:when>
                <!-- For odd or even, select properties with the right "scope" if found somewhere, otherwise, use normal properties -->
                <xsl:when test="$odd-or-even = 'odd' or $odd-or-even = 'even'">
                  <xsl:choose>
                    <xsl:when test=".//*[name() = $type][@odd-or-even = $odd-or-even]/*[name(.) = $position]/*[name() = $property-tag]">
                      <xsl:sequence select=".//*[name() = $type][@odd-or-even = $odd-or-even]/*[name(.) = $position]/*[name() = $property-tag]" />
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:sequence select=".//*[name() = $type][string(@odd-or-even) = '' and string(@first) = '']
                                              /*[name(.) = $position]/*[name() = $property-tag]" />
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:when>
              </xsl:choose>
            </xsl:when>
            <xsl:when test="$type = 'header' or $type = 'footer' or $type = 'right' or $type = 'left'">
              <xsl:choose>
                <!-- For first, select properties from first if found somewhere, otherwise, use non even properties -->
                <xsl:when test="$odd-or-even = 'first'">
                  <xsl:choose>
                    <xsl:when test=".//*[name() = $type][@first = 'true']/*[name() = $property-tag]">
                      <xsl:sequence select=".//*[name() = $type][@first = 'true']/*[name() = $property-tag]" />
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:sequence select=".//*[name() = $type][@odd-or-even = 'odd' or (string(@odd-or-even) = '' and string(@first) = '')]
                                              /*[name() = $property-tag]" />
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:when>
                <!-- For odd or even, select properties with the right "scope" if found somewhere, otherwise, use normal properties -->
                <xsl:when test="$odd-or-even = 'odd' or $odd-or-even = 'even'">
                  <xsl:choose>
                    <xsl:when test=".//*[name() = $type][@odd-or-even = $odd-or-even]/*[name() = $property-tag]">
                      <xsl:sequence select=".//*[name() = $type][@odd-or-even = $odd-or-even]/*[name() = $property-tag]" />
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:sequence select=".//*[name() = $type][string(@odd-or-even) = '' and string(@first) = '']/*[name() = $property-tag]" />
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:when>
              </xsl:choose>
            </xsl:when>
            <xsl:when test="$type = 'page' or $type = 'body'">
              <xsl:sequence select=".//*[name() = $type][string(@role) = $role]/*[name() = $property-tag]" />
            </xsl:when>
            <!-- heading/para prefix: heading-prefix-2 ==> <element name="heading-prefix" level="2"> -->
            <xsl:when test="($type = 'heading' or $type = 'para') and $odd-or-even = 'prefix' and .//element[string(@name) = concat($type, '-prefix') and @level = $position]">
              <xsl:sequence select=".//element[string(@name) = concat($type, '-prefix') and @level = $position][string(@role) = $role]/*[name() = $property-tag]" />
            </xsl:when>
            <!-- heading/para: heading-2 ==> <element name="heading" level="2"> -->
            <xsl:when test="($type = 'heading' or $type = 'para') and .//element[string(@name) = $type and @level = $odd-or-even]">
              <xsl:sequence select=".//element[string(@name) = $type and @level = $odd-or-even][string(@role) = $role]/*[name() = $property-tag]" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:sequence select=".//element[string(@name) = $element-name][string(@role) = $role]/*[name() = $property-tag]" />
            </xsl:otherwise>
          </xsl:choose>
        </foconfig>
      </xsl:for-each>
    </xsl:variable>
    
    <!-- finally filter the duplicates by removing the lower priorities -->
    <!-- and make sure that all properties are present -->
    <xsl:for-each select="$all-properties//*[name() = $property-tag]">
      <xsl:variable name="max-priority" select="max($all-properties//foconfig[.//*[name() = $property-tag][@name=current()/@name]][@priority]/@priority)" />
      <xsl:if test="ancestor::foconfig/@priority = $max-priority">
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
  <xsl:function name="psf:style-region-properties">
    <xsl:param name="config" />
    <xsl:param name="element-name" />
    <xsl:sequence select="psf:style-properties-all($config, $element-name, 'region-property', '')" />
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