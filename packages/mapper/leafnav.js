Meteor.leafnav = {
	markIntervals : [],
	getDistance : function(currentPosition, destination) {			
		var R = 6371; // km
        var dLat = (destination.lat-currentPosition.lat).toRad();
        var dLon = (destination.lng-currentPosition.lng).toRad();
        var lat1 = (currentPosition.lat).toRad();
        var lat2 = (destination.lat).toRad();
        var a = Math.sin(dLat/2) * Math.sin(dLat/2) + Math.sin(dLon/2) * Math.sin(dLon/2) * Math.cos(lat1) * Math.cos(lat2); 
        var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
        var d = R * c;
        return d;
	},

	getBearing : function(currentPosition, destination) {
		var startLat = currentPosition.lat.toRad();
		var startLng = currentPosition.lng.toRad();
		var endLat = destination.lat.toRad();
		var endLng = destination.lng.toRad();
		var dLng = Math.sin(endLng - startLng) * Math.cos(endLat);
		var dLat = Math.cos(startLat) * Math.sin(endLat) - Math.sin(startLat)
				* Math.cos(endLat) * Math.cos(endLng - startLng);
		var bearing = Math.atan2(dLng, dLat) * 57.2957795;
		return bearing;
	},
	
	getMidPoint : function (pointA, pointB) {
		var lat1 = pointA.lat.toRad();
		var lat2 = pointB.lat.toRad();
		var lon1 = pointA.lng.toRad();		
		var theta = (pointB.lng - pointA.lng).toRad();
		var Bx = Math.cos(lat2) * Math.cos(theta);
		var By = Math.cos(lat2) * Math.sin(theta);
		var lat3 = Math.atan2(Math.sin(lat1) + Math.sin(lat2), Math.sqrt((Math.cos(lat1) + Bx) * (Math.cos(lat1) + Bx) + By * By));
	    var lon3 = lon1 + Math.atan2(By, Math.cos(lat1) + Bx);
	    return new L.LatLng(lat3 * 57.2957795, lon3 * 57.2957795);
	},

	calculateNewPosition : function(currentPosition, distance, bearing) {
		// distance = 150.0/6371.0;
		distance = distance / 6371.0;
		var oldLat = currentPosition.lat.toRad();
		var oldLng = currentPosition.lng.toRad();
		bearing = bearing.toRad();
		var newLat = Math.asin(Math.sin(oldLat) * Math.cos(distance)
				+ Math.cos(oldLat) * Math.sin(distance) * Math.cos(bearing));
		var a = Math.atan2(Math.sin(bearing) * Math.sin(distance)
				* Math.cos(oldLat), Math.cos(distance) - Math.sin(oldLat)
				* Math.sin(newLat));
		var newLng = oldLng + a;
		newLng = (newLng + 3 * Math.PI) % (2 * Math.PI) - Math.PI;
		return new L.LatLng(newLat * 57.2957795, newLng * 57.2957795);
	},
	
	calculateNewPositionArch : function(currentPosition, distance, bearing, latArch, lngArch, pm) {
		distance = distance / 6371.0;
		var oldLat = currentPosition.lat.toRad();
		var oldLng = currentPosition.lng.toRad();
		bearing = bearing.toRad();
		var newLat = Math.asin(Math.sin(oldLat) * Math.cos(distance)
				+ Math.cos(oldLat) * Math.sin(distance) * Math.cos(bearing));
		var a = Math.atan2(Math.sin(bearing) * Math.sin(distance)
				* Math.cos(oldLat), Math.cos(distance) - Math.sin(oldLat)
				* Math.sin(newLat));
		var newLng = oldLng + a;
		newLng = (newLng + 3 * Math.PI) % (2 * Math.PI) - Math.PI;
		if(pm)			
			return new L.LatLng(newLat * (57.2957795+latArch), newLng * 57.2957795+lngArch);
		else
			return new L.LatLng(newLat * (57.2957795-latArch), newLng * 57.2957795-lngArch);
	},
};

Number.prototype.toRad = function() {
	return this * Math.PI / 180;
}