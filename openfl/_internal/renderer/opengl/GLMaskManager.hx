package openfl._internal.renderer.opengl;


import lime.graphics.GLRenderContext;
import lime.utils.Float32Array;
import openfl._internal.renderer.AbstractMaskManager;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.display.Shader;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.display.Stage;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;

@:access(openfl._internal.renderer.opengl.GLRenderer)
@:access(openfl.display.DisplayObject)
@:access(openfl.display.Graphics)
@:access(openfl.display.Stage)
@:access(openfl.geom.Matrix)
@:access(openfl.geom.Rectangle)
@:keep


class GLMaskManager extends AbstractMaskManager {
    
    
    private var gl:GLRenderContext;
    private var clipRects:Array<Rectangle>;
    private var numClipRects:Int;
    private var mask : DisplayObject;
    private var masked : DisplayObject;
    private var alphaMask : Bool;
    private var nonMaskedVisible : Bool;
    
    
    public function new (renderSession:RenderSession) {
        
        super (renderSession);

        this.gl = renderSession.gl;
        
        clipRects = new Array ();
        
    }

    public override function pushObject (object:DisplayObject, handleScrollRect:Bool = true):Void {
        
        if (handleScrollRect && object.__scrollRect != null) {

            pushRect (object.__scrollRect, object.__renderTransform);
            
        }

        if (object.__mask != null) {
            // This implementation only supports a single mask application; it
            // does not support nested masks
            if (this.mask == null) {
                this.mask = object.__mask;
                this.masked = object;
                this.alphaMask = (this.mask.__cacheAsBitmap &&
                                  this.masked.__cacheAsBitmap);
                this.nonMaskedVisible = object.__nonMaskedVisible;
            }
            else {
                // throw "Nested masks not supported";
            }
        }

        this.setupMasking(object);
    }
    
    
    public override function pushRect (rect:Rectangle, transform:Matrix):Void {
        
        // TODO: Handle rotation?

        if (numClipRects == clipRects.length) {
            
            clipRects[numClipRects] = new Rectangle ();
            
        }
        
        var clipRect = clipRects[numClipRects];
        rect.__transform (clipRect, transform);

        if (numClipRects > 0) {
            
            var parentClipRect = clipRects[numClipRects - 1];

            clipRect.__contract (parentClipRect.x, parentClipRect.y, parentClipRect.width, parentClipRect.height);
            
        }
        
        if (clipRect.height < 0) {
            
            clipRect.height = 0;
            
        }
        
        if (clipRect.width < 0) {
            
            clipRect.width = 0;
            
        }
        
        scissorRect (clipRect);
        numClipRects++;
        
    }
    

    public override function popObject (object:DisplayObject, handleScrollRect:Bool = true):Void {
        
        if (handleScrollRect && object.__scrollRect != null) {
            
            popRect ();
            
        }

        if (this.masked == object) {
            this.masked = null;
            this.mask = null;
        }
    }
    
    
    public override function popRect ():Void {
        
        if (numClipRects > 0) {

            numClipRects--;
            
            if (numClipRects > 0) {
                
                scissorRect (clipRects[numClipRects - 1]);
                
            } else {
                
                scissorRect ();
                
            }
            
        }
        
    }
    
    
    private function scissorRect (rect:Rectangle = null):Void {
        
        if (rect != null) {

            var renderer:GLRenderer = cast renderSession.renderer;

            gl.enable (gl.SCISSOR_TEST);

            var x = Math.floor (rect.x);
            var y = Math.floor (renderer.windowHeight - rect.y - rect.height);
            var width = Math.ceil (rect.width);
            var height = Math.ceil (rect.height);
            
            if (width < 0) width = 0;
            if (height < 0) height = 0;

            // Bug 488619 - Ghosting on navigation through menu
            //
            // Workaround glScissor issue on Amino devices not handling 0 for
            // width and/or height parameters. (The opengl spec says 0 width
            // or height should cause no rendering of pixels.)
            //
            // Translate 0 width or height to x,y,width,height of 0,0,1,1.
            // This effectively causes no pixels to be drawn, although it
            // technically is a 1-by-1 pixel window at the origin.
            if (width <= 0 || height <= 0) {
                x = 0;
                y = 0;
                width = 1;
                height = 1;
            }

            gl.scissor (x, y, width, height);

        } else {
            
            gl.disable (gl.SCISSOR_TEST);
            
        }
        
    }
    
    // Helper function for applying masking
    private function setupMasking(object : DisplayObject)
    {
        var maskBitmapData : BitmapData = null;
        var mask : DisplayObject = this.mask;

        // TiVo HACK -- use the single-child bitmap if there is one
        if (Std.is(mask, Sprite)) {
            var sprite = cast(mask, Sprite);
            if (sprite.numChildren == 1) {
                var child = sprite.getChildAt(0);
                if (Std.is(child, Bitmap)) {
                    mask = cast(child, Bitmap);
                }
            }
        }

        if (mask != null) {
            if (Std.is(mask, Bitmap)) {
                maskBitmapData = (cast(mask, Bitmap)).bitmapData;
            }
            // Else, need to render the display object into a bitmap and use
            // that.  XXX todo.
        }

        var gl = renderSession.gl;
        var shader = renderSession.shaderManager.defaultShader;

        // If no mask, then set masking type in fragment shader to "no mask"
        if (maskBitmapData == null) {
            gl.uniform1i(shader.data.uMaskType.index, 0);
            return;
        }

        // Bind mask into fragment shader
        gl.activeTexture(gl.TEXTURE0);
        gl.bindTexture(gl.TEXTURE_2D, maskBitmapData.getTexture(gl));

        // Calculate the mask scale and offset relative to the masked display
        // object -- keep in mind that the offset must be in uv coordinates

        var maskScaleX : Float, maskScaleY : Float;
        var maskOffsetX : Float, maskOffsetY : Float;

        var maskBounds = mask.getBounds(this.mask.parent);
        var maskedBounds = object.getBounds(this.masked.parent);

        maskScaleX = maskedBounds.width / maskBounds.width;
        maskScaleY = maskedBounds.height / maskBounds.height;

        maskOffsetX = (maskedBounds.x - maskBounds.x - 0.5) / maskBounds.width;
        maskOffsetY = (maskedBounds.y - maskBounds.y - 0.5) / maskBounds.height;

        gl.uniform2fv(shader.data.uMaskScale.index,
                      new Float32Array([ maskScaleX, maskScaleY ]));
        gl.uniform2fv(shader.data.uMaskOffset.index,
                      new Float32Array([ maskOffsetX, maskOffsetY ]));

        // If the masked and mask are both 'cache as bitmap', then alpha
        // masking is to be used
        if (alphaMask) {
            gl.uniform1i(shader.data.uMaskType.index, 2);
        }
        // Else, on/off masking is to be used
        else {
            gl.uniform1i(shader.data.uMaskType.index, 1);
        }

        // Finally, set the alpha value that should be used outside of the mask
        var maskOutsideAlpha = this.nonMaskedVisible ? 1.0 : 0.0;
        gl.uniform1f(shader.data.uMaskOutside.index, maskOutsideAlpha);
    }
    
    
}
