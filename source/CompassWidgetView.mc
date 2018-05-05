using Toybox.WatchUi as Ui;
using Toybox.Application as App;
using Toybox.Graphics as Gfx;

class CompassWidgetView extends Ui.View {

    hidden var RAY_EARTH = 6378137; 
    hidden var heading_rad = null;

    hidden var northStr="";
    hidden var eastStr="";
    hidden var southStr="";
    hidden var westStr="";
    hidden var center_x;
	hidden var center_y;
	hidden var size_max;
	hidden var update;
	hidden var timer;
	
	function initialize() {
		northStr = Ui.loadResource(Rez.Strings.north);
		eastStr = Ui.loadResource(Rez.Strings.east);
		southStr = Ui.loadResource(Rez.Strings.south);
		westStr = Ui.loadResource(Rez.Strings.west);
    
		View.initialize();
	}
    
	function compute(info) {
		if( info.currentHeading != null ) {
			heading_rad = info.currentHeading;
		}
	}
    
    function onShow() {
    	timer = new Timer.Timer();
    	timer.start(method(:timerCallback), 1000, true);
    }

	function timerCallback() {
    	Ui.requestUpdate();
	}

    function onHide() {
    	timer.stop();
    }
    
    function onLayout(dc) {
    	size_max = dc.getWidth() > dc.getHeight() ? dc.getHeight() : dc.getWidth();
    	center_x = dc.getWidth() / 2;
		center_y = dc.getHeight() / 2;
    }
    
	function onUpdate(dc) {  

	    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();  
               
		var actInfo = Activity.getActivityInfo();
		heading_rad = actInfo.currentHeading;
		if( heading_rad != null) {
			var map_declination =  App.getApp().getProperty("map_declination");
			if (map_declination != null ) {
				if(map_declination instanceof Toybox.Lang.String) {
					map_declination = map_declination.toFloat();
				}	
				heading_rad= heading_rad+map_declination*Math.PI/180;
			}
			
			if( heading_rad < 0 ) {
				heading_rad = 2*Math.PI+heading_rad;
			}
            							
			var display_logo_orientation = App.getApp().getProperty("display_logo_orientation");
			
            if( display_logo_orientation ){
            	drawLogoOrientation(dc, center_x, center_y, size_max, heading_rad);
			}
			
			var display_text_orientation = App.getApp().getProperty("display_text_orientation");
			
			if( display_text_orientation ){
				var y = center_y ;
				var size = size_max;

				drawTextOrientation(dc, center_x, y, size, heading_rad);
			}
						
			var display_compass = App.getApp().getProperty("display_compass");
			if( display_compass ){
				drawCompass(dc, center_x, center_y, size_max);
			}
		}
	}
    
	function drawTextOrientation(dc, center_x, center_y, size, orientation){
		var color = getColor(App.getApp().getProperty("color_text_orientation"), Graphics.COLOR_LT_GRAY);
		var fontOrientaion;
		var fontMetric = Graphics.FONT_TINY;

       	if( orientation < 0 ) {
				orientation = 2*Math.PI+orientation;
		}
		var orientationStr=Lang.format("$1$", [(orientation*180/Math.PI).format("%d")]);
		
		fontOrientaion = Graphics.FONT_NUMBER_THAI_HOT ;
		
		dc.setColor(color, Graphics.COLOR_TRANSPARENT);
		dc.drawText(center_x, center_y, fontOrientaion, orientationStr, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
		
		var text_width = dc.getTextWidthInPixels(orientationStr, fontOrientaion);
		var text_height =dc.getFontHeight(fontOrientaion);
		dc.drawText(center_x+text_width/2+2, center_y-text_height/4+2, fontMetric, "o", Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
		
	}
	   
	function drawCompass(dc, center_x, center_y, size) {
		var colorText = getColor(App.getApp().getProperty("color_text_compass"), Graphics.COLOR_WHITE);
		var colorTextNorth = getColor(App.getApp().getProperty("color_text_north"), Graphics.COLOR_WHITE);
		var colorCompass = getColor(App.getApp().getProperty("color_compass"), Graphics.COLOR_RED);
		var radius = size/2-12;
		var font=Graphics.FONT_MEDIUM;
		var penWidth = 8;
		var step = 12;

		dc.setColor(colorTextNorth, Graphics.COLOR_TRANSPARENT);
		drawTextPolar(dc, center_x, center_y, heading_rad, radius, font, northStr);
             
		dc.setColor(colorText, Graphics.COLOR_TRANSPARENT);
		drawTextPolar(dc, center_x, center_y, heading_rad + 3*Math.PI/2, radius, font, eastStr);
        
		dc.setColor(colorText, Graphics.COLOR_TRANSPARENT);
		drawTextPolar(dc, center_x, center_y, heading_rad+ Math.PI, radius, font, southStr);

		dc.setColor(colorText, Graphics.COLOR_TRANSPARENT);
		drawTextPolar(dc, center_x, center_y, heading_rad+ Math.PI / 2, radius, font, westStr);
        
		var startAngle = heading_rad*180/Math.PI - step;
		var endAngle = heading_rad*180/Math.PI + 90+ step;
       	dc.setColor(colorCompass, Graphics.COLOR_TRANSPARENT);
		dc.setPenWidth(penWidth);
		for( var i = 0; i < 4; i++ ) {
			dc.drawArc(center_x, center_y, radius, Gfx.ARC_CLOCKWISE, 90+startAngle-i*90, (360-90+endAngle.toLong()-i*90)%360 );
		}
		
		dc.setPenWidth(penWidth/4);
		for( var i = 0; i < 12; i++) {
			if( i % 3 != 0 ) {
				var xy1 = pol2Cart(center_x, center_y, heading_rad+i*Math.PI/6, radius);
				var xy2 = pol2Cart(center_x, center_y, heading_rad+i*Math.PI/6, radius-radius/10);
				dc.drawLine(xy1[0],xy1[1],xy2[0],xy2[1]);
			}
		}      
	}
    
	function drawLogoOrientation(dc, center_x, center_y, size, orientation){
		var color = getColor(App.getApp().getProperty("color_orientation_logo"), Graphics.COLOR_WHITE);
		var radius=size/3.10;
		
		dc.setColor(color, Graphics.COLOR_TRANSPARENT);
	
		var xy1 = pol2Cart(center_x, center_y, orientation, radius);
		var xy2 = pol2Cart(center_x, center_y, orientation+135*Math.PI/180, radius);
		var xy3 = pol2Cart(center_x, center_y, orientation+171*Math.PI/180, radius/2.5);
		var xy4 = pol2Cart(center_x, center_y, orientation, radius/3);
		var xy5 = pol2Cart(center_x, center_y, orientation+189*Math.PI/180, radius/2.5);
		var xy6 = pol2Cart(center_x, center_y, orientation+225*Math.PI/180, radius);
		dc.fillPolygon([xy1, xy2, xy3, xy4, xy5, xy6]);
	}
    
	function drawTextPolar(dc, center_x, center_y, radian, radius, font, text) {
		var xy = pol2Cart(center_x, center_y, radian, radius);
		dc.drawText(xy[0], xy[1], font, text, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
	}
    
	function pol2Cart(center_x, center_y, radian, radius) {
		var x = center_x - radius * Math.sin(radian);
		var y = center_y - radius * Math.cos(radian);
		 
		return [Math.ceil(x), Math.ceil(y)];
	}
     
   	function getColor(color_property, color_default){
        if (color_property == 1) {
        	return Gfx.COLOR_BLUE;
        }else if (color_property == 2) {
        	return Gfx.COLOR_DK_BLUE;
        }else if (color_property == 3) {
        	return Gfx.COLOR_GREEN;
        }else if (color_property == 4) {
        	return Gfx.COLOR_DK_GREEN;
        }else if (color_property == 5) {
        	return Gfx.COLOR_LT_GRAY;
        }else if (color_property == 6) {
        	return Gfx.COLOR_DK_GRAY;
        }else if (color_property == 7) {
        	return Gfx.COLOR_ORANGE;
        }else if (color_property == 8) {
        	return Gfx.COLOR_PINK;
        }else if (color_property == 9) {
        	return Gfx.COLOR_PURPLE;
        }else if (color_property == 10) {
        	return Gfx.COLOR_RED;
        }else if (color_property == 11) {
        	return Gfx.COLOR_DK_RED;
        }else if (color_property == 12) {
        	return Gfx.COLOR_YELLOW;
        }
        return color_default;
    }  
           
}
