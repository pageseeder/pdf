/*
 * Copyright (c) 1999-2012 weborganic systems pty. ltd.
 */
package org.pageseeder.pdf.util;

import org.pageseeder.pdf.PDFException;

import javax.xml.transform.*;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;
import java.io.*;
import java.net.URL;
import java.util.Hashtable;
import java.util.Map;
import java.util.Map.Entry;


/**
 * A utility class for common XML functions.
 *
 * @author Philip Rutherford
 */
public final class XML {

  // Characters of significance in XML
  // ---------------------------------------------------------------------------------------------

  /** Horizontal Tab character. */
  private static final int HT = 0x9;

  /** Line Feed character. */
  private static final int LF = 0xA;

  /** Carriage Return character */
  private static final int CR = 0xD;

  /** Space character. */
  private static final int SP = 0x20;

  /** Delete characters (last ASCII character). */
  private static final int DEL = 0x7F;

  /** The last of the C1 control characters. */
  private static final int APC = 0x9F;

  /** Utility class. */
  private XML() {
  }

  /**
   * Replaces all occurrences of a &, < and > in the src string with entities.
   *
   * <p>Note: this method does not handle supplementary characters.
   *
   * @param text original string or null
   * @param xml result is appended here
   */
  public static void makeXMLSafe(String text, StringBuilder xml) {
    if (text != null) {
      for (int i = 0; i < text.length(); i++) {
        char c = text.charAt(i);
        if (isLegalXMLChar(c)) {
          switch (c) {
            case '>':
              xml.append("&gt;");
              break;
            case '<':
              xml.append("&lt;");
              break;
            case '&':
              xml.append("&amp;");
              break;
            default:
              xml.append(c);
              break;
          }
        } else {
          xml.append('?');
        }
      }
    }
  }

  /**
   * Indicates whether the character is a valid XML character.
   *
   * <p>This method will let through surrogate pairs assuming the target encoding is a Unicode Transformation Format.
   *
   * @param c The character to test.
   *
   * @return <code>true</code> if it is a valid XML character;
   *         <code>false</code> otherwise.
   */
  private static boolean isLegalXMLChar(char c) {
    return (c >= SP || c == HT || c == LF || c == CR) && !(c >= DEL && c <= APC);
  }

}
