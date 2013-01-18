

function getdata(command,callback) {
  var xmlhttp = null;
  var cb = null;
  xmlhttp=new XMLHttpRequest();
  cb = callback;
  
  xmlhttp.onreadystatechange = function() {
    if(xmlhttp.readyState == 4) {
      if(cb)
        cb(xmlhttp.responseText);
      }
    }
  xmlhttp.open("GET",command,true);
  xmlhttp.send(null);
  }
  

function SciNotation(v) {
  if (v == 0) return "0";
  if (v < 1000) return  v;
  if (v < 20000) return  (v/1E3).toFixed(3)+"k" ;
  if (v < 1E6) return  (v/1E3).toFixed(2)+"k" ;
  if (v < 20E6) return  (v/1E6).toFixed(3)+"M" ;
  if (v < 1E9) return  (v/1E6).toFixed(2)+"M" ;
  if (v < 20E9) return  (v/1E9).toFixed(3)+"G" ;
  if (v < 1E12) return  (v/1E9).toFixed(2)+"G" ;
  return  v;
  }
  
  

function findcolor(v,min,max,lg) {
  if (!(v>0)){    v = 0;}
  if (v && lg){        v = log(v);}
  if (min && lg){      min = log(min);}
  if (max && lg){      max = log(max);}
  if (max == undefined){max  = 1;}

  step = ((max-min)/655);
  v =  Math.round(v);

  if (v == 0 || v<min) {
    return "transparent";
  } else {
    v -= min;
    if (step) {
      v  = v/step;
      }
    if (v<156) {
      r = 0;
      g = v+100;
      b = 0;
    } else if (v<412) {
      v -= 156;
      r = v;
      g = 255;
      b = 0;
    } else {
      v -= 412;
      r = 255;
      g = 255-v;
      b = 0;
    }
  }
r = Math.floor(r);
g = Math.floor(g);
b = Math.floor(b);

  return "rgb("+(r%256)+","+(g%256)+","+(b%256)+")";
  
}