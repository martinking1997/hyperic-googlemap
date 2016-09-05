<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="initial-scale=1.0, user-scalable=no">
    <meta charset="utf-8">
    <title>Hyperic HQ Google Map</title>
    <style>
      html, body, #map-canvas {
        height: 100%;
        margin: 0px;
        padding: 0px
      }
    </style>
    <script type="text/javascript" src="/static/js/dojo/1.5/dojo/dojo.js.uncompressed.js" 
		djConfig="isDebug:false, parseOnLoad: true,useCommentedJson:true" ></script>

    <script src="http://ditu.google.cn/maps/api/js?sensor=false"></script>
    <script src="/hqu/googlemap/public/js/googlemap.js"></script>
    <script>
        dojo.require("dojox.timing._base");

	var getAlertsUrl= "/<%= urlFor(action:"getAlerts", encodeUrl:true) %>";
	var AllMarkers=[];
	var failedUpdateRequests = 0;
	var map = null;

function GM_UpdateTimestamp() {
        var d = new Date();
        var h = d.getHours();
        var m = d.getMinutes();
        if(m < 10)
                m = '0' + m;
        var s = d.getSeconds();
        if(s < 10)
                s = '0' + s;

        dojo.byId('timestamp').innerHTML = "Time: "+h + ':' + m + ':' + s;
}

function updateAllPostUrl(sessionRandom){
        if( sessionRandom == null || sessionRandom==""){
                return "";
        }
        getAlertsUrl= "hqu/googlemap/googlemap/getAlerts.hqu?org.apache.catalina.filters.CSRF_NONCE="+sessionRandom;
}

function GM_UpdateValues() {
        var contentObject = {};
        var jsonData = {};
        var nodeList = [];
        for(var i = 0; i < AllMarkers.length; i++){
		if( map.getBounds().contains(AllMarkers[i].marker.getPosition())){
	                var data = {};
        	        data['aeid'] = AllMarkers[i].aeid;
                	data['type'] = AllMarkers[i].hyptype;
	                nodeList.push(data);
		}
        }
        jsonData['items'] = nodeList;
        contentObject['jsonData'] = dojo.toJson(jsonData);

        dojo.xhrPost({
                url: getAlertsUrl,
                handleAs: "json-comment-filtered",
                timeout: 10000,
                preventCache: true,
                content: contentObject,
                load: function(response, ioArgs) {
                        if (response.actionToken) {
                      // use new CSRF token for subsequent POST requests
                      // getAlertsUrl = response.actionToken;
                         sessionRandom=getQueryValueByName("org.apache.catalina.filters.CSRF_NONCE",response.actionToken);
                         updateAllPostUrl(sessionRandom);
                        }
                        for (var i = 0; i < response.items.length; i++) {
                                var item = response.items[i];
                                GM_HandleUpdate(item.aeid,item.status,item.hyptype);
                        }
                        GM_UpdateTimestamp();
                        // reset counter
                        failedUpdateRequests = 0;
                        return response;
                },
                error: function(response, ioArgs) {
                        failedUpdateRequests++;
                        // too many failures. Just Give up.
                        if(failedUpdateRequests > 10) {
                                timer.stop();
                                alert('Too many failures to request new alerts. Alert updater stopped.');
                        }
                        return response;
                }
        });
};
function GM_HandleUpdate(aeid,status,type) {
        // first find all components which has relative eid value
        // note: resource and resource type may have same id
        // this case is handled later
        for(var i = 0; i < AllMarkers.length; i++){

                // stop if we have wrong type
                var oldHypType = AllMarkers[i].hyptype;
                if(type != oldHypType || aeid != AllMarkers[i].aeid || status == AllMarkers[i].status)
                        continue;
		var t_pos = AllMarkers[i].marker.getPosition();
		var t_name = AllMarkers[i].hqName;
		AllMarkers[i].marker.setMap(null);
		AllMarkers[i]= createMarker(t_pos,t_name,aeid,type,status);	
		attachMarkerActions( AllMarkers[i].marker, AllMarkers[i].aeid ,AllMarkers[i].hqName);
        }
};

function attachMarkerActions(marker,aeid, name){
	var infowindow = new google.maps.InfoWindow(
	      { content: name,
//	        size: new google.maps.Size(50,50)
      		});
	 google.maps.event.addListener(marker, 'mouseover', function() {
	    infowindow.open(map,marker);
	  });
	 google.maps.event.addListener(marker, 'mouseout', function() {
	    infowindow.close();
	  });

	google.maps.event.addListener(marker, 'click', function() {
                    window.open("/Resource.do?eid="+aeid , "_blank");
                 });
	
}

// This example adds a marker to indicate the position
// of Bondi Beach in Sydney, Australia
function createMarker(myLatLng,name,aeid,hyptype,status){
  var theNode={}
  var image = '/hqu/googlemap/public/images/'+status+'-default-18-'+ hyptype +'.png';
  var theMarker = new google.maps.Marker({
      position: myLatLng,
      map: map,
      icon: image
  });
  theNode.hqName= name;
  theNode.aeid = aeid;
  theNode.status= status;
  theNode.hyptype = hyptype;
  theNode.marker = theMarker;
  return theNode;
}

function initialize() {
  var mapOptions = {
    zoom: 4,
    center: new google.maps.LatLng(35, 105),
    mapTypeId: google.maps.MapTypeId.ROADMAP
  }
  map = new google.maps.Map(document.getElementById('map-canvas'),
                                mapOptions);

//  var image = 'images/beachflag.png';
 platforms=<%=platforms %>;
  for( i=0; i < platforms.length; i++ ){
	var tlatlng = new google.maps.LatLng(platforms[i].latlng[0], platforms[i].latlng[1]);
	AllMarkers[i] =	createMarker(tlatlng, platforms[i].name,platforms[i].aeid,platforms[i].hyptype,"unknown");
  }
}
function init_gm(){
	google.maps.event.addDomListener(window, 'load', initialize);
  	GM_UpdateValues();
}

	timer = new dojox.timing.Timer(30000);
        dojo.connect(timer, "onTick", function(obj){GM_UpdateValues();});
       // connect onStart after timer has started.
        dojo.connect(timer, "onStart", function(obj){GM_UpdateValues();});

	dojo.addOnLoad(init_gm);
        timer.start();
    </script>
  </head>
  <body>
<div id="timestamp">Good Luck!!</div>
    <div id="map-canvas"></div>
  </body>
</html>


