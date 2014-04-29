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

import java.util.HashMap;
import java.util.List;
import java.util.Map;
// import android.content.Intent;
// import android.os.Bundle;
import java.io.IOException;
import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;

import cc.fovea.microphone.functions.InitLibFunction;
import cc.fovea.microphone.functions.StartMicFunction;
import cc.fovea.microphone.functions.StopMicFunction;
import cc.fovea.microphone.functions.GetActivityLevelFunction;

import android.media.MediaRecorder;
import android.media.AudioRecord;
import android.media.AudioFormat;

public class AirMicrophoneExtensionContext extends FREContext
{
    // private MediaRecorder mRecorder = null;
    private AudioRecord mRecorder = null;
    private Boolean mStarted = false;
    private int mBufferSize = 0;
    private int mSampleRate =  0;
    private byte[] mBuffer;

	@Override
	public void dispose()
	{
        if (mRecorder != null) {
            mRecorder.release();
            mRecorder = null;
        }
		AirMicrophoneExtension.context = null;
	}

	@Override
	public Map<String, FREFunction> getFunctions()
	{
		Map<String, FREFunction> functions = new HashMap<String, FREFunction>();
		
		functions.put("initLib", new InitLibFunction());
		functions.put("getActivityLevel", new GetActivityLevelFunction());
		functions.put("startMic", new StartMicFunction());
		functions.put("stopMic", new StopMicFunction());
		return functions;	
	}
    /**
     * Scan for the best configuration parameter for AudioRecord object on this device.
     * Constants value are the audio source, the encoding and the number of channels.
     * That means were are actually looking for the fitting sample rate and the minimum
     * buffer size. Once both values have been determined, the corresponding program
     * variable are initialized (audioSource, sampleRate, channelConfig, audioFormat)
     * For each tested sample rate we request the minimum allowed buffer size. Testing the
     * return value let us know if the configuration parameter are good to go on this
     * device or not.
     * 
     * This should be called in at start of the application in onCreate().
     * 
     */
    public void initRecorderParameters(int[] sampleRates) {

        for (int i = 0; i < sampleRates.length; ++i) {
            try {
                AirMicrophoneExtension.log("Indexing "+sampleRates[i]+"Hz Sample Rate");
                int tmpBufferSize = AudioRecord.getMinBufferSize(sampleRates[i], 
                        AudioFormat.CHANNEL_IN_MONO,
                        AudioFormat.ENCODING_PCM_16BIT);

                // Test the minimum allowed buffer size with this configuration on this device.
                if(tmpBufferSize != AudioRecord.ERROR_BAD_VALUE){
                    // Seems like we have ourself the optimum AudioRecord parameter for this device.
                    AudioRecord tmpRecoder = new AudioRecord(MediaRecorder.AudioSource.MIC, 
                            sampleRates[i], 
                            AudioFormat.CHANNEL_IN_MONO,
                            AudioFormat.ENCODING_PCM_16BIT,
                            tmpBufferSize);
                    // Test if an AudioRecord instance can be initialized with the given parameters.
                    if(tmpRecoder.getState() == AudioRecord.STATE_INITIALIZED) {
                        String configResume = "initRecorderParameters(sRates) has found recorder settings supported by the device:"  
                            + "\nSource   = MICROPHONE"
                            + "\nsRate    = "+sampleRates[i]+"Hz"
                            + "\nChannel  = MONO"
                            + "\nEncoding = 16BIT";
                        AirMicrophoneExtension.log(configResume);

                        //+++Release temporary recorder resources and leave.
                        tmpRecoder.release();
                        tmpRecoder = null;

                        mSampleRate = sampleRates[i];
                        mBufferSize = tmpBufferSize;
                        mBuffer = new byte[mBufferSize];

                        return;
                    }
                }
                else {
                    AirMicrophoneExtension.log("Incorrect buffer size. Continue sweeping Sampling Rate...");
                }
            }
            catch (IllegalArgumentException e) {
                AirMicrophoneExtension.log("The "+sampleRates[i]+"Hz Sampling Rate is not supported on this device");
            }
        }
    }
	
	public void initLib(Boolean debug)
    {
        AirMicrophoneExtension.log("initLib");
        initRecorderParameters(new int[]{8000, 11025, 16000, 22050, 32000, 44100, 48000});
    }

    public float getActivityLevel()
    {
        if (mStarted) {
            double sum = 0;
            int readSize = mRecorder.read(mBuffer, 0, mBufferSize);
            for (int i = 0; i < readSize; i++) {
                sum += mBuffer[i] * mBuffer[i];
            }
            if (readSize > 0) {
                final double amplitude = sum / readSize;
                return (float)Math.sqrt(amplitude);
            }
        }
        // return mRecorder.getMaxAmplitude();
        return 0.0f;
    }

    public void startMic()
    {
        if (mStarted) return;
        AirMicrophoneExtension.log("startMic");
        if (mRecorder == null) {
            mRecorder = new AudioRecord(MediaRecorder.AudioSource.MIC, mSampleRate, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT, mBufferSize);
            if (mRecorder.getState() == AudioRecord.STATE_INITIALIZED) {
                AirMicrophoneExtension.log("start recording");
                mRecorder.startRecording();
            }
            else {
                AirMicrophoneExtension.log("Cannot initialize microphone");
            }
            /* mRecorder = new MediaRecorder();
            mRecorder.reset();
            mRecorder.setAudioSource(MediaRecorder.AudioSource.MIC);
            mRecorder.setOutputFormat(MediaRecorder.OutputFormat.DEFAULT);
            mRecorder.setOutputFile("/dev/null"); 
            mRecorder.setAudioEncoder(MediaRecorder.AudioEncoder.DEFAULT);
            mRecorder.setAudioSamplingRate(mSampleRate);

            try {
                mRecorder.prepare();
            }
            catch (IOException e) {
                AirMicrophoneExtension.log("prepare() failed");
            }
            mRecorder.start(); */
            mStarted = true;
        }
    }

    public void stopMic()
    {
        if (!mStarted) return;
        AirMicrophoneExtension.log("stopMic");
        if (mRecorder != null) {
            mRecorder.stop();
        }
        /* if (mRecorder != null) {
            mRecorder.stop();
            mRecorder.release();
            mRecorder = null;
        } */
        mStarted = false;
    }
}
