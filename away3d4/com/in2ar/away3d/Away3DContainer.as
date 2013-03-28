package com.in2ar.away3d
{
import away3d.containers.ObjectContainer3D;

import flash.geom.Matrix3D;

public class Away3DContainer extends ObjectContainer3D
{
    protected var maxDropFrames:int = 2;
    protected var droppedFrames:int = 0;

    protected var transformRAW:Vector.<Number>;
    protected var arTransform:Matrix3D;
    protected var arNextTransform:Matrix3D;
    protected var detected:Boolean;

    public function Away3DContainer(maxDropFrames:int = 2)
    {
        super();

        this.maxDropFrames = maxDropFrames;
        droppedFrames = 0;

        transformRAW = new Vector.<Number>(16, true);
        arTransform = new Matrix3D();
        arNextTransform = new Matrix3D();

        // hide at start
        detected = false;
        visible = false;
    }

    public function lost():void
    {
        if(detected) {
            droppedFrames++;
            if (droppedFrames >= maxDropFrames) {
                detected = false;
                visible = false;
            }
        }
    }

    public function in2arTransform(rotationMatrix:Vector.<Number>, translationVector:Vector.<Number>, smooth:Number = 1.0, mirror:Boolean = false):void
    {
        get3DMatrixLH(transformRAW, rotationMatrix, translationVector, mirror);

        if (smooth != 1.0) {
            arTransform.copyRawDataFrom(transformRAW);
            arNextTransform.position = arNextTransform.position;
            arNextTransform.interpolateTo(arTransform, smooth);
            transform = arNextTransform;
        } else {
            arTransform.copyRawDataFrom(transformRAW);
            transform = arTransform;
        }

        droppedFrames = 0;

        if (!detected) {
            detected = true;
            visible = true;
        }
    }

    protected function get3DMatrixLH(data:Vector.<Number>, R:Vector.<Number>, t:Vector.<Number>, mirror:Boolean = false):void
    {
        if (!mirror)
        {
            data[0] = R[0]; data[1] = -R[3]; data[2] = R[6]; data[3] = 0.0;
            data[4] = R[1]; data[5] = -R[4]; data[6] = R[7]; data[7] = 0.0;
            data[8] = -R[2]; data[9] = R[5]; data[10] = -R[8]; data[11] = 0.0;
            data[12] = t[0]; data[13] = -t[1]; data[14] = t[2]; data[15] = 1.0;
        } else {
            data[0] = -R[0]; data[1] = -R[3]; data[2] = R[6]; data[3] = 0.0;
            data[4] = R[1]; data[5] = R[4]; data[6] = -R[7]; data[7] = 0.0;
            data[8] = R[2]; data[9] = R[5]; data[10] = -R[8]; data[11] = 0.0;
            data[12] = -t[0]; data[13] = -t[1]; data[14] = t[2]; data[15] = 1.0;
        }
    }
}
}
