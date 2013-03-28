package
{
import com.in2ar.calibration.IntrinsicParameters;
import com.in2ar.detect.IN2ARDetectType;
import com.in2ar.detect.IN2ARReference;
import com.in2ar.event.IN2ARDetectionEvent;
import com.in2ar.worker.IN2ARWorkerMessage;

import flash.concurrent.Condition;

import flash.concurrent.Mutex;

import flash.display.BitmapData;

import flash.events.Event;
import flash.geom.Rectangle;

import flash.system.MessageChannel;
import flash.system.Worker;
import flash.utils.ByteArray;
import flash.utils.Endian;

/**
 * Possible Worker + IN2AR implementation.
 *
 * You can switch base class to compile for FLASH/AIR(ANE)
 * @author Eugene Zatepyakin
 */

[SWF(frameRate='30',backgroundColor='0xFFFFFF')]
public class IN2ARWorker extends IN2ARBase
//public class IN2ARWorker extends IN2ARNativeBase
{

    // tracking data file
    [Embed(source="../assets/def_data.ass", mimeType="application/octet-stream")]
    public static const DefinitionaData:Class;

    // asfeat variables
    public var intrinsic:IntrinsicParameters;
    public var maxPoints:int = 300; // max points to allow to detect
    public var maxReferences:int = 1; // max objects will be used
    public var maxTrackIterations:int = 5; // track iterations

    // camera and viewport options
    public var workW:int = 640;
    public var workH:int = 480;

    public var imageBitmap:BitmapData;
    public var imageRect:Rectangle;

    // worker stuff
    protected var mutex:Mutex;
    protected var mainToBack:MessageChannel;
    protected var backToMain:MessageChannel;
    protected var workBytes:ByteArray;
    protected var imageOffset:int = 0;

    public function IN2ARWorker()
    {
        var worker:Worker = Worker.current;

        //Exit now if we're not a background worker...
        if(worker.isPrimordial){ return; }

        // setup communication
        mainToBack = worker.getSharedProperty("mainToBack");
        backToMain = worker.getSharedProperty("backToMain");
        workBytes = worker.getSharedProperty("workBytes");
        mutex = worker.getSharedProperty("mutex");

        mainToBack.addEventListener(Event.CHANNEL_MESSAGE, onMainToBack);

        addEventListener(Event.INIT, initIN2AR);
        super.onAddedToStage();
    }

    private function initIN2AR(e:Event):void
    {
        removeEventListener(Event.INIT, initIN2AR);

        // init our engine
        // we pass null for Stage argument since it is a worker
        // !!! IMPORTANT !!!
        // that means Free License will work for 90 seconds as with AIR Native Extension
        in2arLib.init( workW, workH, maxPoints, maxReferences, 100, null );

        // indexing reference data will result in huge
        // speed up during matching (see docs for more info)
        // !!! u always need to setup indexing even if u dont plan to use it !!!
        in2arLib.setupIndexing(12, 10, true);

        // but u can switch it off if u want
        in2arLib.setUseLSHDictionary(true);

        // ATTENTION
        // limit the amount of references to be detected per frame
        // if u have only one reference u can skip this option
        in2arLib.setMaxReferencesPerFrame(1);

        in2arLib.addReferenceObject( ByteArray(new DefinitionaData) );

        intrinsic = in2arLib.getIntrinsicParams();
        //
        // setup work bitmapdata
        imageBitmap = new BitmapData(workW, workH);
        imageRect = imageBitmap.rect;
        imageOffset = workW * workH * 4;

        // notify main thread that we finished
        backToMain.send(IN2ARWorkerMessage.IN2AR_INIT);

        initListeners();
    }

    private function initListeners():void
    {
        in2arLib.addListener(IN2ARDetectionEvent.DETECTED, onModelDetected);
        in2arLib.addListener(IN2ARDetectionEvent.FAILED, onDetectionFailed);
        addEventListener(Event.ENTER_FRAME, onEnterFrame);
    }

    private function cleanListeners():void
    {
        in2arLib.removeListener(IN2ARDetectionEvent.DETECTED, onModelDetected);
        in2arLib.removeListener(IN2ARDetectionEvent.FAILED, onDetectionFailed);
        removeEventListener(Event.ENTER_FRAME, onEnterFrame);
    }

    private function onEnterFrame(e:Event):void
    {
        in2arLib.run();
    }

    private function onModelDetected(e:IN2ARDetectionEvent):void
    {
        var refList:Vector.<IN2ARReference> = e.detectedReferences;
        var ref:IN2ARReference;
        var n:int = e.detectedReferencesCount;
        var i:int, j:int;
        var state:String;

        mutex.lock();
        workBytes.position = imageOffset;

        workBytes.writeInt(n);

        for(i = 0; i < n; ++i) {
            ref = refList[i];
            state = ref.detectType;
            workBytes.writeInt(ref.id);
            workBytes.writeInt( state == IN2ARDetectType.DETECTED ? 0 : 1 );
            for(j = 0; j < 9; ++j)
            {
                workBytes.writeDouble(ref.rotationMatrix[j]);
            }
            workBytes.writeDouble(ref.translationVector[0]);
            workBytes.writeDouble(ref.translationVector[1]);
            workBytes.writeDouble(ref.translationVector[2]);
        }

        mutex.unlock();

        backToMain.send(IN2ARWorkerMessage.IN2AR_DETECTION_DETECTED);
    }

    private function onDetectionFailed(e:IN2ARDetectionEvent):void
    {
        backToMain.send(IN2ARWorkerMessage.IN2AR_DETECTION_FAILED);
    }

    private function onMainToBack(e:Event):void
    {
        var id:int = mainToBack.receive();

        switch (id)
        {
            case IN2ARWorkerMessage.IN2AR_ADD_FRAME:
                mutex.lock();
                workBytes.position = 0;
                imageBitmap.setPixels(imageRect, workBytes);
                mutex.unlock();
                in2arLib.addBitmapFrame(imageBitmap);
                break;
            case IN2ARWorkerMessage.IN2AR_GET_INTRINSIC:
                backToMain.send(IN2ARWorkerMessage.IN2AR_GET_INTRINSIC);
                backToMain.send(intrinsic.fx);
                backToMain.send(intrinsic.fy);
                break;
            case IN2ARWorkerMessage.IN2AR_SET_INTRINSIC:
                var fx:Number = mainToBack.receive();
                var fy:Number = mainToBack.receive();
                var cx:Number = mainToBack.receive();
                var cy:Number = mainToBack.receive();
                intrinsic.update(fx, fy, cx, cy);
                in2arLib.updateIntrinsicParams();
                break;
            case IN2ARWorkerMessage.IN2AR_START:
                removeEventListener(Event.ENTER_FRAME, onEnterFrame);
                addEventListener(Event.ENTER_FRAME, onEnterFrame);
                break;
            case IN2ARWorkerMessage.IN2AR_STOP:
                removeEventListener(Event.ENTER_FRAME, onEnterFrame);
                break;
            case IN2ARWorkerMessage.IN2AR_DISPOSE:
                cleanListeners();
                disposeIN2AR();
                break;
        }
    }
}
}
