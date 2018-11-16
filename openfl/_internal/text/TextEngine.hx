package openfl._internal.text;


import haxe.Timer;
import haxe.Utf8;
import lime.graphics.cairo.CairoFontFace;
import lime.graphics.opengl.GLTexture;
import lime.system.System;
import lime.text.TextLayout;
import openfl.events.Event;
import openfl.events.FocusEvent;
import openfl.events.MouseEvent;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.text.AntiAliasType;
import openfl.text.Font;
import openfl.text.GridFitType;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFieldType;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;

#if (js && html5)
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import js.html.CSSStyleDeclaration;
import js.html.InputElement;
import js.html.KeyboardEvent in HTMLKeyboardEvent;
import js.Browser;
#end

#if sys
import haxe.io.Path;
#end

@:access(openfl.text.Font)
@:access(openfl.text.TextField)
@:access(openfl.text.TextFormat)


class TextEngine {
	
	/* The stock OpenFL adds 2 pixels margins around text from each side. These
       margins are not included into the textWidth and textHeight properties'
       values.
       Widgets based on the OpenFL's TextField that set their (and TextField's)
       size basing on the text size have no chance to get a size that includes
       those margins because openfl.text.TextField doesn't have any APIs to get
       margins' values. The getLineMetrics() API is line-specific and returns
       only left margin.
       Since there is no way for TextFields users to get margins' values, I
       (nmamaev) believe the idea of those margins itself is wrong. So setting
       all margins to zero. */
	//public static inline var HORIZONTAL_MARGIN : Float = 2.0;
	//public static inline var VERTICAL_MARGIN : Float = 2.0;
	public static inline var HORIZONTAL_MARGIN : Float = 0.0;
	public static inline var VERTICAL_MARGIN : Float = 0.0;
	
	private static inline var UTF8_TAB = 9;
	private static inline var UTF8_ENDLINE = 10;
	private static inline var UTF8_SPACE = 32;
	private static inline var UTF8_HYPHEN = 0x2D;
	
	private static var __defaultFonts = new Map<String, Font> ();
	
	#if (js && html5)
	private static var __canvas:CanvasElement;
	private static var __context:CanvasRenderingContext2D;
	#end
	
	public var antiAliasType:AntiAliasType;
	public var autoSize:TextFieldAutoSize;
	public var background:Bool;
	public var backgroundColor:Int;
	public var border:Bool;
	public var borderColor:Int;
	public var bottomScrollV (default, null):Int;
	public var bounds:Rectangle;
	public var caretIndex:Int;
	public var displayAsPassword:Bool;
	public var embedFonts:Bool;
	public var gridFitType:GridFitType;
	public var height:Float;
	public var layoutGroups:Array<TextLayoutGroup>;
	public var lineAscents:Array<Float>;
	public var lineBreaks:Array<Int>;
	public var lineDescents:Array<Float>;
	public var lineLeadings:Array<Float>;
	public var lineHeights:Array<Float>;
	public var lineWidths:Array<Float>;
	public var maxChars:Int;
	public var maxScrollH (default, null):Int;
	public var maxScrollV (default, null):Int;
	public var multiline:Bool;
	public var numLines (default, null):Int;
	public var restrict:String;
	public var scrollH:Int;
	public var scrollV:Int;
	public var selectable:Bool;
	public var sharpness:Float;
	public var text:String;
	public var textHeight:Float;
	public var textFormatRanges:Array<TextFormatRange>;
	public var textWidth:Float;
	public var type:TextFieldType;
	public var width:Float;
	public var wordWrap:Bool;
	
	private var textField:TextField;
	
	@:noCompletion private var __cursorPosition:Int;
	@:noCompletion private var __cursorTimer:Timer;
	@:noCompletion private var __hasFocus:Bool;
	@:noCompletion private var __isKeyDown:Bool;
	@:noCompletion private var __measuredHeight:Int;
	@:noCompletion private var __measuredWidth:Int;
	@:noCompletion private var __selectionStart:Int;
	@:noCompletion private var __showCursor:Bool;
	@:noCompletion private var __textFormat:TextFormat;
	@:noCompletion private var __textLayout:TextLayout;
	@:noCompletion private var __texture:GLTexture;
	//@:noCompletion private var __tileData:Map<Tilesheet, Array<Float>>;
	//@:noCompletion private var __tileDataLength:Map<Tilesheet, Int>;
	//@:noCompletion private var __tilesheets:Map<Tilesheet, Bool>;
	
	@:noCompletion @:dox(hide) public var __cairoFont:CairoFontFace;
	@:noCompletion @:dox(hide) public var __font:Font;
	
	#if (js && html5)
	private var __hiddenInput:InputElement;
	#end
	
	
	public function new (textField:TextField) {
		
		this.textField = textField;
		
		width = 100;
		height = 100;
		text = "";
		
		bounds = new Rectangle (0, 0, 0, 0);
		
		type = TextFieldType.DYNAMIC;
		autoSize = TextFieldAutoSize.NONE;
		displayAsPassword = false;
		embedFonts = false;
		selectable = true;
		borderColor = 0x000000;
		border = false;
		backgroundColor = 0xffffff;
		background = false;
		gridFitType = GridFitType.PIXEL;
		maxChars = 0;
		multiline = false;
		sharpness = 0;
		scrollH = 0;
		scrollV = 1;
		wordWrap = false;
		
		lineAscents = new Array ();
		lineBreaks = new Array ();
		lineDescents = new Array ();
		lineLeadings = new Array ();
		lineHeights = new Array ();
		lineWidths = new Array ();
		layoutGroups = new Array ();
		textFormatRanges = new Array ();
		
		#if (js && html5)
		__canvas = cast Browser.document.createElement ("canvas");
		__context = __canvas.getContext ("2d");
		#end
		
	}
	
	
	private static function findFont (name:String):Font {
		
		#if (cpp || neko || nodejs)
		
		for (registeredFont in Font.__registeredFonts) {
			
			if (registeredFont == null) continue;
			
			if (registeredFont.fontName == name || (registeredFont.__fontPath != null && (registeredFont.__fontPath == name || registeredFont.__fontPathWithoutDirectory == name))) {
				
				return registeredFont;
				
			}
			
		}
		
		var font = Font.fromFile (name);
		
		if (font != null) {
			
			Font.__registeredFonts.push (font);
			return font;
			
		}
		
		#end
		
		return null;
		
	}
	
	
	private function getBounds ():Void {
		
		var padding = border ? 1 : 0;
		
		bounds.width = width + padding;
		bounds.height = height + padding;
		
	}
	
	
	public static function getFont (format:TextFormat):String {
		
		var font = format.italic ? "italic " : "normal ";
		font += "normal ";
		font += format.bold ? "bold " : "normal ";
		font += format.size + "px";
		font += "/" + (format.size + format.leading + 6) + "px ";
		
		font += "" + switch (format.font) {
			
			case "_sans": "sans-serif";
			case "_serif": "serif";
			case "_typewriter": "monospace";
			default: "'" + format.font + "'";
			
		}
		
		return font;
		
	}
	
	
	public static function getFontInstance (format:TextFormat):Font {
		
		#if (cpp || neko || nodejs)
		
		var instance = null;
		var fontList = null;
		
		if (format != null && format.font != null) {
			
			if (__defaultFonts.exists (format.font)) {
				
				return __defaultFonts.get (format.font);
				
			}
			
			instance = findFont (format.font);
			if (instance != null) return instance;
			
			var systemFontDirectory = System.fontsDirectory;
			
			switch (format.font) {
				
				case "_sans":
					
					#if windows
					if (format.bold) {
						
						if (format.italic) {
							
							fontList = [ systemFontDirectory + "/arialbi.ttf" ];
							
						} else {
							
							fontList = [ systemFontDirectory + "/arialbd.ttf" ];
							
						}
						
					} else {
						
						if (format.italic) {
							
							fontList = [ systemFontDirectory + "/ariali.ttf" ];
							
						} else {
							
							fontList = [ systemFontDirectory + "/arial.ttf" ];
							
						}
						
					}
					#elseif (mac || ios || tvos)
					fontList = [ systemFontDirectory + "/Arial Black.ttf", systemFontDirectory + "/Arial.ttf", systemFontDirectory + "/Helvetica.ttf", systemFontDirectory + "/Cache/Arial Black.ttf", systemFontDirectory + "/Cache/Arial.ttf", systemFontDirectory + "/Cache/Helvetica.ttf", systemFontDirectory + "/Core/Arial Black.ttf", systemFontDirectory + "/Core/Arial.ttf", systemFontDirectory + "/Core/Helvetica.ttf", systemFontDirectory + "/CoreAddition/Arial Black.ttf", systemFontDirectory + "/CoreAddition/Arial.ttf", systemFontDirectory + "/CoreAddition/Helvetica.ttf" ];
					#elseif linux
					fontList = [ new sys.io.Process('fc-match', ['sans', '-f%{file}']).stdout.readLine() ];
					#elseif android
					fontList = [ systemFontDirectory + "/DroidSans.ttf" ];
					#elseif blackberry
					fontList = [ systemFontDirectory + "/arial.ttf" ];
					#end
				
				case "_serif":
					
					// pass through
				
				case "_typewriter":
					
					#if windows
					if (format.bold) {
						
						if (format.italic) {
							
							fontList = [ systemFontDirectory + "/courbi.ttf" ];
							
						} else {
							
							fontList = [ systemFontDirectory + "/courbd.ttf" ];
							
						}
						
					} else {
						
						if (format.italic) {
							
							fontList = [ systemFontDirectory + "/couri.ttf" ];
							
						} else {
							
							fontList = [ systemFontDirectory + "/cour.ttf" ];
							
						}
						
					}
					#elseif (mac || ios || tvos)
					fontList = [ systemFontDirectory + "/Courier New.ttf", systemFontDirectory + "/Courier.ttf", systemFontDirectory + "/Cache/Courier New.ttf", systemFontDirectory + "/Cache/Courier.ttf", systemFontDirectory + "/Core/Courier New.ttf", systemFontDirectory + "/Core/Courier.ttf", systemFontDirectory + "/CoreAddition/Courier New.ttf", systemFontDirectory + "/CoreAddition/Courier.ttf" ];
					#elseif linux
					fontList = [ new sys.io.Process('fc-match', ['mono', '-f%{file}']).stdout.readLine() ];
					#elseif android
					fontList = [ systemFontDirectory + "/DroidSansMono.ttf" ];
					#elseif blackberry
					fontList = [ systemFontDirectory + "/cour.ttf" ];
					#end
				
				default:
					
					fontList = [ systemFontDirectory + "/" + format.font ];
				
			}
			
			#if lime_console
				
				// TODO(james4k): until we figure out our story for the above switch
				// statement, always load arial unless a file is specified.
				if (format == null
					|| StringTools.startsWith (format.font,  "_")
					|| format.font.indexOf(".") == -1
				) {
					fontList = [ "arial.ttf" ];
				}
				
			#end
			
			if (fontList != null) {
				
				for (font in fontList) {
					
					instance = findFont (font);
					
					if (instance != null) {
						
						__defaultFonts.set (format.font, instance);
						return instance;
						
					}
					
				}
				
			}
			
			instance = findFont ("_serif");
			if (instance != null) return instance;
			
		}
		
		var systemFontDirectory = System.fontsDirectory;
		
		#if windows
		if (format.bold) {
			
			if (format.italic) {
				
				fontList = [ systemFontDirectory + "/timesbi.ttf" ];
				
			} else {
				
				fontList = [ systemFontDirectory + "/timesbd.ttf" ];
				
			}
			
		} else {
			
			if (format.italic) {
				
				fontList = [ systemFontDirectory + "/timesi.ttf" ];
				
			} else {
				
				fontList = [ systemFontDirectory + "/times.ttf" ];
				
			}
			
		}
		#elseif (mac || ios || tvos)
		fontList = [ systemFontDirectory + "/Georgia.ttf", systemFontDirectory + "/Times.ttf", systemFontDirectory + "/Times New Roman.ttf", systemFontDirectory + "/Cache/Georgia.ttf", systemFontDirectory + "/Cache/Times.ttf", systemFontDirectory + "/Cache/Times New Roman.ttf", systemFontDirectory + "/Core/Georgia.ttf", systemFontDirectory + "/Core/Times.ttf", systemFontDirectory + "/Core/Times New Roman.ttf", systemFontDirectory + "/CoreAddition/Georgia.ttf", systemFontDirectory + "/CoreAddition/Times.ttf", systemFontDirectory + "/CoreAddition/Times New Roman.ttf" ];
		#elseif linux
		fontList = [ new sys.io.Process('fc-match', ['serif', '-f%{file}']).stdout.readLine() ];
		#elseif android
		fontList = [ systemFontDirectory + "/DroidSerif-Regular.ttf", systemFontDirectory + "/NotoSerif-Regular.ttf" ];
		#elseif blackberry
		fontList = [ systemFontDirectory + "/georgia.ttf" ];
		#else
		fontList = [];
		#end
		
		for (font in fontList) {
			
			instance = findFont (font);
			
			if (instance != null) {
				
				__defaultFonts.set (format.font, instance);
				return instance;
				
			}
			
		}
		
		__defaultFonts.set (format.font, null);
		
		#end
		
		return null;
		
	}
	
	
	public function getLine (index:Int):String {
		
		if (index < 0 || index > lineBreaks.length + 1) {
			
			return null;
			
		}
		
		if (lineBreaks.length == 0) {
			
			return text;
			
		} else {
			
			return text.substring (index > 0 ? lineBreaks[index - 1] : 0, lineBreaks[index]);
			
		}
		
	}
	
	
	public function getLineBreakIndex (startIndex:Int = 0):Int {
		
		var cr = text.indexOf ("\n", startIndex);
		var lf = text.indexOf ("\r", startIndex);
		
		if (cr == -1) return lf;
		if (lf == -1) return cr;
		
		return cr < lf ? cr : lf;
		
	}
	
	
	private function getLineMeasurements ():Void {
		
		lineAscents.splice (0, lineAscents.length);
		lineDescents.splice (0, lineDescents.length);
		lineLeadings.splice (0, lineLeadings.length);
		lineHeights.splice (0, lineHeights.length);
		lineWidths.splice (0, lineWidths.length);
		
		var currentLineAscent = 0.0;
		var currentLineDescent = 0.0;
		var currentLineLeading:Null<Int> = null;
		var currentLineHeight = 0.0;
		var currentLineWidth = 0.0;
		
		textWidth = 0;
		textHeight = 0;
		numLines = 1;
		bottomScrollV = 0;
		maxScrollH = 0;
		
		for (group in layoutGroups) {
			
			while (group.lineIndex > numLines - 1) {
				
				lineAscents.push (currentLineAscent);
				lineDescents.push (currentLineDescent);
				lineLeadings.push (currentLineLeading != null ? currentLineLeading : 0);
				lineHeights.push (currentLineHeight);
				lineWidths.push (currentLineWidth);
				
				currentLineAscent = 0;
				currentLineDescent = 0;
				currentLineLeading = null;
				currentLineHeight = 0;
				currentLineWidth = 0;
				
				numLines++;
				
				if (textHeight <= height - VERTICAL_MARGIN) {
					
					bottomScrollV++;
					
				}
				
			}
			
			currentLineAscent = Math.max (currentLineAscent, group.ascent);
			currentLineDescent = Math.max (currentLineDescent, group.descent);
			
			if (currentLineLeading == null) {
				
				currentLineLeading = group.leading;
				
			} else {
				
				currentLineLeading = Std.int (Math.max (currentLineLeading, group.leading));
				
			}
			
			currentLineHeight = Math.max (currentLineHeight, group.height);
			currentLineWidth = group.offsetX - HORIZONTAL_MARGIN + group.width;
			
			if (currentLineWidth > textWidth) {

				textWidth = currentLineWidth;
				
			}
			
			textHeight = group.offsetY - VERTICAL_MARGIN + group.ascent + group.descent;
			
		}
		
		lineAscents.push (currentLineAscent);
		lineDescents.push (currentLineDescent);
		lineLeadings.push (currentLineLeading != null ? currentLineLeading : 0);
		lineHeights.push (currentLineHeight);
		lineWidths.push (currentLineWidth);
		
		if (numLines == 1) {
			
			bottomScrollV = 1;
			
			if (currentLineLeading > 0) {
				
				textHeight += currentLineLeading;
				
			}
			
		} else if (textHeight <= height - VERTICAL_MARGIN) {
			
			bottomScrollV++;
			
		}
		
		if (textWidth > width - 2 * HORIZONTAL_MARGIN) {
			
			maxScrollH = Std.int (textWidth - width + 2 * HORIZONTAL_MARGIN);
			
		} else {
			
			maxScrollH = 0;
			
		}
		
		maxScrollV = numLines - bottomScrollV + 1;

	}

    // Recalculates the layout groups    
    private function getLayoutGroups()
    {
        // Clear existing layout groups
        layoutGroups.splice(0, layoutGroups.length);

        if (text.length == 0) {
            return;
        }
        
        var font = null;
		var formatRange : TextFormatRange = null;
        var textLayout : TextLayout = new TextLayout();
		var rangeIndex = -1;
        var spaceWidth = 0.0;
        var ascent = 0.0, descent = 0.0, leading = 0, lineHeight = 0.0;
		var currentTextFormat = TextField.__defaultTextFormat.clone();
        var index : Int = 0;
        var x = HORIZONTAL_MARGIN;
        var y = VERTICAL_MARGIN;
        var max_x = this.width - HORIZONTAL_MARGIN;
        var lineIndex = 0;

        // Helper function ...
		inline function getAdvances(text : String, startIndex : Int,
                                    endIndex : Int) : Array<Float>
        {
			// TODO: optimize
			
			var advances = [ ];
			
			#if (js && html5)

            while (startIndex < endIndex) {
				advances.push
                    (__context.measureText(text.charAt(startIndex++)).width);
			}
			
			#else
			
			var width = 0.0;

            textLayout.text = null;
            textLayout.font = font;
            if (formatRange.format.size != null) {
                textLayout.size = formatRange.format.size;
            }
            textLayout.text = text.substring(startIndex, endIndex);

            var i = 0;
            while (i < textLayout.positions.length) {
				advances.push(textLayout.positions[i++].advance.x);
			}
			
			#end
			
			return advances;
        }

        // Helper function ...
		inline function getAdvancesWidth(advances : Array<Float>) : Float
        {
			var width = 0.0;
            var i = 0;
            while (i < advances.length) {
				width += advances[i++];
			}
			
			return width;
		}
        
		inline function nextFormatRange()
        {
			if (rangeIndex < (this.textFormatRanges.length - 1)) {
				rangeIndex += 1;
				formatRange = this.textFormatRanges[rangeIndex];
				currentTextFormat.__merge(formatRange.format);
				
				#if (js && html5)
                __context.font = getFont(currentTextFormat);
				
				ascent = currentTextFormat.size;
				descent = currentTextFormat.size * 0.185;
				leading = currentTextFormat.leading;
				
				#elseif (cpp || neko || nodejs)
				
				font = getFontInstance(currentTextFormat);
				
				if (font == null) {
					ascent = currentTextFormat.size;
					descent = currentTextFormat.size * 0.185;
					leading = currentTextFormat.leading;
                }
                else {
					ascent = ((font.ascender / font.unitsPerEM) *
                              currentTextFormat.size);
					descent = Math.abs((font.descender / font.unitsPerEM) *
                                       currentTextFormat.size);
					leading = currentTextFormat.leading;
				}
				#end

                spaceWidth = getAdvances(" ", 0, 1)[0];
			}
		}

        // Get the first format range
        nextFormatRange();

        // Current line height is that of the current text format
        lineHeight = ascent + descent + leading;

        // Handle each line in sequence
        while (index < text.length) {
            // breakIndex is the index of the next break (or the end of text
            // if there is no next break)
            var breakIndex = getLineBreakIndex(index);
            if (breakIndex == -1) {
                breakIndex = text.length;
            }

            // Handle format ranges up to breakIndex
            while (index < breakIndex) {
                // rangeEndIndex is the end of the current format range (or
                // breakIndex if the current format range goes beyond
                // breakIndex)
                var rangeEndIndex = formatRange.end;
                if (rangeEndIndex > breakIndex) {
                    rangeEndIndex = breakIndex;
                }
                // rangeEndIndex may be manipulated within the body of this
                // loop but its original value may be needed, so save it
                var rangeMax = rangeEndIndex;

                // Get the positions that will be used for this range
                var advances = getAdvances(text, index, rangeEndIndex);
                
                // Compute length of the range
                var len = getAdvancesWidth(advances);

                // If word wrapping is allowed, then while the current range
                // does not fit, back rangeEndIndex up to the end of the
                // previous word where all characters fit.
                var wrap = false;
                var indexOfAnySpace = -1;
                if (this.wordWrap && ((x + len) > max_x)) {
                    // Trim whitespace to see if the range fits now
                    if ((rangeEndIndex > index) &&
                        StringTools.isSpace(text, rangeEndIndex - 1)) {
                        do {
                            rangeEndIndex -= 1;
                            len -= advances[rangeEndIndex - index];
                            indexOfAnySpace = rangeEndIndex;
                        }
                        while ((rangeEndIndex > index) &&
                               StringTools.isSpace(text, rangeEndIndex - 1));
                    }
                    // While it doesn't fit ...
                    while (((x + len) > max_x) && (rangeEndIndex > index)) {
                        // Skip back to just before the current word
                        do {
                            rangeEndIndex -= 1;
                            len -= advances[rangeEndIndex - index];
                        } while ((rangeEndIndex > index) &&
                                 !StringTools.isSpace(text, rangeEndIndex - 1));
                        // Skip back to the end of the previous word
                        while ((rangeEndIndex > index) &&
                               StringTools.isSpace(text, rangeEndIndex - 1)) {
                            rangeEndIndex -= 1;
                            len -= advances[rangeEndIndex - index];
                            indexOfAnySpace = rangeEndIndex;
                        }
                        // Recompute length of shorter range
                        wrap = true;
                    }

                    // If not even a single non-whitespace character could be
                    // fit ...
                    if (rangeEndIndex == index) {
                        if (indexOfAnySpace != -1)
                        {
                            // If we're at the beginning of a line, then force the
                            // first non-whitespace character before the break
                            // onto the line
                            if (x == HORIZONTAL_MARGIN) {
                                while ((index < (rangeMax - 1)) &&
                                       StringTools.isSpace(text, index)) {
                                    index += 1;
                                    advances.shift();
                                }
                                // If absolutely nothing could be included, then
                                // just go to the next break
                                if (StringTools.isSpace(text, index)) {
                                    index = breakIndex;
                                    break;
                                }
                                rangeEndIndex = index + 1;
                                len = advances[index];
                            }
                            // Else, just go to the beginning of the next line
                            // and try again
                            else {
                                break;
                            }
                        }
                        else
                        {
                            // It means that we have full word and it can't be fit fully.
                            // Then let's go fit while we can
                            while (rangeEndIndex < rangeMax)
                            {
                                len += advances[rangeEndIndex - index];

                                if (x + len > max_x)
                                {
                                    len -= advances[rangeEndIndex - index];
                                    break;
                                }
                                ++rangeEndIndex;
                            }

                            // if the width of one symbol is more than maxWidth,
                            // then add only one symbol and break it again
                            if (rangeEndIndex == index)
                            {
                                rangeEndIndex = index + 1;
                            }
                        }
                    }
                }

                // Add a layout group for this range
                var layoutGroup = new TextLayoutGroup
                    (formatRange.format, index, rangeEndIndex);
                if (advances.length != (rangeEndIndex - index)) {
                    advances = advances.slice(0, rangeEndIndex - index);
                }
                layoutGroup.advances = advances;
                layoutGroup.offsetX = x;
                layoutGroup.ascent = ascent;
                layoutGroup.descent = descent;
                layoutGroup.leading = leading;
                layoutGroup.lineIndex = lineIndex;
                layoutGroup.offsetY = y;
                layoutGroup.width = len;
                layoutGroup.height = lineHeight;
                layoutGroups.push(layoutGroup);

                if (wrap) {
                    x = HORIZONTAL_MARGIN;
                    y += lineHeight;
                    lineIndex += 1;
                    // Line height is now the height of the current text format
                    lineHeight = ascent + descent + leading;
                    // Skip the whitespace at the beginning of the next line
                    while ((rangeEndIndex < rangeMax) &&
                           StringTools.isSpace(text, rangeEndIndex)) {
                        rangeEndIndex += 1;
                    }
                }
                else {
                    x += len;
                }

                // If the range has been completely used up, go to the
                // next range
                if (rangeEndIndex == formatRange.end) {
                    nextFormatRange();
                    // If the current text format has an even bigger height,
                    // then the whole line is now this height
                    var nextHeight = ascent + descent + leading;
                    if (nextHeight > lineHeight) {
                        lineHeight = nextHeight;
                    }
                }

                index = rangeEndIndex;
            }

            // Go to the next line
            x = HORIZONTAL_MARGIN;
            y += lineHeight;
            lineIndex += 1;
            
            // Line height is now the height of the current text format
            lineHeight = ascent + descent + leading;

            // If we're at a break, skip it
            if (index == breakIndex) {
                index += 1;
            }
        }
    }
	
	private function setTextAlignment ():Void {
		
		var lineIndex = -1;
		var offsetX = 0.0;
		var group, lineLength;
		
		for (i in 0...layoutGroups.length) {
			
			group = layoutGroups[i];
			
			if (group.lineIndex != lineIndex) {
				
				lineIndex = group.lineIndex;
				
				switch (group.format.align) {
					
					case CENTER:
						
						if (lineWidths[lineIndex] < (width - 2 * HORIZONTAL_MARGIN)) {
							
							offsetX = Math.round ((width - 2 * HORIZONTAL_MARGIN - lineWidths[lineIndex]) / 2);
							
						} else {
							
							offsetX = 0;
							
						}
					
					case RIGHT:
						
						if (lineWidths[lineIndex] < width - 2 * HORIZONTAL_MARGIN) {
							
							offsetX = Math.round (width - 2 * HORIZONTAL_MARGIN - lineWidths[lineIndex]);
							
						} else {
							
							offsetX = 0;
							
						}
					
					case JUSTIFY:
						
						if (lineWidths[lineIndex] < width - 2 * HORIZONTAL_MARGIN) {
							
							lineLength = 1;
							
							for (j in (i + 1)...layoutGroups.length) {
								
								if (layoutGroups[j].lineIndex == lineIndex) {
									
									lineLength++;
									
								} else {
									
									break;
									
								}
								
							}
							
							if (lineLength > 1) {
								
								group = layoutGroups[i + lineLength - 1];
								
								var endChar = text.charAt (group.endIndex);
								if (group.endIndex < text.length && endChar != "\n" && endChar != "\r") {
									
									offsetX = (width - 2 * HORIZONTAL_MARGIN - lineWidths[lineIndex]) / (lineLength - 1);
									
									for (j in 1...lineLength) {
										
										layoutGroups[i + j].offsetX += (offsetX * j);
										
									}
									
								}
								
							}
							
						}
						
						offsetX = 0;
					
					default:
						
						offsetX = 0;
					
				}
				
			}
			
			if (offsetX > 0) {
				
				group.offsetX += offsetX;
				
			}
			
		}
		
	}
	
	
	private function update ():Void {
		
		if (text == null || text == "" || textFormatRanges.length == 0) {
			
			lineAscents.splice (0, lineAscents.length);
			lineBreaks.splice (0, lineBreaks.length);
			lineDescents.splice (0, lineDescents.length);
			lineLeadings.splice (0, lineLeadings.length);
			lineHeights.splice (0, lineHeights.length);
			lineWidths.splice (0, lineWidths.length);
			layoutGroups.splice (0, layoutGroups.length);
			
			textWidth = 0;
			textHeight = 0;
			numLines = 1;
			maxScrollH = 0;
			maxScrollV = 1;
			bottomScrollV = 1;
			
		} else {
			
			getLayoutGroups ();
			getLineMeasurements ();
			setTextAlignment ();
			
		}
		
		getBounds ();
		
	}
	
	
}
