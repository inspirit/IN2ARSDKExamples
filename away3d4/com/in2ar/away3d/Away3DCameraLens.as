package com.in2ar.away3d
{
import away3d.cameras.lenses.LensBase;
import away3d.core.math.Matrix3DUtils;

public class Away3DCameraLens extends LensBase
{
    private var _focalLengthInv:Number;
    private var _scaleFactor:Number;

    public function Away3DCameraLens()
    {
        super();
    }

    public function updateProjection(focalX:Number, focalY:Number, viewWidth:int, viewHeight:int, in2arWidth:int, in2arHeight:int):void
    {
        var fx:Number = focalX;
        var fy:Number = focalY;
        var w:Number = viewWidth;
        var h:Number = viewHeight;
        var fov:Number = 2.0 * Math.atan( (h - 1) / (2 * fy) );

        _aspectRatio = w / h;
        _near = fx / 32;
        _far = fx * 32;
        _focalLengthInv = Math.tan(fov * 0.5);
        _scaleFactor = Math.max(Number(viewWidth) / Number(in2arWidth), Number(viewHeight) / Number(in2arHeight));

        invalidateMatrix();
    }

    public function get scaleFactor():Number
    {
        return _scaleFactor;
    }
    public function set scaleFactor(val:Number):void
    {
        _scaleFactor = val;
        invalidateMatrix();
    }

    override protected function updateMatrix() : void
    {
        var raw:Vector.<Number> = Matrix3DUtils.RAW_DATA_CONTAINER;

        var _yMax:Number = _near*_focalLengthInv;
        var _xMax:Number = _yMax*_aspectRatio;

        raw[uint(0)] = _near/_xMax * _scaleFactor;
        raw[uint(5)] = _near/_yMax * _scaleFactor;
        raw[uint(10)] = _far/(_far-_near);
        raw[uint(11)] = 1;
        raw[uint(1)] = raw[uint(2)] = raw[uint(3)] = raw[uint(4)] =
                       raw[uint(6)] = raw[uint(7)] = raw[uint(8)] = raw[uint(9)] =
                       raw[uint(12)] = raw[uint(13)] = raw[uint(15)] = 0;
        raw[uint(14)] = -_near*raw[uint(10)];

        _matrix.copyRawDataFrom(raw);

        var yMaxFar:Number = _far*_focalLengthInv;
        var xMaxFar:Number = yMaxFar*_aspectRatio;

        _frustumCorners[0] = _frustumCorners[9] = -_xMax;
        _frustumCorners[3] = _frustumCorners[6] = _xMax;
        _frustumCorners[1] = _frustumCorners[4] = -_yMax;
        _frustumCorners[7] = _frustumCorners[10] = _yMax;

        _frustumCorners[12] = _frustumCorners[21] = -xMaxFar;
        _frustumCorners[15] = _frustumCorners[18] = xMaxFar;
        _frustumCorners[13] = _frustumCorners[16] = -yMaxFar;
        _frustumCorners[19] = _frustumCorners[22] = yMaxFar;

        _frustumCorners[2] = _frustumCorners[5] = _frustumCorners[8] = _frustumCorners[11] = _near;
        _frustumCorners[14] = _frustumCorners[17] = _frustumCorners[20] = _frustumCorners[23] = _far;
    }
}
}
