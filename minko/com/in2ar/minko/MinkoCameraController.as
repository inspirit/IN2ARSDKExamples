package com.in2ar.minko 
{
    import aerys.minko.ns.minko_scene;
    import aerys.minko.scene.controller.AbstractController;
    import aerys.minko.scene.data.CameraDataProvider;
    import aerys.minko.scene.node.camera.AbstractCamera;
    import aerys.minko.scene.node.ISceneNode;
    import aerys.minko.scene.node.Scene;
    import aerys.minko.type.binding.DataBindings;
    import aerys.minko.type.binding.IDataProvider;
    import aerys.minko.type.math.Matrix4x4;
    import aerys.minko.type.math.Vector4;
    import com.in2ar.calibration.IntrinsicParameters;
    
    /**
     * ...
     * @author Eugene Zatepyakin
     */
    public final class MinkoCameraController extends AbstractController 
    {
        use namespace minko_scene;
        
        private var _camera:AbstractCamera = null;
        private var _intrinsic:IntrinsicParameters = null;
        private var _arScale:Number;
        
        public var projectionRAW:Vector.<Number>;
        
        public function MinkoCameraController() 
        {
            super(AbstractCamera);
            
            projectionRAW = new Vector.<Number>(16);
            
            targetAdded.add(targetAddedHandler);
            targetRemoved.add(targetRemovedHandler);
        }
        
        private function targetAddedHandler(controller  : MinkoCameraController,
                                            target      : AbstractCamera) : void
        {
            if (_camera != null)
                throw new Error('The CameraController can target only one Camera object.');

            _camera = target;
            _camera.addedToScene.add(addedToSceneHandler);
            _camera.removedFromScene.add(removedFromSceneHandler);
            _camera.worldToLocal.changed.add(worldToLocalChangedHandler);
        }

        private function targetRemovedHandler(controller    : MinkoCameraController,
                                              target        : AbstractCamera) : void
        {
            _camera.addedToScene.remove(addedToSceneHandler);
            _camera.removedFromScene.remove(removedFromSceneHandler);
            _camera.worldToLocal.changed.remove(worldToLocalChangedHandler);
            _camera = null;
        }

        private function addedToSceneHandler(camera : AbstractCamera, scene : Scene) : void
        {
            var sceneBindings : DataBindings = scene.bindings;

            resetSceneCamera(scene);

            if (camera.enabled)
                sceneBindings.addProvider(camera.cameraData);

            camera.activated.add(cameraActivatedHandler);
            camera.deactivated.add(cameraDeactivatedHandler);

            camera.cameraData.changed.add(cameraPropertyChangedHandler);

            sceneBindings.addCallback('viewportWidth', viewportSizeChanged);
            sceneBindings.addCallback('viewportHeight', viewportSizeChanged);

            updateProjection();
        }

        private function removedFromSceneHandler(camera : AbstractCamera, scene : Scene) : void
        {
            var sceneBindings : DataBindings = scene.bindings;

            resetSceneCamera(scene);

            if (camera.enabled)
                sceneBindings.removeProvider(camera.cameraData);

            camera.activated.remove(cameraActivatedHandler);
            camera.deactivated.remove(cameraDeactivatedHandler);

            camera.cameraData.changed.remove(cameraPropertyChangedHandler);

            sceneBindings.removeCallback('viewportWidth', viewportSizeChanged);
            sceneBindings.removeCallback('viewportHeight', viewportSizeChanged);
        }

        private function worldToLocalChangedHandler(worldToLocal : Matrix4x4) : void
        {
            var cameraData      : CameraDataProvider    = _camera.cameraData;
            var worldToScreen   : Matrix4x4             = cameraData.worldToScreen;
            var screenToWorld   : Matrix4x4             = cameraData.screenToWorld;
            var viewToWorld     : Matrix4x4             = cameraData.viewToWorld;
            var cameraPosition  : Vector4               = cameraData.position;
            var cameraDirection : Vector4               = cameraData.direction;

            worldToScreen.lock();
            screenToWorld.lock();
            cameraPosition.lock();
            cameraDirection.lock();

            worldToScreen.copyFrom(_camera.worldToLocal).append(cameraData.projection);
            screenToWorld.copyFrom(cameraData.screenToView).append(_camera.localToWorld);
            viewToWorld.transformVector(Vector4.ZERO, cameraPosition);
            viewToWorld.deltaTransformVector(Vector4.Z_AXIS, cameraDirection).normalize();

            cameraData.frustum.updateFromMatrix(worldToScreen);

            worldToScreen.unlock();
            screenToWorld.unlock();
            cameraPosition.unlock();
            cameraDirection.unlock();
        }

        private function viewportSizeChanged(bindings   : DataBindings,
                                             key        : String,
                                             oldValue   : Object,
                                             newValue   : Object) : void
        {
            updateProjection();
        }

        private function cameraPropertyChangedHandler(provider : IDataProvider, property : String) : void
        {
            // we dont change any of this parameters
            //if (property == 'zFar' || property == 'zNear' || property == 'fieldOfView' || property == 'zoom')
                //updateProjection();
        }
        
        public function setupProjectionMatrix(intrinsic:IntrinsicParameters, 
                                                viewWidth:uint, viewHeight:uint, 
                                                in2arWidth:uint, in2arHeight:uint):void
        {
            _intrinsic = intrinsic;
            _arScale = Math.max(Number(viewWidth)/Number(in2arWidth), Number(viewHeight)/Number(in2arHeight));
        }
        
        private function updateProjection() : void
        {
            var cameraData      : CameraDataProvider    = _camera.cameraData;
            var sceneBindings   : DataBindings          = Scene(_camera.root).bindings;
            var viewportWidth   : Number                = sceneBindings.getProperty('viewportWidth');
            var viewportHeight  : Number                = sceneBindings.getProperty('viewportHeight');
            var ratio           : Number                = viewportWidth / viewportHeight;

            var projection      : Matrix4x4             = cameraData.projection;
            var screenToView    : Matrix4x4             = cameraData.screenToView;
            var screenToWorld   : Matrix4x4             = cameraData.screenToWorld;
            var worldToScreen   : Matrix4x4             = cameraData.worldToScreen;

            projection.lock();
            screenToView.lock();
            screenToWorld.lock();
            worldToScreen.lock();
            
            var cx      : Number    = _intrinsic.cx;
            var cy      : Number    = _intrinsic.cy;
            var w       : Number    = viewportWidth;
            var h       : Number    = viewportHeight;
            var fx      : Number    = _intrinsic.fx;
            var fy      : Number    = _intrinsic.fy;
            var aspect  : Number    = w / h;
            
            var _zNear:Number = fx / 32;
            var _zFar:Number = fx * 32;
            var _fov:Number = 2.0 * Math.atan((h - 1) / (2 * fy));
            
            var pSizeY  : Number    = _zNear * Math.tan(_fov * .5);
            var pSizeX  : Number    = pSizeY * aspect;
            
            cameraData.fieldOfView = _fov;
            cameraData.zFar = _zFar;
            cameraData.zNear = _zNear;
            
            var raw:Vector.<Number> = projectionRAW;
            
            raw[uint(0)] = _zNear/pSizeX * _arScale;
            raw[uint(5)] = _zNear/pSizeY * _arScale;
            raw[uint(10)] = _zFar/(_zFar-_zNear);
            raw[uint(11)] = 1.;
            raw[uint(14)] = -_zNear*raw[uint(10)];
            
            projection.setRawData(raw);
            
            screenToView.copyFrom(projection).invert();
            screenToWorld.copyFrom(screenToView).append(_camera.localToWorld);
            worldToScreen.copyFrom(_camera.worldToLocal).append(projection);

            cameraData.frustum.updateFromMatrix(worldToScreen);

            projection.unlock();
            screenToView.unlock();
            screenToWorld.unlock();
            worldToScreen.unlock();
        }
        
        private function cameraActivatedHandler(camera : AbstractCamera) : void
        {
            var scene : Scene = camera.root as Scene;

            scene.bindings.addProvider(camera.cameraData);
            resetSceneCamera(scene);
        }

        private function cameraDeactivatedHandler(camera : AbstractCamera) : void
        {
            var scene   : Scene = camera.root as Scene;

            scene.bindings.removeProvider(camera.cameraData);
            resetSceneCamera(scene);
        }

        private function resetSceneCamera(scene : Scene) : void
        {
            var cameras     : Vector.<ISceneNode>   = scene.getDescendantsByType(AbstractCamera);
            var numCameras  : uint                  = cameras.length;
            var cameraId    : uint                  = 0;
            var camera      : AbstractCamera        = null;

            if (_camera.enabled)
            {
                scene._camera = _camera;
                for (cameraId; cameraId < numCameras; ++cameraId)
                {
                    camera = cameras[cameraId] as AbstractCamera;
                    camera.enabled = camera == _camera;
                }
            }
            else
            {
                scene._camera = null;
                for (cameraId; cameraId < numCameras; ++cameraId)
                {
                    camera = cameras[cameraId] as AbstractCamera;
                    if (camera.enabled)
                        scene._camera = camera;
                }
            }
        }
        
    }

}