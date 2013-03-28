package
{
import away3d.containers.View3D;
import away3d.core.managers.Stage3DManager;
import away3d.core.managers.Stage3DProxy;

import com.in2ar.away3d.Away3DCameraLens;
import com.in2ar.away3d.Away3DCaptureTexture;

import com.in2ar.worker.IN2ARWorkerMessage;

import flash.concurrent.Mutex;

import flash.display.BitmapData;

import flash.display.Sprite;
import flash.display.Stage;
import flash.events.Event;
import flash.geom.Matrix;
import flash.geom.Rectangle;
import flash.geom.Vector3D;
import flash.media.Video;
import flash.system.MessageChannel;
import flash.system.Worker;
import flash.system.WorkerDomain;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.utils.ByteArray;

import net.hires.debug.Stats;

[SWF(width='640', height='480', frameRate='60',backgroundColor='0xFFFFFF')]
public final class Away3DWorkerDemo extends Sprite
{

    // worker stuff
    public var mainToBack:MessageChannel;
    public var backToMain:MessageChannel;
    public var worker:Worker;
    public var in2arWorker:IN2ARWorker;
    public var mutex:Mutex;

    // asfeat variables
    public var intrinsicFx:Number = 500;
    public var intrinsicFy:Number = 500;
    public var maxPoints:int = 300; // max points to allow to detect
    public var maxReferences:int = 1; // max objects will be used
    public var maxTrackIterations:int = 5; // track iterations

    private var camController:CaptureController;
    private var video:Video;
    private var workBuffer:BitmapData;
    private var workBytes:ByteArray;
    private var imageOffset:int;
    private var workRect:Rectangle;
    private var cameraMatrix:Matrix;
    public static var text:TextField;

    // 3d stuff
    private var away3dView:View3D;
    private var away3dLens:Away3DCameraLens;
    private var away3dCapture:Away3DCaptureTexture;
    private var in2arModel:IN2ARLogoModel;

    // camera and viewport options
    public var streamW:int = 640;
    public var streamH:int = 480;
    public var streamFPS:int = 30;
    public var downScaleRatio:Number = 1;
    public var workW:int = streamW * downScaleRatio;
    public var workH:int = streamH * downScaleRatio;
    public var viewWidth:int = 640;
    public var viewHeight:int = 480;
    public var mirror:Boolean = true; // mirror camera output

    public var stat:Stats;

    public function Away3DWorkerDemo()
    {
        stage.scaleMode = "noScale";

        if(Worker.current.isPrimordial)
        {
            initText();

            // create worker
            worker = WorkerDomain.current.createWorker( loaderInfo.bytes );

            mainToBack = Worker.current.createMessageChannel(worker);
            backToMain = worker.createMessageChannel(Worker.current);

            backToMain.addEventListener(Event.CHANNEL_MESSAGE, onBackToMain);

            worker.setSharedProperty("backToMain", backToMain);
            worker.setSharedProperty("mainToBack", mainToBack);

            mutex = new Mutex();
            worker.setSharedProperty("mutex", mutex);

            workBytes = new ByteArray();
            workBytes.length = workW * workH * 4 + (1024 << 3);
            workBytes.shareable = true;

            imageOffset = workW * workH * 4;

            worker.setSharedProperty("workBytes", workBytes);

            worker.start();
            //
            text.text = "worker supported:" + Worker.isSupported;
        }
        else
        {
            in2arWorker = new IN2ARWorker();
        }
    }

    private function initAway3D():void
    {
        // request intrinsic parameters
        mainToBack.send(IN2ARWorkerMessage.IN2AR_GET_INTRINSIC);
        //

        away3dView = new View3D();
        away3dView.width = viewWidth;
        away3dView.height = viewHeight;

        away3dLens = new Away3DCameraLens();
        away3dLens.updateProjection(intrinsicFx, intrinsicFy, viewWidth, viewHeight, workW, workH);

        away3dView.camera.lens = away3dLens;
        away3dView.camera.position = new Vector3D(0,0,0);

        // init webcam texture
        away3dCapture = new Away3DCaptureTexture(camController.bitmapData);
        away3dCapture.mirror = mirror;
        away3dView.background = away3dCapture;

        // init model
        in2arModel = new IN2ARLogoModel();
        away3dView.scene.addChild(in2arModel);

        addChild(away3dView);
    }

    private function initText():void
    {
        // DEBUG TEXT FIELD
        text = new TextField();
        text.defaultTextFormat = new TextFormat("Verdana", 11, 0xFFFFFF);
        text.background = true;
        text.backgroundColor = 0x000000;
        text.textColor = 0xFFFFFF;
        text.width = 640;
        text.height = 18;
        text.selectable = false;
        text.mouseEnabled = false;
        text.y = stage.stageHeight - text.height;
        addChild(text);

        stat = new Stats();
        addChild(stat);
    }

    private function initListeners():void
    {
        camController.addEventListener(Event.VIDEO_FRAME, newWebCamFrame);
        addEventListener(Event.ENTER_FRAME, onEnterFrame);
    }

    private function cleanListeners():void
    {
        camController.removeEventListener(Event.VIDEO_FRAME, newWebCamFrame);
        removeEventListener(Event.ENTER_FRAME, onEnterFrame);
    }

    private function onEnterFrame(e:Event = null):void
    {
        away3dView.render();
    }

    private function onBackToMain(e:Event):void
    {
        var mess_id:int = backToMain.receive();

        text.text = "message from in2ar: " + mess_id;

        switch (mess_id)
        {
            case IN2ARWorkerMessage.IN2AR_INIT:
                initCamera();
                initAway3D();
                initListeners();
                break;
            case IN2ARWorkerMessage.IN2AR_GET_INTRINSIC:
                intrinsicFx = backToMain.receive();
                intrinsicFy = backToMain.receive();
                if(away3dLens)
                {
                    away3dLens.updateProjection(intrinsicFx, intrinsicFy, viewWidth, viewHeight, workW, workH);
                }
                break;
            case IN2ARWorkerMessage.IN2AR_DETECTION_DETECTED:
                onModelDetected();
                break;
            case IN2ARWorkerMessage.IN2AR_DETECTION_FAILED:
                onDetectionFailed();
                break;
        }
    }

    private function onModelDetected():void
    {
        mutex.lock();
        var info:ByteArray = workBytes;
        info.position = imageOffset;

        var rotationMatrix:Vector.<Number> = new Vector.<Number>(9);
        var translationVector:Vector.<Number> = new Vector.<Number>(3);
        var n:int = info.readInt();
        var state:String;
        var ref_id:int;
        var j:int;

        for(var i:int = 0; i < n; ++i)
        {
            ref_id = info.readInt();
            state = info.readInt() == 0 ? "detected" : "tracked";

            for(j=0;j<9;++j)
            {
                rotationMatrix[j] = info.readDouble();
            }
            translationVector[0] = info.readDouble();
            translationVector[1] = info.readDouble();
            translationVector[2] = info.readDouble();

            in2arModel.in2arTransform(rotationMatrix, translationVector, 0.85, mirror);

            text.text = state;
            text.appendText( ' @ ' + ref_id );
        }
        mutex.unlock();
    }

    private function onDetectionFailed():void
    {
        text.text = "nothing found";
        if(in2arModel) in2arModel.lost();
    }

    private function newWebCamFrame(e:Event):void
    {
        var frameBitmap:BitmapData = camController.bitmapData;
        mutex.lock();
        workBytes.position = 0;
        if(downScaleRatio != 1){
            workBuffer.draw(frameBitmap, cameraMatrix);
            workBuffer.copyPixelsToByteArray(workRect, workBytes);
        } else {
            frameBitmap.copyPixelsToByteArray(workRect, workBytes);
        }

        mutex.unlock();

        // send to worker;
        mainToBack.send(IN2ARWorkerMessage.IN2AR_ADD_FRAME);

        away3dCapture.invalidate();
    }

    protected function initCamera():void
    {
        var camera:flash.media.Camera = flash.media.Camera.getCamera();
        camera.setMode(streamW, streamH, streamFPS, false);

        video = new Video(camera.width, camera.height);
        video.attachCamera(camera);

        camController = new CaptureController(camera, CaptureController.UPDATE_BITMAPDATA);

        workBuffer = new BitmapData(workW, workH, true, 0x0);
        cameraMatrix = new Matrix(downScaleRatio, 0, 0, downScaleRatio);
        workRect = new Rectangle(0,0,workW,workH);
    }
}
}
