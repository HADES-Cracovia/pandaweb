function getdata(command,dId,async) {
  //async==true : do what you can when you can do it :D
  //async==false : do the task after you finished the previous task!
  
  // super duper debug line!
//   alert("caller is " + arguments.callee.caller.toString());
  
  var xmlhttp = null;
  //var cb = null;
  xmlhttp=new XMLHttpRequest();
  //cb = callback;
  var destId = dId;
  
  xmlhttp.onreadystatechange = function() {
    if(xmlhttp.readyState == 4 && xmlhttp.status==200) {
      //if(cb)
  if(document.getElementById(destId)){
  document.getElementById(destId).innerHTML  = xmlhttp.responseText;  
  }
        //cb(xmlhttp.responseText);
  //document.getElementById(destId).innerHTML  = xmlhttp.responseText;  
      }
    }

  xmlhttp.open("GET",command,async);
  xmlhttp.send(null);
  }