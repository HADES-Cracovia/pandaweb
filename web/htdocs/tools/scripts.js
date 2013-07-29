

function getdata(command,callback,option) {
  var xmlhttp = null;
  var cb = null;
  xmlhttp=new XMLHttpRequest();
  cb = callback;
  
  xmlhttp.onreadystatechange = function() {
    if(xmlhttp.readyState == 4) {
      if(cb && option)
        cb(xmlhttp.responseText,option);
      else if(cb)
        cb(xmlhttp.responseText);
      }
    }
  xmlhttp.open("GET",command,true);
  xmlhttp.send(null);
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