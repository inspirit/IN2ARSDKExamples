package  
{
    import com.in2ar.calibration.IntrinsicParameters;
    import com.in2ar.detect.IN2ARReference;
    import com.in2ar.event.IN2ARDetectionEvent;
    import com.in2ar.flare3d.Flare3DCamera;
    import com.in2ar.flare3d.Flare3DCaptureMesh;
    import com.in2ar.flare3d.Flare3DContainer;
    import flare.basic.Scene3D;
    import flare.basic.Viewer3D;
    import flare.core.Pivot3D;
    import flare.system.Device3D;
    import flash.display.BitmapData;
    import flash.events.Event;
    import flash.geom.Matrix;
    import flash.media.Video;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.utils.ByteArray;
    
    /**
     * Basic Flare3D + IN2AR example
     * You can switch base class to compile for FLASH/AIR(ANE)
     * @author Eugene Zatepyakin
     */
    
    [SWF(width='640',height='480',frameRate='30',backgroundColor='0xFFFFFF')]
    public final class Flare3DDemo extends /* IN2ARNativeBase */  IN2ARBase 
    {
        
        // embed your data file here
        [Embed(source="../assets/def_data.ass", mimeType="application/octet-stream")]
        private static const data_ass:Class;
        
        // init asfeat instance and support classes
        public var intrinsic:IntrinsicParameters;
        
        // max transfromation error to accept
        public var maxTransformError:Number = 10 * 10;
        
        // different visual objects
        private var video:Video;
        private var cameraBuffer:BitmapData;
        private var workBuffer:BitmapData;
        private var cameraMatrix:Matrix;
        public static var text:TextField;
        
        // camera and viewport options
        public var streamW:int = 640;
        public var streamH:int = 480;
        public var downScaleRatio:Number = 1;
        public var workW:int = streamW * downScaleRatio;
        public var workH:int = streamH * downScaleRatio;
        public var viewWidth:int = 640;
        public var viewHeight:int = 480;
        public var maxPointsToDetect:int = 300; // max point to allow on the screen
        public var maxReferenceObjects:int = 1; // max reference objects to be used
        public var mirror:Boolean = true; // mirror camera output
        
        // flare3d
        private var fl3dScene:Viewer3D;
        private var fl3dCamera:Flare3DCamera;
        private var fl3dCaptureMesh:Flare3DCaptureMesh;
        private var fl3dAxis:Flare3DContainer;
        
        public function Flare3DDemo() 
        {
            addEventListener(Event.INIT, initIN2AR);
            
            super();
        }
        
        protected function initIN2AR(e:Event = null):void
        {
            removeEventListener(Event.INIT, initIN2AR);
            
            // init our engine
            in2arLib.init( workW, workH, maxPointsToDetect, maxReferenceObjects, maxTransformError, stage );
            
            intrinsic = in2arLib.getIntrinsicParams();
            
            // indexing reference data will result in huge
            // speed up during matching (see docs for more info)
            // !!! u always need to setup indexing even if u dont plan to use it !!!
            in2arLib.setupIndexing(12, 10, true);
            
            // but u can switch it off if u want
            in2arLib.setUseLSHDictionary(true);
            
            // add reference object
            in2arLib.addReferenceObject( ByteArray( new data_ass ) );
            
            // add event listeners
            in2arLib.addListener( IN2ARDetectionEvent.DETECTED, onModelDetected );
            in2arLib.addListener( IN2ARDetectionEvent.FAILED, onDetectionFailed );
            
            // ATTENTION 
            // limit the amount of references to be detected per frame
            // if u have only one reference u can skip this option
            in2arLib.setMaxReferencesPerFrame(1);
            
            // setup web camera
            initCamera();            
            initText();            
            // setup 3d
            initFlare3D();
            
            // run detection
            this.addEventListener(Event.ENTER_FRAME, onEnterFrame);
        }
        
        protected function onDetectionFailed(e:IN2ARDetectionEvent):void 
        {
            fl3dAxis.lost();
            text.text = "nothing found";
        }
        
        protected function onModelDetected(e:IN2ARDetectionEvent):void 
        {
            var refList:Vector.<IN2ARReference> = e.detectedReferences;
            var ref:IN2ARReference;
            var n:int = e.detectedReferencesCount;
            var state:String;
            
            for(var i:int = 0; i < n; ++i) {
                ref = refList[i];
                state = ref.detectType;
                
                fl3dAxis.in2arTransform(ref, 0.8, mirror);
                
                text.text = state;
                text.appendText( ' @ ' + ref.id );
                
                if(state == '_detect')
                    text.appendText( ' :: matched: ' + ref.matchedPointsCount );
            }
        }
        
        protected function onEnterFrame(e:Event = null):void
        {
            // draw video object
            if(cameraBuffer){
                cameraBuffer.draw(video);
                if(downScaleRatio != 1){
                    workBuffer.draw(cameraBuffer, cameraMatrix);
                    // run in2ar
                    in2arLib.detect(workBuffer);
                } else {
                    // run in2ar
                    in2arLib.detect(cameraBuffer);
                }
            }
        }
        
        protected function initFlare3D():void
        {
            fl3dScene = new Viewer3D(this);
            fl3dScene.camera = fl3dCamera = new Flare3DCamera("IN2ARCamera");
            
            fl3dScene.setViewport(0, 0, viewWidth, viewHeight, 2);
            fl3dScene.autoResize = false;
            
            // setup projection matrix
            fl3dCamera.setupProjectionMatrix(intrinsic, viewWidth, viewHeight, workW, workH);
            
            // Web Camera plane
            fl3dCaptureMesh = new Flare3DCaptureMesh("WebCamDisplay", viewWidth, viewHeight, streamW, streamH);
            if (cameraBuffer) {
                fl3dCaptureMesh.setupForBitmapData(cameraBuffer);
            }
            
            fl3dScene.addChild(fl3dCaptureMesh);
            fl3dCaptureMesh.mirror = mirror;
            fl3dCaptureMesh.layer = -100; // force it back
            
            // add model
            fl3dAxis = new Flare3DContainer("axis");
            var axis:Pivot3D = new Pivot3D();
            fl3dScene.addChildFromFile("http://wiki.flare3d.com/demos/resources/axis.f3d", axis);
            axis.setScale(10, 10, 10);
            fl3dAxis.addChild(axis);
            fl3dScene.addChild(fl3dAxis);
            
            fl3dAxis.visible = false;
            
            // start to update the scene.
            fl3dScene.addEventListener( Scene3D.UPDATE_EVENT, fl3dUpdateEvent );
            // for some reason flare3d doesnt allow to use custom projection matrix
            // so we need to update it every (!) render event
            fl3dScene.addEventListener( Scene3D.RENDER_EVENT, fl3dRenderEvent );
        }
        
        protected function fl3dRenderEvent(e:Event):void 
        {
            fl3dCamera.updateProjection();
            Device3D.proj.copyRawDataFrom( fl3dCamera.projectionRAW );
            Device3D.viewProj.copyRawDataFrom( fl3dCamera.viewProjection.rawData );
        }
        protected function fl3dUpdateEvent(e:Event):void 
        {
            // upload web camera image
            fl3dCaptureMesh.invalidate(fl3dScene);
        }
        
        protected function initCamera():void
        {
            var camera:flash.media.Camera = flash.media.Camera.getCamera();
            camera.setMode(streamW, streamH, 30, false);
            
            video = new Video(camera.width, camera.height);
            video.attachCamera(camera);
            
            cameraBuffer = new BitmapData(streamW, streamH, true, 0x0);
            workBuffer = new BitmapData(workW, workH, true, 0x0);
            cameraMatrix = new Matrix(downScaleRatio, 0, 0, downScaleRatio);
            
            if (fl3dCaptureMesh) {
                fl3dCaptureMesh.setupForBitmapData(cameraBuffer);
            }
        }
        
        protected function initText():void
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
        }
        
    }

}