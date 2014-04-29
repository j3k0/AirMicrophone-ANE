//////////////////////////////////////////////////////////////////////////////////////
//
//  Copyright 2012 Freshplanet (http://freshplanet.com | opensource@freshplanet.com)
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

package cc.fovea.microphone.functions;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREObject;
import cc.fovea.microphone.AirMicrophoneExtension;

public class GetActivityLevelFunction extends BaseFunction
{
	public FREObject call(FREContext context, FREObject[] args)
	{
		super.call(context, args);
		float l = AirMicrophoneExtension.context.getActivityLevel();
        AirMicrophoneExtension.context.dispatchStatusEventAsync("ACTIVITY_LEVEL", Float.toString(l)) ;
		
		return null;
	}
}
