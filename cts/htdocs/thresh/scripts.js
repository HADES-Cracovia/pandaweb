

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
  
  
//   function reload() {
//   xmlhttp=new XMLHttpRequest();
//   xmlhttp.onreadystatechange = function() {
//     if(xmlhttp.readyState == 4) {
//       document.getElementById("content").innerHTML=xmlhttp.responseText;
//       if(document.getElementById('logbox')) {
//         if(saveScrollTop) {
//           document.getElementById('logbox').scrollTop = saveScrollTop;
//           }
//         }
// 
//       document.getElementById("stop").style.background="#444";
//       reloadevery = setTimeout('reload()',$.($delay*1000).qq$);
//       }
//     };
//   if(document.getElementById('logbox')) {
//     saveScrollTop = document.getElementById('logbox').scrollTop;
//     if (saveScrollTop == 0) {saveScrollTop = 0.1;}
//     }
//   xmlhttp.open("GET","get.cgi?$.$ENV{'QUERY_STRING'}.qq$",true);
//   xmlhttp.send(null);
//   document.getElementById("stop").style.background="#111";
//   }