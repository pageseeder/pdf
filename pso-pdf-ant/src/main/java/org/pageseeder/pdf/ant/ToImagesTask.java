/*
 * Copyright (c) 1999-2012 weborganic systems pty. ltd.
 */
package org.pageseeder.pdf.ant;

import java.awt.image.BufferedImage;
import java.io.File;
import java.util.List;

import javax.imageio.ImageIO;

import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDDocumentCatalog;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.util.ImageIOUtil;
import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.Task;


/**
 * An ANT task to transform a PDF document to a set of images.
 *
 * @author Christophe Lauret
 * @version 14 November 2012
 */
public final class ToImagesTask extends Task {

  /**
   * The PowerPoint Presentation to import.
   */
  private File _source;

  /**
   * Where to create the PageSeeder documents (a directory).
   */
  private File _destination;

  /**
   * The resolution in DPI.
   */
  private int _resolution = 300;

  /**
   * The image format.
   */
  private String _format = "png";

  // Set properties
  // ----------------------------------------------------------------------------------------------

  /**
   * Set the source PDF file to process.
   *
   * @param pdf The PDF file to process
   */
  public void setSrc(File pdf) {
    if (!(pdf.exists())) {
      throw new BuildException("the PDF " + pdf.getName()+ " doesn't exist");
    }
    if (pdf.isDirectory()) {
      throw new BuildException("the PDF " + pdf.getName() + " can't be a directory");
    }
    String name = pdf.getName();
    if (!name.endsWith(".pdf") && !name.endsWith(".pdf")) {
      log("presentation file should generally end with .pptx or .zip - but was "+name);
    }
    this._source = pdf;
  }

  /**
   * Set the destination folder where the PageSeeder document should be created.
   *
   * @param destination The destination folder.
   */
  public void setDest(File destination) {
    this._destination = destination;
    if (destination.exists() && !destination.isDirectory()) {
      throw new BuildException("the destination " + destination.getName() + " must be a directory");
    }
  }

  /**
   * Set the resolution in DPI.
   *
   * @param dpi The resolution in DPI.
   */
  public void setResolution(int dpi) {
    this._resolution = dpi;
    if (dpi < 1) {
      throw new BuildException("The dpi " + dpi + " is too small (< 1)");
    } else if (dpi < 72) {
      log("The dpi " + dpi + " might be too small (<72) and result in poor quality images.");
    } else if (dpi > 300) {
      log("The dpi " + dpi + " might be too large (>300) and result in slow processing.");
    } else if (dpi > 4000) {
      throw new BuildException("The dpi " + dpi + " is too large (> 4000)");
    }
  }

  /**
   * Set the image format to use.
   *
   * @param format The image format to use.
   */
  public void setFormat(String format) {
    this._format = format;
    // check that the format is supported
    boolean isSupported = false;
    String[] supported = ImageIO.getReaderFormatNames();
    for (String s :  supported) {
      if (s.equals(format)) isSupported = true;
    }
    if (!isSupported)
      throw new BuildException("The image format '"+format+"' is not supported, must be one of "+supported);
  }

  // Execute
  // ----------------------------------------------------------------------------------------------

  @SuppressWarnings("unchecked")
  @Override
  public void execute() throws BuildException {
    if (this._source == null)
      throw new BuildException("Source presentation must be specified using 'src' attribute");

    // Defaulting destination directory
    if (this._destination == null) {
      this._destination = this._source.getParentFile();
      log("Destination set to source directory "+this._destination.getAbsolutePath()+"");
    }

    // 4. Convert rows to PSXML
    log("Processing "+this._source.getName());
    PDDocument document = null;
    try {
      document = PDDocument.load(this._source);

      // Grab the name
      String name = this._source.getName();
      if (name.endsWith(".pdf")) name = name.substring(0, name.length() - 4);

      // Compute the destination
      this._destination.mkdirs();
      String prefix = new File(this._destination, name +"-p").getAbsolutePath();

      if (document.isEncrypted()) {
        throw new BuildException("The PDF document is encrypted");
      }

      // Iterate over the pages
      PDDocumentCatalog catalog = document.getDocumentCatalog();

      List<PDPage> pages = catalog.getAllPages();
      log("Found "+pages.size()+" pages");

      for (int i = 0; i < pages.size(); ++i) {
        PDPage page = pages.get(i);
        BufferedImage image = page.convertToImage(BufferedImage.TYPE_INT_RGB, this._resolution);
        String fileName = prefix + (i + 1);
        boolean ok = ImageIOUtil.writeImage(image, this._format, fileName, BufferedImage.TYPE_INT_RGB, this._resolution);
        if (!ok) {
          log("Unable to write page #"+(i+1), Project.MSG_WARN);
        }
      }

    } catch (Exception ex) {
      ex.printStackTrace();
    }

  }

}



