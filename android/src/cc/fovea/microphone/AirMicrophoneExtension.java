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

package cc.fovea.microphone;

import android.util.Log;
import com.adobe.fre.FREContext;
import com.adobe.fre.FREExtension;

public class AirMicrophoneExtension implements FREExtension
{
	public static String TAG = "AirMicrophone";
	private static Boolean PRINT_LOG = true;
	
	public static AirMicrophoneExtensionContext context;

	public FREContext createContext(String extId)
	{
		return context = new AirMicrophoneExtensionContext();
	}

	public void dispose()
	{
		context = null;
	}
	
	public void initialize() {}
	
	public static void log(String message)
	{
		if (PRINT_LOG) Log.d(TAG, message);
		if (context != null && message != null) context.dispatchStatusEventAsync("LOGGING", message);
	}
	
	public static int getResourceId(String name)
	{
		return context != null ? context.getResourceId(name) : 0;
	}
}
