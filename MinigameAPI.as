﻿package  {
	import flash.display.MovieClip;
	import flash.text.TextField;
	import flash.display.Loader;
	import flash.net.Socket;
	import flash.events.Event;
	import com.adobe.crypto.SHA1;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import flash.utils.ByteArray;
	
	public class MinigameAPI implements IMinigameAPI{
		private static const salt:String = "";
		private var minigameID:String = "";
		private var DEBUG:Boolean = false;
		private var gameName:String = "";
		private var lx:Object = null;
		private var data:Object = null;
		private var uid:String = null;
		
		private var container:MovieClip;
		private var panel:MovieClip;
		private var indent:MovieClip;
		private var outer:MovieClip;
		private var minigame:Minigame;
		private var title:TextField;
		private var closeButton:MovieClip;
		
		public function MinigameAPI(minigame:Minigame, container:MovieClip, panel:MovieClip, indent:MovieClip, 
									outer:MovieClip, title:TextField, closeButton:MovieClip, lx:Object, 
									gameName:String, debug:Boolean, uid:String) {
			this.minigame = minigame;
			this.container = container;
			this.panel = panel;
			this.indent = indent;
			this.outer = outer;
			this.title = title;
			this.closeButton = closeButton;
			this.uid = uid;
			
			this.minigameID = minigame.minigameID;
			
			this.lx = lx;
			this.gameName = gameName;
			this.DEBUG = debug;
		}
		
		public function getData() : Object{
			if (data == null){
				data = lx.minigameData.GameData[gameName];
				if (data == null){
					data = new Object();
					lx.minigameData.GameData[gameName] = data;
					saveData();
				}
			}
			
			return data;
		}
		public function saveData() : void{
			lx.writeMinigamesKV();
		}
		
		public function resizeGameWindow() : void {
			panel.width = minigame.width + 15;
			panel.height = minigame.height + 15;
			
			indent.width = minigame.width + 14;
			
			outer.height = minigame.height + 35;
			outer.width = minigame.width + 18;
			
			title.width = minigame.width + 18;
			
			closeButton.x = minigame.width + 12;
		}
		
		public function updateTitle() : void {
			title.text = minigame.title;
		}
		
		public function closeMinigame() : void {
			lx.closeMinigame();
		}
		
		public function updateLeaderboard(leaderboard:String, value:Number) : void {
			if (DEBUG) {
				log("DEBUG on, not sending leaderboard info: " + leaderboard + " -- " + value);
				return;
			}
			
			var msg:Object = {minigameID:minigameID, leaderboard:leaderboard, value:value, userID32:uid, type:"HIGHSCORE"};
			var encodedJSON:String = GetDotaLobby.encode(msg);
			log("Leaderboard message: " + encodedJSON);
			msg["hmac"] = SHA1.hash(salt + encodedJSON);
			encodedJSON = GetDotaLobby.encode(msg);

			var socket:Socket = new Socket();

			var leaderboardConnect:Function = (function(json:String, socket:Socket) {
				socket.removeEventListener(Event.CONNECT, leaderboardConnect);
				return function(e:Event){
					trace("writing leaderboard socket: " + json);
					try{
						var ba:ByteArray = new ByteArray();
						var len:uint = ba.length;
						
						ba = new ByteArray();
						ba.writeUTF(json);
						trace(ba.length);
		
						socket.writeBytes(ba, 0, ba.length);
						socket.flush();
						
						var fun:Function = function(te:TimerEvent){
							socket.close();
						};
						var timer:Timer = new Timer(500, 1);
						timer.addEventListener(TimerEvent.TIMER, fun);
						timer.start();
					}catch(err:Error){
						trace(err);
					}
				};
			})(encodedJSON, socket);

			trace("CONNECTING");
			socket.connect("176.31.182.87", 4450);
			socket.addEventListener(Event.CONNECT, leaderboardConnect);
		}
		
		public function getUserID() : String {
			return uid;
		}
		
		public function log(obj:Object) : void {
			lx.traceLX("[" + gameName + "]" + obj.toString());
		}
	}
	
}