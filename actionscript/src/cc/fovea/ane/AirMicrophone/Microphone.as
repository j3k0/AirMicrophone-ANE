//////////////////////////////////////////////////////////////////////////////////////
//
//  Copyright 2014 Fovea.cc (http://fovea.cc | hoelt@fovea.cc)
//  
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//    http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//  
//////////////////////////////////////////////////////////////////////////////////////

package cc.fovea.ane.AirMicrophone
{
    import flash.events.EventDispatcher;
    import flash.events.StatusEvent;
    import flash.external.ExtensionContext;
    import flash.system.Capabilities;
    import flash.media.Microphone;

    public class Microphone extends EventDispatcher
    {
        private static var _instance:cc.fovea.ane.AirMicrophone.Microphone;

        private var extCtx:*;

        public function Microphone()
        {
            if (!_instance)
            {
                if (isSupported)
                {
                    trace("[Microphone] create extCtx");
                    extCtx = ExtensionContext.createExtensionContext("cc.fovea.AirMicrophone", null);
                    if (extCtx != null) {
                        extCtx.addEventListener(StatusEvent.STATUS, onStatus);
                        init(true);
                    } else {
                        trace('[Microphone] extCtx is null.');
                    }
                }
                _instance = this;
            }
            else {
                throw Error( 'This is a singleton, use getMicrophone(), do not call the constructor directly');
            }
        }

        public static function getMicrophone():Object {
            if (isSupported) {
                trace("[Microphone] getMicrophone native");
                return _instance != null ? _instance : new cc.fovea.ane.AirMicrophone.Microphone();
            }
            else
                return flash.media.Microphone.getMicrophone();
        }

        public function init(debug:Boolean):void
        {
            if (isSupported) {
                trace("[Microphone] init library");
                extCtx.call("initLib", debug);
            }
        }

        /* public function userCanMakeAPurchase():void 
        {
            if (this.isMicrophoneSupported)
            {
                trace("[Microphone] check user can make a purchase");
                extCtx.call("userCanMakeAPurchase");
            } else
            {
                this.dispatchEvent(new MicrophoneEvent(MicrophoneEvent.PURCHASE_DISABLED));
            }
        } */

        public static function get isSupported():Boolean
        {
            var value:Boolean = Capabilities.manufacturer.indexOf('iOS') > -1 || Capabilities.manufacturer.indexOf('Android') > -1;
            // trace(value ? '[Microphone] supported' : '[Microphone] not supported');
            return value;
        }

        private var _activityLevel:Number = 0;
        public function get activityLevel():Number
        {
            // Make sure to refresh activity level for next time it's requested
            // doing this call here ensure we're refreshing at the same frequency
            // that the app require.
            extCtx.call("getActivityLevel");

            return _activityLevel;
        }

        private function setActivityLevel(value:Number):void {
            _activityLevel = value * 100.0;
            if (!(_activityLevel >= 0 && _activityLevel <= 100)) {
                if (_activityLevel > 100)
                    _activityLevel = 100;
                else
                    _activityLevel = 0;
            }
        }

        private function onStatus(event:StatusEvent):void
        {
            // trace(event);
            var e:MicrophoneEvent;
            switch(event.code)
            {
                case "ACTIVITY_LEVEL":
                    e = new MicrophoneEvent(MicrophoneEvent.ACTIVITY_LEVEL, event.level);
                    setActivityLevel(Number(event.level));
                    break;
                default:
            }
            if (e)
                this.dispatchEvent(e);
        }

        // Bunch of methods that do nothing but ensure compatibility
        // with flash.media Microphone class.
        public function get muted():Boolean { return false; }
        public function setLoopBack(value:Boolean = true):void { }
        public function setSilenceLevel(value:Number):void { }
        public function set soundTransform(value:*):void { }
        public function set codec(value:*):void { }
        public function set rate(value:int):void {
            if (isSupported) {
                if (value > 0) {
                    extCtx.call("startMic");
                }
                else {
                    extCtx.call("stopMic");
                }
            }
        }
        public function set framesPerPacket(value:*):void { }
        public function set enableVAD(value:Boolean):void { }
    }
}
