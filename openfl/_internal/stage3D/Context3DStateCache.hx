package openfl._internal.stage3D;

import openfl.display3D.Context3DBlendFactor;
import openfl.display3D.Context3DCompareMode;
import openfl.display3D.Program3D;
import openfl.Vector;

class Context3DStateCache {

    private static inline var disableCache:Bool = true;

    // blend
    private var _srcBlendFactor:Context3DBlendFactor;
    private var _destlendFactor:Context3DBlendFactor;

    // depth test
    private var _deptTestEnabled:Bool;
    private var _depthTestMask:Bool;
    private var _depthTestCompareMode:Context3DCompareMode;

    // program
    private var _program:Program3D;

    // culling
    private var _cullingMode:String;

    // texture
    private var _activeTexture:Int;

    // vertex array
    private var _activeVertexArray:Int;

    // viewport
    private var _viewportOriginX:Int;
    private var _viewportOriginY:Int;
    private var _viewportWidth:Int;
    private var _viewportHeight:Int;

    // registers
    private static inline var MAX_NUM_REGISTERS:Int = 1024;
    private static inline var FLOATS_PER_REGISTER:Int = 4;

    private var _registers:Vector<Float> = new Vector<Float>(MAX_NUM_REGISTERS * FLOATS_PER_REGISTER);


    public function new()
    {
        clearSettings();
    }

    public function clearSettings():Void
    {

        _srcBlendFactor = "";
        _destlendFactor = "";
        _deptTestEnabled = false;
        _depthTestMask = false;
        _depthTestCompareMode = "";
        _program = null;
        _cullingMode = "";
        _activeTexture = -1;
        _activeVertexArray = -1;
        _viewportOriginX = -1;
        _viewportOriginY = -1;
        _viewportWidth = -1;
        _viewportHeight = -1;

        clearRegisters();
    }

    private function clearRegisters():Void
    {
        var numFloats:Int = MAX_NUM_REGISTERS * FLOATS_PER_REGISTER;
        for (c in 0...numFloats) {
            _registers [c] = -999999999.0;
        }
    }

    public function updateBlendSrcFactor(factor:Context3DBlendFactor):Bool
    {
        if (!disableCache && factor == _srcBlendFactor)
            return false;
        _srcBlendFactor = factor;
        return true;
    }

    public function updateBlendDestFactor(factor:Context3DBlendFactor):Bool
    {
        if (!disableCache && factor == _destlendFactor)
            return false;
        _destlendFactor = factor;
        return true;
    }

    public function updateDepthTestEnabled(test:Bool):Bool
    {
        if (!disableCache && test == _deptTestEnabled)
            return false;
        _deptTestEnabled = test;
        return true;
    }

    public function updateDepthTestMask(mask:Bool):Bool
    {
        if (!disableCache && mask == _depthTestMask)
            return false;
        _depthTestMask = mask;
        return true;
    }

    public function updateDepthCompareMode(mode:Context3DCompareMode):Bool
    {
        if (!disableCache && mode == _depthTestCompareMode)
            return false;
        _depthTestCompareMode = mode;
        return true;
    }

    public function updateProgram3D(program3d:Program3D):Bool
    {
        if (!disableCache && program3d == _program)
            return false;
        _program = program3d;
        return true;
    }

    public function updateCullingMode(cullMode:String):Bool
    {
        if (!disableCache && cullMode == _cullingMode)
            return false;
        _cullingMode = cullMode;
        return true;
    }

    public function updateActiveTextureSample(texture:Int):Bool
    {
        if (!disableCache && texture == _activeTexture)
            return false;
        _activeTexture = texture;
        return true;
    }

    public function updateActiveVertexArray(vertexArray:Int):Bool
    {
        if (!disableCache && vertexArray == _activeVertexArray)
            return false;
        _activeVertexArray = vertexArray;
        return true;
    }

    public function updateViewport(originX:Int, originY:Int, width:Int, height:Int):Bool
    {
        if (!disableCache && _viewportOriginX == originX && _viewportOriginY == originY && _viewportWidth == width && _viewportHeight == height)
            return false;

        _viewportOriginX = originX;
        _viewportOriginY = originY;
        _viewportWidth = width;
        _viewportHeight = height;

        return true;
    }

    public function updateRegisters(mTemp:Vector<Float>, startRegister:Int, numRegisters:Int):Bool
    {
        return true;

        /*
			Bool needToUpdate		= false;
			Int  startFloat 		= startRegister * FLOATS_PER_REGISTER;
			Int  numFloat   		= numRegisters  * FLOATS_PER_REGISTER;
			Int  inCounter 			= 0;

			while (numFloat != 0)
			{
				if (_registers [startFloat] != mTemp [inCounter]) 
				{
					_registers [startFloat] = mTemp [inCounter];
					needToUpdate = true;
				}
				
				--numFloat;
				++startFloat;
				++inCounter;
			}

			return needToUpdate;*/
    }

}

