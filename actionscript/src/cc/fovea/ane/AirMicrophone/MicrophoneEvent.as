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
    import flash.events.Event;

    public class MicrophoneEvent extends Event
    {
        public static const ACTIVITY_LEVEL:String = "activityLevel";

        // json encoded string (if any)
        public var data:String;

        public function MicrophoneEvent(type:String, data:String = null, bubbles:Boolean=false, cancelable:Boolean=false)
        {
            this.data = data;
            super(type, bubbles, cancelable);
        }
    }
}
