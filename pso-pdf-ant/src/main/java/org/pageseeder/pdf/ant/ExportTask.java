/*
 * Copyright (c) 1999-2012 weborganic systems pty. ltd.
 */
package org.pageseeder.pdf.ant;

import net.sourceforge.jeuclid.fop.plugin.JEuclidFopFactoryConfigurator;
import org.apache.commons.io.IOUtils;
import org.apache.fop.apps.*;
import org.apache.fop.configuration.Configuration;
import org.apache.fop.configuration.ConfigurationException;
import org.apache.fop.configuration.DefaultConfigurationBuilder;
import org.apache.fop.fonts.FontManager;
import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.Task;
import org.pageseeder.pdf.util.XML;
import org.pageseeder.pdf.util.XSLT;

import javax.xml.transform.*;
import javax.xml.transform.sax.SAXResult;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;
import java.io.*;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.util.*;
import java.util.stream.Collector;
import java.util.stream.Collectors;

import org.apache.fop.events.Event;
import org.apache.fop.events.EventFormatter;
import org.apache.fop.events.EventListener;
import org.apache.fop.events.model.EventSeverity;

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
  private static final Charset UTF8 = StandardCharsets.UTF_8;

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
   * The working directory
   */
  private File _working;

  /**
   * The font base directory
   */
  private File _fontFolder;

  /**
   * The font config file
   */
  private File _fontConfig;

  /**
   * The image resolution in DPI
   */
  private int _resolution = 200;

  /**
   * The FOConfig files to use.
   */
  private List<FOConfig> _FOConfigs = new ArrayList<>();

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
   * Set the font folder (optional).
   *
   * @param folder The font base folder
   */
  public void setFontFolder(File folder) {
    if (!folder.exists() || !folder.isDirectory()) {
      throw new BuildException("the font folder must exists and must be a directory");
    }
    this._fontFolder = folder;
  }

  /**
   * Set the font config file (optional).
   *
   * @param config The font config file
   */
  public void setFontConfig(File config) {
    if (!config.exists() || config.isDirectory()) {
      throw new BuildException("the font config must exists and must be a file");
    }
    this._fontConfig = config;
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
   * Create a config object and stores it in the list To be used by Ant
   * Task to get all nested element of <config ../>
   */
  public FOConfig createConfig() {
    FOConfig cfg = new FOConfig();
    this._FOConfigs.add(cfg);
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
    if (!this._FOConfigFolders.isEmpty()) {
      log("The 'configs' element under 'export-pdf' is deprecated, please remove it", Project.MSG_WARN);
    }

    if (this._source == null)
      throw new BuildException("Source PSML document must be specified using 'src' attribute");
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
    parameters.put("source-filename", this._source.getName());

    FileInputStream in = null;
    FileOutputStream out = null;

    try {
      // generate FOP config
      StringBuilder config = new StringBuilder();
      config.append("<fop version=\"1.0\">");
      if (this._fontFolder != null) {
        config.append("<font-base>file:///");
        XML.makeXMLSafe(this._fontFolder.getAbsolutePath(), config);
        config.append("</font-base>");
      }
      if (this._fontConfig != null) {
        config.append("<renderers>");
        config.append("<renderer mime=\"application/pdf\">");
        config.append(new String(Files.readAllBytes(this._fontConfig.toPath()),StandardCharsets.UTF_8));
        config.append("</renderer>");
        config.append("</renderers>");
      }
      config.append("</fop>");

      // initiate FOP
      DefaultConfigurationBuilder cfgBuilder = new DefaultConfigurationBuilder();
      Configuration cfg = cfgBuilder.build(new ByteArrayInputStream(config.toString().getBytes(StandardCharsets.UTF_8)));
      FopFactoryBuilder builder = new FopFactoryBuilder(this._source.getParentFile().toURI()).setConfiguration(cfg);

      //FopFactoryBuilder builder = new FopFactoryBuilder(this._source.getParentFile().toURI());
      // set resolution
      builder.setSourceResolution(this._resolution);
      FopFactory factory = builder.build();
      JEuclidFopFactoryConfigurator.configure(factory);
      FOUserAgent userAgent = factory.newFOUserAgent();
      userAgent.setCreationDate(new Date());
      userAgent.setProducer("PageSeeder ANT PDF Library");
      // log events through ANT
      userAgent.getEventBroadcaster().addEventListener(new AntEventListener(this));

      // source
      in = new FileInputStream(this._source);
      out = new FileOutputStream(this._destination);
      Fop fop = factory.newFop(MimeConstants.MIME_PDF, userAgent, out);
      // run transform
      Source source = new StreamSource(new BufferedInputStream(in), this._source.toURI().toString());
      Result result = new SAXResult(fop.getDefaultHandler());
      if (this.debug) {
        // write FO to working folder
        ByteArrayOutputStream fo_out = new ByteArrayOutputStream();
        XSLT.transform(source, new StreamResult(fo_out), templates, parameters);
        String fo = new String(fo_out.toByteArray(), UTF8);
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
        Source src = new StreamSource(new ByteArrayInputStream(fo.getBytes(UTF8)));
        transformer.transform(src, result);
      } else {
        XSLT.transform(source, result, templates, parameters);
      }
      log("PDF successfully generated ("+fop.getResults().getPageCount()+" pages)");
    } catch (FOPException ex) {
      log("PDF generation failed:", Project.MSG_ERR);
      log(ex, Project.MSG_ERR);
      throw new BuildException("Failed to build PDF file: "+ex.getMessage());
    } catch (IOException | TransformerException | ConfigurationException ex) {
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
    }
  }

  // Helpers
  // ----------------------------------------------------------------------------------------------

  /**
   * Build the complete config file
   *
   * @param config the file to write to
   *
   * @throws IOException if writing to the file failed
   */
  private void buildFOConfig(File config) throws IOException {
    // start with root
    FileWriter writer = new FileWriter(config);
    writer.write("<foconfigs>\n");
    // find highest priority
    int highestPriority = this._FOConfigs.stream().filter(c -> c._config != null && c._config.exists()).mapToInt(FOConfig::getPriority).max().orElseGet(() -> 0);
    // write the first one found with the highest priority
    FOConfig conf = this._FOConfigs.stream().filter(c -> c._config != null && c._config.exists() && c.getPriority() == highestPriority).findFirst().orElse(null);
    if (conf != null && conf._config != null && conf._config.exists()) {
      writer.write("<foconfig config=\"custom\">");
      writeStream(writer, new FileInputStream(conf._config));
      writer.write("</foconfig>\n");
    }
    // write default styles, with lowest priority
    writer.write("<foconfig config=\"default\">");
    ClassLoader loader = ExportTask.class.getClassLoader();
    InputStream defaultFO = loader.getResourceAsStream("org/pageseeder/pdf/resource/defaultFOConfig.xml");
    if (defaultFO != null) writeStream(writer, defaultFO);
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

  // FOConfig object
  /**
   * Holder for FO config definition.
   */
  public static final class FOConfig {
    /** The actual config file */
    private File _config;
    /** The priority */
    private int _priority = 1;

    /**
     * Set the config name (matching a psml document type)
     *
     * @param name the config name (matching a psml document type)
     *
     * @deprectated this method is no longer supported
     */
    public void setName(String name) {
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

    /**
     * @return the priority
     */
    public int getPriority() { return _priority; }
  }

  // FOConfigs object
  /**
   * Holder for FO configs definition.
   *
   * @deprectated this object is no longer supported
   */
  public static final class FOConfigs {
    /** The priority */
    private int _priority = 1;
    /** The folder containing the config files */
    private File _folder;

    /**
     * Set the FO configuration file.
     *
     * @param folder The configuration folder.
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

  private class AntEventListener implements EventListener {

    /**
     * ANT task to log to
     */
    private Task _task;

    /**
     * Constructor
     *
     * @param task the ANT task to log to
     */
    public AntEventListener(Task task) {
      this._task = task;
    }

    /** {@inheritDoc} */
    public void processEvent(Event event) {
      String msg = EventFormatter.format(event);
      EventSeverity severity = event.getSeverity();
      if (severity == EventSeverity.INFO) {
        // log to verbose to reduce chatter
        _task.log("[INFO] " + msg, Project.MSG_VERBOSE);
      } else if (severity == EventSeverity.WARN) {
        // remove chatty logs about ZapfDingbats
        if (msg.indexOf("Font \"ZapfDingbats") != -1 &&
                msg.indexOf("Substituting with \"ZapfDingbats") != -1) return;
        // log to verbose to reduce chatter
        _task.log("[WARN] " + msg, Project.MSG_VERBOSE);
      } else if (severity == EventSeverity.ERROR) {
        // log to verbose to reduce chatter
        _task.log("[ERROR] " + msg, Project.MSG_ERR);
      } else if (severity == EventSeverity.FATAL) {
        _task.log("[FATAL] " + msg, Project.MSG_ERR);
      }
    }
  }
}
