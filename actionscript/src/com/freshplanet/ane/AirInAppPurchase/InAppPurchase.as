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

	public class Microphone extends EventDispatcher
	{
		private static var _instance:Microphone;
		
		private var extCtx:*;
		
		public function Microphone()
		{
			if (!_instance)
			{
				if (this.isMicrophoneSupported)
				{
					extCtx = ExtensionContext.createExtensionContext("cc.fovea.AirMicrophone", null);
					if (extCtx != null)
					{
						extCtx.addEventListener(StatusEvent.STATUS, onStatus);
					} else
					{
						trace('[Microphone] extCtx is null.');
					}
				}
			_instance = this;
			}
			else
			{
				throw Error( 'This is a singleton, use getInstance, do not call the constructor directly');
			}
		}
		
		
		public static function getInstance():Microphone
		{
			return _instance != null ? _instance : new Microphone();
		}
		
		
		public function init(googlePlayKey:String, debug:Boolean = false):void
		{
			if (this.isMicrophoneSupported)
			{
				trace("[Microphone] init library");
				extCtx.call("initLib", googlePlayKey, debug);
			}
		}
		
		public function makePurchase(productId:String ):void
		{
			if (this.isMicrophoneSupported)
			{
				trace("[Microphone] purchasing", productId);
				extCtx.call("makePurchase", productId);
			} else
			{
				this.dispatchEvent(new MicrophoneEvent(MicrophoneEvent.PURCHASE_ERROR, "Microphone not supported"));
			}
		}
		
		// receipt is for android device.
		public function removePurchaseFromQueue(productId:String, receipt:String):void
		{
			if (this.isMicrophoneSupported)
			{
				trace("[Microphone] removing product from queue", productId, receipt);
				extCtx.call("removePurchaseFromQueue", productId, receipt);
				
				if (Capabilities.manufacturer.indexOf("iOS") > -1)
				{
					_iosPendingPurchases = _iosPendingPurchases.filter(function(jsonPurchase:String, index:int, purchases:Vector.<Object>):Boolean {
						try
						{
							var purchase:Object = JSON.parse(jsonPurchase);
							return JSON.stringify(purchase.receipt) != receipt;
						} 
						catch(error:Error)
						{
							trace("[Microphone] Couldn't parse purchase: " + jsonPurchase);
						}
						return false;
					});
				}
			}
		}
		
		
		
		public function getProductsInfo(productsId:Array, subscriptionIds:Array):void
		{
			if (this.isMicrophoneSupported)
			{
				trace("[Microphone] get Products Info");
				extCtx.call("getProductsInfo", productsId, subscriptionIds);
			} else
			{
				this.dispatchEvent( new MicrophoneEvent(MicrophoneEvent.PRODUCT_INFO_ERROR) );
			}

		}
		
		
		public function userCanMakeAPurchase():void 
		{
			if (this.isMicrophoneSupported)
			{
				trace("[Microphone] check user can make a purchase");
				extCtx.call("userCanMakeAPurchase");
			} else
			{
				this.dispatchEvent(new MicrophoneEvent(MicrophoneEvent.PURCHASE_DISABLED));
			}
		}
			
		public function userCanMakeASubscription():void
		{
			if (Capabilities.manufacturer.indexOf('Android') > -1)
			{
				trace("[Microphone] check user can make a purchase");
				extCtx.call("userCanMakeASubscription");
			} else
			{
				this.dispatchEvent(new MicrophoneEvent(MicrophoneEvent.PURCHASE_DISABLED));
			}
		}
		
		public function makeSubscription(productId:String):void
		{
			if (Capabilities.manufacturer.indexOf('Android') > -1)
			{
				trace("[Microphone] check user can make a subscription");
				extCtx.call("makeSubscription", productId);
			} else
			{
				this.dispatchEvent(new MicrophoneEvent(MicrophoneEvent.PURCHASE_ERROR, "Microphone not supported"));
			}
		}
		
		
		public function restoreTransactions():void
		{
			if (Capabilities.manufacturer.indexOf('Android') > -1)
			{
				extCtx.call("restoreTransaction");
			}
			else if (Capabilities.manufacturer.indexOf("iOS") > -1)
			{
				var jsonPurchases:String = "[" + _iosPendingPurchases.join(",") + "]";
				var jsonData:String = "{ \"purchases\": " + jsonPurchases + "}";
				dispatchEvent(new MicrophoneEvent(MicrophoneEvent.RESTORE_INFO_RECEIVED, jsonData));
			}
		}


		public function stop():void
		{
			if (Capabilities.manufacturer.indexOf('Android') > -1)
			{
				trace("[Microphone] stop library");
				extCtx.call("stopLib");
			}
		}

		
		public function get isMicrophoneSupported():Boolean
		{
			var value:Boolean = Capabilities.manufacturer.indexOf('iOS') > -1 || Capabilities.manufacturer.indexOf('Android') > -1;
			trace(value ? '[Microphone]  in app purchase is supported ' : '[Microphone]  in app purchase is not supported ');
			return value;
		}
		
		private var _iosPendingPurchases:Vector.<Object> = new Vector.<Object>();
		
		private function onStatus(event:StatusEvent):void
		{
			trace(event);
			var e:MicrophoneEvent;
			switch(event.code)
			{
				case "PRODUCT_INFO_RECEIVED":
					e = new MicrophoneEvent(MicrophoneEvent.PRODUCT_INFO_RECEIVED, event.level);
					break;
				case "PURCHASE_SUCCESSFUL":
					if (Capabilities.manufacturer.indexOf("iOS") > -1)
					{
						_iosPendingPurchases.push(event.level);
					}
					e = new MicrophoneEvent(MicrophoneEvent.PURCHASE_SUCCESSFULL, event.level);
					break;
				case "PURCHASE_ERROR":
					e = new MicrophoneEvent(MicrophoneEvent.PURCHASE_ERROR, event.level);
					break;
				case "PURCHASE_ENABLED":
					e = new MicrophoneEvent(MicrophoneEvent.PURCHASE_ENABLED, event.level);
					break;
				case "PURCHASE_DISABLED":
					e = new MicrophoneEvent(MicrophoneEvent.PURCHASE_DISABLED, event.level);
					break;
				case "PRODUCT_INFO_ERROR":
					e = new MicrophoneEvent(MicrophoneEvent.PRODUCT_INFO_ERROR);
					break;
				case "SUBSCRIPTION_ENABLED":
					e = new MicrophoneEvent(MicrophoneEvent.SUBSCRIPTION_ENABLED);
					break;
				case "SUBSCRIPTION_DISABLED":
					e = new MicrophoneEvent(MicrophoneEvent.SUBSCRIPTION_DISABLED);
					break;
				case "RESTORE_INFO_RECEIVED":
					e = new MicrophoneEvent(MicrophoneEvent.RESTORE_INFO_RECEIVED, event.level);
					break;
				default:
				
			}
			if (e)
			{
				this.dispatchEvent(e);
			}
			
		}
		
		
		
	}
}
