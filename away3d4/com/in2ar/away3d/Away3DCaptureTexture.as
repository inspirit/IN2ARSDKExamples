package com.in2ar.away3d
{
import away3d.textures.Texture2DBase;
import away3d.tools.utils.TextureUtils;

import flash.display.BitmapData;
import flash.display3D.textures.Texture;
import flash.display3D.textures.TextureBase;
import flash.geom.Matrix;

public class Away3DCaptureTexture extends Texture2DBase
{
    private var _bitmapData:BitmapData;
    private var _bufferData:BitmapData;

    private var _matrix:Matrix;
    private var _mirror:Boolean;

    private var _maxTextureSize:uint;

    public function Away3DCaptureTexture(src:BitmapData, maxTextureSize:uint = 0)
    {
        super();

        this.captureData = src;

        _mirror = false;
        _maxTextureSize = maxTextureSize > 0 ? TextureUtils.getBestPowerOf2(maxTextureSize) : 0;
    }

    public function get bitmapData() : BitmapData
    {
        return _bitmapData;
    }

    public function set captureData(value : BitmapData) : void
    {
        if (value == _bufferData) return;

        var w2:int = TextureUtils.getBestPowerOf2(value.width);
        var h2:int = TextureUtils.getBestPowerOf2(value.height);

        if(_maxTextureSize > 0) {
            w2 = Math.min(_maxTextureSize, w2);
            h2 = Math.min(_maxTextureSize, h2);
        }

        _bitmapData = new BitmapData(w2, h2, false, 0x0);
        _bufferData = value;

        _matrix = new Matrix(_bitmapData.width/value.width, 0, 0, _bitmapData.height/value.height);

        invalidateContent();
        setSize(w2,  h2);
    }
    public function get mirror():Boolean
    {
        return mirror;
    }
    public function set mirror(value:Boolean):void
    {
        _mirror = value;
        if(!value)
        {
            _matrix.a = _bitmapData.width/_bufferData.width;
            _matrix.tx = 0;
        } else {
            _matrix.a = -_bitmapData.width/_bufferData.width;
            _matrix.tx = _bitmapData.width;
        }
    }

    public function invalidate():void
    {
        _bitmapData.lock();
        _bitmapData.draw(_bufferData, _matrix);
        _bitmapData.unlock();

        invalidateContent();
    }

    // avoid mipmap expensive upload
    override protected function uploadContent(texture : TextureBase) : void
    {
        Texture(texture).uploadFromBitmapData(_bitmapData, 0);
    }
}
}
