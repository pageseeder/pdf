/*
 * Copyright (c) 1999-2012 weborganic systems pty. ltd.
 */
package org.pageseeder.pdf.ant;

import java.io.BufferedInputStream;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.Writer;
import java.nio.charset.Charset;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.xml.transform.Result;
import javax.xml.transform.Source;
import javax.xml.transform.Templates;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerConfigurationException;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.sax.SAXResult;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;

import org.apache.commons.io.IOUtils;
import org.apache.fop.apps.FOPException;
import org.apache.fop.apps.FOUserAgent;
import org.apache.fop.apps.Fop;
import org.apache.fop.apps.FopFactory;
import org.apache.fop.apps.FopFactoryBuilder;
import org.apache.fop.apps.MimeConstants;
import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.Task;
import org.pageseeder.pdf.util.XSLT;

/**
 * An ANT task to export a PageSeeder PSML document to a PDF document using FOP.
 *
 * <p>format is: </p>
 * <pre>{@code
 * <pdf:pdf-export src="${source}" dest="${output}" working="working">
 *     <configs folder="config" priority="5"/>
 *     <config name="drug" file="pdf-export-config.xml" priority="3 />
 *   </pdf:pdf-export>
 * </pre>}
 *
 * @author Jean-Baptiste Reure
 * @version 28 March 2014
 */
public final class ExportTask extends Task {

  /**
   * UTF 8 charset
   */
  private static final Charset UTF8 = Charset.forName("utf-8");

  /**
   * If debug mode.
   */
  private boolean debug = false;

  /**
   * The PSML document to export.
   */
  private File _source;

  /**
   * The PDF document to generate.
   */
  private File _destination;

  /**
   * The name of the working directory
   */
  private File _working;

  /**
   * The image resolution in DPI
   */
  private int _resolution = 200;

  /**
   * The FOConfig files to use.
   */
  private List<FOConfig> _FOConfigs = new ArrayList<FOConfig>();

  /**
   * The FOConfig folders to use.
   */
  private List<FOConfigs> _FOConfigFolders = new ArrayList<FOConfigs>();

  // Set properties
  // ----------------------------------------------------------------------------------------------

  /**
   * @param debug mode
   */
  public void setDebug(boolean debug) {
    this.debug = debug;
  }

  /**
   * Set the source file: a PageSeeder document to export as PDF.
   *
   * @param source The PSML document to export.
   */
  public void setSrc(File source) {
    if (!(source.exists())) {
      throw new BuildException("the document " + source.getName()+ " doesn't exist");
    }
    if (source.isDirectory()) {
      throw new BuildException("the document " + source.getName() + " can't be a directory");
    }
    this._source = source;
  }

  /**
   * Set the destination folder where PDF files should be stored.
   *
   * @param destination Where to store the PDF files.
   */
  public void setDest(File destination) {
    if (destination.exists() && destination.isDirectory()) {
      throw new BuildException("if destination PDF exists, it must be a file");
    }
    this._destination = destination;
  }

  /**
   * Set the working folder (optional).
   *
   * @param working The working folder.
   */
  public void setWorking(File working) {
    if (working.exists() && !working.isDirectory()) {
      throw new BuildException("if working folder exists, it must be a directory");
    }
    this._working = working;
  }

  /**
   * Create a config object and stores it in the list To be used by Ant
   * Task to get all nested element of <config ../>
   */
  public FOConfig createConfig() {
    FOConfig cfg = new FOConfig();
    this._FOConfigs.add(cfg);
    return cfg;
  }

  /**
   * Create a config folder object and stores it in the list To be used by Ant
   * Task to get all nested element of <configs ../>
   */
  public FOConfigs createConfigs() {
    FOConfigs cfg = new FOConfigs();
    this._FOConfigFolders.add(cfg);
    return cfg;
  }

  /**
   * Set the image resolution in DPI (optional).
   * 
   * @param resolution the image resolution in DPI
   */
  public void setResolution(int resolution) {
    this._resolution = resolution;
  }

  // Execute
  // ----------------------------------------------------------------------------------------------

  @Override
  public void execute() throws BuildException {
    if (this._source == null)
      throw new BuildException("Source presentation must be specified using 'src' attribute");
    // Defaulting working directory
    if (this._working == null) {
      String tmp = "antpdf-"+System.currentTimeMillis();
      this._working = new File(System.getProperty("java.io.tmpdir"), tmp);
    }
    if (!this._working.exists()) {
      this._working.mkdirs();
    }

    // Defaulting destination directory
    if (this._destination == null) {
      this._destination = new File(this._source.getParentFile(), ".pdf");
      log("Destination set to "+this._destination.getName());
    }
    this._destination.getParentFile().mkdirs();

    // Complete config file
    File foConfig = new File(this._working, this._source.getName()+"-FOConfig.xml");
    try {
      buildFOConfig(foConfig);
    } catch (IOException ex) {
      log("Config file generation failed:", Project.MSG_ERR);
      log(ex, Project.MSG_ERR);
      throw new BuildException("Failed to build FO Config file: "+ex.getMessage());
    }

    // Parse templates
    Templates templates = XSLT.getTemplatesFromResource("org/pageseeder/pdf/xslt/export.xsl");

    // Initiate parameters
    Map<String, String> parameters = new HashMap<String, String>();
    parameters.put("foconfigfileurl", foConfig.toURI().toString());
    parameters.put("base", this._source.getParentFile().toURI().toString());

    FileInputStream in = null;
    FileOutputStream out = null;
    
    // initiate FOP
    FopFactoryBuilder builder = new FopFactoryBuilder(this._source.getParentFile().toURI());
    // set resolution
    builder.setSourceResolution(this._resolution);
    FopFactory factory = builder.build();
    FOUserAgent userAgent = factory.newFOUserAgent();
    userAgent.setCreationDate(new Date());
    userAgent.setProducer("PageSeeder ANT PDF Library");
    Fop fop;
    try {
      // source
      in = new FileInputStream(this._source);
      out = new FileOutputStream(this._destination);
      fop = factory.newFop(MimeConstants.MIME_PDF, userAgent, out);
      // run transform
      Source source = new StreamSource(new BufferedInputStream(in), this._source.toURI().toString());
      Result result = new SAXResult(fop.getDefaultHandler());
      if (this.debug) {
        // write FO to working folder
        ByteArrayOutputStream fo_out = new ByteArrayOutputStream();
        XSLT.transform(source, new StreamResult(fo_out), templates, parameters);
        String fo = new StringBuffer(new String(fo_out.toByteArray(), "utf-8")).toString();
        OutputStream fout;
        try {
          fout = new FileOutputStream(new File(_working, "fo.xml"));
          try {
            IOUtils.write(fo, fout, "utf-8");
          } finally {
            fout.close();
          }
        } catch (Exception ex) {
          log("Unable to save FO document: " + ex.getMessage());
        }

        // generate PDF
        TransformerFactory tfactory = TransformerFactory.newInstance();
        Transformer transformer = tfactory.newTransformer(); // identity transformer
        Source src = new StreamSource(new ByteArrayInputStream(fo.getBytes("utf-8")));
        transformer.transform(src, result);
      } else {
        XSLT.transform(source, result, templates, parameters);
      }
      log("PDF successfully generated ("+fop.getResults().getPageCount()+" pages)");
    } catch (FOPException ex) {
      log("PDF generation failed:", Project.MSG_ERR);
      log(ex, Project.MSG_ERR);
      throw new BuildException("Failed to build PDF file: "+ex.getMessage());
    } catch (IOException ex) {
      log("PDF generation failed:", Project.MSG_ERR);
      log(ex, Project.MSG_ERR);
      throw new BuildException("Failed to build PDF file: "+ex.getMessage());
    } catch (TransformerConfigurationException ex) {
      log("PDF generation failed:", Project.MSG_ERR);
      log(ex, Project.MSG_ERR);
      throw new BuildException("Failed to build PDF file: "+ex.getMessage());
    } catch (TransformerException ex) {
      log("PDF generation failed:", Project.MSG_ERR);
      log(ex, Project.MSG_ERR);
      throw new BuildException("Failed to build PDF file: "+ex.getMessage());
    } finally {
      try {
        if (in != null) in.close();
        if (out != null) out.close();
      } catch (IOException ex) {
        log("Failed to close stream: {}", ex, Project.MSG_ERR);
      }
      // free memory?
      userAgent = null;
      fop = null;
    }
  }

  // Helpers
  // ----------------------------------------------------------------------------------------------

  /**
   * Build the complete config file
   * 
   * @param config the file to write to
   * @throws IOException 
   */
  private void buildFOConfig(File config) throws IOException {
    // start with root
    FileWriter writer = new FileWriter(config);
    writer.write("<foconfigs>\n");
    // write all styles
    for (FOConfig conf : this._FOConfigs) {
      if (conf._config == null) {
        log("Ignoring config "+conf._name+" which does not exist", Project.MSG_WARN);
      } else {
        writer.write("<foconfig config=\""+escapeAttValue(conf._name)+"\" priority=\""+conf._priority+"\">");
        writeStream(writer, new FileInputStream(conf._config));
        writer.write("</foconfig>\n");
      }
    }
    // write all styles
    for (FOConfigs conf : this._FOConfigFolders) {
      if (conf._folder != null) {
        File[] folders = conf._folder.listFiles();
        if (folders != null) {
          for (File folder : folders) {
            File foconfig = new File(folder, "pdf-export-config.xml");
            if (foconfig.exists() && foconfig.isFile()) {
              writer.write("<foconfig config=\""+escapeAttValue(folder.getName())+"\" priority=\""+conf._priority+"\">");
              writeStream(writer, new FileInputStream(foconfig));
              writer.write("</foconfig>\n");
            } else {
              log("Ignoring configs folder "+folder.getName()+" as no valid FO config file was found (it should be named pdf-export-config.xml)", Project.MSG_WARN);
            }
          }
        } else {
          log("Ignoring configs folder "+conf._folder.getName(), Project.MSG_WARN);
        }
      } else {
        log("Ignoring configs folder which does not exist", Project.MSG_WARN);
      }
    }
    // write default styles, with lowest priority
    writer.write("<foconfig config=\"default\" priority=\"0\">");
    ClassLoader loader = ExportTask.class.getClassLoader();
    writeStream(writer, loader.getResourceAsStream("org/pageseeder/pdf/resource/defaultFOConfig.xml"));
    writer.write("</foconfig>\n");
    // close root
    writer.write("</foconfigs>");
    writer.close();
  }

  /**
   * Write a stream to the writer provided
   * 
   * @param out wher to write
   * @param in  what to write
   * 
   * @throws IOException if reading/writing the content failed
   */
  private static void writeStream(Writer out, InputStream in) throws IOException {
    try {
      // 4K buffer
      final byte[] buffer = new byte[1024 * 4];
      int n;
      boolean start = true; // faster
      while ((n = in.read(buffer)) != -1) {
        String s = new String(buffer, 0, n, UTF8);
        if (s.startsWith("<?xml") && start) s = s.substring(s.indexOf('>')+1);
        out.write(s);
        start = false;
      }
     } finally {
       in.close();
     }
  }

  /**
   * Escapes the text to be used as an attribute value for an UTF-8 encoded XML document.
   *
   * <p>
   * Replace characters which are invalid in element values, by the corresponding entity in a given <code>String</code>.
   *
   * <p>
   * These characters are:<br>
   * <ul>
   *   <li>'&amp' by the ampersand entity "&amp;amp"</li>
   *   <li>'&lt;' by the entity "&amp;lt;"</li>
   *   <li>'&apos;' by the entity "&amp;apos;"</li>
   *   <li>'&quot;' by the entity "&amp;quot;"</li>
   * </ul>
   * </p>
   *
   * <p>
   * Empty strings or <code>null</code> return respectively "" and <code>null</code>.

   * <p>
   * This method is lenient in the sense that it will not report illegal characters that cannot be escaped such as
   * control characters.
   *
   * <pre>
   * {@code
   *   [10]     AttValue     ::=    '"' ([^<&"] | Reference)* '"'
   *                             |  "'" ([^<&'] | Reference)* "'"
   * }
   * </pre>
   *
   * <p>
   * This method assumes that the given text is not XML data, that is it does not attempt to understand entities, child
   * elements or other XML data.
   *
   * @param value the attribute value to escape
   * @return the corresponding escaped text
   */
  public static String escapeAttValue(String value) {
    // bypass null and empty strings
    if (value == null || "".equals(value)) return "";
    // do not process valid strings
    if (value.indexOf('&') == -1 && value.indexOf('<') == -1 && value.indexOf('\'') == -1 && value.indexOf('"') == -1)
      return value;
    // process the rest
    StringBuilder out = new StringBuilder(value.length() + 8);
    for (int i = 0; i < value.length(); i++) {
      char c = value.charAt(i);
      switch (c) {
        case '&':
          out.append("&amp;");
          break;
        case '<':
          out.append("&lt;");
          break;
        case '\'':
          out.append("apos;");
          break;
        case '"':
          out.append("&quot;");
          break;
        default:
          out.append(c);
      }
    }
    return out.toString();
  }

  // FOConfig object
  /**
   * Holder for FO config definition.
   */
  public static final class FOConfig {
    /** Config name (matching a psml document type) */
    private String _name = "default";
    /** The actual config file */
    private File _config;
    /** The priority */
    private int _priority = 1;

    /**
     * Set the config name (matching a psml document type)
     * 
     * @param name the config name (matching a psml document type)
     */
    public void setName(String name) {
      this._name = name;
    }

    /**
     * Set the FO configuration file.
     *
     * @param file The configuration file.
     */
    public void setFile(File file) {
      if (file.exists() && !file.isDirectory()) {
        this._config = file;
      }     
    }

    /**
     * Set the priority
     * 
     * @param priority The priority
     */
    public void setPriority(int priority) {
      this._priority = priority;
    }
  }

  // FOConfigs object
  /**
   * Holder for FO configs definition.
   */
  public static final class FOConfigs {
    /** The priority */
    private int _priority = 1;
    /** The folder containing the config files */
    private File _folder;

    /**
     * Set the FO configuration file.
     *
     * @param file The configuration file.
     */
    public void setFolder(File folder) {
      if (folder.exists() && folder.isDirectory()) {
        this._folder = folder;
      }  
    }

    /**
     * Set the priority
     * 
     * @param priority The priority
     */
    public void setPriority(int priority) {
      this._priority = priority;
    }
  }
}
