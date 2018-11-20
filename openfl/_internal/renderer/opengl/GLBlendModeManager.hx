package openfl._internal.renderer.opengl;


import lime.graphics.GLRenderContext;
import openfl._internal.renderer.AbstractBlendModeManager;
import openfl.display.BlendMode;

#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end


class GLBlendModeManager extends AbstractBlendModeManager {
	
	
	private var currentBlendMode:BlendMode;
	private var gl:GLRenderContext;
	
	
	public function new (gl:GLRenderContext) {
		
		super ();
		
		this.gl = gl;
		
		setBlendMode (NORMAL);
		gl.enable (gl.BLEND);
		
	}
	
	
	public override function setBlendMode (blendMode:BlendMode):Void {
		
		if (currentBlendMode == blendMode) return;
		
		currentBlendMode = blendMode;
		
		switch (blendMode) {
			
			case ADD:
				
				gl.enable (gl.BLEND);
				gl.blendEquation (gl.FUNC_ADD);
				gl.blendFunc (gl.ONE, gl.ONE);
			
			// TIVO: Custom behavior for BlendMode.ERASE to support clobbering
			// destination alpha, for example, for a video window
			case ERASE:
				
				gl.disable (gl.BLEND);
			
			case MULTIPLY:
				
				gl.enable (gl.BLEND);
				gl.blendEquation (gl.FUNC_ADD);
				gl.blendFunc (gl.DST_COLOR, gl.ONE_MINUS_SRC_ALPHA);
			
			case SCREEN:
				
				gl.enable (gl.BLEND);
				gl.blendEquation (gl.FUNC_ADD);
				gl.blendFunc (gl.ONE, gl.ONE_MINUS_SRC_COLOR);
			
			case SUBTRACT:
				
				gl.enable (gl.BLEND);
				gl.blendEquation (gl.FUNC_REVERSE_SUBTRACT);
				gl.blendFunc (gl.ONE, gl.ONE);
			
			#if desktop
			case DARKEN:
				
				gl.enable (gl.BLEND);
				gl.blendEquation (0x8007); // GL_MIN
				gl.blendFunc (gl.ONE, gl.ONE);
				
			case LIGHTEN:
				
				gl.enable (gl.BLEND);
				gl.blendEquation (0x8008); // GL_MAX
				gl.blendFunc (gl.ONE, gl.ONE);
			#end
			
			default:
				
				gl.enable (gl.BLEND);
				gl.blendEquation (gl.FUNC_ADD);
				gl.blendFunc (gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
			
		}
		
	}
	
	
}